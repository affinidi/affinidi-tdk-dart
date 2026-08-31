import 'dart:convert';

import 'package:affinidi_tdk_vault/affinidi_tdk_vault.dart' show Restorable;
import 'package:affinidi_tdk_vault_iota/affinidi_tdk_vault_iota.dart'
    hide TdkExceptionType;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../src/exceptions/consent_storage_exception.dart';
import '../src/exceptions/vault_restore_exception.dart';

/// Implementation of [ConsentStorage] backed by Flutter's secure storage.
///
/// Each record is stored as a JSON string keyed by its [IotaConsentRecord.hash],
/// prefixed with a namespace to avoid collisions with other secure storage entries.
class FlutterSecureConsentStorage
    implements EnumerableConsentStorage, Restorable {
  /// Creates a [FlutterSecureConsentStorage].
  ///
  /// Parameters:
  /// * [namespace] - Prefix applied to every storage key. Defaults to `iota_consent`.
  /// * [secureStorage] - Optional [FlutterSecureStorage] instance for testing.
  FlutterSecureConsentStorage({
    String namespace = 'iota_consent',
    FlutterSecureStorage? secureStorage,
  }) : _namespace = namespace,
       _secureStorage =
           secureStorage ??
           const FlutterSecureStorage(
             aOptions: AndroidOptions(),
             iOptions: IOSOptions(
               accessibility: KeychainAccessibility.unlocked_this_device,
             ),
           );

  final String _namespace;
  final FlutterSecureStorage _secureStorage;
  bool _importPendingRollback = false;

  static const _backupVersion = '1.0.0';

  String _key(String hash) => '${_namespace}_$hash';

  @override
  Future<void> saveOrUpdate(IotaConsentRecord record) async {
    await _secureStorage.write(
      key: _key(record.hash),
      value: jsonEncode(record.toJson()),
    );
  }

  @override
  Future<IotaConsentRecord?> findByRequestHash(String requestHash) async {
    IotaConsentRecord? bestMatch;

    for (final record in await _readAllRecords()) {
      if (record.requestHash != requestHash) continue;
      if (bestMatch == null ||
          record.sharedAt.compareTo(bestMatch.sharedAt) > 0) {
        bestMatch = record;
      }
    }

    return bestMatch;
  }

  @override
  Future<List<IotaConsentRecord>> findAllByRequestHash(
    String requestHash,
  ) async {
    return (await _readAllRecords())
        .where((record) => record.requestHash == requestHash)
        .toList();
  }

  @override
  Future<List<IotaConsentRecord>> listAll() => _readAllRecords();

  @override
  Future<bool> deleteByHash(String hash) async {
    final key = _key(hash);
    if (!await _secureStorage.containsKey(key: key)) return false;
    await _secureStorage.delete(key: key);
    return true;
  }

  @override
  Future<Map<String, dynamic>> export() async => {
    'version': _backupVersion,
    'records': [for (final record in await _readAllRecords()) record.toJson()],
  };

  @override
  Future<void> validateImport(Map<String, dynamic> data) async {
    _parseBackup(data);
  }

  @override
  Future<bool> isEmpty() async {
    final all = await _secureStorage.readAll();
    final prefix = '${_namespace}_';
    return all.keys.every((key) => !key.startsWith(prefix));
  }

  @override
  Future<void> import(Map<String, dynamic> data) async {
    final records = _parseBackup(data);
    if (!await isEmpty()) {
      throw VaultRestoreException.destinationNotEmpty('Consent history');
    }
    _importPendingRollback = true;
    for (final record in records) {
      await saveOrUpdate(record);
    }
  }

  @override
  Future<void> clearAllData() async {
    final all = await _secureStorage.readAll();
    final prefix = '${_namespace}_';
    for (final key in all.keys) {
      if (key.startsWith(prefix)) {
        await _secureStorage.delete(key: key);
      }
    }
    _importPendingRollback = false;
  }

  @override
  Future<void> rollbackImport() async {
    if (!_importPendingRollback) return;
    await clearAllData();
  }

  List<IotaConsentRecord> _parseBackup(Map<String, dynamic> data) {
    const allowedKeys = {'version', 'records'};
    final rawRecords = data['records'];
    if (data.keys.any((key) => !allowedKeys.contains(key)) ||
        data['version'] != _backupVersion ||
        rawRecords is! List) {
      throw VaultRestoreException.invalidBackupFormat('consent history');
    }

    final records = <IotaConsentRecord>[];
    try {
      for (final rawRecord in rawRecords) {
        if (rawRecord is! Map<String, dynamic>) {
          throw const FormatException('Consent record must be an object.');
        }
        records.add(IotaConsentRecord.fromJson(rawRecord));
      }
    } catch (error) {
      throw VaultRestoreException.invalidBackupFormat(
        'consent history',
        originalMessage: error.toString(),
      );
    }

    return records;
  }

  Future<List<IotaConsentRecord>> _readAllRecords() async {
    final all = await _secureStorage.readAll();
    final prefix = '${_namespace}_';
    final records = <IotaConsentRecord>[];
    for (final entry in all.entries) {
      if (!entry.key.startsWith(prefix)) continue;
      try {
        records.add(
          IotaConsentRecord.fromJson(
            jsonDecode(entry.value) as Map<String, dynamic>,
          ),
        );
      } catch (error) {
        throw ConsentStorageException.failedToReadRecord(
          key: entry.key,
          originalMessage: error.toString(),
        );
      }
    }
    return records;
  }
}
