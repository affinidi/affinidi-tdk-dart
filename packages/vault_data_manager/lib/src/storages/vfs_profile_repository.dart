import 'dart:convert';
import 'dart:typed_data';

import 'package:affinidi_tdk_common/affinidi_tdk_common.dart';
import 'package:affinidi_tdk_consumer_auth_provider/affinidi_tdk_consumer_auth_provider.dart';
import 'package:affinidi_tdk_consumer_iam_client/affinidi_tdk_consumer_iam_client.dart';
import 'package:affinidi_tdk_cryptography/affinidi_tdk_cryptography.dart';
import 'package:affinidi_tdk_vault/affinidi_tdk_vault.dart';
import 'package:dio/dio.dart';
import 'package:meta/meta.dart';
import 'package:ssi/ssi.dart';

import '../exceptions/tdk_exception_type.dart';
import '../helpers/dio_cancel_token_adapter.dart';
import '../helpers/jwt_helper.dart';
import '../model/account.dart';
import '../model/vault_data_manager_profile.dart';
import '../services/vault_data_manager_service.dart';
import '../services/vault_data_manager_service_interface.dart';
import '../services/vault_data_manager_shared_access_api_service.dart';
import '../services/vault_data_manager_shared_access_api_service_interface.dart';
import 'vfs_credential_storage.dart';
import 'vfs_file_storage.dart';
import 'vfs_shared_storage.dart';

/// Type definition for creating [ConsumerAuthProvider] instances
typedef ConsumerAuthProviderFactory =
    ConsumerAuthProvider Function(DidSigner didSigner, {Dio? client});

/// Factory function type for creating [VaultDataManagerSharedAccessApiService] instances.
typedef IamApiServiceFactory =
    VaultDataManagerSharedAccessApiServiceInterface Function(
      ConsumerAuthProvider provider,
    );

/// Type definition for creating regular [VaultDataManagerService] instances
typedef VaultDataManagerServiceFactory =
    Future<VaultDataManagerServiceInterface> Function({
      required KeyPair keyPair,
      required Uint8List encryptedDekek,
    });

/// Type definition for creating delegated [VaultDataManagerService] instances
typedef VaultDelegatedDataManagerServiceFactory =
    Future<VaultDataManagerServiceInterface> Function({
      required KeyPair keyPair,
      required Uint8List encryptedDekek,
      required String profileDid,
    });

