/// Defines the contract for creating and restoring Vault backups.
abstract interface class VaultBackupServiceInterface {
  /// Exports the state of all registered `Restorable` components into a single
  /// merged map suitable for long-term storage or transfer.
  ///
  /// Returns a [Future] containing the merged backup as a JSON-serialisable
  /// [Map].
  Future<Map<String, dynamic>> createBackup();

  /// Restores the state of all registered `Restorable` components from a
  /// previously created backup.
  ///
  /// Parameters:
  /// * [data] - the map returned by a prior [createBackup] call.
  Future<void> restoreFromBackup(Map<String, dynamic> data);
}
