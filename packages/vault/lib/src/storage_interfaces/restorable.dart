/// Defines the contract for Vault components whose durable state can be
/// exported and restored.
abstract interface class Restorable {
  /// Serialises this component's current state.
  ///
  /// The returned map must be JSON-serialisable and contain only this
  /// component's payload.
  Future<Map<String, dynamic>> export();

  /// Validates a previously exported payload without mutating durable state.
  ///
  /// Implementations must perform every deterministic format and compatibility
  /// check needed by [import].
  Future<void> validateImport(Map<String, dynamic> data);

  /// Returns whether this component's restoration destination has no existing
  /// durable state.
  Future<bool> isEmpty();

  /// Restores a previously exported payload into an empty destination.
  ///
  /// [data] must have passed [validateImport]. Implementations should also call
  /// [validateImport] defensively and reject non-empty destinations when invoked
  /// directly.
  Future<void> import(Map<String, dynamic> data);

  /// Rolls back durable state written by [import].
  ///
  /// This is required so multi-component restore flows can compensate for
  /// partial progress after a late import failure. It must be a no-op when
  /// this instance has not started an import, and must be idempotent.
  Future<void> rollbackImport();
}
