import 'package:affinidi_tdk_common/affinidi_tdk_common.dart' show Restorable;

import 'vault_backup_service_interface.dart';

/// Orchestrates backup and restore by delegating to injected [Restorable]
/// components.
///
/// Each component's [Restorable.export] output is merged into a single flat map
/// by [createBackup]; the same map is passed to every component's
/// [Restorable.import] during [restoreFromBackup].
class VaultBackupService implements VaultBackupServiceInterface {
  final List<Restorable> _restorables;

  /// Creates a [VaultBackupService].
  ///
  /// Parameters:
  /// * [restorables] - the list of components to include in every backup and
  ///   restore cycle.
  VaultBackupService({required List<Restorable> restorables})
      : _restorables = List.unmodifiable(restorables);

  /// Exports the state of all [Restorable] components into a single merged map.
  ///
  /// Returns a [Future] containing the merged backup map. Entries from later
  /// components overwrite entries from earlier components on key collision.
  @override
  Future<Map<String, dynamic>> createBackup() async {
    final backup = <String, dynamic>{};
    for (final restorable in _restorables) {
      backup.addAll(await restorable.export());
    }
    return backup;
  }

  /// Passes [data] to every registered [Restorable] component for restoration.
  ///
  /// Parameters:
  /// * [data] - the map returned by a prior [createBackup] call.
  @override
  Future<void> restoreFromBackup(Map<String, dynamic> data) async {
    final snapshot = Map<String, dynamic>.unmodifiable(data);
    for (final restorable in _restorables) {
      await restorable.import(snapshot);
    }
  }
}
