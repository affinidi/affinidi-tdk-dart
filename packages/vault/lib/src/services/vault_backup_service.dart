import 'dart:convert';

import 'package:affinidi_tdk_common/affinidi_tdk_common.dart';
import 'package:affinidi_tdk_cryptography/affinidi_tdk_cryptography.dart';

import '../backup.dart';
import '../backup_data.dart';
import '../exceptions/tdk_exception_type.dart';
import '../passphrase_policy.dart';
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
  /// Length, in bytes, of the per-backup PBKDF2 salt generated internally.
  static const int _saltLength = 16;

  /// Creates a [VaultBackupService].
  ///
  /// Parameters:
  /// * [restorables] - The components to include in every backup and restore
  ///   cycle.
  /// * [cryptographyService] - Provides PBKDF2 key derivation and authenticated
  ///   AES-CBC (HMAC-SHA256) encryption.
  /// * [logger] - Optional logger; defaults to [Logger.instance].
  /// * [now] - Optional clock used for the backup timestamp; defaults to
  ///   [DateTime.now]. Injectable for deterministic tests.
  VaultBackupService({
    required List<Restorable> restorables,
    required CryptographyServiceInterface cryptographyService,
    Logger? logger,
    DateTime Function()? now,
  }) : _restorables = List.unmodifiable(restorables),
       _cryptographyService = cryptographyService,
       _logger = logger ?? Logger.instance,
       _now = now ?? DateTime.now;

  final List<Restorable> _restorables;
  final CryptographyServiceInterface _cryptographyService;
  final Logger _logger;
  final DateTime Function() _now;

  @override
  Future<BackupData> createBackup({required String passphrase}) async {
    final policyViolation = PassphrasePolicy.standard.validate(passphrase);
    if (policyViolation != null) {
      throw TdkException(
        message: policyViolation,
        code: TdkExceptionType.weakPassphrase.code,
      );
    }
    try {
      final backup = Backup(data: await _exportSections());
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

      return BackupData(
        encryptedBackup: encryptedBackup,
        salt: base64Encode(salt),
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
      final salt = base64Decode(backupData.salt);
      final key = await _cryptographyService.Pbkdf2(
        password: passphrase,
        nonce: salt,
      );

      final String? decrypted;
      try {
        decrypted = await _cryptographyService.Aes256DecryptStringFromHex(
          key: key,
          encryptedData: backupData.encryptedBackup,
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
      final section = await restorable.export();
      for (final key in section.keys) {
        if (sections.containsKey(key)) {
          throw TdkException(
            message:
                'Duplicate backup section "$key": each source must own a '
                'unique namespace.',
            code: TdkExceptionType.backupCreationFailed.code,
          );
        }
      }
      sections.addAll(section);
    }
    return sections;
  }

  Future<void> _importSections(Map<String, dynamic> data) async {
    final snapshot = Map<String, dynamic>.unmodifiable(data);
    for (final restorable in _restorables) {
      await restorable.import(snapshot);
    }
  }

  /// Overwrite of a derived-key buffer to shorten its lifetime.
  void _wipe(List<int> bytes) {
    try {
      bytes.fillRange(0, bytes.length, 0);
    } on UnsupportedError {
      // The buffer is not mutable; nothing more we can do.
    }
  }
}
