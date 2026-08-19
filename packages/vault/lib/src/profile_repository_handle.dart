import 'repository_decorators/cache_invalidating_profile_access_sharing.dart';
import 'repository_decorators/cache_invalidating_profile_repository.dart';
import 'storage_interfaces/profile_access_sharing.dart';
import 'storage_interfaces/profile_repository.dart';
import 'storage_interfaces/profile_storage_info.dart';
import 'storage_interfaces/restorable.dart';
import 'storage_interfaces/restorable_profile_repository.dart';

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

    // Preserve the restore capability through the decorator when present.
    final wrapped =
        repository is RestorableProfileRepository && repository is Restorable
        ? CacheInvalidatingRestorableProfileRepository(
            repository,
            onProfilesMutated: onProfilesMutated,
          )
        : repository is Restorable
        ? CacheInvalidatingRestorableRepository(
            repository,
            onProfilesMutated: onProfilesMutated,
          )
        : CacheInvalidatingProfileRepository(
            repository,
            onProfilesMutated: onProfilesMutated,
          );

    return ProfileRepositoryHandle._(
      repository: wrapped,
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
