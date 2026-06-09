import 'dart:convert' show jsonEncode;

import 'package:affinidi_tdk_common/affinidi_tdk_common.dart' hide LogLevel;
import 'package:affinidi_tdk_cryptography/affinidi_tdk_cryptography.dart';
import 'package:dcql/dcql.dart'
    show
        DcqlCredential,
        DcqlCredentialQuery,
        DcqlCredentialSet,
        DigitalCredential,
        W3CDigitalCredential;
import 'package:ssi/ssi.dart'
    show
        ParsedVerifiableCredential,
        VerifiableCredential,
        dmV1ContextUrl,
        dmV2ContextUrl;

import '../exceptions/tdk_exception_type.dart';
import '../helpers/presentation_definition_parser.dart';
import '../models/auto_consent_result.dart';
import '../models/iota_consent_record.dart';
import '../models/matched_credentials_result.dart';
import '../models/pd_descriptor.dart';
import '../models/share_requirements.dart';
import '../models/verifier_client_metadata.dart';
import 'consent_storage.dart';
import 'iota_consent_record_service_interface.dart';
import 'iota_share_response_service_interface.dart';
import 'share_requirements_matcher_service.dart';

/// Persists a consent record after a successful Iota OID4VP share.
///
/// Computes an internal fingerprint and delegates storage to the
/// consumer-provided [ConsentStorage]:
///
/// - `hash` = `sha1("$profileId|$vaultId|$clientId|$name|$logo|$origin|$vcsFingerprint")`
///   — full fingerprint that changes if the profile, verifier branding,
///   or selected credentials change. Used as the storage key
///
/// The VC fingerprint format: each VC contributes `issuer-id-validFrom-credentialSubject`,
/// joined with `|` in presentation order. ZPD datapoints are not tracked by the TDK.
///
/// [IotaConsentRecord.sharedAt] is always set to the current UTC time,
/// so it reflects the most recent share ("Last Consent" in the UI).
class IotaConsentRecordService implements IotaConsentRecordServiceInterface {
  final ConsentStorage _store;
  final CryptographyServiceInterface _cryptography;
  final IotaShareResponseServiceInterface _shareResponseService;
  final Logger _logger;

  /// Creates an [IotaConsentRecordService].
  ///
  /// Parameters:
  /// * [store] - Consumer-provided storage backend for consent records.
  /// * [cryptography] - Cryptography service used to compute SHA-1 hashes.
  /// * [shareResponseService] - Service used to build and submit the VP.
  /// * [logger] - Optional logger; defaults to [Logger.instance].
  IotaConsentRecordService({
    required ConsentStorage store,
    required CryptographyServiceInterface cryptography,
    required IotaShareResponseServiceInterface shareResponseService,
    Logger? logger,
  }) : _store = store,
       _cryptography = cryptography,
       _shareResponseService = shareResponseService,
       _logger = logger ?? Logger.instance;

  @override
  Future<void> saveConsentRecord({
    required String requestHash,
    required String clientId,
    required VerifierClientMetadata verifierMetadata,
    required String profileId,
    required String profileName,
    required String vaultId,
    required List<VerifiableCredential> sharedVcs,
    required String claimedVcTypesCsv,
    required bool isAutoShareEnabled,
    Map<String, String> historySharedData = const {},
    bool isConsentManagementEnabled = false,
  }) async {
    final sharedVcIds = sharedVcs.map((vc) => vc.id?.toString() ?? '').toList();
    final hash = _computeConsentHash(
      profileId: profileId,
      vaultId: vaultId,
      clientId: clientId,
      verifierName: verifierMetadata.name,
      logo: verifierMetadata.logo,
      siteUrl: verifierMetadata.origin,
      vcsFingerprint: _stringifyVcs(sharedVcs),
    );

    try {
      final record = IotaConsentRecord(
        hash: hash,
        requestHash: requestHash,
        logo: verifierMetadata.logo,
        siteUrl: verifierMetadata.origin,
        sharedAt: DateTime.now().toUtc().toIso8601String(),
        profileName: profileName,
        profileId: profileId,
        clientId: clientId,
        isAutoShareEnabled: isAutoShareEnabled,
        sharedVcIds: sharedVcIds,
        claimedVcTypesCsv: claimedVcTypesCsv,
        historySharedData: historySharedData,
        isConsentManagementEnabled: isConsentManagementEnabled,
      );

      await _store.saveOrUpdate(record);
    } catch (e, stackTrace) {
      if (e is TdkException) rethrow;

      _logger.warning('Failed to persist consent record');

      Error.throwWithStackTrace(
        TdkException(
          message: 'Failed to persist consent record.',
          code: TdkExceptionType.failedToPersistConsentRecord.code,
          originalMessage: e.toString(),
        ),
        stackTrace,
      );
    }
  }

