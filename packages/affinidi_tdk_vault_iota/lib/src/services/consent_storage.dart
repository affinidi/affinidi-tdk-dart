import '../models/iota_consent_record.dart';

/// Consumer-provided storage backend for Iota consent records.
///
/// Implement this interface to persist consent history using any storage
/// technology. [saveOrUpdate] must upsert by [IotaConsentRecord.hash].
abstract interface class ConsentStorage {
  /// Persists a consent record, replacing any existing record with the same
  /// [IotaConsentRecord.hash].
  ///
  /// Parameters:
  /// * [record] - The consent record to persist or update.
  ///
  /// Throws if the underlying storage operation fails.
  Future<void> saveOrUpdate(IotaConsentRecord record);

  /// Returns the most recently saved record whose [IotaConsentRecord.requestHash]
  /// matches [requestHash], or `null` if none exists.
  ///
  /// Parameters:
  /// * [requestHash] - Verifier+request hash supplied by the caller.
  Future<IotaConsentRecord?> findByRequestHash(String requestHash);
}
