import 'storage_interfaces/profile_repository.dart';
import 'storage_interfaces/restorable.dart';

/// Executes an ordered Vault backup import with compensating rollback.
class BackupRestorePlan {
  BackupRestorePlan._();

  /// Creates a plan for the repository and named-restorable backup sections.
  factory BackupRestorePlan.fromBackupData({
    required Map<String, dynamic> repositoryData,
    required Map<String, dynamic> namedData,
    required Map<String, ProfileRepository> profileRepositories,
    required Map<String, Restorable> namedRestorables,
  }) {
    final importPlan = BackupRestorePlan._();

    final repositoryIds = repositoryData.keys.toList()..sort();
    for (final id in repositoryIds) {
      importPlan._add(
        'repository:$id',
        profileRepositories[id]! as Restorable,
        repositoryData[id] as Map<String, dynamic>,
      );
    }

    final namedIds = namedData.keys.toList()..sort();
    for (final id in namedIds) {
      importPlan._add(
        'named:$id',
        namedRestorables[id]!,
        namedData[id] as Map<String, dynamic>,
      );
    }

    return importPlan;
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
  Future<BackupRestoreFailure?> execute() async {
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
typedef BackupRestoreFailure = ({
  Object error,
  StackTrace stackTrace,
  List<String> rollbackErrors,
});
