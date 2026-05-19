import 'dart:convert';

import 'package:affinidi_tdk_common/affinidi_tdk_common.dart';
import 'package:affinidi_tdk_cryptography/affinidi_tdk_cryptography.dart';

import '../exceptions/tdk_exception_type.dart';
import '../models/iota_consent_record.dart';
import '../models/verifier_client_metadata.dart';
import 'consent_record_store.dart';
import 'iota_consent_record_service_interface.dart';

/// Persists a consent record after a successful Iota OID4VP share.
///
/// Computes two fingerprints and delegates storage to the consumer-provided
/// [ConsentRecordStore]:
///
/// - `requestHash` = `sha1("$clientId|${jsonEncode(presentationDefinition)}")`
///   — stable identifier for a verifier + PD combination.
/// - `hash` = `sha1("$profileId|$did|$clientId|$logo|$siteUrl|$vcFingerprint")`
///   — full fingerprint that changes if the profile, verifier branding, or
///   selected credentials change.
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
  /// * [logger] - Optional logger; defaults to [Logger.instance].
  IotaConsentRecordService({
    required ConsentRecordStore store,
    required CryptographyServiceInterface cryptography,
    Logger? logger,
  }) : _store = store,
       _cryptography = cryptography,
       _logger = logger ?? Logger.instance;

  @override
  Future<void> saveConsentRecord({
    required String clientId,
    required Map<String, dynamic> presentationDefinition,
    required VerifierClientMetadata verifierMetadata,
    required String profileId,
    required String profileName,
    required String did,
    required List<String> sharedVcIds,
    required String sharedVcTypesCsv,
    required bool isAutoShareEnabled,
  }) async {
    _logger.log(LogLevel.fine, 'Saving consent record for clientId: $clientId');

    try {
      final requestHash = _computeRequestHash(
        clientId: clientId,
        presentationDefinition: presentationDefinition,
      );

      final sortedVcIds = List<String>.from(sharedVcIds)..sort();
      final hash = _computeConsentHash(
        profileId: profileId,
        did: did,
        clientId: clientId,
        logo: verifierMetadata.logo,
        siteUrl: verifierMetadata.origin,
        vcFingerprint: sortedVcIds.join('|'),
      );

      final existing = await _store.findByRequestHashAndDid(requestHash, did);

      final record = IotaConsentRecord(
        hash: hash,
        requestHash: requestHash,
        logo: verifierMetadata.logo,
        siteUrl: verifierMetadata.origin,
        did: did,
        sharedAt: existing?.sharedAt ?? DateTime.now().toIso8601String(),
        profileName: profileName,
        profileId: profileId,
        clientId: clientId,
        isAutoShareEnabled: isAutoShareEnabled,
        sharedVcIds: sharedVcIds,
        sharedVcTypesCsv: sharedVcTypesCsv,
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

  /// Computes the request fingerprint as `sha1("$clientId|${jsonEncode(pd)}")`.
  ///
  /// Parameters:
  /// * [clientId] - The verifier's client ID.
  /// * [presentationDefinition] - The raw PD JSON map.
  ///
  /// Returns a hex SHA-1 digest stable across repeat requests with the same PD.
  String _computeRequestHash({
    required String clientId,
    required Map<String, dynamic> presentationDefinition,
  }) => _cryptography.createHash(
    hashSource: '$clientId|${jsonEncode(presentationDefinition)}',
  );

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
