import '../models/iota_consent_record.dart';
import 'consent_storage.dart';

/// A [ConsentStorage] that can additionally enumerate every stored record.
///
/// The base [ConsentStorage] only supports lookup by request hash, which is not
/// enough to back up the full consent history. Consumers that want their
/// consent history included in a vault backup implement this interface so the
/// backup source can read all records.
abstract interface class EnumerableConsentStorage implements ConsentStorage {
  /// Returns every consent record currently held by this storage.
  Future<List<IotaConsentRecord>> listAll();
}
