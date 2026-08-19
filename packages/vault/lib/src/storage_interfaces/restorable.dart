/// Defines the contract for Vault components whose durable state can be
/// exported and restored.
abstract interface class Restorable {
  /// Serialises this component's current state.
  ///
  /// The returned map must be JSON-serialisable and contain only this
  /// component's payload.
  Future<Map<String, dynamic>> export();

  /// Replaces this component's durable state with a previously exported
  /// payload.
  ///
  /// [data] must be a map returned by this component's [export] method.
  Future<void> import(Map<String, dynamic> data);
}
