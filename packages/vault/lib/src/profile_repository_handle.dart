import 'repository_decorators/cache_invalidating_profile_access_sharing.dart';
import 'repository_decorators/cache_invalidating_profile_repository.dart';
import 'storage_interfaces/profile_access_sharing.dart';
import 'storage_interfaces/profile_repository.dart';
import 'storage_interfaces/profile_storage_info.dart';

/// A handle for a profile repository that may also include access sharing and storage info.
final class ProfileRepositoryHandle {
  const ProfileRepositoryHandle._({
    required this.repository,
    this.accessSharing,
    this.storageInfo,
  });

  /// Creates a [ProfileRepositoryHandle] from a given [ProfileRepository], automatically
  factory ProfileRepositoryHandle.fromRepository(
    ProfileRepository repository, {
    required void Function() onProfilesMutated,
  }) {
    final accessSharing = repository is ProfileAccessSharing
        ? CacheInvalidatingProfileAccessSharing(
            repository as ProfileAccessSharing,
            onProfilesMutated: onProfilesMutated,
          )
        : null;
    final storageInfo = repository is ProfileStorageInfo
        ? repository as ProfileStorageInfo
        : null;

    return ProfileRepositoryHandle._(
      repository: CacheInvalidatingProfileRepository(
        repository,
        onProfilesMutated: onProfilesMutated,
      ),
      accessSharing: accessSharing,
      storageInfo: storageInfo,
    );
  }

  /// The underlying profile repository with cache invalidation.
  final ProfileRepository repository;

  /// Optional access sharing capabilities if the underlying repository supports it.
  final ProfileAccessSharing? accessSharing;

  /// Optional storage info if the underlying repository provides it.
  final ProfileStorageInfo? storageInfo;
}
