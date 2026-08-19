import 'dart:convert';
import 'dart:typed_data';

import 'package:affinidi_tdk_common/affinidi_tdk_common.dart';

import '../exceptions/tdk_exception_type.dart';
import '../storage_interfaces/restorable.dart';
import '../storage_interfaces/vault_store.dart';

/// A [Restorable] that backs up and restores the wallet keys held by a
/// [VaultStore].
///
/// The exported section contains the raw `seed`, the root `accountIndex`, and
/// the content encryption `contentKey` when one exists. The content key is
/// created lazily by the vault, so a freshly created vault may not have one
/// yet; in that case it is simply omitted from the backup. The raw seed is
/// protected by the outer encrypted backup envelope produced by the backup
/// service, so it is never exposed in plaintext outside that envelope.
class VaultStoreBackupSource implements Restorable {
  /// Creates a [VaultStoreBackupSource].
  ///
  /// Parameters:
  /// * [vaultStore] - The store whose wallet keys are backed up and restored.
  /// * [logger] - Optional logger; defaults to [Logger.instance].
  VaultStoreBackupSource({required VaultStore vaultStore, Logger? logger})
    : _vaultStore = vaultStore,
      _logger = logger ?? Logger.instance;

  final VaultStore _vaultStore;
  final Logger _logger;

  static const String _sectionKey = 'wallet';
  static const String _seedKey = 'seed';
  static const String _contentKeyKey = 'contentKey';
  static const String _accountIndexKey = 'accountIndex';

  /// Serialises the wallet keys for backup.
  ///
  /// Returns a [Future] containing a [Map] with a single `wallet` section
  /// holding the base64-encoded seed, the integer account index, and the
  /// base64-encoded content key when the vault has one.
  /// Throws [TdkException] with code `invalid_backup_format` if the seed is not
  /// set.
  @override
  Future<Map<String, dynamic>> export() async {
    final seed = await _vaultStore.getSeed();
    if (seed == null) {
      _logger.warning('Cannot export wallet backup: seed is missing.');
      throw TdkException(
        message: 'Cannot export wallet backup: the vault seed must be set.',
        code: TdkExceptionType.invalidBackupFormat.code,
      );
    }

    final contentKey = await _vaultStore.getContentKey();
    final accountIndex = await _vaultStore.getAccountIndex();

    return {
      _sectionKey: {
        _seedKey: base64Encode(seed),
        // Content key is created lazily; omit it when the vault has none yet.
        if (contentKey != null) _contentKeyKey: base64Encode(contentKey),
        _accountIndexKey: accountIndex,
      },
    };
  }

  /// Restores the wallet keys from a previously exported snapshot.
  ///
  /// Parameters:
  /// * [data] - The merged backup envelope containing the `wallet` section.
  ///
  /// Throws [TdkException] with code `invalid_backup_format` if the `wallet`
  /// section is missing, malformed, or contains invalid base64 data.
  @override
  Future<void> import(Map<String, dynamic> data) async {
    final section = data[_sectionKey];
    if (section is! Map<String, dynamic>) {
      _logger.warning('Backup is missing the "$_sectionKey" section.');
      throw TdkException(
        message: 'Backup is missing the "$_sectionKey" section.',
        code: TdkExceptionType.invalidBackupFormat.code,
      );
    }

    final seedB64 = section[_seedKey];
    final contentKeyB64 = section[_contentKeyKey];
    final accountIndex = section[_accountIndexKey];

    if (seedB64 is! String ||
        accountIndex is! int ||
        (contentKeyB64 != null && contentKeyB64 is! String)) {
      _logger.warning('The "$_sectionKey" backup section is malformed.');
      throw TdkException(
        message: 'The "$_sectionKey" backup section is malformed.',
        code: TdkExceptionType.invalidBackupFormat.code,
      );
    }

    final Uint8List seed;
    Uint8List? contentKey;
    try {
      seed = base64Decode(seedB64);
      if (contentKeyB64 is String) {
        contentKey = base64Decode(contentKeyB64);
      }
    } on FormatException catch (error, stackTrace) {
      _logger.warning('Failed to decode wallet backup section: $error');
      Error.throwWithStackTrace(
        TdkException(
          message: 'The "$_sectionKey" backup section contains invalid data.',
          code: TdkExceptionType.invalidBackupFormat.code,
        ),
        stackTrace,
      );
    }

    await _vaultStore.setSeed(seed);
    if (contentKey != null) {
      await _vaultStore.setContentKey(contentKey);
    }
    await _vaultStore.setAccountIndex(accountIndex);
  }
}
