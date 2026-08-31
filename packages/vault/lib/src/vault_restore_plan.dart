import 'dart:convert';
import 'dart:typed_data';

import 'backup.dart';
import 'exceptions/vault_restore_exception.dart';
import 'extensions/set_extensions.dart';
import 'storage_interfaces/profile_repository.dart';
import 'storage_interfaces/restorable.dart';
import 'storage_interfaces/vault_store.dart';

/// Executes an ordered Vault backup import with compensating rollback.
class VaultRestorePlan {
  VaultRestorePlan._();

  /// Returns whether all registered local restore destinations are empty.
  ///
  /// The already-open [VaultStore] is intentionally excluded.
  static Future<bool> isDestinationEmpty({
    required Map<String, Restorable> restorableRepositories,
    required Map<String, Restorable> namedRestorables,
  }) async {
    final repositoryIds = restorableRepositories.keys.toList()..sort();
    for (final id in repositoryIds) {
      if (!await restorableRepositories[id]!.isEmpty()) {
        return false;
      }
    }

    final namedIds = namedRestorables.keys.toList()..sort();
    for (final id in namedIds) {
      if (!await namedRestorables[id]!.isEmpty()) {
        return false;
      }
    }
    return true;
  }

  /// Validates backup data and creates its ordered import plan.
  static Future<VaultRestorePlan> prepare({
    required Map<String, dynamic> data,
    required VaultStore vaultStore,
    required Map<String, ProfileRepository> profileRepositories,
    required Map<String, Restorable> restorableRepositories,
    required Map<String, Restorable> namedRestorables,
  }) async {
    final backup = Backup.fromVaultData(data);
    final repositorySection =
        backup.data['repositories'] as Map<String, dynamic>;
    final manifest = repositorySection['manifest'] as List;
    final repositoryData = repositorySection['data'] as Map<String, dynamic>;
    final namedData = backup.data['namedComponents'] as Map<String, dynamic>;

    final expectedRepositoryIds = profileRepositories.keys.toSet();
    final backupRepositoryIds = <String>{};
    for (final rawEntry in manifest) {
      final entry = rawEntry as Map<String, dynamic>;
      final id = entry['id'] as String;
      backupRepositoryIds.add(id);
      if (restorableRepositories.containsKey(id) !=
          (entry['restorable'] as bool)) {
        throw VaultRestoreException.invalidBackupFormat();
      }
    }
    if (!expectedRepositoryIds.hasSameElementsAs(backupRepositoryIds) ||
        !namedRestorables.keys.toSet().hasSameElementsAs(
          namedData.keys.toSet(),
        )) {
      throw VaultRestoreException.invalidBackupFormat();
    }

    final vaultStoreData = backup.data['vaultStore'] as Map<String, dynamic>;
    final encodedSeed = vaultStoreData['seed'];
    final currentSeed = await vaultStore.getSeed();
    if (encodedSeed is! String || currentSeed == null) {
      throw VaultRestoreException.invalidBackupFormat();
    }
    final Uint8List backupSeed;
    try {
      backupSeed = base64Decode(encodedSeed);
    } on FormatException {
      throw VaultRestoreException.invalidBackupFormat();
    }
    if (!_sameBytes(currentSeed, backupSeed)) {
      throw VaultRestoreException.invalidBackupFormat();
    }

    await vaultStore.validateImport(vaultStoreData);
    final importPlan = VaultRestorePlan._();

    final repositoryIds = repositoryData.keys.toList()..sort();
    for (final id in repositoryIds) {
      final restorable = restorableRepositories[id]!;
      final payload = repositoryData[id] as Map<String, dynamic>;
      await restorable.validateImport(payload);
      importPlan._add('repository:$id', restorable, payload);
    }

    final namedIds = namedData.keys.toList()..sort();
    for (final id in namedIds) {
      final restorable = namedRestorables[id]!;
      final payload = namedData[id] as Map<String, dynamic>;
      await restorable.validateImport(payload);
      importPlan._add('named:$id', restorable, payload);
    }

    return importPlan;
  }

  static bool _sameBytes(Uint8List left, Uint8List right) {
    if (left.length != right.length) return false;
    var diff = 0;
    for (var index = 0; index < left.length; index++) {
      diff |= left[index] ^ right[index];
    }
    return diff == 0;
  }

  final Map<String, ({Restorable restorable, Map<String, dynamic> payload})>
  _operations = {};
  final Map<String, Restorable> _attemptedImports = {};

  void _add(
    String target,
    Restorable restorable,
    Map<String, dynamic> payload,
  ) {
    _operations[target] = (restorable: restorable, payload: payload);
  }

  /// Executes the plan and returns failure details after attempting rollback.
  Future<VaultRestoreFailure?> execute() async {
    try {
      for (final entry in _operations.entries) {
        _attemptedImports[entry.key] = entry.value.restorable;
        await entry.value.restorable.import(entry.value.payload);
      }
      return null;
    } catch (error, stackTrace) {
      final rollbackErrors = await rollback();
      return (
        error: error,
        stackTrace: stackTrace,
        rollbackErrors: rollbackErrors,
      );
    }
  }

  /// Rolls back attempted imports in reverse order.
  Future<List<String>> rollback() async {
    final rollbackErrors = <String>[];
    for (final entry in _attemptedImports.entries.toList().reversed) {
      try {
        await entry.value.rollbackImport();
      } catch (_) {
        rollbackErrors.add(entry.key);
      }
    }
    return rollbackErrors;
  }
}

/// Details of an import failure and any targets that could not be rolled back.
typedef VaultRestoreFailure = ({
  Object error,
  StackTrace stackTrace,
  List<String> rollbackErrors,
});
