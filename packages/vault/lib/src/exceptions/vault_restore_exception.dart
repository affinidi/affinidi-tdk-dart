import 'package:affinidi_tdk_common/affinidi_tdk_common.dart';

import 'tdk_exception_type.dart';

/// Creates exceptions raised while restoring a Vault backup.
abstract final class VaultRestoreException {
  /// Creates an exception for a backup incompatible with an open Vault.
  static TdkException invalidBackupFormat() => TdkException(
    message: 'The Vault backup cannot be imported into this Vault.',
    code: TdkExceptionType.invalidBackupFormat.code,
  );

  /// Creates an exception for a non-empty Vault restore destination.
  static TdkException destinationNotEmpty() => TdkException(
    message: 'Vault restore destination is not empty.',
    code: TdkExceptionType.restoreDestinationNotEmpty.code,
  );

  /// Creates an exception identifying targets that could not be rolled back.
  static TdkException rollbackFailed(List<String> targets) => TdkException(
    message:
        'Vault restore failed and automatic rollback could not fully clear: '
        '${targets.join(', ')}.',
    code: TdkExceptionType.restoreRollbackFailed.code,
  );
}
