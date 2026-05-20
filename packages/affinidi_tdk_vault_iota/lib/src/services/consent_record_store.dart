import '../models/iota_consent_record.dart';

/// Consumer-provided storage backend for Iota consent records.
///
/// Implement this interface to persist consent history using any storage
/// technology. [saveOrUpdate] must upsert by [IotaConsentRecord.requestHash].
abstract interface class ConsentRecordStore {
  /// Persists a consent record, replacing any existing record with the same
  /// [IotaConsentRecord.requestHash].
  ///
  /// Parameters:
  /// * [record] - The consent record to persist or update.
  ///
  /// Throws if the underlying storage operation fails.
  Future<void> saveOrUpdate(IotaConsentRecord record);

  /// Returns the record matching [requestHash], or `null` if none exists.
  ///
  /// Parameters:
  /// * [requestHash] - Consumer-computed hash identifying the verifier+request combination.
  Future<IotaConsentRecord?> findByRequestHash(String requestHash);
}