/// A VFS implementation of [ProfileRepository] for managing user profiles.
class VfsProfileRepository
    implements ProfileRepository, ProfileAccessSharing, ProfileStorageInfo {
  /// The key ID for the root account.
  static const _rootAccountKeyId = '0';
  static const _nonceSize = 32;

  /// The expiration time in seconds for authentication tokens.
  static int expiration = 300;

  /// The audience URL for authentication tokens.
  static String aud = Uri.parse(
    Environment.fetchEnvironment().elementsVaultApiUrl,
  ).resolve('vfs/v1/accounts').toString();

  final String _id;
  late final Wallet _wallet;
  late VaultStore _keyStorage;
  bool _configured = false;

  // Internal services that can be overridden for testing
  final ConsumerAuthProviderFactory _consumerAuthProviderFactory;
  final IamApiServiceFactory _iamApiServiceFactory;
  final VaultDataManagerServiceFactory _vaultDataManagerServiceFactory;
  final VaultDelegatedDataManagerServiceFactory
  _vaultDelegatedDataManagerServiceFactory;

  /// Logger instance for error handling
  final Logger _logger;

  /// Creates a new instance of [VfsProfileRepository].
  ///
  /// The [id] parameter is used to identify this repository instance.
  /// Creates a new instance of [VfsProfileRepository].
  ///
  /// The [id] parameter is used to identify this repository instance.
  factory VfsProfileRepository(String id) => VfsProfileRepository._(id);

  /// Creates a new instance of [VfsProfileRepository].
  ///
  /// The [id] parameter is used to identify this repository instance.
  ///
  /// For testing purposes, you can provide mock implementations of:
  /// - [cryptographyService]: A cryptographyService used to generate KEKs
  /// - [consumerAuthProviderFactory]: A factory function for creating [ConsumerAuthProvider] instances
  /// - [iamApiServiceFactory]: A factory function for creating [VaultDataManagerSharedAccessApiService] instances
  /// - [vaultDataManagerServiceFactory]: A factory function for creating regular [VaultDataManagerService] instances
  /// - [vaultDelegatedDataManagerServiceFactory]: A factory function for creating delegated [VaultDataManagerService] instances
  @visibleForTesting
  factory VfsProfileRepository.withDependencies(
    String id, {
    CryptographyServiceInterface? cryptographyService,
    ConsumerAuthProviderFactory? consumerAuthProviderFactory,
    IamApiServiceFactory? iamApiServiceFactory,
    VaultDataManagerServiceFactory? vaultDataManagerServiceFactory,
    VaultDelegatedDataManagerServiceFactory?
    vaultDelegatedDataManagerServiceFactory,
  }) => VfsProfileRepository._(
    id,
    cryptographyService: cryptographyService,
    consumerAuthProviderFactory: consumerAuthProviderFactory,
    iamApiServiceFactory: iamApiServiceFactory,
    vaultDataManagerServiceFactory: vaultDataManagerServiceFactory,
    vaultDelegatedDataManagerServiceFactory:
        vaultDelegatedDataManagerServiceFactory,
  );

  VfsProfileRepository._(
    this._id, {
    CryptographyServiceInterface? cryptographyService,
    ConsumerAuthProviderFactory? consumerAuthProviderFactory,
    IamApiServiceFactory? iamApiServiceFactory,
    VaultDataManagerServiceFactory? vaultDataManagerServiceFactory,
    VaultDelegatedDataManagerServiceFactory?
    vaultDelegatedDataManagerServiceFactory,
    Logger? logger,
  }) : _cryptographyService = cryptographyService ?? CryptographyService(),
       _consumerAuthProviderFactory =
           consumerAuthProviderFactory ??
           ((DidSigner didSigner, {Dio? client}) =>
               ConsumerAuthProvider(signer: didSigner, client: client)),
       _iamApiServiceFactory =
           iamApiServiceFactory ??
           ((ConsumerAuthProvider provider) {
             final consumerIamClient = AffinidiTdkConsumerIamClient(
               authTokenHook: provider.fetchConsumerToken,
               basePathOverride:
                   '${Environment.fetchEnvironment().apiGwUrl}/cid',
             );
             return VaultDataManagerSharedAccessApiService(
               affinidiTdkConsumerIamClient: consumerIamClient,
             );
           }),
       _vaultDataManagerServiceFactory =
           vaultDataManagerServiceFactory ?? VaultDataManagerService.create,
       _vaultDelegatedDataManagerServiceFactory =
           vaultDelegatedDataManagerServiceFactory ??
           VaultDataManagerService.createDelegated,
       _logger = logger ?? Logger.instance;

  @override
  String get id => _id;

  final CryptographyServiceInterface _cryptographyService;

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

    if (configuration.keyStorage == null) {
      Error.throwWithStackTrace(
        TdkException(
          message:
              'VFS Profile repository must receive a KeyStorage to maintain account indexes and avoid duplicate accounts',
          code: TdkExceptionType.missingVaultStore.code,
        ),
        StackTrace.current,
      );
    }

    _wallet = configuration.wallet;
    _keyStorage = configuration.keyStorage!;

    _configured = true;
  }

  @override
  Future<bool> isConfigured() async {
    return _configured;
  }

  Future<String> _getDidProof({required DidSigner didSigner}) async {
    final jwtHelper = JwtHelper(didSigner);
    final jwt = await jwtHelper.getJwt(audience: aud, expiration: 300);
    return jwt;
  }

  @override
  Future<Profile> createProfile({
    required String name,
    String? description,
    VaultCancelToken? cancelToken,
  }) async {
    if (!_configured) {
      Error.throwWithStackTrace(
        TdkException(
          message:
              'Profile repository must be configured using a RepositoryConfiguration',
          code: TdkExceptionType.profileNotConfigured.code,
        ),
        StackTrace.current,
      );
    }

    final nextAccountIndex = (await _keyStorage.getAccountIndex()) + 1;

    final profileDidSigner = await _memoizedDidSigner('$nextAccountIndex');
    final profileDid = profileDidSigner.did;
    final profileDidProof = await _getDidProof(didSigner: profileDidSigner);

    final kekBuffer = Uint8List.fromList(
      _cryptographyService.getRandomBytes(_nonceSize),
    );
    final profileKeyPair = await _memoizedKeyPair(
      accountIndex: '$nextAccountIndex',
    );
    final encryptedDekek = await profileKeyPair.encrypt(kekBuffer);

    final accountMetadata = AccountMetadata(
      dekekInfo: DekekInfo(encryptedDekek: base64.encode(encryptedDekek)),
      sharedStorageData: [],
    );

    final accountVaultDataManagerService = await _memoizedDataManagerService(
      walletKeyId: _rootAccountKeyId,
    );
    final result = await accountVaultDataManagerService.createProfile(
      accountIndex: nextAccountIndex,
      accountMetadata: accountMetadata,
      profileDid: profileDid,
      profileDidProof: profileDidProof,
      profileKeyPair: profileKeyPair,
      profileName: name,
      profileDescription: description,
      cancelToken: cancelToken,
    );
    final profileId = result.data?.profileId;
    if (profileId == null) {
      Error.throwWithStackTrace(
        TdkException(
          message: 'Failed to create profile in VFS',
          code: TdkExceptionType.unableToCreateAccount.code,
        ),
        StackTrace.current,
      );
    }

    await _keyStorage.setAccountIndex(nextAccountIndex);

    final profileDataManager = await _memoizedDataManagerService(
      walletKeyId: nextAccountIndex.toString(),
      encryptedDekek: encryptedDekek,
    );

    return Profile(
      id: profileId,
      name: name,
      description: description,
      did: profileDid,
      accountIndex: nextAccountIndex,
      profileRepositoryId: id,
      fileStorages: {
        _id: VFSFileStorage(id: _id, dataManagerService: profileDataManager),
      },
      credentialStorages: {
        _id: VFSCredentialStorage(
          id: _id,
          dataManagerService: profileDataManager,
          profileId: profileId,
        ),
      },
      sharedStorages: {},
    );
  }

  @override
  Future<List<Profile>> listProfiles({VaultCancelToken? cancelToken}) async {
    if (!_configured) {
      Error.throwWithStackTrace(
        TdkException(
          message:
              'Profile repository must be configured using a RepositoryConfiguration',
          code: TdkExceptionType.profileNotConfigured.code,
        ),
        StackTrace.current,
      );
    }

    final accountVaultDataManagerService = await _memoizedDataManagerService(
      walletKeyId: _rootAccountKeyId,
    );
    final vfsProfiles = await accountVaultDataManagerService.getProfiles(
      cancelToken: cancelToken,
    );

    final profiles = await Future.wait<Profile?>(
      vfsProfiles.map((profile) async {
        try {
          return await _makeProfile(profile);
        } catch (e, stackTrace) {
          _logger.log(
            LogLevel.warning,
            'Unable to reconstruct profile ${profile.id}: ${e.toString()}',
            stackTrace: stackTrace,
          );

          return null;
        }
      }),
    );

    return profiles.nonNulls.toList();
  }

  Future<Profile> _makeProfile(VaultDataManagerProfile profile) async {
    final encryptedDekek = profile.accountMetadata?.dekekInfo.encryptedDekek;
    if (encryptedDekek == null) {
      throw TdkException(
        message: 'Missing encrypted DEKEK for profile ${profile.id}',
        code: TdkExceptionType.missingEncryptedDekek.code,
      );
    }

    final profileDataManager = await _memoizedDataManagerService(
      walletKeyId: profile.accountIndex.toString(),
      encryptedDekek: base64.decode(encryptedDekek),
    );

    final profileKeyPair = await _memoizedKeyPair(
      accountIndex: '${profile.accountIndex}',
    );

    final did = DidKey.getDid(profileKeyPair.publicKey);
    final sharedStorages = await _makeSharedStorages(
      profileKeyPair: profileKeyPair,
      accountMetadata: profile.accountMetadata,
    );

    return Profile(
      id: profile.id,
      name: profile.name,
      description: profile.description,
      profilePictureURI: profile.pictureURI,
      did: did,
      accountIndex: profile.accountIndex,
      profileRepositoryId: id,
      fileStorages: {
        _id: VFSFileStorage(id: _id, dataManagerService: profileDataManager),
      },
      credentialStorages: {
        _id: VFSCredentialStorage(
          id: _id,
          dataManagerService: profileDataManager,
          profileId: profile.id,
        ),
      },
      sharedStorages: sharedStorages,
    );
  }

  Future<Map<String, SharedStorage>> _makeSharedStorages({
    required KeyPair profileKeyPair,
    AccountMetadata? accountMetadata,
  }) async {
    final sharedStorages = <String, SharedStorage>{};
    final sharedStorageData = accountMetadata?.sharedStorageData ?? [];

    for (final sharedStorage in sharedStorageData) {
      sharedStorages[sharedStorage.nodePath] = VfsSharedStorage(
        id: sharedStorage.nodePath,
        sharedProfileId: sharedStorage.nodePath,
        dataManagerService: await _vaultDelegatedDataManagerServiceFactory(
          profileDid: sharedStorage.profileDid,
          keyPair: profileKeyPair,
          encryptedDekek: base64.decode(sharedStorage.encryptedDekek),
        ),
      );
    }

    return sharedStorages;
  }

  @override
  Future<void> deleteProfile(
    Profile profile, {
    VaultCancelToken? cancelToken,
  }) async {
    if (!_configured) {
      Error.throwWithStackTrace(
        TdkException(
          message:
              'Profile repository must be configured using a RepositoryConfiguration',
          code: TdkExceptionType.profileNotConfigured.code,
        ),
        StackTrace.current,
      );
    }

    if (profile.profileRepositoryId != id) {
      Error.throwWithStackTrace(
        TdkException(
          message:
              'Profile is associated to a different repository and cannot be deleted',
          code: TdkExceptionType.wrongProfileRepository.code,
        ),
        StackTrace.current,
      );
    }

    final profileDataManager = await _memoizedDataManagerService(
      walletKeyId: profile.accountIndex.toString(),
    );
    await profileDataManager.deleteProfile(
      profile.id,
      cancelToken: cancelToken,
    );

    final accountVaultDataManagerService = await _memoizedDataManagerService(
      walletKeyId: _rootAccountKeyId,
    );
    await accountVaultDataManagerService.deleteAccount(
      accountIndex: profile.accountIndex,
      cancelToken: cancelToken,
    );

    _clearMemoizedProfileData(profile.accountIndex);
  }

  @override
  Future<void> updateProfile(
    Profile profile, {
    VaultCancelToken? cancelToken,
  }) async {
    if (!_configured) {
      Error.throwWithStackTrace(
        TdkException(
          message:
              'Profile repository must be configured using a RepositoryConfiguration',
          code: TdkExceptionType.profileNotConfigured.code,
        ),
        StackTrace.current,
      );
    }

    if (profile.profileRepositoryId != id) {
      Error.throwWithStackTrace(
        TdkException(
          message:
              'Profile is associated to a different repository and cannot be updated',
          code: TdkExceptionType.wrongProfileRepository.code,
        ),
        StackTrace.current,
      );
    }

    final profileDataManager = await _memoizedDataManagerService(
      walletKeyId: profile.accountIndex.toString(),
    );
    await profileDataManager.updateProfileMetadata(
      id: profile.id,
      name: profile.name,
      description: profile.description,
      profilePictureURI: profile.profilePictureURI,
      cancelToken: cancelToken,
    );
  }

  final _didSigners = <String, DidSigner>{};
  final _dataManagers = <String, VaultDataManagerServiceInterface>{};
  final _keyPairs = <String, KeyPair>{};

  /// Deletes any memoized data associated to the accountIndex when a profile is deleted
  void _clearMemoizedProfileData(int accountIndex) {
    _didSigners.remove('$accountIndex');
    _dataManagers.remove('$accountIndex');
    _keyPairs.remove('$accountIndex');
  }

  Future<KeyPair> _memoizedKeyPair({required String accountIndex}) async {
    _keyPairs[accountIndex] ??= await _getProfileKeyPair(
      accountIndex: accountIndex,
    );
    return _keyPairs[accountIndex]!;
  }

  /// Memoize dataManagerService based on the walletKeyId
  Future<VaultDataManagerServiceInterface> _memoizedDataManagerService({
    required String walletKeyId,
    Uint8List? encryptedDekek,
  }) async {
    _dataManagers[walletKeyId] ??= await _vaultDataManagerServiceFactory(
      encryptedDekek: encryptedDekek ?? Uint8List(0),
      keyPair: await _memoizedKeyPair(accountIndex: walletKeyId),
    );
    return _dataManagers[walletKeyId]!;
  }

  /// Memoize didSigner based on the walletKeyId
  Future<DidSigner> _memoizedDidSigner(String accountIndex) async {
    _didSigners[accountIndex] ??= await _makeDidSigner(
      await _memoizedKeyPair(accountIndex: accountIndex),
    );
    return _didSigners[accountIndex]!;
  }

  Future<DidSigner> _makeDidSigner(KeyPair keyPair) async {
    final didDocument = DidKey.generateDocument(keyPair.publicKey);
    return DidSigner(
      did: didDocument.id,
      didKeyId: didDocument.verificationMethod.first.id,
      keyPair: keyPair,
      signatureScheme: SignatureScheme.ecdsa_secp256k1_sha256,
    );
  }

  @override
  Future<Uint8List> grantItemAccessMultiple({
    required int accountIndex,
    required String granteeDid,
    required List<
      ({List<String> itemIds, Permissions permissions, DateTime? expiresAt})
    >
    permissionGroups,
    VaultCancelToken? cancelToken,
  }) async {
    _ensureConfigured();

    final iamApiService = await _getIamApiService(accountIndex);
    await iamApiService.setItemsAccessVfs(
      granteeDid: granteeDid,
      permissionGroups: permissionGroups
          .map(
            (group) => (
              itemIds: group.itemIds,
              permissions: group.permissions,
              expiresAt: group.expiresAt,
            ),
          )
          .toList(),
      cancelToken: cancelToken != null
          ? DioCancelTokenAdapter.from(cancelToken)
          : null,
    );

    final accountVaultDataManagerService = await _memoizedDataManagerService(
      walletKeyId: _rootAccountKeyId,
    );
    final accounts = await accountVaultDataManagerService.getAccounts();
    final account = accounts
        .where((account) => account.accountIndex == accountIndex)
        .firstOrNull;

    if (account == null) {
      Error.throwWithStackTrace(
        TdkException(
          message: 'Account with index $accountIndex does not exist',
          code: TdkExceptionType.invalidAccountIndex.code,
        ),
        StackTrace.current,
      );
    }

    final profileKeyPair = await _memoizedKeyPair(
      accountIndex: '$accountIndex',
    );
    final kek = await profileKeyPair.decrypt(
      base64.decode(account.accountMetadata!.dekekInfo.encryptedDekek),
    );

    return kek;
  }

  @override
  Future<void> revokeItemAccess({
    required int accountIndex,
    required String granteeDid,
    required List<String> itemIds,
    VaultCancelToken? cancelToken,
  }) async {
    _ensureConfigured();

    final iamApiService = await _getIamApiService(accountIndex);

    await iamApiService.revokeItemsAccessVfs(
      granteeDid: granteeDid,
      itemIds: itemIds,
      cancelToken: cancelToken != null
          ? DioCancelTokenAdapter.from(cancelToken)
          : null,
    );
  }

  @override
  Future<Map<String, dynamic>> getItemAccess({
    required int accountIndex,
    required String granteeDid,
    VaultCancelToken? cancelToken,
  }) async {
    _ensureConfigured();

    final iamApiService = await _getIamApiService(accountIndex);
    final response = await iamApiService.getItemsAccessVfs(
      granteeDid: granteeDid,
      cancelToken: cancelToken != null
          ? DioCancelTokenAdapter.from(cancelToken)
          : null,
    );

    return {
      'permissions': response.data!.permissions
          .map(
            (p) => {
              'nodeIds': p.nodeIds.toList(),
              'rights': p.rights.map((r) => r.toString()).toList(),
              'expiresAt': p.expiresAt?.toString(),
            },
          )
          .toList(),
    };
  }

  @override
  Future<Profile> receiveItemAccess({
    required Profile profile,
    required String ownerProfileId,
    required Uint8List kek,
    required String ownerProfileDid,
    VaultCancelToken? cancelToken,
  }) async {
    _ensureConfigured();

    final profileKeyPair = await _memoizedKeyPair(
      accountIndex: '${profile.accountIndex}',
    );

    final accountVaultDataManagerService = await _memoizedDataManagerService(
      walletKeyId: _rootAccountKeyId,
    );

    final profileDidSigner = await _memoizedDidSigner(
      profile.accountIndex.toString(),
    );
    final profileDidProof = await _getDidProof(didSigner: profileDidSigner);

    final updatedAccount = await accountVaultDataManagerService.patchAccount(
      accountIndex: profile.accountIndex,
      didProof: profileDidProof,
      encryptedDekek: base64.encode(await profileKeyPair.encrypt(kek)),
      ownerProfileId: ownerProfileId,
      ownerProfileDid: ownerProfileDid,
      cancelToken: cancelToken,
    );

    final sharedStorages = await _makeSharedStorages(
      profileKeyPair: profileKeyPair,
      accountMetadata: updatedAccount.accountMetadata,
    );

    return profile.refreshSharedStorages(sharedStorages);
  }

  Future<KeyPair> _getProfileKeyPair({required String accountIndex}) async {
    return await _wallet.generateKey(keyId: _getDerivationPath(accountIndex));
  }

  String _getDerivationPath(String accountIndex) =>
      "m/44'/60'/$accountIndex'/0'/0'";

  /// Ensures the repository is configured.
  ///
  /// Throws [TdkException] if not configured.
  void _ensureConfigured() {
    if (!_configured) {
      Error.throwWithStackTrace(
        TdkException(
          message:
              'Profile repository must be configured using a RepositoryConfiguration',
          code: TdkExceptionType.profileNotConfigured.code,
        ),
        StackTrace.current,
      );
    }
  }

  /// Creates an IAM API service for the given account index.
  Future<VaultDataManagerSharedAccessApiServiceInterface> _getIamApiService(
    int accountIndex,
  ) async {
    final didSigner = await _memoizedDidSigner('$accountIndex');
    final consumerAuthProvider = _consumerAuthProviderFactory(didSigner);
    return _iamApiServiceFactory(consumerAuthProvider);
  }

  @override
  Future<VaultStorageUsage> getStorageUsage({
    VaultCancelToken? cancelToken,
  }) async {
    _ensureConfigured();
    final accountVaultDataManagerService = await _memoizedDataManagerService(
      walletKeyId: _rootAccountKeyId,
    );
    final consumption = await accountVaultDataManagerService
        .getVaultDataFileConsumption(cancelToken: cancelToken);
    return VaultStorageUsage.fromBytes(
      (consumption.sizeInMB * 1024 * 1024).round(),
    );
  }
}

extension _ProfileSharedStorages on Profile {
  Profile refreshSharedStorages(Map<String, SharedStorage> sharedStorages) {
    final existingSharedStorageIds = this.sharedStorages
        .map((sharedStorage) => sharedStorage.id)
        .toList();

    for (final sharedStorageId in existingSharedStorageIds) {
      removeSharedStorage(id: sharedStorageId);
    }

    for (final entry in sharedStorages.entries) {
      addSharedStorage(id: entry.key, sharedStorage: entry.value);
    }

    return this;
  }
}
