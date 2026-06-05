import 'dart:convert' show jsonEncode;

import 'package:affinidi_tdk_common/affinidi_tdk_common.dart' hide LogLevel;
import 'package:affinidi_tdk_cryptography/affinidi_tdk_cryptography.dart';
import 'package:ssi/ssi.dart'
    show ParsedVerifiableCredential, VerifiableCredential;

import '../exceptions/tdk_exception_type.dart';
import '../models/auto_consent_result.dart';
import '../models/claimed_credentials_result.dart';
import '../models/iota_consent_record.dart';
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
    required ClaimedCredentialsResult claimedCredentials,
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

    // Parse PD fields once — they come from the request, not from any stored record.
    final rawDescriptors =
        shareRequest.presentationDefinition['input_descriptors'];
    if (rawDescriptors is! List<dynamic>) {
      throw TdkException(
        message: 'Presentation definition is missing input_descriptors.',
        code: TdkExceptionType.invalidPresentationDefinition.code,
      );
    }

    final List<PDDescriptor> inputDescriptors;
    try {
      inputDescriptors = rawDescriptors
          .map((e) => PDDescriptor.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e, stackTrace) {
      Error.throwWithStackTrace(
        TdkException(
          message: 'Malformed input_descriptors in presentation definition.',
          code: TdkExceptionType.invalidPresentationDefinition.code,
          originalMessage: e.toString(),
        ),
        stackTrace,
      );
    }

    final definitionId = shareRequest.presentationDefinition['id'];
    if (definitionId is! String) {
      throw TdkException(
        message: 'Presentation definition is missing a valid id.',
        code: TdkExceptionType.invalidPresentationDefinition.code,
      );
    }

    final allVcs = claimedCredentials.vcsGroups.values
        .expand((group) => group.allAvailableVCs)
        .map((a) => a.vc)
        .whereType<ParsedVerifiableCredential<dynamic>>()
        .toList();

    for (final record in enabledCandidates) {
      if (record.isConsentManagementEnabled) {
        continue;
      }

      final previouslySelectedVcs = record.sharedVcIds
          .map(
            (id) => allVcs.where((vc) => vc.id?.toString() == id).firstOrNull,
          )
          .whereType<ParsedVerifiableCredential<dynamic>>()
          .toList();

      if (previouslySelectedVcs.length != record.sharedVcIds.length) {
        continue;
      }

      if (inputDescriptors.length != previouslySelectedVcs.length) {
        continue;
      }

      final remainingVcs = List<ParsedVerifiableCredential<dynamic>>.of(
        previouslySelectedVcs,
      );
      final previouslySelected =
          <
            ({
              PDDescriptor descriptor,
              ParsedVerifiableCredential<dynamic> credential,
            })
          >[];

      var descriptorMatchFailed = false;
      for (final descriptor in inputDescriptors) {
        final match = remainingVcs
            .where(
              (vc) => PexEvaluator.selectMatching(descriptor.toJson(), [
                vc,
              ]).isNotEmpty,
            )
            .firstOrNull;

        if (match == null) {
          descriptorMatchFailed = true;
          break;
        }
        previouslySelected.add((descriptor: descriptor, credential: match));
        remainingVcs.remove(match);
      }
      if (descriptorMatchFailed) continue;

      if (record.clientId != shareRequest.request.clientId) {
        continue;
      }

      final currentHash = _computeConsentHash(
        profileId: record.profileId,
        vaultId: vaultId,
        clientId: record.clientId,
        verifierName: verifierMetadata.name,
        logo: verifierMetadata.logo,
        siteUrl: verifierMetadata.origin,
        vcsFingerprint: _stringifyVcs(previouslySelectedVcs),
      );

      if (record.hash != currentHash) {
        continue;
      }

      final iotaRequest = shareRequest.request;
      final redirectUri = await _shareResponseService.submitShareResponse(
        state: iotaRequest.state,
        nonce: iotaRequest.nonce,
        clientId: iotaRequest.clientId,
        definitionId: definitionId,
        selectedCredentials: previouslySelected,
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
