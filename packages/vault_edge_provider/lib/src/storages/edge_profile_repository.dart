import 'package:affinidi_tdk_vault/affinidi_tdk_vault.dart';
import 'package:ssi/ssi.dart';

import '../exceptions/tdk_exception_type.dart';
import '../interfaces/edge_repository_factory_interface.dart';
import '../models/edge_profile.dart';
import '../services/edge_encryption_service_interface.dart';
import 'edge_credential_storage.dart';
import 'edge_file_storage.dart';

/// A Vault implementation of [ProfileRepository] for locally managing
/// user profiles.
class EdgeProfileRepository
    implements ProfileRepository, RestorableProfileRepository, Restorable {
  /// Creates a new instance of [EdgeProfileRepository].
  ///
  /// The [_id] parameter is used to identify this repository instance.
  /// The [_repositoryFactory] used to create repositories for handling operations on profiles, files and credentials.
  /// The [_encryptionService] for encrypting content.
  EdgeProfileRepository(
    this._id,
    this._repositoryFactory,
    this._encryptionService,
  );

  final String _id;
  final EdgeRepositoryFactoryInterface _repositoryFactory;
  final EdgeEncryptionServiceInterface _encryptionService;
  final _keyPairs = <String, KeyPair>{};

  static const _backupVersion = '1.0.0';
  static const _invalidBackupFormatCode = 'invalid_backup_format';

  @override
  String get id => _id;

  bool _configured = false;
  late final Wallet _wallet;
  late final VaultStore _vaultStore;
  late final _repository = _repositoryFactory.createProfileRepository();

  @override
  Future<void> configure(Object configuration) async {
    if (configuration is! RepositoryConfiguration) {
      Error.throwWithStackTrace(
        TdkException(
          message: 'Wrong configuration type',
          code: TdkExceptionType.invalidRepositoryConfigurationType.code,
        ),
        StackTrace.current,
      );
    }

    _wallet = configuration.wallet;

    if (configuration.keyStorage == null) {
      Error.throwWithStackTrace(
        TdkException(
          message:
              'Key storage is required to '
              'maintain account indexes and avoid duplicate accounts',
          code: TdkExceptionType.missingVaultStore.code,
        ),
        StackTrace.current,
      );
    }

    _vaultStore = configuration.keyStorage!;

    _configured = true;
  }

  /// Returns true if the repository has been configured
  @override
  Future<bool> isConfigured() async {
    return _configured;
  }

  /// Creates a local profile
  ///
  /// The [name] for the profile
  /// The [description] for the profile
  /// The [cancelToken] to cancel the operation in progress.
  @override
  Future<Profile> createProfile({
    required String name,
    String? description,
    VaultCancelToken? cancelToken,
  }) async {
    if (!_configured) {
      Error.throwWithStackTrace(
        TdkException(
          message: '''
Profile repository must be configured using a RepositoryConfiguration''',
          code: TdkExceptionType.profileNotConfigured.code,
        ),
        StackTrace.current,
      );
    }

    final nextAccountIndex = (await _vaultStore.getAccountIndex()) + 1;

    final newId = await _repository.createProfile(
      name: name,
      description: description,
      cancelToken: cancelToken,
      accountIndex: nextAccountIndex,
    );

    await _vaultStore.setAccountIndex(nextAccountIndex);

    final profileKeyPair = await _memoizedKeyPair(
      accountIndex: nextAccountIndex.toString(),
    );
    final profileDid = DidKey.getDid(profileKeyPair.publicKey);

    return Profile(
      id: newId,
      name: name,
      description: description,
      did: profileDid,
      accountIndex: nextAccountIndex,
      profileRepositoryId: id,
      fileStorages: {
        _id: EdgeFileStorage(
          repository: _repositoryFactory.createFileRepository(profileId: newId),
          id: _id,
          profileId: newId.toString(),
          encryptionService: _encryptionService,
        ),
      },
      credentialStorages: {
        _id: EdgeCredentialStorage(
          repository: _repositoryFactory.createCredentialRepository(
            profileId: newId,
          ),
          id: _id,
          profileId: newId.toString(),
          encryptionService: _encryptionService,
        ),
      },
      sharedStorages: {},
    );
  }

  @override
  Future<Profile> restoreProfile({
    required int accountIndex,
    required String name,
    String? id,
    String? description,
    VaultCancelToken? cancelToken,
  }) => _restoreProfile(
    accountIndex: accountIndex,
    name: name,
    id: id,
    description: description,
    cancelToken: cancelToken,
  );

  Future<Profile> _restoreProfile({
    required int accountIndex,
    required String name,
    String? id,
    String? description,
    VaultCancelToken? cancelToken,
  }) async {
    if (!_configured) {
      Error.throwWithStackTrace(
        TdkException(
          message: '''
Profile repository must be configured using a RepositoryConfiguration''',
          code: TdkExceptionType.profileNotConfigured.code,
        ),
        StackTrace.current,
      );
    }

    final newId = await _repository.createProfile(
      name: name,
      description: description,
      cancelToken: cancelToken,
      accountIndex: accountIndex,
      id: id,
    );

    // Keep the counter ahead of every restored index so later creates don't
    // reuse an account index.
    if (accountIndex > await _vaultStore.getAccountIndex()) {
      await _vaultStore.setAccountIndex(accountIndex);
    }

    final profileKeyPair = await _memoizedKeyPair(
      accountIndex: accountIndex.toString(),
    );
    final profileDid = DidKey.getDid(profileKeyPair.publicKey);

    return Profile(
      id: newId,
      name: name,
      description: description,
      did: profileDid,
      accountIndex: accountIndex,
      profileRepositoryId: _id,
      fileStorages: {
        _id: EdgeFileStorage(
          repository: _repositoryFactory.createFileRepository(profileId: newId),
          id: _id,
          profileId: newId.toString(),
          encryptionService: _encryptionService,
        ),
      },
      credentialStorages: {
        _id: EdgeCredentialStorage(
          repository: _repositoryFactory.createCredentialRepository(
            profileId: newId,
          ),
          id: _id,
          profileId: newId.toString(),
          encryptionService: _encryptionService,
        ),
      },
      sharedStorages: {},
    );
  }

  /// Deleted an existing local profile
  ///
  /// The [profile] to delete
  /// The [cancelToken] to cancel the operation in progress.
  @override
  Future<void> deleteProfile(
    Profile profile, {
    VaultCancelToken? cancelToken,
  }) async {
    if (!_configured) {
      Error.throwWithStackTrace(
        TdkException(
          message: '''
Profile repository must be configured using a RepositoryConfiguration''',
          code: TdkExceptionType.profileNotConfigured.code,
        ),
        StackTrace.current,
      );
    }

    final hasContent = await _repository.hasAnyContent(profile.id);
    if (hasContent) {
      Error.throwWithStackTrace(
        TdkException(
          message: 'Cannot delete profile with content',
          code: TdkExceptionType.unableToDeleteProfileWithContent.code,
        ),
        StackTrace.current,
      );
    }

    return await _repository.deleteProfile(
      profileId: profile.id,
      cancelToken: cancelToken,
    );
  }

  /// Returns the list of local profiles
  ///
  /// The [cancelToken] to cancel the operation in progress.
  @override
  Future<List<Profile>> listProfiles({VaultCancelToken? cancelToken}) async {
    if (!_configured) {
      Error.throwWithStackTrace(
        TdkException(
          message: '''
Profile repository must be configured using a RepositoryConfiguration''',
          code: TdkExceptionType.profileNotConfigured.code,
        ),
        StackTrace.current,
      );
    }

    final items = await _repository.listProfiles(cancelToken: cancelToken);

    final profiles = <Profile>[];

    for (final item in items) {
      final profileKeyPair = await _memoizedKeyPair(
        accountIndex: item.accountIndex.toString(),
      );
      final did = DidKey.getDid(profileKeyPair.publicKey);

      profiles.add(
        Profile(
          id: item.id.toString(),
          accountIndex: item.accountIndex,
          name: item.name,
          description: item.description,
          did: did,
          profileRepositoryId: _id,
          fileStorages: {
            _id: EdgeFileStorage(
              repository: _repositoryFactory.createFileRepository(
                profileId: item.id,
              ),
              id: _id,
              profileId: item.id.toString(),
              encryptionService: _encryptionService,
            ),
          },
          credentialStorages: {
            _id: EdgeCredentialStorage(
              repository: _repositoryFactory.createCredentialRepository(
                profileId: item.id,
              ),
              id: _id,
              profileId: item.id.toString(),
              encryptionService: _encryptionService,
            ),
          },
          sharedStorages: {},
        ),
      );
    }

    return profiles;
  }

  /// Updates an existing local profile
  ///
  /// The [profile] to update
  /// The [cancelToken] to cancel the operation in progress.
  @override
  Future<void> updateProfile(
    Profile profile, {
    VaultCancelToken? cancelToken,
  }) async {
    if (!_configured) {
      Error.throwWithStackTrace(
        TdkException(
          message: '''
Profile repository must be configured using a RepositoryConfiguration''',
          code: TdkExceptionType.profileNotConfigured.code,
        ),
        StackTrace.current,
      );
    }

    final edgeProfile = EdgeProfile.from(profile);
    return await _repository.updateProfile(
      profile: edgeProfile,
      cancelToken: cancelToken,
    );
  }

  @override
  Future<Map<String, dynamic>> export() async {
    final profiles = <Map<String, dynamic>>[];
    for (final profile in await listProfiles()) {
      profiles.add({
        'id': profile.id,
        'accountIndex': profile.accountIndex,
        'name': profile.name,
        'did': profile.did,
        if (profile.description != null) 'description': profile.description,
        'fileStorages': await _exportStorages(profile.fileStorages),
        'credentialStorages': await _exportStorages(profile.credentialStorages),
        'sharedStorages': await _exportSharedStorages(profile.sharedStorages),
      });
    }
    return {'version': _backupVersion, 'profiles': profiles};
  }

  Future<Map<String, dynamic>> _exportStorages(
    Map<String, Object> storages,
  ) async {
    final data = <String, dynamic>{};
    for (final entry in storages.entries) {
      final storage = entry.value;
      if (storage is Restorable) {
        data[entry.key] = await storage.export();
      }
    }
    return data;
  }

  Future<Map<String, dynamic>> _exportSharedStorages(
    List<SharedStorage> storages,
  ) async {
    final data = <String, dynamic>{};
    for (final storage in storages) {
      if (storage is Restorable) {
        data[storage.id] = await (storage as Restorable).export();
      }
    }
    return data;
  }

  @override
  Future<void> import(Map<String, dynamic> data) async {
    final profiles = await _parseBackup(data);
    final existingProfiles = await listProfiles();
    final existingById = {
      for (final profile in existingProfiles) profile.id: profile,
    };

    for (final backupProfile in profiles) {
      var profile = existingById[backupProfile.id];
      if (profile != null &&
          (profile.accountIndex != backupProfile.accountIndex ||
              profile.did != backupProfile.did)) {
        throw _invalidBackupFormat();
      }
      profile ??= await _restoreProfile(
        accountIndex: backupProfile.accountIndex,
        name: backupProfile.name,
        id: backupProfile.id,
        description: backupProfile.description,
      );
      await _importStorages(profile.fileStorages, backupProfile.fileStorages);
      await _importStorages(
        profile.credentialStorages,
        backupProfile.credentialStorages,
      );
      await _importSharedStorages(
        profile.sharedStorages,
        backupProfile.sharedStorages,
      );
      existingById[profile.id] = profile;
    }
  }

  Future<List<_BackupProfile>> _parseBackup(Map<String, dynamic> data) async {
    const allowedKeys = {'version', 'profiles'};
    final rawProfiles = data['profiles'];
    if (data.keys.any((key) => !allowedKeys.contains(key)) ||
        data['version'] != _backupVersion ||
        rawProfiles is! List) {
      throw _invalidBackupFormat();
    }

    final profiles = <_BackupProfile>[];
    final ids = <String>{};
    final accountIndexes = <int>{};
    for (final rawProfile in rawProfiles) {
      if (rawProfile is! Map<String, dynamic>) {
        throw _invalidBackupFormat();
      }
      const requiredKeys = {
        'id',
        'accountIndex',
        'name',
        'did',
        'fileStorages',
        'credentialStorages',
        'sharedStorages',
      };
      const optionalKeys = {'description'};
      if (!rawProfile.keys.toSet().containsAll(requiredKeys) ||
          rawProfile.keys.any(
            (key) => !requiredKeys.contains(key) && !optionalKeys.contains(key),
          )) {
        throw _invalidBackupFormat();
      }
      final id = rawProfile['id'];
      final accountIndex = rawProfile['accountIndex'];
      final name = rawProfile['name'];
      final did = rawProfile['did'];
      final description = rawProfile['description'];
      if (id is! String ||
          id.isEmpty ||
          !ids.add(id) ||
          accountIndex is! int ||
          accountIndex < 0 ||
          !accountIndexes.add(accountIndex) ||
          name is! String ||
          name.isEmpty ||
          did is! String ||
          did.isEmpty ||
          (description != null && description is! String)) {
        throw _invalidBackupFormat();
      }

      final derivedDid = DidKey.getDid(
        (await _memoizedKeyPair(
          accountIndex: accountIndex.toString(),
        )).publicKey,
      );
      if (derivedDid != did) {
        throw _invalidBackupFormat();
      }

      profiles.add(
        _BackupProfile(
          id: id,
          accountIndex: accountIndex,
          name: name,
          did: did,
          description: description as String?,
          fileStorages: _parseStoragePayloads(rawProfile['fileStorages']),
          credentialStorages: _parseStoragePayloads(
            rawProfile['credentialStorages'],
          ),
          sharedStorages: _parseStoragePayloads(rawProfile['sharedStorages']),
        ),
      );
    }
    profiles.sort(
      (left, right) => left.accountIndex.compareTo(right.accountIndex),
    );
    return profiles;
  }

  Map<String, Map<String, dynamic>> _parseStoragePayloads(Object? raw) {
    if (raw is! Map<String, dynamic>) {
      throw _invalidBackupFormat();
    }
    final payloads = <String, Map<String, dynamic>>{};
    for (final entry in raw.entries) {
      if (entry.key.isEmpty || entry.value is! Map<String, dynamic>) {
        throw _invalidBackupFormat();
      }
      payloads[entry.key] = entry.value as Map<String, dynamic>;
    }
    return payloads;
  }

  Future<void> _importStorages(
    Map<String, Object> storages,
    Map<String, Map<String, dynamic>> payloads,
  ) async {
    for (final entry in payloads.entries) {
      final storage = storages[entry.key];
      if (storage is! Restorable) {
        throw _invalidBackupFormat();
      }
      await storage.import(entry.value);
    }
  }

  Future<void> _importSharedStorages(
    List<SharedStorage> storages,
    Map<String, Map<String, dynamic>> payloads,
  ) async {
    final byId = {for (final storage in storages) storage.id: storage};
    await _importStorages(byId, payloads);
  }

  TdkException _invalidBackupFormat() => TdkException(
    message: 'The edge profile repository backup payload is malformed.',
    code: _invalidBackupFormatCode,
  );

  Future<KeyPair> _memoizedKeyPair({required String accountIndex}) async {
    _keyPairs[accountIndex] ??= await _getProfileKeyPair(
      accountIndex: accountIndex,
    );
    return _keyPairs[accountIndex]!;
  }

  Future<KeyPair> _getProfileKeyPair({required String accountIndex}) async {
    return await _wallet.generateKey(keyId: _getDerivationPath(accountIndex));
  }

  String _getDerivationPath(String accountIndex) =>
      "m/44'/60'/$accountIndex'/0'/0'";
}

class _BackupProfile {
  const _BackupProfile({
    required this.id,
    required this.accountIndex,
    required this.name,
    required this.did,
    required this.description,
    required this.fileStorages,
    required this.credentialStorages,
    required this.sharedStorages,
  });

  final String id;
  final int accountIndex;
  final String name;
  final String did;
  final String? description;
  final Map<String, Map<String, dynamic>> fileStorages;
  final Map<String, Map<String, dynamic>> credentialStorages;
  final Map<String, Map<String, dynamic>> sharedStorages;
}
