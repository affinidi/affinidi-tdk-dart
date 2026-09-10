import 'package:affinidi_tdk_vault_iota/affinidi_tdk_vault_iota.dart'
    hide TdkExceptionType;

/// Creates exceptions raised while restoring Vault Flutter Utils data.
abstract final class VaultRestoreException {
  /// Creates an exception for malformed backup data for [subject].
  static TdkException invalidBackupFormat(
    String subject, {
    String? originalMessage,
  }) => TdkException(
    message: 'The $subject backup payload is malformed.',
    code: 'invalid_backup_format',
    originalMessage: originalMessage,
  );

  /// Creates an exception for a non-empty restore [destination].
  static TdkException destinationNotEmpty(String destination) => TdkException(
    message: '$destination restore destination is not empty.',
    code: 'restore_destination_not_empty',
  );
}