  @override
  Future<AutoConsentResult> tryAutomaticConsent({
    required Oid4vpShareRequest shareRequest,
    required MatchedCredentialsResult matchedCredentials,
    required VerifierClientMetadata verifierMetadata,
    required String requestHash,
    required String vaultId,
  }) async {
    final List<IotaConsentRecord> candidates;
    try {
      candidates = await _store.findAllByRequestHash(requestHash);
    } catch (e, stackTrace) {
      if (e is TdkException) rethrow;

      Error.throwWithStackTrace(
        TdkException(
          message: 'Failed to read consent record.',
          code: TdkExceptionType.failedToReadConsentRecord.code,
          originalMessage: e.toString(),
        ),
        stackTrace,
      );
    }

    final enabledCandidates = candidates
        .where((r) => r.isAutoShareEnabled)
        .toList();

    if (enabledCandidates.isEmpty) {
      return const AutoConsentDeclined();
    }

    final allVcs = matchedCredentials.availableCredentials
        .whereType<ParsedVerifiableCredential<dynamic>>()
        .toList();

    return switch (shareRequest) {
      PexShareRequest pex => _tryPexAutoConsent(
        pex,
        enabledCandidates,
        allVcs,
        verifierMetadata,
        vaultId,
      ),
      DcqlShareRequest dcql => _tryDcqlAutoConsent(
        dcql,
        enabledCandidates,
        allVcs,
        verifierMetadata,
        vaultId,
      ),
    };
  }

  Future<AutoConsentResult> _tryPexAutoConsent(
    PexShareRequest shareRequest,
    List<IotaConsentRecord> enabledCandidates,
    List<ParsedVerifiableCredential<dynamic>> allVcs,
    VerifierClientMetadata verifierMetadata,
    String vaultId,
  ) async {
    // Parse PD fields once — they come from the request, not from any stored
    // record. Both calls fail fast with a typed exception on a malformed PD.
    final pd = shareRequest.presentationDefinition;
    final inputDescriptors = PresentationDefinitionParser.parseInputDescriptors(
      pd,
    );
    PresentationDefinitionParser.parseDefinitionId(pd);

    return _matchAndSubmit<PDDescriptor>(
      shareRequest: shareRequest,
      requirements: inputDescriptors,
      enabledCandidates: enabledCandidates,
      allVcs: allVcs,
      verifierMetadata: verifierMetadata,
      vaultId: vaultId,
      matches: (descriptor, vc) =>
          PexEvaluator.selectMatching(descriptor.toJson(), [vc]).isNotEmpty,
    );
  }

  Future<AutoConsentResult> _tryDcqlAutoConsent(
    DcqlShareRequest shareRequest,
    List<IotaConsentRecord> enabledCandidates,
    List<ParsedVerifiableCredential<dynamic>> allVcs,
    VerifierClientMetadata verifierMetadata,
    String vaultId,
  ) {
    final credentialSets = shareRequest.dcqlQuery.credentialSets;
    if (credentialSets != null && credentialSets.isNotEmpty) {
      return _tryDcqlWithSetsAutoConsent(
        shareRequest,
        enabledCandidates,
        allVcs,
        verifierMetadata,
        vaultId,
      );
    }
    return _matchAndSubmit<DcqlCredential>(
      shareRequest: shareRequest,
      requirements: shareRequest.dcqlQuery.credentials.toList(),
      enabledCandidates: enabledCandidates,
      allVcs: allVcs,
      verifierMetadata: verifierMetadata,
      vaultId: vaultId,
      matches: _vcMatchesDcqlCredential,
      isMultiple: (credential) => credential.multiple,
    );
  }

