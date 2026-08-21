import 'package:affinidi_tdk_common/affinidi_tdk_common.dart';

import 'tdk_exception_type.dart';

/// Creates exceptions raised while creating a Vault backup.
abstract final class VaultBackupException {
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
