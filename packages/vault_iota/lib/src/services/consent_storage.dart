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

  /// Returns all records whose [IotaConsentRecord.requestHash] matches
  /// [requestHash]. Returns an empty list if none exist.
  ///
  /// Parameters:
  /// * [requestHash] - Verifier+request hash supplied by the caller.
  Future<List<IotaConsentRecord>> findAllByRequestHash(String requestHash);

  /// Deletes the record identified by [hash].
  ///
  /// Returns `true` if a record existed and was removed, or `false` if no
  /// record matched [hash]. Throws if the underlying storage operation fails.
  ///
  /// Parameters:
  /// * [hash] - The [IotaConsentRecord.hash] of the record to delete.
  Future<bool> deleteByHash(String hash);
}

/// Optional consent-storage extension for backends that can enumerate history.
abstract interface class EnumerableConsentStorage implements ConsentStorage {
  /// Returns all persisted consent records.
  ///
  /// Records are returned in storage-defined order. Returns an empty list if
  /// none exist.
  Future<List<IotaConsentRecord>> listAll();
}