  /// Auto-consent path for DCQL requests that include `credential_sets`.
  ///
  /// Unlike plain DCQL, a valid share covers only the subset of credential
  /// queries satisfying one option per required set, so the strict
  /// requirements-count equality check used by [_matchAndSubmit] would
  /// incorrectly decline valid stored selections.
  Future<AutoConsentResult> _tryDcqlWithSetsAutoConsent(
    DcqlShareRequest shareRequest,
    List<IotaConsentRecord> enabledCandidates,
    List<ParsedVerifiableCredential<dynamic>> allVcs,
    VerifierClientMetadata verifierMetadata,
    String vaultId,
  ) async {
    final dcqlQuery = shareRequest.dcqlQuery;
    final credentialSets = dcqlQuery.credentialSets!;

    for (final record in enabledCandidates) {
      if (record.isConsentManagementEnabled) continue;

      final previouslySelectedVcs = record.sharedVcIds
          .map(
            (id) => allVcs.where((vc) => vc.id?.toString() == id).firstOrNull,
          )
          .whereType<ParsedVerifiableCredential<dynamic>>()
          .toList();

      // Decline if any previously-stored VC has disappeared from the vault.
      if (previouslySelectedVcs.length != record.sharedVcIds.length) continue;

      // Greedily assign each stored VC to a credential query.
      // For multiple:true queries, claim all matching VCs; for multiple:false
      // (the default), claim exactly one.
      //
      // Queries are processed most-constrained first (fewest matching VCs
      // first) to reduce false negatives from greedy assignment when a single
      // VC can satisfy more than one query. A full bipartite matching would
      // eliminate false negatives entirely but is not warranted here: false
      // negatives only cause a fall-through to manual confirmation, they are
      // not a correctness or security issue.
      final remainingVcs = List<ParsedVerifiableCredential<dynamic>>.of(
        previouslySelectedVcs,
      );
      final sortedCredentials = dcqlQuery.credentials.toList()
        ..sort(
          (a, b) => remainingVcs
              .where((vc) => _vcMatchesDcqlCredential(a, vc))
              .length
              .compareTo(
                remainingVcs
                    .where((vc) => _vcMatchesDcqlCredential(b, vc))
                    .length,
              ),
        );
      final coveredQueryIds = <String>{};
      for (final query in sortedCredentials) {
        if (query.multiple) {
          final matches = remainingVcs
              .where((vc) => _vcMatchesDcqlCredential(query, vc))
              .toList();
          if (matches.isNotEmpty) {
            coveredQueryIds.add(query.id);
            for (final vc in matches) {
              remainingVcs.remove(vc);
            }
          }
        } else {
          final match = remainingVcs
              .where((vc) => _vcMatchesDcqlCredential(query, vc))
              .firstOrNull;
          if (match != null) {
            coveredQueryIds.add(query.id);
            remainingVcs.remove(match);
          }
        }
      }

      // Every stored VC must have been matched to some query; otherwise at
      // least one VC is no longer valid for this request.
      if (remainingVcs.isNotEmpty) continue;

      // All required credential_sets must be satisfied by the covered queries.
      final setsSatisfied = _requiredSetsSatisfied(
        credentialSets,
        coveredQueryIds,
      );
      if (!setsSatisfied) continue;

      if (record.clientId != shareRequest.request.clientId) continue;

      final currentHash = _computeConsentHash(
        profileId: record.profileId,
        vaultId: vaultId,
        clientId: record.clientId,
        verifierName: verifierMetadata.name,
        logo: verifierMetadata.logo,
        siteUrl: verifierMetadata.origin,
        vcsFingerprint: _stringifyVcs(previouslySelectedVcs),
      );

      if (record.hash != currentHash) continue;

      final redirectUri = await _shareResponseService.submitShareResponse(
        shareRequest: shareRequest,
        selectedCredentials: previouslySelectedVcs,
        acceptResponseUri: shareRequest.request.acceptResponseUri,
      );
      return AutoConsentApproved(redirectUri: redirectUri);
    }

    return const AutoConsentDeclined();
  }

