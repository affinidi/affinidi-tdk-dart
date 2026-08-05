import 'package:affinidi_tdk_common/affinidi_tdk_common.dart';

import 'exceptions/tdk_exception_type.dart';

/// Represents the decrypted contents of a vault backup.
///
/// A backup is an envelope rather than a fixed schema: [version] identifies the
/// format, and [data] holds the sections contributed by each `Restorable`
/// component. Every component owns its own top-level keys within [data], so a
/// package contributing to (or restoring from) a backup never needs to know
/// about another package's backup contents.
class Backup {
  /// The current backup format version produced by this package.
  static const currentVersion = '1.0.0';

  /// Creates a [Backup].
  ///
  /// Parameters:
  /// * [data] - The merged sections contributed by each `Restorable` component,
  ///   keyed by each component's namespace.
  /// * [version] - The backup format version. Defaults to [currentVersion].
  Backup({required Map<String, dynamic> data, this.version = currentVersion})
    : data = Map.unmodifiable(data);

  /// The backup format version.
  final String version;

  /// The merged sections contributed by each `Restorable` component.
  final Map<String, dynamic> data;

  /// Creates a [Backup] from its JSON representation.
  ///
  /// Parameters:
  /// * [json] - The decoded backup envelope.
  ///
  /// Returns a [Backup] containing the parsed [version] and [data].
  /// Throws a [TdkException] if [json] is missing required fields or has
  /// fields of the wrong type.
  factory Backup.fromJson(Map<String, dynamic> json) {
    final version = json['version'];
    if (version is! String) {
      throw TdkException(
        message: 'Backup is missing a valid "version" field.',
        code: TdkExceptionType.invalidBackupFormat.code,
      );
    }
    final data = json['data'];
    if (data is! Map<String, dynamic>) {
      throw TdkException(
        message: 'Backup is missing a valid "data" field.',
        code: TdkExceptionType.invalidBackupFormat.code,
      );
    }
    return Backup(version: version, data: data);
  }

  /// Serialises this backup to its JSON representation.
  ///
  /// Returns a JSON-serialisable [Map] containing [version] and [data].
  Map<String, dynamic> toJson() => {'version': version, 'data': data};
}
