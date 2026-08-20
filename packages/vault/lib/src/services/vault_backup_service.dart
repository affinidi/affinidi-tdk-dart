import 'dart:convert';
import 'dart:typed_data';

import 'package:affinidi_tdk_common/affinidi_tdk_common.dart';
import 'package:affinidi_tdk_cryptography/affinidi_tdk_cryptography.dart';
import 'package:ssi/ssi.dart';
import 'package:synchronized/synchronized.dart';

import '../backup.dart';
import '../backup_data.dart';
import '../exceptions/tdk_exception_type.dart';
import '../exceptions/vault_restore_exception.dart';
import '../extensions/set_extensions.dart';
import '../passphrase_policy.dart';
import '../storage_interfaces/profile_repository.dart';
import '../storage_interfaces/repository_configuration.dart';
import '../storage_interfaces/restorable.dart';
import '../vault.dart';
import 'vault_backup_service_interface.dart';

/// Creates and restores encrypted Vault backups.
///
/// The Vault exports a repository-scoped [Backup], which is JSON-encoded and
/// encrypted with a passphrase-derived key (PBKDF2 + AES-CBC authenticated with
/// HMAC-SHA256). Any tampering with the ciphertext fails authentication before
/// the plaintext is used. Only encrypted bytes leave this service.
class VaultBackupService implements VaultBackupServiceInterface {
  /// Length, in bytes, of the per-backup PBKDF2 salt generated internally.
  static const int _saltLength = 16;

  /// Creates a [VaultBackupService].
  ///
  /// Parameters:
  /// * [cryptographyService] - Optional cryptography implementation. Defaults
  ///   to [CryptographyService].
  /// * [logger] - Optional logger; defaults to [Logger.instance].
  /// * [now] - Optional clock used for the backup timestamp; defaults to
  ///   [DateTime.now]. Injectable for deterministic tests.
  VaultBackupService({
    CryptographyServiceInterface? cryptographyService,
    Logger? logger,
    DateTime Function()? now,
  }) : _cryptographyService = cryptographyService ?? CryptographyService(),
       _logger = logger ?? Logger.instance,
       _now = now ?? DateTime.now;

  final CryptographyServiceInterface _cryptographyService;
  final Logger _logger;
  final DateTime Function() _now;
  final Lock _restoreLock = Lock();

  @override
  Future<ByteData> createBackup({
    required Vault vault,
    required String passphrase,
  }) async {
    final policyViolation = PassphrasePolicy.standard.validate(passphrase);
    if (policyViolation != null) {
      throw TdkException(
        message: policyViolation,
        code: TdkExceptionType.weakPassphrase.code,
      );
    }
    try {
      final backup = Backup.fromVaultData(await vault.export());
      final plaintext = jsonEncode(backup.toJson());

      final salt = _cryptographyService.getRandomBytes(_saltLength);
      final key = await _cryptographyService.Pbkdf2(
        password: passphrase,
        nonce: salt,
      );

      final String encryptedBackup;
      try {
        encryptedBackup = await _cryptographyService.Aes256EncryptStringToHex(
          key: key,
          data: plaintext,
        );
      } finally {
        _wipe(key);
      }

      final backupData = BackupData(
        encryptedBackup: encryptedBackup,
        salt: base64Encode(salt),
        timestamp: _now().toUtc().toIso8601String(),
      );
      return ByteData.sublistView(
        Uint8List.fromList(utf8.encode(jsonEncode(backupData.toJson()))),
      );
    } on TdkException {
      rethrow;
    } catch (error, stackTrace) {
      _logger.error('Failed to create vault backup (${error.runtimeType})');
      Error.throwWithStackTrace(
        TdkException(
          message: 'Failed to create vault backup.',
          code: TdkExceptionType.backupCreationFailed.code,
        ),
        stackTrace,
      );
    }
  }

