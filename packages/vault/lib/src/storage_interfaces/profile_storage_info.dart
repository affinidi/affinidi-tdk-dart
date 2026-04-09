import '../helpers/vault_cancel_token.dart';
import '../vault_storage_usage.dart';

/// Interface for querying vault storage usage.
///
/// Repositories that support reporting storage consumption should implement
/// this interface.
abstract interface class ProfileStorageInfo {
  /// Returns the current storage usage for this vault.
  ///
  /// [cancelToken] - Optional cancel token for the operation.
  Future<VaultStorageUsage> getStorageUsage({VaultCancelToken? cancelToken});
}
