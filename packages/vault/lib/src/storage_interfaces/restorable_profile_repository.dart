import '../helpers/vault_cancel_token.dart';
import '../profile.dart';

/// An optional capability a profile repository can offer to recreate a profile
/// with its original account index during a restore.
///
/// Because a profile's decentralised identifier is derived from the wallet seed
/// and the account index, recreating a profile at its original account index
/// reproduces the same identifier. That lets credentials and files, which are
/// grouped by that identifier in a backup, reattach to the restored profile.
///
/// Repositories that assign the account index themselves (for example a
/// server-backed repository) do not implement this; the backup service falls
/// back to a normal create for those.
abstract interface class RestorableProfileRepository {
  /// Recreates a profile at the given [accountIndex] so its derived identity is
  /// preserved.
  ///
  /// Parameters:
  /// * [accountIndex] - The original account index from the backup.
  /// * [name] - The profile name.
  /// * [id] - The original profile id from the backup, preserved when provided
  ///   so links keyed by profile id (such as consent records) still resolve.
  /// * [description] - Optional profile description.
  /// * [cancelToken] - Optional cancel token.
  Future<Profile> restoreProfile({
    required int accountIndex,
    required String name,
    String? id,
    String? description,
    VaultCancelToken? cancelToken,
  });
}