  @override
  Future<Vault> restoreBackup({
    required ByteData backupData,
    required String passphrase,
    required VaultStoreFactory vaultStoreFactory,
    required Map<String, ProfileRepositoryRegistration> repositoryFactories,
    Map<String, RestorableFactory> namedRestorableFactories = const {},
  }) => _restoreLock.synchronized(() async {
    final Backup backup;
    try {
      final bytes = backupData.buffer.asUint8List(
        backupData.offsetInBytes,
        backupData.lengthInBytes,
      );
      final rawBackupData = jsonDecode(utf8.decode(bytes));
      if (rawBackupData is! Map<String, dynamic>) {
        throw VaultRestoreException.invalidBackupFormat();
      }
      final encryptedData = BackupData.fromJson(rawBackupData);
      final salt = base64Decode(encryptedData.salt);
      final key = await _cryptographyService.Pbkdf2(
        password: passphrase,
        nonce: salt,
      );

      final String? decrypted;
      try {
        decrypted = await _cryptographyService.Aes256DecryptStringFromHex(
          key: key,
          encryptedData: encryptedData.encryptedBackup,
        );
      } finally {
        _wipe(key);
      }

      if (decrypted == null) {
        _logger.warning(
          'Failed to decrypt backup; wrong passphrase or tampered data.',
        );
        throw TdkException(
          message:
              'Failed to decrypt backup; the passphrase may be incorrect or '
              'the backup has been tampered with.',
          code: TdkExceptionType.invalidBackupFormat.code,
        );
      }

      final json = jsonDecode(decrypted) as Map<String, dynamic>;
      final decodedBackup = Backup.fromJson(json);
      backup = Backup.fromVaultData(decodedBackup.data);
    } on TdkException {
      rethrow;
    } catch (error, stackTrace) {
      _logger.error('Failed to read backup (${error.runtimeType})');
      Error.throwWithStackTrace(
        TdkException(
          message:
              'Backup could not be decrypted or is not in a recognised '
              'format.',
          code: TdkExceptionType.invalidBackupFormat.code,
        ),
        stackTrace,
      );
    }

    final repositoriesSection =
        backup.data['repositories'] as Map<String, dynamic>;
    final manifest = repositoriesSection['manifest'] as List;
    final repositoryData = repositoriesSection['data'] as Map<String, dynamic>;
    final defaultRepositoryId = repositoriesSection['defaultId'] as String;
    final repositoryIds = {
      for (final entry in manifest)
        (entry as Map<String, dynamic>)['id'] as String,
    };
    final namedData = backup.data['namedComponents'] as Map<String, dynamic>;
    if (!repositoryIds.hasSameElementsAs(repositoryFactories.keys.toSet()) ||
        !namedData.keys.toSet().hasSameElementsAs(
          namedRestorableFactories.keys.toSet(),
        )) {
      throw VaultRestoreException.invalidBackupFormat();
    }

    for (final entry in manifest) {
      final manifestEntry = entry as Map<String, dynamic>;
      final id = manifestEntry['id'] as String;
      final registration = repositoryFactories[id]!;
      if (registration.id != id ||
          registration.expectsBackupData !=
              (manifestEntry['restorable'] as bool)) {
        throw VaultRestoreException.invalidBackupFormat();
      }
    }

    final vaultStore = await vaultStoreFactory();
    final repositories = <String, ProfileRepository>{};
    final restorableRepositories = <String, Restorable>{};
    for (final entry in manifest) {
      final manifestEntry = entry as Map<String, dynamic>;
      final id = manifestEntry['id'] as String;
      final registration = repositoryFactories[id]!;
      final repository = await registration.create(vaultStore);
      if (repository.id != id) {
        throw VaultRestoreException.invalidBackupFormat();
      }
      final restorable = registration.restorableView(repository);
      if ((restorable != null) != (manifestEntry['restorable'] as bool) ||
          (!registration.expectsBackupData && repository is Restorable)) {
        throw VaultRestoreException.invalidBackupFormat();
      }
      repositories[id] = repository;
      if (restorable != null) {
        restorableRepositories[id] = restorable;
      }
    }
    final namedRestorables = <String, Restorable>{};
    for (final id in namedData.keys) {
      namedRestorables[id] = await namedRestorableFactories[id]!();
    }

    final vaultStoreData = backup.data['vaultStore'] as Map<String, dynamic>;
    await vaultStore.validateImport(vaultStoreData);
    final seed = base64Decode(vaultStoreData['seed'] as String);
    final wallet = Bip32Wallet.fromSeed(seed);
    for (final entry in repositoryData.entries) {
      final repository = restorableRepositories[entry.key]!;
      final profileRepository = repositories[entry.key]!;
      if (!await profileRepository.isConfigured()) {
        await profileRepository.configure(
          RepositoryConfiguration(wallet: wallet, keyStorage: vaultStore),
        );
      }
      await repository.validateImport(entry.value as Map<String, dynamic>);
    }
    for (final entry in namedData.entries) {
      await namedRestorables[entry.key]!.validateImport(
        entry.value as Map<String, dynamic>,
      );
    }

    if (!await vaultStore.isEmpty()) {
      throw VaultRestoreException.destinationNotEmpty('VaultStore');
    }
    for (final id in repositoryData.keys.toList()..sort()) {
      if (!await restorableRepositories[id]!.isEmpty()) {
        throw VaultRestoreException.destinationNotEmpty('Repository "$id"');
      }
    }
    for (final id in namedData.keys.toList()..sort()) {
      if (!await namedRestorables[id]!.isEmpty()) {
        throw VaultRestoreException.destinationNotEmpty(
          'Named component "$id"',
        );
      }
    }
    var vaultStoreImported = false;
    try {
      await vaultStore.import(vaultStoreData);
      vaultStoreImported = true;
      final vault = await Vault.fromVaultStore(
        vaultStore,
        profileRepositories: repositories,
        namedRestorables: namedRestorables,
        defaultProfileRepositoryId: defaultRepositoryId,
      );
      await vault.ensureInitialized();
      await vault.import(backup.data);
      return vault;
    } catch (error, stackTrace) {
      if (vaultStoreImported) {
        try {
          await vaultStore.rollbackImport();
        } catch (_) {
          Error.throwWithStackTrace(
            TdkException(
              message:
                  'Vault restore failed and automatic rollback could not '
                  'clear the VaultStore.',
              code: TdkExceptionType.restoreRollbackFailed.code,
            ),
            stackTrace,
          );
        }
      }
      Error.throwWithStackTrace(error, stackTrace);
    }
  });

  /// Overwrite of a derived-key buffer to shorten its lifetime.
  void _wipe(List<int> bytes) {
    if (bytes is Uint8List) {
      bytes.fillRange(0, bytes.length, 0);
      return;
    }

    try {
      for (var index = 0; index < bytes.length; index++) {
        bytes[index] = 0;
      }
    } catch (_) {
      _logger.warning(
        'Unable to wipe derived key material: unsupported buffer type '
        '(${bytes.runtimeType}).',
      );
    }
  }
}
