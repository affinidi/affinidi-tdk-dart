import 'package:affinidi_tdk_common/affinidi_tdk_common.dart';

import '../exceptions/tdk_exception_type.dart';
import '../storage_interfaces/profile_repository.dart';

/// A [Restorable] that backs up and restores the profiles held by a
/// [ProfileRepository].
///
/// Each profile is keyed by its decentralised identifier (`did`), which is
/// derived deterministically from the wallet seed and account index. The
/// server-assigned profile `id` is intentionally not persisted because it is
/// not stable across a restore into a fresh vault; other per-profile sources
/// (credentials, files) therefore reattach their data by `did` rather than by
/// `id`.
///
/// This source must be registered before any per-profile source so that the
/// profiles exist before their credentials or files are imported.
class VaultProfilesBackupSource implements Restorable {
  /// Creates a [VaultProfilesBackupSource].
  ///
  /// Parameters:
  /// * [profileRepository] - The repository whose profiles are backed up and
  ///   recreated.
  /// * [logger] - Optional logger; defaults to [Logger.instance].
  VaultProfilesBackupSource({
    required ProfileRepository profileRepository,
    Logger? logger,
  }) : _profileRepository = profileRepository,
       _logger = logger ?? Logger.instance;

  final ProfileRepository _profileRepository;
  final Logger _logger;

  static const String _sectionKey = 'profiles';
  static const String _accountIndexKey = 'accountIndex';
  static const String _nameKey = 'name';
  static const String _didKey = 'did';
  static const String _descriptionKey = 'description';
  static const String _pictureKey = 'profilePictureURI';

  /// The top-level backup section owned by this source.
  static const String sectionKey = _sectionKey;

  /// The per-profile key under which credentials and files reference a profile.
  static const String didKey = _didKey;

  @override
  Future<Map<String, dynamic>> export() async {
    final profiles = await _profileRepository.listProfiles();
    return {
      _sectionKey: [
        for (final profile in profiles)
          {
            _accountIndexKey: profile.accountIndex,
            _nameKey: profile.name,
            _didKey: profile.did,
            _descriptionKey: profile.description,
            _pictureKey: profile.profilePictureURI,
          },
      ],
    };
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

    final existingDids = {
      for (final profile in await _profileRepository.listProfiles())
        profile.did,
    };

    for (final entry in entries) {
      final did = entry[_didKey] as String;
      if (existingDids.contains(did)) {
        continue;
      }

      final profile = await _profileRepository.createProfile(
        name: entry[_nameKey] as String,
        description: entry[_descriptionKey] as String?,
      );

      final picture = entry[_pictureKey];
      if (picture is String) {
        profile.profilePictureURI = picture;
        await _profileRepository.updateProfile(profile);
      }
    }
  }
}
