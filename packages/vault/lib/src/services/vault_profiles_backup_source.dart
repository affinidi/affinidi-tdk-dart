import 'package:affinidi_tdk_common/affinidi_tdk_common.dart';

import '../exceptions/tdk_exception_type.dart';
import '../storage_interfaces/profile_repository.dart';
import '../storage_interfaces/restorable_profile_repository.dart';

/// A [Restorable] that backs up and restores the profiles held across one or
/// more [ProfileRepository] instances.
///
/// Each profile is keyed by its decentralised identifier (`did`), which is
/// derived deterministically from the wallet seed and account index. For local
/// (on-device) repositories, the profile `id` is also exported so it can be
/// reused during restore (e.g. to reattach consent history keyed by profile
/// id). Per-profile sources (credentials, files) still reattach their data by
/// `did` rather than by `id`.
///
/// This source must be registered before any per-profile source so that the
/// profiles exist before their credentials or files are imported.
///
/// Only local (on-device) profiles held in a repository that supports
/// [RestorableProfileRepository] are backed up, and they are recreated on
/// restore with their original account index so the derived identity is
/// preserved.
class VaultProfilesBackupSource implements Restorable {
  /// Creates a [VaultProfilesBackupSource].
  ///
  /// Parameters:
  /// * [profileRepositories] - The repositories whose profiles are backed up.
  /// * [logger] - Optional logger; defaults to [Logger.instance].
  VaultProfilesBackupSource({
    required List<ProfileRepository> profileRepositories,
    Logger? logger,
  }) : _profileRepositories = profileRepositories,
       _logger = logger ?? Logger.instance;

  final List<ProfileRepository> _profileRepositories;
  final Logger _logger;

  static const String _sectionKey = 'profiles';
  static const String _idKey = 'id';
  static const String _accountIndexKey = 'accountIndex';
  static const String _nameKey = 'name';
  static const String _didKey = 'did';
  static const String _descriptionKey = 'description';
  static const String _pictureKey = 'profilePictureURI';
  static const String _isLocalKey = 'isLocal';

  /// The top-level backup section owned by this source.
  static const String sectionKey = _sectionKey;

  /// The per-profile key under which credentials and files reference a profile.
  static const String didKey = _didKey;

  List<ProfileRepository> _restorableRepositories() => _profileRepositories
      .where((repository) => repository is RestorableProfileRepository)
      .toList();

  Future<Set<String>> _existingDids(
    List<ProfileRepository> repositories,
  ) async {
    final dids = <String>{};
    for (final repository in repositories) {
      for (final profile in await repository.listProfiles()) {
        dids.add(profile.did);
      }
    }
    return dids;
  }

  @override
  Future<Map<String, dynamic>> export() async {
    final profiles = <Map<String, dynamic>>[];
    // Back up local (edge) profiles only.
    for (final repository in _restorableRepositories()) {
      final isLocal = repository is RestorableProfileRepository;
      for (final profile in await repository.listProfiles()) {
        profiles.add({
          _idKey: profile.id,
          _accountIndexKey: profile.accountIndex,
          _nameKey: profile.name,
          _didKey: profile.did,
          _descriptionKey: profile.description,
          _pictureKey: profile.profilePictureURI,
          _isLocalKey: isLocal,
        });
      }
    }
    return {_sectionKey: profiles};
  }

  @override
  Future<void> import(Map<String, dynamic> data) async {
    final section = data[_sectionKey];
    if (section is! List) {
      _logger.warning('Backup is missing the "$_sectionKey" section.');
      throw TdkException(
        message: 'Backup is missing the "$_sectionKey" section.',
        code: TdkExceptionType.invalidBackupFormat.code,
      );
    }

    final entries = <Map<String, dynamic>>[];
    for (final entry in section) {
      if (entry is! Map<String, dynamic> ||
          entry[_accountIndexKey] is! int ||
          entry[_nameKey] is! String ||
          entry[_didKey] is! String) {
        _logger.warning('The "$_sectionKey" backup section is malformed.');
        throw TdkException(
          message: 'The "$_sectionKey" backup section is malformed.',
          code: TdkExceptionType.invalidBackupFormat.code,
        );
      }
      entries.add(entry);
    }

    // Recreate in account-index order so derived DIDs match the originals.
    entries.sort(
      (a, b) =>
          (a[_accountIndexKey] as int).compareTo(b[_accountIndexKey] as int),
    );

    final restorableRepositories = _restorableRepositories();
    if (restorableRepositories.isEmpty) {
      // No local storage to restore into; cloud data returns with the wallet.
      return;
    }
    final target = restorableRepositories.first;
    final restorable = target as RestorableProfileRepository;
    final existingDids = await _existingDids(restorableRepositories);

    for (final entry in entries) {
      // Only local profiles are recreated; cloud profiles return with the
      // wallet seed, so recreating them would duplicate the data.
      if (entry[_isLocalKey] != true) {
        continue;
      }
      final did = entry[_didKey] as String;
      if (existingDids.contains(did)) {
        continue;
      }

      final profile = await restorable.restoreProfile(
        accountIndex: entry[_accountIndexKey] as int,
        name: entry[_nameKey] as String,
        id: entry[_idKey] is String ? entry[_idKey] as String : null,
        description: entry[_descriptionKey] as String?,
      );

      final picture = entry[_pictureKey];
      if (picture is String) {
        profile.profilePictureURI = picture;
        await target.updateProfile(profile);
      }
    }
  }
}
