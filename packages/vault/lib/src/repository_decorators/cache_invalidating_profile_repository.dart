import '../helpers/vault_cancel_token.dart';
import '../profile.dart';
import '../storage_interfaces/profile_repository.dart';

/// A decorator for [ProfileRepository] that invalidates cache on profile mutations.
class CacheInvalidatingProfileRepository implements ProfileRepository {
  /// Creates an instance of [CacheInvalidatingProfileRepository].
  CacheInvalidatingProfileRepository(
    ProfileRepository repository, {
    required void Function() onProfilesMutated,
  }) : _repository = repository,
       _onProfilesMutated = onProfilesMutated;

  final ProfileRepository _repository;
  final void Function() _onProfilesMutated;

  @override
  String get id => _repository.id;

  @override
  Future<List<Profile>> listProfiles({VaultCancelToken? cancelToken}) {
    return _repository.listProfiles(cancelToken: cancelToken);
  }

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
  Future<void> configure(Object configuration) {
    return _repository.configure(configuration);
  }

  @override
  Future<bool> isConfigured() {
    return _repository.isConfigured();
  }
}
