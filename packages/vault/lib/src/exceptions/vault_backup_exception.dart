import 'package:affinidi_tdk_common/affinidi_tdk_common.dart';

import 'tdk_exception_type.dart';

/// Creates exceptions raised while creating a Vault backup.
abstract final class VaultBackupException {
  /// Creates an exception when a VaultStore cannot be exported without a seed.
  static TdkException missingVaultStoreSeed() => TdkException(
    message: 'Cannot export VaultStore state without a seed.',
    code: TdkExceptionType.invalidBackupFormat.code,
  );

  /// Creates an exception for a passphrase that violates the configured policy.
  static TdkException weakPassphrase() => TdkException(
    message: 'Passphrase does not satisfy the required policy.',
    code: TdkExceptionType.weakPassphrase.code,
  );

  /// Creates an exception for an unexpected backup creation failure.
  static TdkException creationFailed() => TdkException(
    message: 'Failed to create vault backup.',
    code: TdkExceptionType.backupCreationFailed.code,
  );

  /// Creates an exception for a repository registered under a mismatched ID.
  static TdkException repositoryIdMismatch({
    required String registrationId,
    required String repositoryId,
  }) => TdkException(
    message:
        'Profile repository registration ID "$registrationId" does not match '
        'repository ID "$repositoryId".',
    code: TdkExceptionType.invalidProfileRepositoryIdentifier.code,
  );
}
