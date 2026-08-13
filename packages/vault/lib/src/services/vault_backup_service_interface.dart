import '../backup_data.dart' show BackupData;

/// Defines the contract for creating and restoring encrypted Vault backups.
abstract interface class VaultBackupServiceInterface {
  /// Creates an encrypted backup of all registered `Restorable` components.
  ///
  /// Parameters:
  /// * [passphrase] - The user passphrase used to derive the backup encryption
  ///   key.
  ///
  /// Returns a [Future] containing the encrypted [BackupData].
  /// Throws a `TdkException` if the backup cannot be created.
  Future<BackupData> createBackup({required String passphrase});

  /// Restores all registered `Restorable` components from an encrypted backup.
  ///
  /// Parameters:
  /// * [backupData] - The encrypted backup previously produced by [createBackup].
  /// * [passphrase] - The user passphrase used to derive the decryption key.
  ///
  /// Throws a `TdkException` if the passphrase is incorrect or the backup is
  /// malformed.
  Future<void> restoreFromBackup({
    required BackupData backupData,
    required String passphrase,
  });
}