  /// Returns `true` when every `required` set has at least one option whose
  /// query IDs are all contained in [coveredQueryIds].
  static bool _requiredSetsSatisfied(
    Iterable<DcqlCredentialSet> credentialSets,
    Set<String> coveredQueryIds,
  ) => credentialSets
      .where((s) => s.required)
      .every(
        (set) =>
            set.options.any((option) => option.every(coveredQueryIds.contains)),
      );

  /// Returns `true` if [vc] matches the given DCQL [credential] query using
  /// the `dcql` package evaluator.
  static bool _vcMatchesDcqlCredential(
    DcqlCredential credential,
    VerifiableCredential vc,
  ) {
    final wrapped = _toDigitalCredential(vc);
    if (wrapped == null) return false;
    final query = DcqlCredentialQuery(credentials: [credential]);
    final result = query.query([wrapped]);
    return result.verifiableCredentials[credential.id]?.isNotEmpty == true;
  }

  /// Wraps a [VerifiableCredential] for evaluation by the `dcql` package.
  /// Returns `null` for unsupported formats.
  static DigitalCredential? _toDigitalCredential(VerifiableCredential vc) {
    final contextUri = vc.context.firstUri?.toString();
    try {
      if (contextUri == dmV1ContextUrl) {
        return W3CDigitalCredential.fromLdVcDataModelV1(vc.toJson());
      }
      if (contextUri == dmV2ContextUrl) {
        return W3CDigitalCredential.fromLdVcDataModelV2(vc.toJson());
      }
      return null;
    } on Exception {
      return null;
    }
  }

  /// Reconstructs the previously-approved VC set for each candidate record and
  /// submits the VP for the first record that satisfies every guard.
  ///
  /// Parameters:
  /// * [requirements] - The per-VC constraints from the live request
  ///   (PD descriptors for PEX, credential queries for DCQL).
  /// * [matches] - Predicate deciding whether a VC satisfies a requirement.
  /// * [isMultiple] - Optional predicate; when it returns `true` for a
  ///   requirement, ALL matching VCs are claimed (DCQL `multiple: true`).
  ///   When omitted or `false`, exactly one VC is claimed per requirement.
  ///
  /// Returns [AutoConsentApproved] for the first passing record, otherwise
  /// [AutoConsentDeclined].
  Future<AutoConsentResult> _matchAndSubmit<T>({
    required Oid4vpShareRequest shareRequest,
    required List<T> requirements,
    required List<IotaConsentRecord> enabledCandidates,
    required List<ParsedVerifiableCredential<dynamic>> allVcs,
    required VerifierClientMetadata verifierMetadata,
    required String vaultId,
    required bool Function(
      T requirement,
      ParsedVerifiableCredential<dynamic> vc,
    )
    matches,
    bool Function(T requirement)? isMultiple,
  }) async {
    for (final record in enabledCandidates) {
      if (record.isConsentManagementEnabled) continue;

      final previouslySelectedVcs = record.sharedVcIds
          .map(
            (id) => allVcs.where((vc) => vc.id?.toString() == id).firstOrNull,
          )
          .whereType<ParsedVerifiableCredential<dynamic>>()
          .toList();

      if (previouslySelectedVcs.length != record.sharedVcIds.length) continue;

      final remainingVcs = List<ParsedVerifiableCredential<dynamic>>.of(
        previouslySelectedVcs,
      );
      final matched = <ParsedVerifiableCredential<dynamic>>[];

      var matchFailed = false;
      for (final requirement in requirements) {
        if (isMultiple?.call(requirement) == true) {
          // Claim every stored VC that satisfies this query (multiple: true).
          final allMatches = remainingVcs
              .where((vc) => matches(requirement, vc))
              .toList();
          if (allMatches.isEmpty) {
            matchFailed = true;
            break;
          }
          matched.addAll(allMatches);
          for (final vc in allMatches) {
            remainingVcs.remove(vc);
          }
        } else {
          final match = remainingVcs
              .where((vc) => matches(requirement, vc))
              .firstOrNull;

          if (match == null) {
            matchFailed = true;
            break;
          }
          matched.add(match);
          remainingVcs.remove(match);
        }
      }
      if (matchFailed) continue;
      // Every stored VC must be accounted for; orphaned VCs indicate the
      // request changed (e.g. a descriptor was removed or a query type changed).
      if (remainingVcs.isNotEmpty) continue;

      if (record.clientId != shareRequest.request.clientId) continue;

      final currentHash = _computeConsentHash(
        profileId: record.profileId,
        vaultId: vaultId,
        clientId: record.clientId,
        verifierName: verifierMetadata.name,
        logo: verifierMetadata.logo,
        siteUrl: verifierMetadata.origin,
        vcsFingerprint: _stringifyVcs(previouslySelectedVcs),
      );

      if (record.hash != currentHash) continue;

      final redirectUri = await _shareResponseService.submitShareResponse(
        shareRequest: shareRequest,
        selectedCredentials: matched,
        acceptResponseUri: shareRequest.request.acceptResponseUri,
      );
      return AutoConsentApproved(redirectUri: redirectUri);
    }

    return const AutoConsentDeclined();
  }

