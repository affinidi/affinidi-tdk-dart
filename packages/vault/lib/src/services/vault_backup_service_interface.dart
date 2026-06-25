/// Defines the contract for creating and restoring Vault backups.
abstract interface class VaultBackupServiceInterface {
  /// Creates a backup of all registered `Restorable` components.
  ///
  /// Returns a [Future] containing the merged backup map.
  Future<Map<String, dynamic>> createBackup();

  /// Restores all registered `Restorable` components from a backup.
  ///
  /// Parameters:
  /// * [data] - The backup map previously produced by [createBackup].
  Future<void> restoreFromBackup(Map<String, dynamic> data);
}
