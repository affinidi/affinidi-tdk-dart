import 'package:affinidi_tdk_vault_edge_provider/affinidi_tdk_vault_edge_provider.dart';

/// Creates exceptions raised by the Edge Drift profile repository.
abstract final class ProfileRepositoryException {
  /// Creates an exception when deleting a profile that does not exist.
  static TdkException unableToDeleteNonExistentProfile() => TdkException(
    message: 'Failed to delete profile',
    code: TdkExceptionType.unableToDeleteNonExistentProfile.code,
  );

  /// Creates an exception when updating a profile that does not exist.
  static TdkException unableToUpdateNonExistentProfile() => TdkException(
    message: 'Failed to update profile',
    code: TdkExceptionType.unableToUpdateNonExistentProfile.code,
  );
}
