import 'dart:convert';
import 'dart:typed_data';

import 'package:affinidi_tdk_common/affinidi_tdk_common.dart';
import 'package:affinidi_tdk_cryptography/affinidi_tdk_cryptography.dart';

import '../backup.dart';
import '../backup_data.dart';
import '../exceptions/tdk_exception_type.dart';
import '../passphrase_policy.dart';
import '../storage_interfaces/profile_repository.dart';
import '../storage_interfaces/restorable.dart';
import '../vault.dart';
import 'vault_backup_service_interface.dart';

/// Creates and restores encrypted Vault backups.
///
/// The Vault exports a repository-scoped [Backup], which is JSON-encoded and
/// encrypted with a passphrase-derived key (PBKDF2 + AES-CBC authenticated with
/// HMAC-SHA256).
/// Any tampering with the ciphertext fails authentication before the plaintext
/// is used. Only the encrypted [BackupData] ever leaves this service; the
/// plaintext envelope and the derived key are never exposed.
class VaultBackupService implements VaultBackupServiceInterface {
  /// Length, in bytes, of the per-backup PBKDF2 salt generated internally.
  static const int _saltLength = 16;

  /// Creates a [VaultBackupService].
  ///
  /// Parameters:
  /// * [cryptographyService] - Provides PBKDF2 key derivation and authenticated
  ///   AES-CBC (HMAC-SHA256) encryption.
  /// * [logger] - Optional logger; defaults to [Logger.instance].
  /// * [now] - Optional clock used for the backup timestamp; defaults to
  ///   [DateTime.now]. Injectable for deterministic tests.
  VaultBackupService({
    required CryptographyServiceInterface cryptographyService,
    Logger? logger,
    DateTime Function()? now,
  }) : _cryptographyService = cryptographyService,
       _logger = logger ?? Logger.instance,
       _now = now ?? DateTime.now;

  final CryptographyServiceInterface _cryptographyService;
  final Logger _logger;
  final DateTime Function() _now;

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
    required Map<String, ProfileRepositoryFactory> repositoryFactories,
    Map<String, RestorableFactory> namedRestorableFactories = const {},
    String? defaultProfileRepositoryId,
  }) async {
    final Backup backup;
    try {
      final bytes = backupData.buffer.asUint8List(
        backupData.offsetInBytes,
        backupData.lengthInBytes,
      );
      final rawBackupData = jsonDecode(utf8.decode(bytes));
      if (rawBackupData is! Map<String, dynamic>) {
        throw _invalidBackupFormat();
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
    final repositoryIds = {
      for (final entry in manifest)
        (entry as Map<String, dynamic>)['id'] as String,
    };
    final namedData = backup.data['namedComponents'] as Map<String, dynamic>;
    if (!_sameIds(repositoryIds, repositoryFactories.keys.toSet()) ||
        !_sameIds(
          namedData.keys.toSet(),
          namedRestorableFactories.keys.toSet(),
        )) {
      throw _invalidBackupFormat();
    }

    final vaultStore = await vaultStoreFactory();
    final repositories = <String, ProfileRepository>{};
    for (final entry in manifest) {
      final manifestEntry = entry as Map<String, dynamic>;
      final id = manifestEntry['id'] as String;
      final repository = await repositoryFactories[id]!(vaultStore);
      if (repository.id != id ||
          (repository is Restorable) != (manifestEntry['restorable'] as bool)) {
        throw _invalidBackupFormat();
      }
      repositories[id] = repository;
    }
    final namedRestorables = <String, Restorable>{};
    for (final id in namedData.keys) {
      namedRestorables[id] = await namedRestorableFactories[id]!();
    }

    await vaultStore.import(backup.data['vaultStore'] as Map<String, dynamic>);
    final vault = await Vault.fromVaultStore(
      vaultStore,
      profileRepositories: repositories,
      namedRestorables: namedRestorables,
      defaultProfileRepositoryId: defaultProfileRepositoryId,
    );
    await vault.ensureInitialized();
    await vault.import(backup.data);
    return vault;
  }

  /// Overwrite of a derived-key buffer to shorten its lifetime.
  void _wipe(List<int> bytes) {
    if (bytes is Uint8List) {
      bytes.fillRange(0, bytes.length, 0);
    }
  }

  bool _sameIds(Set<String> left, Set<String> right) =>
      left.length == right.length && left.containsAll(right);

  TdkException _invalidBackupFormat() => TdkException(
    message: 'Backup is not compatible with the configured Vault factories.',
    code: TdkExceptionType.invalidBackupFormat.code,
  );
}
