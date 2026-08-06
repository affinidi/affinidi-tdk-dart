import 'dart:convert';

import 'package:affinidi_tdk_common/affinidi_tdk_common.dart';
import 'package:affinidi_tdk_cryptography/affinidi_tdk_cryptography.dart';

import '../backup.dart';
import '../backup_data.dart';
import '../exceptions/tdk_exception_type.dart';
import 'vault_backup_service_interface.dart';

/// Creates and restores encrypted Vault backups.
///
/// Each registered [Restorable] component contributes a namespaced section to a
/// versioned [Backup] envelope, which is JSON-encoded and encrypted with a
/// passphrase-derived key (PBKDF2 + AES-CBC authenticated with HMAC-SHA256).
/// Any tampering with the ciphertext fails authentication before the plaintext
/// is used. Only the encrypted [BackupData] ever leaves this service; the
/// plaintext envelope and the derived key are never exposed.
class VaultBackupService implements VaultBackupServiceInterface {
  /// Minimum number of characters required for a backup passphrase.
  static const int _minPassphraseLength = 12;

  /// Minimum length, in bytes, required for the PBKDF2 salt.
  static const int _minNonceLength = 16;

  /// Creates a [VaultBackupService].
  ///
  /// Parameters:
  /// * [restorables] - The components to include in every backup and restore
  ///   cycle.
  /// * [cryptographyService] - Provides PBKDF2 key derivation and authenticated
  ///   AES-CBC (HMAC-SHA256) encryption.
  /// * [nonce] - The PBKDF2 salt used to derive the backup key. The consumer
  ///   owns this value: supply your own cryptographically random salt of at
  ///   least [_minNonceLength] bytes and persist it wherever you like. The same
  ///   salt must be provided at backup and restore time, otherwise the key
  ///   cannot be re-derived and the backup cannot be decrypted.
  /// * [logger] - Optional logger; defaults to [Logger.instance].
  /// * [now] - Optional clock used for the backup timestamp; defaults to
  ///   [DateTime.now]. Injectable for deterministic tests.
  VaultBackupService({
    required List<Restorable> restorables,
    required CryptographyServiceInterface cryptographyService,
    required List<int> nonce,
    Logger? logger,
    DateTime Function()? now,
  }) : _restorables = List.unmodifiable(restorables),
       _cryptographyService = cryptographyService,
       _nonce = nonce,
       _logger = logger ?? Logger.instance,
       _now = now ?? DateTime.now {
    if (_nonce.length < _minNonceLength) {
      throw ArgumentError.value(
        nonce,
        'nonce',
        'must be at least $_minNonceLength bytes',
      );
    }
  }

  final List<Restorable> _restorables;
  final CryptographyServiceInterface _cryptographyService;
  final List<int> _nonce;
  final Logger _logger;
  final DateTime Function() _now;

  @override
  Future<BackupData> createBackup({required String passphrase}) async {
    if (passphrase.length < _minPassphraseLength) {
      throw TdkException(
        message:
            'Passphrase must be at least $_minPassphraseLength characters long.',
        code: TdkExceptionType.weakPassphrase.code,
      );
    }
    try {
      final backup = Backup(data: await _exportSections());
      final plaintext = jsonEncode(backup.toJson());

      final key = await _cryptographyService.Pbkdf2(
        password: passphrase,
        nonce: _nonce,
      );

      final encryptedBackup =
          await _cryptographyService.Aes256EncryptStringToHex(
            key: key,
            data: plaintext,
          );

      return BackupData(
        encryptedBackup: encryptedBackup,
        timestamp: _now().toUtc().toIso8601String(),
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
  Future<void> restoreFromBackup({
    required BackupData backupData,
    required String passphrase,
  }) async {
    final Backup backup;
    try {
      final key = await _cryptographyService.Pbkdf2(
        password: passphrase,
        nonce: _nonce,
      );

      final decrypted = await _cryptographyService.Aes256DecryptStringFromHex(
        key: key,
        encryptedData: backupData.encryptedBackup,
      );

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
      backup = Backup.fromJson(json);
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

    await _importSections(backup.data);
  }

  Future<Map<String, dynamic>> _exportSections() async {
    final sections = <String, dynamic>{};
    for (final restorable in _restorables) {
      sections.addAll(await restorable.export());
    }
    return sections;
  }

  Future<void> _importSections(Map<String, dynamic> data) async {
    final snapshot = Map<String, dynamic>.unmodifiable(data);
    for (final restorable in _restorables) {
      await restorable.import(snapshot);
    }
  }
}