  /// Computes the full share fingerprint covering all share-event fields.
  ///
  /// Hash field ordering:
  /// `profileId|vaultId|clientId|name|logo|origin|vcsFingerprint`.
  /// ZPD datapoints are not tracked by the TDK and are omitted from the hash.
  ///
  /// [vaultId] is included for change detection so that switching wallets
  /// produces a distinct fingerprint. It is not persisted on [IotaConsentRecord]
  /// because it is available from the wallet at share time.
  ///
  /// Parameters:
  /// * [profileId] - ID of the profile used for the share.
  /// * [vaultId] - Opaque vault or wallet identifier (e.g. a DID or account ID).
  /// * [clientId] - Verifier's client ID.
  /// * [verifierName] - Verifier display name; treated as empty string when absent.
  /// * [logo] - Verifier logo URL; treated as empty string when absent.
  /// * [siteUrl] - Verifier origin URL; treated as empty string when absent.
  /// * [vcsFingerprint] - Pipe-joined per-VC strings in presentation order.
  ///
  /// Returns a hex SHA-1 digest that changes whenever the profile, verifier
  /// branding, or selected credentials change.
  String _computeConsentHash({
    required String profileId,
    required String vaultId,
    required String clientId,
    required String? verifierName,
    required String? logo,
    required String? siteUrl,
    required String vcsFingerprint,
  }) => _cryptography.createHash(
    hashSource:
        '$profileId|$vaultId|$clientId|${verifierName ?? ''}|${logo ?? ''}|${siteUrl ?? ''}|$vcsFingerprint',
  );

  /// Builds a pipe-joined fingerprint string from a list of [VerifiableCredential]s.
  ///
  /// Each VC contributes one segment: `issuer-id-validFrom-credentialSubject`.
  /// VCs are joined in the order they were presented (no sorting).
  String _stringifyVcs(List<VerifiableCredential> vcs) {
    return vcs
        .map((vc) {
          final credentialSubjectJson = vc.credentialSubject.isEmpty
              ? '{}'
              : jsonEncode(vc.credentialSubject.first.toJson());
          return '${vc.issuer.id}-${vc.id}-${vc.validFrom?.toIso8601String() ?? ''}-$credentialSubjectJson';
        })
        .join('|');
  }
}
