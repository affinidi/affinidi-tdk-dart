import '../models/iota_consent_record.dart';

/// Consumer-provided storage backend for Iota consent records.
///
/// Implement this interface to persist consent history using any storage
/// technology.  [saveOrUpdate] must upsert by the combination of
/// [IotaConsentRecord.requestHash] and [IotaConsentRecord.did] so that each
/// vault holder's consent history is kept independent.
abstract interface class ConsentRecordStore {
  /// Persists a consent record, replacing any existing record with the same
  /// [IotaConsentRecord.requestHash] and [IotaConsentRecord.did].
  ///
  /// Parameters:
  /// * [record] - The consent record to persist or update.
  ///
  /// Throws if the underlying storage operation fails.
  Future<void> saveOrUpdate(IotaConsentRecord record);

  /// Returns the record matching [requestHash] and [did], or `null` if none
  /// exists.
  ///
  /// Parameters:
  /// * [requestHash] - Computed from `sha1(clientId | presentationDefinition)`.
  /// * [did] - The holder DID that signed the VP for this record.
  Future<IotaConsentRecord?> findByRequestHashAndDid(
    String requestHash,
    String did,
  );
}
