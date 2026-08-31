/// Converts a backup payload from one schema version to its next version.
typedef BackupSchemaMigration =
    Map<String, dynamic> Function(Map<String, dynamic> data);

/// Returns [data] at [currentSchemaVersion], applying migrations in order.
///
/// Each migration must return a new payload whose `schemaVersion` identifies
/// the next migration or [currentSchemaVersion]. Returns `null` when the
/// payload schema version is invalid, unsupported, or part of a migration
/// cycle.
Map<String, dynamic>? migrateBackupSchemaData({
  required Map<String, dynamic> data,
  required String currentSchemaVersion,
  required Map<String, BackupSchemaMigration> schemaMigrations,
}) {
  var migratedData = Map<String, dynamic>.of(data);
  final migratedSchemaVersions = <String>{};

  while (migratedData['schemaVersion'] != currentSchemaVersion) {
    final schemaVersion = migratedData['schemaVersion'];
    if (schemaVersion is! String ||
        !migratedSchemaVersions.add(schemaVersion)) {
      return null;
    }

    final migration = schemaMigrations[schemaVersion];
    if (migration == null) return null;
    migratedData = Map<String, dynamic>.of(
      migration(Map<String, dynamic>.unmodifiable(migratedData)),
    );
  }

  return migratedData;
}

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

  /// Deletes all durable state owned by this restore target.
  ///
  /// This operation must be idempotent. Applications should invoke it only
  /// after explicitly confirming that an interrupted restore may be discarded.
  Future<void> clearAllData();

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
