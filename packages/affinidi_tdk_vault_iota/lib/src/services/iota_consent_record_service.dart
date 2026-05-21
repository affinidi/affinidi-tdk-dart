import 'dart:convert' show jsonEncode;

import 'package:affinidi_tdk_common/affinidi_tdk_common.dart';
import 'package:affinidi_tdk_cryptography/affinidi_tdk_cryptography.dart';
import 'package:ssi/ssi.dart' show VerifiableCredential;

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
/// - `hash` = `sha1("$profileId|$did|$clientId|$name|$logo|$origin|$vcsFingerprint|$datapointsFingerprint")`
///   — full fingerprint that changes if the profile, verifier branding,
///   selected credentials, or ZPD datapoints change.
///
/// The hash structure matches vault_universal_ui's `_generateHash` concept:
/// VC fingerprint is `issuer-id-validFrom-credentialSubject` per VC joined
/// with `|`, and datapoints are `key:value` pairs joined with `|`.
/// ZPD datapoints are omitted from non-ZPD flows (pass empty map).
///
/// The `requestHash` deduplication key is supplied by the caller — the
/// consumer is free to use any algorithm.
///
/// If a record with the same `requestHash` already exists it is
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
    required String requestHash,
    required String clientId,
    required VerifierClientMetadata verifierMetadata,
    required String profileId,
    required String profileName,
    required String did,
    required List<VerifiableCredential> sharedVcs,
    required String claimedVcTypesCsv,
    required bool isAutoShareEnabled,
    Map<String, String> historySharedData = const {},
    Map<String, dynamic> datapoints = const {},
    bool isConsentManagementEnabled = false,
  }) async {
    _logger.log(LogLevel.fine, 'Saving consent record for clientId: $clientId');

    final sharedVcIds = sharedVcs.map((vc) => vc.id?.toString() ?? '').toList();
    final hash = _computeConsentHash(
      profileId: profileId,
      did: did,
      clientId: clientId,
      verifierName: verifierMetadata.name,
      logo: verifierMetadata.logo,
      siteUrl: verifierMetadata.origin,
      vcsFingerprint: _stringifyVcs(sharedVcs),
      datapointsFingerprint: _buildDatapointsFingerprint(datapoints),
    );

    final existing = await _store.findByRequestHash(requestHash);

    final record = IotaConsentRecord(
      hash: hash,
      requestHash: requestHash,
      logo: verifierMetadata.logo,
      siteUrl: verifierMetadata.origin,
      sharedAt: existing?.sharedAt ?? DateTime.now().toUtc().toIso8601String(),
      profileName: profileName,
      profileId: profileId,
      clientId: clientId,
      isAutoShareEnabled: isAutoShareEnabled,
      sharedVcIds: sharedVcIds,
      claimedVcTypesCsv: claimedVcTypesCsv,
      historySharedData: historySharedData,
      isConsentManagementEnabled: isConsentManagementEnabled,
    );

    try {
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
  /// Matches vault_universal_ui's `_generateHash` structure:
  /// `profileId|did|clientId|name|logo|origin|vcsFingerprint|datapointsFingerprint`.
  ///
  /// [did] is included for change detection (a DID rotation produces a new
  /// fingerprint) but is not persisted on [IotaConsentRecord] because it is
  /// available from the wallet at share time.
  ///
  /// Parameters:
  /// * [profileId] - ID of the profile used for the share.
  /// * [did] - Holder DID that signed the VP.
  /// * [clientId] - Verifier's client ID.
  /// * [verifierName] - Verifier display name; treated as empty string when absent.
  /// * [logo] - Verifier logo URL; treated as empty string when absent.
  /// * [siteUrl] - Verifier origin URL; treated as empty string when absent.
  /// * [vcsFingerprint] - Pipe-joined per-VC strings in presentation order.
  /// * [datapointsFingerprint] - Pipe-joined `key:value` ZPD pairs; empty for non-ZPD flows.
  ///
  /// Returns a hex SHA-1 digest that changes whenever the profile, verifier
  /// branding, selected credentials, or ZPD datapoints change.
  String _computeConsentHash({
    required String profileId,
    required String did,
    required String clientId,
    required String? verifierName,
    required String? logo,
    required String? siteUrl,
    required String vcsFingerprint,
    required String datapointsFingerprint,
  }) => _cryptography.createHash(
    hashSource:
        '$profileId|$did|$clientId|${verifierName ?? ''}|${logo ?? ''}|${siteUrl ?? ''}|$vcsFingerprint|$datapointsFingerprint',
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

  /// Builds a pipe-joined `key:value` fingerprint from ZPD [datapoints].
  ///
  /// Returns an empty string when [datapoints] is empty.
  String _buildDatapointsFingerprint(Map<String, dynamic> datapoints) {
    return datapoints.entries.map((e) => '${e.key}:${e.value}').join('|');
  }
}
