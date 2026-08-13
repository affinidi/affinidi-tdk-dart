/// Defines the contract for components that can be serialised for backup and
/// restored from a previously exported snapshot.
abstract interface class Restorable {
  /// Serialises the component's current state for backup.
  ///
  /// Returns a [Future] containing a [Map] whose entries represent the
  /// component's state. The map must be JSON-serialisable.
  Future<Map<String, dynamic>> export();

  /// Restores the component's state from a previously exported snapshot.
  ///
  /// Parameters:
  /// * [data] - the map returned by a prior [export] call.
  Future<void> import(Map<String, dynamic> data);
}
