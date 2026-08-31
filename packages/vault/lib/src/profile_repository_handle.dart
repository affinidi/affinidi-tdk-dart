import 'helpers/vault_cancel_token.dart';
import 'profile.dart';
import 'storage_interfaces/profile_access_sharing.dart';
import 'storage_interfaces/profile_repository.dart';
import 'storage_interfaces/profile_storage_info.dart';
import 'storage_interfaces/restorable.dart';

/// A handle for a profile repository that may also include access sharing and storage info.
final class ProfileRepositoryHandle implements ProfileRepository {
  const ProfileRepositoryHandle._({
    required ProfileRepository repository,
    required void Function() onProfilesMutated,
    this.accessSharing,
    this.storageInfo,
    this.restorable,
  }) : _repository = repository,
       _onProfilesMutated = onProfilesMutated;

  /// Creates a [ProfileRepositoryHandle] from a given [ProfileRepository].
  factory ProfileRepositoryHandle.fromRepository(
    ProfileRepository repository, {
    required void Function() onProfilesMutated,
    Restorable? restorableView,
  }) {
    final accessSharing = repository is ProfileAccessSharing
        ? repository as ProfileAccessSharing
        : null;
    final storageInfo = repository is ProfileStorageInfo
        ? repository as ProfileStorageInfo
        : null;

    final restorable =
        restorableView ??
        (repository is Restorable ? repository as Restorable : null);

    return ProfileRepositoryHandle._(
      repository: repository,
      onProfilesMutated: onProfilesMutated,
      accessSharing: accessSharing,
      storageInfo: storageInfo,
      restorable: restorable,
    );
  }

  final ProfileRepository _repository;
  final void Function() _onProfilesMutated;

  @override
  String get id => _repository.id;

  @override
  Future<List<Profile>> listProfiles({VaultCancelToken? cancelToken}) =>
      _repository.listProfiles(cancelToken: cancelToken);

  @override
  Future<Profile> createProfile({
    required String name,
    String? description,
    VaultCancelToken? cancelToken,
  }) async {
    final profile = await _repository.createProfile(
      name: name,
      description: description,
      cancelToken: cancelToken,
    );
    _onProfilesMutated();
    return profile;
  }

  @override
  Future<void> updateProfile(
    Profile profile, {
    VaultCancelToken? cancelToken,
  }) async {
    await _repository.updateProfile(profile, cancelToken: cancelToken);
    _onProfilesMutated();
  }

  @override
  Future<void> deleteProfile(
    Profile profile, {
    VaultCancelToken? cancelToken,
  }) async {
    await _repository.deleteProfile(profile, cancelToken: cancelToken);
    _onProfilesMutated();
  }

  @override
  Future<void> configure(Object configuration) =>
      _repository.configure(configuration);

  @override
  Future<bool> isConfigured() => _repository.isConfigured();

  /// Optional access sharing capabilities if the underlying repository supports it.
  final ProfileAccessSharing? accessSharing;

  /// Optional storage info if the underlying repository provides it.
  final ProfileStorageInfo? storageInfo;

  /// Optional restore capability for the repository.
  final Restorable? restorable;
}
