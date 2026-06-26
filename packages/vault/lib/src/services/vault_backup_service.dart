import 'dart:convert';
import 'dart:typed_data';

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
/// passphrase-derived key (PBKDF2 + AES-CBC). Only the encrypted [BackupData]
/// ever leaves this service; the plaintext envelope is never exposed.
class VaultBackupService implements VaultBackupServiceInterface {
  /// Creates a [VaultBackupService].
  ///
  /// Parameters:
  /// * [restorables] - The components to include in every backup and restore
  ///   cycle.
  /// * [cryptographyService] - Provides PBKDF2 key derivation and AES-CBC.
  /// * [nonce] - The PBKDF2 salt used to derive the backup key. The consumer
  ///   owns this value: supply your own salt and persist it wherever you like.
  ///   The same salt must be provided at backup and restore time, otherwise the
  ///   key cannot be re-derived and the backup cannot be decrypted.
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
       _now = now ?? DateTime.now;

  final List<Restorable> _restorables;
  final CryptographyServiceInterface _cryptographyService;
  final List<int> _nonce;
  final Logger _logger;
  final DateTime Function() _now;

  @override
  Future<BackupData> createBackup({required String passphrase}) async {
    try {
      final backup = Backup(data: await _exportSections());
      final plaintext = jsonEncode(backup.toJson());

      final key = await _cryptographyService.Pbkdf2(
        password: passphrase,
        nonce: _nonce,
      );

      final encryptedBackup = _cryptographyService.encryptToHex(
        Uint8List.fromList(key),
        Uint8List.fromList(utf8.encode(plaintext)),
      );

      return BackupData(
        encryptedBackup: encryptedBackup,
        encryptionKey: Uint8List.fromList(key),
        timestamp: _now().toUtc().toIso8601String(),
      );
    } on TdkException {
      rethrow;
    } catch (error, stackTrace) {
      _logger.error('Failed to create vault backup: $error');
      Error.throwWithStackTrace(
        TdkException(
          message: 'Failed to create vault backup.',
          code: TdkExceptionType.invalidBackupFormat.code,
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

      final decrypted = _cryptographyService.decryptFromHex(
        Uint8List.fromList(key),
        backupData.encryptedBackup,
      );

      if (decrypted == null) {
        _logger.warning('Failed to decrypt backup; likely wrong passphrase.');
        throw TdkException(
          message: 'Failed to decrypt backup; the passphrase may be incorrect.',
          code: TdkExceptionType.invalidBackupFormat.code,
        );
      }

      final json = jsonDecode(utf8.decode(decrypted)) as Map<String, dynamic>;
      backup = Backup.fromJson(json);
    } on TdkException {
      rethrow;
    } catch (error, stackTrace) {
      _logger.error('Failed to read backup: $error');
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
