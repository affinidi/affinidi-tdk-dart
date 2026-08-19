import '../helpers/vault_cancel_token.dart';
import '../profile.dart';
import '../storage_interfaces/profile_repository.dart';
import '../storage_interfaces/restorable.dart';
import '../storage_interfaces/restorable_profile_repository.dart';

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

  /// Invalidates the cached profiles. Exposed for subclasses that add extra
  /// mutating operations.
  void invalidateProfilesCache() => _onProfilesMutated();

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

/// A [CacheInvalidatingProfileRepository] that also forwards the
/// [RestorableProfileRepository] capability of the wrapped repository.
class CacheInvalidatingRestorableProfileRepository
    extends CacheInvalidatingProfileRepository
    implements RestorableProfileRepository, Restorable {
  /// Creates a [CacheInvalidatingRestorableProfileRepository].
  CacheInvalidatingRestorableProfileRepository(
    ProfileRepository repository, {
    required super.onProfilesMutated,
  }) : _restorable = repository as RestorableProfileRepository,
       super(repository);

  final RestorableProfileRepository _restorable;

  Restorable get _restorableState => _restorable as Restorable;

  @override
  Future<Profile> restoreProfile({
    required int accountIndex,
    required String name,
    String? id,
    String? description,
    VaultCancelToken? cancelToken,
  }) async {
    final profile = await _restorable.restoreProfile(
      accountIndex: accountIndex,
      name: name,
      id: id,
      description: description,
      cancelToken: cancelToken,
    );
    invalidateProfilesCache();
    return profile;
  }

  @override
  Future<Map<String, dynamic>> export() => _restorableState.export();

  @override
  Future<void> import(Map<String, dynamic> data) async {
    await _restorableState.import(data);
    invalidateProfilesCache();
  }
}
