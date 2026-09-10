import 'package:affinidi_tdk_common/affinidi_tdk_common.dart';

import 'tdk_exception_type.dart';

/// Creates exceptions raised while restoring a Vault backup.
abstract final class VaultRestoreException {
  /// Creates an exception for a malformed VaultStore backup payload.
  static TdkException malformedVaultStoreData() => TdkException(
    message: 'The VaultStore backup payload is malformed.',
    code: TdkExceptionType.invalidBackupFormat.code,
  );

  /// Creates an exception for invalid encoded VaultStore backup data.
  static TdkException invalidVaultStoreData(String originalMessage) =>
      TdkException(
        message: 'The VaultStore backup payload contains invalid data.',
        code: TdkExceptionType.invalidBackupFormat.code,
        originalMessage: originalMessage,
      );

  /// Creates an exception for missing or invalid encrypted backup fields.
  static TdkException invalidBackupData() => TdkException(
    message: 'Backup file is missing required fields or has invalid types.',
    code: TdkExceptionType.invalidBackupFormat.code,
  );

  /// Creates an exception for backup decryption failure.
  static TdkException decryptionFailed() => TdkException(
    message:
        'Failed to decrypt backup; the passphrase may be incorrect or '
        'the backup has been tampered with.',
    code: TdkExceptionType.invalidBackupFormat.code,
  );

  /// Creates an exception for an unreadable encrypted backup.
  static TdkException unreadableBackup() => TdkException(
    message: 'Backup could not be decrypted or is not in a recognised format.',
    code: TdkExceptionType.invalidBackupFormat.code,
  );

  /// Creates an exception when rollback cannot clear the VaultStore.
  static TdkException vaultStoreRollbackFailed() => TdkException(
    message:
        'Vault restore failed and automatic rollback could not clear the '
        'VaultStore.',
    code: TdkExceptionType.restoreRollbackFailed.code,
  );

  /// Creates an exception for a missing or invalid backup version field.
  static TdkException invalidVersion() => TdkException(
    message: 'Backup is missing a valid "version" field.',
    code: TdkExceptionType.invalidBackupFormat.code,
  );

  /// Creates an exception for an unsupported backup [version].
  static TdkException unsupportedVersion(String version) => TdkException(
    message: 'Unsupported backup version: $version.',
    code: TdkExceptionType.invalidBackupFormat.code,
  );

  /// Creates an exception for a missing or invalid backup data field.
  static TdkException invalidData() => TdkException(
    message: 'Backup is missing a valid "data" field.',
    code: TdkExceptionType.invalidBackupFormat.code,
  );

  /// Creates an exception for malformed Vault backup data.
  static TdkException malformedBackupData() => TdkException(
    message: 'The Vault backup data is malformed.',
    code: TdkExceptionType.invalidBackupFormat.code,
  );

  /// Creates an exception for a backup incompatible with an open Vault.
  static TdkException invalidBackupFormat() => TdkException(
    message: 'The Vault backup cannot be imported into this Vault.',
    code: TdkExceptionType.invalidBackupFormat.code,
  );

  /// Creates an exception for a non-empty restore [destination].
  static TdkException destinationNotEmpty([String destination = 'Vault']) =>
      TdkException(
        message: '$destination restore destination is not empty.',
        code: TdkExceptionType.restoreDestinationNotEmpty.code,
      );

  /// Creates an exception identifying targets that could not be rolled back.
  static TdkException rollbackFailed(List<String> targets) => TdkException(
    message:
        'Vault restore cleanup could not fully clear: '
        '${targets.join(', ')}.',
    code: TdkExceptionType.restoreRollbackFailed.code,
  );
}
