import 'dart:convert' show jsonEncode;

import 'package:affinidi_tdk_common/affinidi_tdk_common.dart';
import 'package:affinidi_tdk_cryptography/affinidi_tdk_cryptography.dart';
import 'package:ssi/ssi.dart' show VerifiableCredential;

import '../exceptions/tdk_exception_type.dart';
import '../models/auto_consent_result.dart';
import '../models/iota_consent_record.dart';
import '../models/verifier_client_metadata.dart';
import 'consent_storage.dart';
import 'iota_consent_record_service_interface.dart';

/// Persists a consent record after a successful Iota OID4VP share.
///
/// Computes an internal fingerprint and delegates storage to the
/// consumer-provided [ConsentStorage]:
///
/// - `hash` = `sha1("$profileId|$vaultId|$clientId|$name|$logo|$origin|$vcsFingerprint")`
///   — full fingerprint that changes if the profile, verifier branding,
///   or selected credentials change. Used as the storage key, matching
///   vault_universal_ui's `addOrUpdate` behaviour.
///
/// The VC fingerprint matches vault_universal_ui's `_stringifyVCs` concept:
/// each VC contributes `issuer-id-validFrom-credentialSubject`, joined with
/// `|` in presentation order. ZPD datapoints are not tracked by the TDK.
///
/// [IotaConsentRecord.sharedAt] is always set to the current UTC time,
/// so it reflects the most recent share — the same semantics as
/// vault_universal_ui's `firstVisited` column ("Last Consent" in the UI).
class IotaConsentRecordService implements IotaConsentRecordServiceInterface {
  final ConsentStorage _store;
  final CryptographyServiceInterface _cryptography;
  final Logger _logger;

  /// Creates an [IotaConsentRecordService].
  ///
  /// Parameters:
  /// * [store] - Consumer-provided storage backend for consent records.
  /// * [cryptography] - Cryptography service used to compute SHA-1 hashes.
  /// * [logger] - Optional logger; defaults to [Logger.instance].
  IotaConsentRecordService({
    required ConsentStorage store,
    required CryptographyServiceInterface cryptography,
    Logger? logger,
  }) : _store = store,
       _cryptography = cryptography,
       _logger = logger ?? Logger.instance;

  @override
  String computeRequestHash({
    required String clientId,
    required Map<String, dynamic> presentationDefinition,
  }) => _cryptography.createHash(
    hashSource: '$clientId|${jsonEncode(presentationDefinition)}',
  );

  @override
  Future<AutoConsentResult> tryAutomaticConsent({
    required String requestHash,
    required String clientId,
    required VerifierClientMetadata verifierMetadata,
    required String profileId,
    required String vaultId,
    required List<VerifiableCredential> availableVcs,
  }) async {
    _logger.log(
      LogLevel.fine,
      'tryAutomaticConsent: checking requestHash=$requestHash',
    );

    final IotaConsentRecord? record;
    try {
      record = await _store.findByRequestHash(requestHash);
    } catch (e) {
      throw TdkException(
        message: 'Failed to read consent record from store.',
        code: TdkExceptionType.failedToReadConsentRecord.code,
        originalMessage: e.toString(),
      );
    }

    if (record == null) {
      _logger.log(LogLevel.fine, 'tryAutomaticConsent: no record found');
      return const AutoConsentDeclined();
    }

    if (!record.isAutoShareEnabled || record.isConsentManagementEnabled) {
      _logger.log(
        LogLevel.fine,
        'tryAutomaticConsent: auto-share disabled or consent management active',
      );
      return const AutoConsentDeclined();
    }

    if (record.sharedVcIds.isEmpty) {
      _logger.log(
        LogLevel.fine,
        'tryAutomaticConsent: stored record has no shared VC IDs',
      );
      return const AutoConsentDeclined();
    }

    // Verify all previously shared VC IDs are still available.
    final vcsToShare = record.sharedVcIds
        .map((id) => availableVcs.cast<VerifiableCredential?>().firstWhere(
              (vc) => vc?.id?.toString() == id,
              orElse: () => null,
            ))
        .whereType<VerifiableCredential>()
        .toList();

    if (vcsToShare.length != record.sharedVcIds.length) {
      _logger.log(
        LogLevel.fine,
        'tryAutomaticConsent: previously shared VCs no longer all available',
      );
      return const AutoConsentDeclined();
    }

    // Recompute the full share fingerprint and compare it to the stored hash.
    final recomputedHash = _computeConsentHash(
      profileId: profileId,
      vaultId: vaultId,
      clientId: clientId,
      verifierName: verifierMetadata.name,
      logo: verifierMetadata.logo,
      siteUrl: verifierMetadata.origin,
      vcsFingerprint: _stringifyVcs(vcsToShare),
    );

    if (recomputedHash != record.hash) {
      _logger.log(
        LogLevel.fine,
        'tryAutomaticConsent: hash mismatch — verifier branding or VC content changed',
      );
      return const AutoConsentDeclined();
    }

    _logger.log(
      LogLevel.fine,
      'tryAutomaticConsent: approved — ${vcsToShare.length} VC(s)',
    );
    return AutoConsentApproved(vcsToShare: vcsToShare);
  }

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
    _logger.log(LogLevel.fine, 'Saving consent record for clientId: $clientId');

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

      _logger.log(
        LogLevel.warning,
        'Failed to persist consent record',
        error: e,
        stackTrace: stackTrace,
      );

      Error.throwWithStackTrace(
        TdkException(
          message: 'Failed to persist consent record.',
          code: TdkExceptionType.failedToPersistConsentRecord.code,
          originalMessage: e.toString(),
        ),
        stackTrace,
      );
    }

    _logger.log(LogLevel.fine, 'Consent record saved for clientId: $clientId');
  }

  /// Computes the full share fingerprint covering all share-event fields.
  ///
  /// Matches vault_universal_ui's `_generateHash` field ordering:
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
