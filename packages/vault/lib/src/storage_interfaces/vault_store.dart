import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:affinidi_tdk_common/affinidi_tdk_common.dart';

import '../exceptions/tdk_exception_type.dart';
import 'restorable.dart';

/// Interface for storing vault data
abstract class VaultStore implements Restorable {
  static const _currentBackupVersion = '1.0.0';
  static const _versionKey = 'version';
  static const _seedKey = 'seed';
  static const _contentKeyKey = 'contentKey';
  static const _accountIndexKey = 'accountIndex';
  bool _importPendingRollback = false;

  /// Stores the account index to storage.
  ///
  /// [accountIndex] - The account index to store.
  Future<void> setAccountIndex(int accountIndex);

  /// Retrieves the account index from storage.
  ///
  /// Returns the stored account index.
  Future<int> getAccountIndex();

  /// Stores the seed value, overwriting any previous seed.
  Future<void> setSeed(Uint8List seed);

  /// Retrieves the stored seed value.
  ///
  /// Returns null if no seed has been stored.
  Future<Uint8List?> getSeed();

  /// Generates a new random seed of 32 bytes.
  ///
  /// Returns a new Uint8List containing the random seed.
  Uint8List getRandomSeed() {
    final length = 32;
    final random = Random.secure();
    final bytes = List<int>.generate(length, (_) => random.nextInt(256));
    return Uint8List.fromList(bytes);
  }

  /// Stores the key to decrypt content.
  ///
  /// [key] - The key to persist.
  Future<void> setContentKey(Uint8List key);

  /// Retrieves the key to decrypt content.
  ///
  /// Returns the key.
  Future<Uint8List?> getContentKey();

  /// Removes all stored data including account index and seed.
  Future<void> clear();

  @override
  Future<void> rollbackImport() async {
    if (!_importPendingRollback) return;
    await clear();
    _importPendingRollback = false;
  }

  @override
  Future<Map<String, dynamic>> export() async {
    final seed = await getSeed();
    if (seed == null) {
      throw TdkException(
        message: 'Cannot export VaultStore state without a seed.',
        code: TdkExceptionType.invalidBackupFormat.code,
      );
    }

    final contentKey = await getContentKey();
    return {
      _versionKey: _currentBackupVersion,
      _seedKey: base64Encode(seed),
      if (contentKey != null) _contentKeyKey: base64Encode(contentKey),
      _accountIndexKey: await getAccountIndex(),
    };
  }

  @override
  Future<void> validateImport(Map<String, dynamic> data) async {
    _parseImportData(data);
  }

  @override
  Future<bool> isEmpty() async =>
      await getSeed() == null &&
      await getContentKey() == null &&
      await getAccountIndex() == 0;

  @override
  Future<void> import(Map<String, dynamic> data) async {
    final parsed = _parseImportData(data);
    if (!await isEmpty()) {
      throw TdkException(
        message: 'VaultStore restore destination is not empty.',
        code: TdkExceptionType.restoreDestinationNotEmpty.code,
      );
    }
    _importPendingRollback = true;
    await setSeed(parsed.seed);
    if (parsed.contentKey != null) {
      await setContentKey(parsed.contentKey!);
    }
    await setAccountIndex(parsed.accountIndex);
  }

  ({Uint8List seed, Uint8List? contentKey, int accountIndex}) _parseImportData(
    Map<String, dynamic> data,
  ) {
    const allowedKeys = {
      _versionKey,
      _seedKey,
      _contentKeyKey,
      _accountIndexKey,
    };
    final version = data[_versionKey];
    final seedValue = data[_seedKey];
    final contentKeyValue = data[_contentKeyKey];
    final accountIndex = data[_accountIndexKey];

    if (data.keys.any((key) => !allowedKeys.contains(key)) ||
        version != _currentBackupVersion ||
        seedValue is! String ||
        (contentKeyValue != null && contentKeyValue is! String) ||
        accountIndex is! int ||
        accountIndex < 0) {
      throw TdkException(
        message: 'The VaultStore backup payload is malformed.',
        code: TdkExceptionType.invalidBackupFormat.code,
      );
    }

    final Uint8List seed;
    final Uint8List? contentKey;
    try {
      seed = base64Decode(seedValue);
      contentKey = contentKeyValue == null
          ? null
          : base64Decode(contentKeyValue as String);
    } on FormatException catch (error, stackTrace) {
      Error.throwWithStackTrace(
        TdkException(
          message: 'The VaultStore backup payload contains invalid data.',
          code: TdkExceptionType.invalidBackupFormat.code,
          originalMessage: error.toString(),
        ),
        stackTrace,
      );
    }

    return (seed: seed, contentKey: contentKey, accountIndex: accountIndex);
  }
}
