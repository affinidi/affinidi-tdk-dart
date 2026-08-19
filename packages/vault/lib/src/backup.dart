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

  /// The backup format versions this package is able to restore.
  static const supportedVersions = {currentVersion};

  /// Creates a [Backup].
  ///
  /// Parameters:
  /// * [data] - The merged sections contributed by each `Restorable` component,
  ///   keyed by each component's namespace.
  /// * [version] - The backup format version. Defaults to [currentVersion].
  Backup({required Map<String, dynamic> data, this.version = currentVersion})
    : data = Map.unmodifiable(data);

  /// Creates a validated repository-scoped Vault backup.
  ///
  /// [repositoryManifest] records every configured repository. Restorable
  /// repositories must have one matching payload in [repositoryData], while
  /// non-restorable repositories must not have a payload.
  factory Backup.vault({
    required Map<String, dynamic> vaultStore,
    required List<Map<String, dynamic>> repositoryManifest,
    required Map<String, dynamic> repositoryData,
    Map<String, dynamic> namedComponents = const {},
  }) {
    final data = <String, dynamic>{
      'vaultStore': vaultStore,
      'repositories': {'manifest': repositoryManifest, 'data': repositoryData},
      'namedComponents': namedComponents,
    };
    _validateVaultData(data);
    return Backup(data: _sortMap(data));
  }

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
    if (!supportedVersions.contains(version)) {
      throw TdkException(
        message: 'Unsupported backup version: $version.',
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

  static void _validateVaultData(Map<String, dynamic> data) {
    const topLevelKeys = {'vaultStore', 'repositories', 'namedComponents'};
    if (data.length != topLevelKeys.length ||
        !data.keys.toSet().containsAll(topLevelKeys)) {
      throw _invalidFormat();
    }

    _validateComponentPayload(data['vaultStore']);

    final repositories = data['repositories'];
    if (repositories is! Map<String, dynamic> ||
        repositories.length != 2 ||
        !repositories.containsKey('manifest') ||
        !repositories.containsKey('data')) {
      throw _invalidFormat();
    }
    final manifest = repositories['manifest'];
    final repositoryData = repositories['data'];
    if (manifest is! List || repositoryData is! Map<String, dynamic>) {
      throw _invalidFormat();
    }

    final repositoryIds = <String>{};
    final restorableIds = <String>{};
    for (final rawEntry in manifest) {
      if (rawEntry is! Map<String, dynamic> ||
          rawEntry.length != 2 ||
          !rawEntry.containsKey('id') ||
          !rawEntry.containsKey('restorable')) {
        throw _invalidFormat();
      }
      final id = rawEntry['id'];
      final restorable = rawEntry['restorable'];
      if (id is! String ||
          id.isEmpty ||
          !repositoryIds.add(id) ||
          restorable is! bool) {
        throw _invalidFormat();
      }
      if (restorable) {
        restorableIds.add(id);
      }
    }
    if (repositoryData.keys.toSet().difference(restorableIds).isNotEmpty ||
        restorableIds.difference(repositoryData.keys.toSet()).isNotEmpty) {
      throw _invalidFormat();
    }
    for (final payload in repositoryData.values) {
      _validateComponentPayload(payload);
    }

    final namedComponents = data['namedComponents'];
    if (namedComponents is! Map<String, dynamic> ||
        namedComponents.keys.any((id) => id.isEmpty)) {
      throw _invalidFormat();
    }
    for (final payload in namedComponents.values) {
      _validateComponentPayload(payload);
    }
  }

  static void _validateComponentPayload(Object? payload) {
    if (payload is! Map<String, dynamic> || payload['version'] is! String) {
      throw _invalidFormat();
    }
  }

  static Map<String, dynamic> _sortMap(Map<String, dynamic> source) {
    final result = <String, dynamic>{};
    final keys = source.keys.toList()..sort();
    for (final key in keys) {
      final value = source[key];
      result[key] = switch (value) {
        Map<String, dynamic>() => _sortMap(value),
        List() =>
          value
              .map((item) {
                return item is Map<String, dynamic> ? _sortMap(item) : item;
              })
              .toList(growable: false),
        _ => value,
      };
    }
    return Map.unmodifiable(result);
  }

  static TdkException _invalidFormat() => TdkException(
    message: 'The Vault backup data is malformed.',
    code: TdkExceptionType.invalidBackupFormat.code,
  );
}
