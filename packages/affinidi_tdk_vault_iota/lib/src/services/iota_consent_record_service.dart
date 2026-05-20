import 'package:affinidi_tdk_common/affinidi_tdk_common.dart';
import 'package:affinidi_tdk_cryptography/affinidi_tdk_cryptography.dart';

import '../exceptions/tdk_exception_type.dart';
import '../models/iota_consent_record.dart';
import '../models/verifier_client_metadata.dart';
import 'consent_record_store.dart';
import 'iota_consent_record_service_interface.dart';

/// Persists a consent record after a successful Iota OID4VP share.
///
/// Computes an internal fingerprint and delegates storage to the
/// consumer-provided [ConsentRecordStore]:
///
/// - `hash` = `sha1("$profileId|$did|$clientId|$logo|$siteUrl|$vcFingerprint")`
///   — full fingerprint that changes if the profile, verifier branding, or
///   selected credentials change.
///
/// The `requestHash` deduplication key is supplied by the caller — the
/// consumer is free to use any algorithm.
///
/// If a record with the same `requestHash` and `did` already exists it is
/// updated rather than duplicated.
class IotaConsentRecordService implements IotaConsentRecordServiceInterface {
  final ConsentRecordStore _store;
  final CryptographyServiceInterface _cryptography;
  final Logger _logger;

  /// Creates an [IotaConsentRecordService].
  ///
  /// Parameters:
  /// * [store] - Consumer-provided storage backend for consent records.
  /// * [cryptography] - Cryptography service used to compute SHA-1 hashes.
  /// * [logger] - Optional logger; defaults to [Logger.instance].s
  IotaConsentRecordService({
    required ConsentRecordStore store,
    required CryptographyServiceInterface cryptography,
    Logger? logger,
  }) : _store = store,
       _cryptography = cryptography,
       _logger = logger ?? Logger.instance;

  @override
  Future<void> saveConsentRecord({
    required String requestHash,
    required String clientId,
    required VerifierClientMetadata verifierMetadata,
    required String profileId,
    required String profileName,
    required String did,
    required List<String> sharedVcIds,
    required String claimedVcTypesCsv,
    required bool isAutoShareEnabled,
    Map<String, String> historySharedData = const {},
    bool isConsentManagementEnabled = false,
  }) async {
    _logger.log(LogLevel.fine, 'Saving consent record for clientId: $clientId');

    try {
      final sortedVcIds = List<String>.from(sharedVcIds)..sort();
      final hash = _computeConsentHash(
        profileId: profileId,
        did: did,
        clientId: clientId,
        logo: verifierMetadata.logo,
        siteUrl: verifierMetadata.origin,
        vcFingerprint: sortedVcIds.join('|'),
      );

      final existing = await _store.findByRequestHash(requestHash);

      final record = IotaConsentRecord(
        hash: hash,
        requestHash: requestHash,
        logo: verifierMetadata.logo,
        siteUrl: verifierMetadata.origin,
        sharedAt: existing?.sharedAt ?? DateTime.now().toIso8601String(),
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

      _logger.log(
        LogLevel.fine,
        'Consent record saved for clientId: $clientId',
      );
    } catch (e) {
      if (e is TdkException) rethrow;

      _logger.log(
        LogLevel.warning,
        'Failed to persist consent record',
        error: e,
      );

      throw TdkException(
        message: 'Failed to persist consent record.',
        code: TdkExceptionType.failedToPersistConsentRecord.code,
        originalMessage: e.toString(),
      );
    }
  }

  /// Computes the full share fingerprint covering all share-event fields.
  ///
  /// Parameters:
  /// * [profileId] - ID of the profile used for the share.
  /// * [did] - Holder DID that signed the VP.
  /// * [clientId] - Verifier's client ID.
  /// * [logo] - Verifier logo URL; treated as empty string when absent.
  /// * [siteUrl] - Verifier origin URL; treated as empty string when absent.
  /// * [vcFingerprint] - Sorted, pipe-joined VC IDs; sorting ensures order does not affect the hash.
  ///
  /// Returns a hex SHA-1 digest that changes whenever the profile, verifier branding, or selected credentials change.
  String _computeConsentHash({
    required String profileId,
    required String did,
    required String clientId,
    required String? logo,
    required String? siteUrl,
    required String vcFingerprint,
  }) => _cryptography.createHash(
    hashSource:
        '$profileId|$did|$clientId|${logo ?? ''}|${siteUrl ?? ''}|$vcFingerprint',
  );
}
