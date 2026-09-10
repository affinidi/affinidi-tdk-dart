import 'package:affinidi_tdk_common/affinidi_tdk_common.dart';

import 'tdk_exception_type.dart';

/// Creates exceptions raised by Vault operations.
abstract final class VaultException {
  /// Creates an exception when the Vault has not been initialized.
  static TdkException notInitialized() => TdkException(
    message: 'Must initialize vault by calling ensureInitialized',
    code: TdkExceptionType.vaultNotInitialized.code,
  );

  /// Creates an exception when a profile cannot be found by [profileId].
  static TdkException profileNotFound(String profileId) => TdkException(
    message: 'Cannot find profile with id: $profileId',
    code: TdkExceptionType.invalidProfileIdentifier.code,
  );

  /// Creates an exception when a repository cannot be found by [repositoryId].
  static TdkException profileRepositoryNotFound(String repositoryId) =>
      TdkException(
        message: 'Cannot find the profile repository with id: $repositoryId',
        code: TdkExceptionType.invalidProfileRepositoryIdentifier.code,
      );

  /// Creates an exception when profile access sharing is unsupported.
  static TdkException unsupportedProfileAccessSharing(String message) =>
      TdkException(
        message: message,
        code: TdkExceptionType.unsupportedProfileAccessSharing.code,
      );

  /// Creates an exception when profile storage usage reporting is unsupported.
  static TdkException unsupportedProfileStorageUsage(String message) =>
      TdkException(
        message: message,
        code: TdkExceptionType.unsupportedProfileStorageUsageReporting.code,
      );

  /// Creates an exception when no profile repository is provided.
  static TdkException missingProfileRepository() => TdkException(
    message: 'Must provide at least one profile repository',
    code: TdkExceptionType.missingProfileRepository.code,
  );

  /// Creates an exception for an invalid profile repository identifier.
  static TdkException invalidProfileRepositoryIdentifier() => TdkException(
    message: 'Invalid profile repository identifier',
    code: TdkExceptionType.invalidProfileRepositoryIdentifier.code,
  );

  /// Creates an exception when the VaultStore has no seed.
  static TdkException missingSeed() => TdkException(
    message: 'No seed found in vault store',
    code: TdkExceptionType.vaultNotInitialized.code,
  );

  /// Creates an exception when the current user has no profiles.
  static TdkException noProfilesForCurrentUser() => TdkException(
    message: 'No profiles found for current user',
    code: TdkExceptionType.invalidProfileIdentifier.code,
  );

  /// Creates an exception when a shared item cannot be read.
  static TdkException cannotReadSharedItem() => TdkException(
    message: 'Cannot read shared item',
    code: TdkExceptionType.invalidProfileIdentifier.code,
  );
}
