import 'package:affinidi_tdk_vault/affinidi_tdk_vault.dart';
import 'package:ssi/ssi.dart';
import 'package:synchronized/synchronized.dart';

import '../exceptions/edge_restore_exception.dart';
import '../exceptions/tdk_exception_type.dart';
import '../interfaces/edge_repository_factory_interface.dart';
import '../models/edge_profile.dart';
import '../services/edge_encryption_service_interface.dart';
import 'edge_credential_storage.dart';
import 'edge_file_storage.dart';

/// A Vault implementation of [ProfileRepository] for locally managing
/// user profiles.
///
/// Profile operations and operations on storages created by this repository
/// share one in-process reentrant lock. This provides a coherent snapshot for
/// [export] and serializes [import] with SDK mutations on the same object graph.
class EdgeProfileRepository implements ProfileRepository, Restorable {
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
  final _lock = Lock(reentrant: true);
  bool _importPendingRollback = false;
  int? _accountIndexBeforeImport;

  static const _backupVersion = '1.0.0';

  @override
  String get id => _id;

  bool _configured = false;
  late final Wallet _wallet;
  late final VaultStore _vaultStore;
  late final _repository = _repositoryFactory.createProfileRepository();

  @override
  Future<void> configure(Object configuration) => _lock.synchronized(() async {
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
  });

  /// Returns true if the repository has been configured
  @override
  Future<bool> isConfigured() => _lock.synchronized(() async {
    return _configured;
  });

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
  }) => _lock.synchronized(() async {
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
          lock: _lock,
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
          lock: _lock,
        ),
      },
      sharedStorages: {},
    );
  });

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
          lock: _lock,
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
          lock: _lock,
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
  }) => _lock.synchronized(() async {
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
  });

  /// Returns the list of local profiles
  ///
  /// The [cancelToken] to cancel the operation in progress.
  @override
  Future<List<Profile>> listProfiles({VaultCancelToken? cancelToken}) =>
      _lock.synchronized(() async {
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
                  lock: _lock,
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
                  lock: _lock,
                ),
              },
              sharedStorages: {},
            ),
          );
        }

        return profiles;
      });

  /// Updates an existing local profile
  ///
  /// The [profile] to update
  /// The [cancelToken] to cancel the operation in progress.
  @override
  Future<void> updateProfile(
    Profile profile, {
    VaultCancelToken? cancelToken,
  }) => _lock.synchronized(() async {
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
  });

  @override
  Future<Map<String, dynamic>> export() => _lock.synchronized(() async {
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
  });

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
  Future<void> validateImport(Map<String, dynamic> data) =>
      _lock.synchronized(() async {
        final profiles = await _parseBackup(data);

        for (final backupProfile in profiles) {
          final fileStorages = <String, Object>{
            _id: EdgeFileStorage(
              repository: _repositoryFactory.createFileRepository(
                profileId: backupProfile.id,
              ),
              id: _id,
              profileId: backupProfile.id,
              encryptionService: _encryptionService,
              lock: _lock,
            ),
          };
          final credentialStorages = <String, Object>{
            _id: EdgeCredentialStorage(
              repository: _repositoryFactory.createCredentialRepository(
                profileId: backupProfile.id,
              ),
              id: _id,
              profileId: backupProfile.id,
              encryptionService: _encryptionService,
              lock: _lock,
            ),
          };
          await _validateStorages(fileStorages, backupProfile.fileStorages);
          await _validateStorages(
            credentialStorages,
            backupProfile.credentialStorages,
          );
          await _validateStorages(const {}, backupProfile.sharedStorages);
        }
      });

  @override
  Future<bool> isEmpty() => _lock.synchronized(
    () async => (await _repository.listProfiles()).isEmpty,
  );

  @override
  Future<void> import(Map<String, dynamic> data) => _lock.synchronized(
    () async {
      await validateImport(data);
      if (!await isEmpty()) {
        throw EdgeRestoreException.destinationNotEmpty('Profile repository');
      }
      _accountIndexBeforeImport = await _vaultStore.getAccountIndex();
      _importPendingRollback = true;
      final profiles = await _parseBackup(data);

      for (final backupProfile in profiles) {
        final profile = await _restoreProfile(
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
      }
    },
  );

  @override
  Future<void> rollbackImport() => _lock.synchronized(() async {
    if (!_importPendingRollback) return;
    for (final profile in await listProfiles()) {
      for (final storage in profile.fileStorages.values) {
        if (storage is Restorable) {
          await (storage as Restorable).rollbackImport();
        }
      }
      for (final storage in profile.credentialStorages.values) {
        if (storage is Restorable) {
          await (storage as Restorable).rollbackImport();
        }
      }
      for (final storage in profile.sharedStorages) {
        if (storage is Restorable) {
          await (storage as Restorable).rollbackImport();
        }
      }
      await _repository.deleteProfile(profileId: profile.id);
    }
    final accountIndexBeforeImport = _accountIndexBeforeImport;
    if (accountIndexBeforeImport != null) {
      await _vaultStore.setAccountIndex(accountIndexBeforeImport);
    }
    _accountIndexBeforeImport = null;
    _importPendingRollback = false;
  });

  Future<List<_BackupProfile>> _parseBackup(Map<String, dynamic> data) async {
    const allowedKeys = {'version', 'profiles'};
    final rawProfiles = data['profiles'];
    if (data.keys.any((key) => !allowedKeys.contains(key)) ||
        data['version'] != _backupVersion ||
        rawProfiles is! List) {
      throw EdgeRestoreException.invalidBackupFormat('edge profile repository');
    }

    final profiles = <_BackupProfile>[];
    final ids = <String>{};
    final accountIndexes = <int>{};
    for (final rawProfile in rawProfiles) {
      if (rawProfile is! Map<String, dynamic>) {
        throw EdgeRestoreException.invalidBackupFormat(
          'edge profile repository',
        );
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
        throw EdgeRestoreException.invalidBackupFormat(
          'edge profile repository',
        );
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
        throw EdgeRestoreException.invalidBackupFormat(
          'edge profile repository',
        );
      }

      final derivedDid = DidKey.getDid(
        (await _memoizedKeyPair(
          accountIndex: accountIndex.toString(),
        )).publicKey,
      );
      if (derivedDid != did) {
        throw EdgeRestoreException.invalidBackupFormat(
          'edge profile repository',
        );
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
      throw EdgeRestoreException.invalidBackupFormat('edge profile repository');
    }
    final payloads = <String, Map<String, dynamic>>{};
    for (final entry in raw.entries) {
      if (entry.key.isEmpty || entry.value is! Map<String, dynamic>) {
        throw EdgeRestoreException.invalidBackupFormat(
          'edge profile repository',
        );
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
        throw EdgeRestoreException.invalidBackupFormat(
          'edge profile repository',
        );
      }
      await storage.import(entry.value);
    }
  }

  Future<void> _validateStorages(
    Map<String, Object> storages,
    Map<String, Map<String, dynamic>> payloads,
  ) async {
    for (final entry in payloads.entries) {
      final storage = storages[entry.key];
      if (storage is! Restorable) {
        throw EdgeRestoreException.invalidBackupFormat(
          'edge profile repository',
        );
      }
      await storage.validateImport(entry.value);
    }
  }

  Future<void> _importSharedStorages(
    List<SharedStorage> storages,
    Map<String, Map<String, dynamic>> payloads,
  ) async {
    final byId = {for (final storage in storages) storage.id: storage};
    await _importStorages(byId, payloads);
  }

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
