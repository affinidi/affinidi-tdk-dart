import 'package:affinidi_tdk_common/affinidi_tdk_common.dart';

import 'exceptions/vault_backup_exception.dart';
import 'exceptions/vault_restore_exception.dart';
import 'storage_interfaces/profile_repository.dart';
import 'storage_interfaces/restorable.dart';
import 'storage_interfaces/vault_store.dart';

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
    required String defaultRepositoryId,
    Map<String, dynamic> namedComponents = const {},
  }) {
    final data = <String, dynamic>{
      'vaultStore': vaultStore,
      'repositories': {
        'defaultId': defaultRepositoryId,
        'manifest': repositoryManifest,
        'data': repositoryData,
      },
      'namedComponents': namedComponents,
    };
    _validateVaultData(data);
    return Backup(data: _sortMap(data));
  }

  /// Exports registered Vault storage into a validated backup envelope.
  static Future<Backup> fromRestorables({
    required VaultStore vaultStore,
    required Map<String, ProfileRepository> profileRepositories,
    required Map<String, Restorable> restorableRepositories,
    required Map<String, Restorable> namedRestorables,
    required String defaultRepositoryId,
  }) async {
    final repositoryIds = profileRepositories.keys.toList()..sort();
    for (final id in repositoryIds) {
      final repositoryId = profileRepositories[id]!.id;
      if (repositoryId != id) {
        throw VaultBackupException.repositoryIdMismatch(
          registrationId: id,
          repositoryId: repositoryId,
        );
      }
    }

    final manifest = <Map<String, dynamic>>[];
    final repositoryData = <String, dynamic>{};
    for (final id in repositoryIds) {
      final restorable = restorableRepositories[id];
      manifest.add({'id': id, 'restorable': restorable != null});
      if (restorable != null) {
        repositoryData[id] = await restorable.export();
      }
    }

    final namedData = <String, dynamic>{};
    final namedIds = namedRestorables.keys.toList()..sort();
    for (final id in namedIds) {
      namedData[id] = await namedRestorables[id]!.export();
    }

    return Backup.vault(
      vaultStore: await vaultStore.export(),
      repositoryManifest: manifest,
      repositoryData: repositoryData,
      defaultRepositoryId: defaultRepositoryId,
      namedComponents: namedData,
    );
  }

  /// Parses and validates repository-scoped Vault backup data.
  factory Backup.fromVaultData(Map<String, dynamic> data) {
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
      throw VaultRestoreException.invalidVersion();
    }
    if (!supportedVersions.contains(version)) {
      throw VaultRestoreException.unsupportedVersion(version);
    }
    final data = json['data'];
    if (data is! Map<String, dynamic>) {
      throw VaultRestoreException.invalidData();
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
      throw VaultRestoreException.malformedBackupData();
    }

    _validateComponentPayload(data['vaultStore']);

    final repositories = data['repositories'];
    if (repositories is! Map<String, dynamic> ||
        repositories.length != 3 ||
        !repositories.containsKey('defaultId') ||
        !repositories.containsKey('manifest') ||
        !repositories.containsKey('data')) {
      throw VaultRestoreException.malformedBackupData();
    }
    final manifest = repositories['manifest'];
    final repositoryData = repositories['data'];
    final defaultRepositoryId = repositories['defaultId'];
    if (manifest is! List || repositoryData is! Map<String, dynamic>) {
      throw VaultRestoreException.malformedBackupData();
    }

    final repositoryIds = <String>{};
    final restorableIds = <String>{};
    for (final rawEntry in manifest) {
      if (rawEntry is! Map<String, dynamic> ||
          rawEntry.length != 2 ||
          !rawEntry.containsKey('id') ||
          !rawEntry.containsKey('restorable')) {
        throw VaultRestoreException.malformedBackupData();
      }
      final id = rawEntry['id'];
      final restorable = rawEntry['restorable'];
      if (id is! String ||
          id.isEmpty ||
          !repositoryIds.add(id) ||
          restorable is! bool) {
        throw VaultRestoreException.malformedBackupData();
      }
      if (restorable) {
        restorableIds.add(id);
      }
    }
    if (defaultRepositoryId is! String ||
        !repositoryIds.contains(defaultRepositoryId)) {
      throw VaultRestoreException.malformedBackupData();
    }
    if (repositoryData.keys.toSet().difference(restorableIds).isNotEmpty ||
        restorableIds.difference(repositoryData.keys.toSet()).isNotEmpty) {
      throw VaultRestoreException.malformedBackupData();
    }
    for (final payload in repositoryData.values) {
      _validateComponentPayload(payload);
    }

    final namedComponents = data['namedComponents'];
    if (namedComponents is! Map<String, dynamic> ||
        namedComponents.keys.any((id) => id.isEmpty)) {
      throw VaultRestoreException.malformedBackupData();
    }
    for (final payload in namedComponents.values) {
      _validateComponentPayload(payload);
    }
  }

  static void _validateComponentPayload(Object? payload) {
    if (payload is! Map<String, dynamic> ||
        payload['schemaVersion'] is! String) {
      throw VaultRestoreException.malformedBackupData();
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
}
