import 'dart:convert';

import 'package:affinidi_tdk_common/affinidi_tdk_common.dart';

import '../exceptions/tdk_exception_type.dart';
import '../profile.dart';
import '../storage_interfaces/file_storage.dart';
import '../storage_interfaces/item.dart';
import '../storage_interfaces/profile_repository.dart';
import '../storage_interfaces/restorable_profile_repository.dart';

/// A [Restorable] that backs up and restores the files and folders stored under
/// every profile of one or more [ProfileRepository] instances.
///
/// Items are grouped by the owning profile's `did` and stored as a flat list
/// with parent references. A root-level item stores a `null` parent so it can
/// be reattached to the restored profile's root regardless of the (unstable)
/// server-assigned folder identifiers. File content is captured inline as
/// base64. This source must be registered after the profiles source so the
/// target profiles already exist on import.
class VaultFilesBackupSource implements Restorable {
  /// Creates a [VaultFilesBackupSource].
  ///
  /// Parameters:
  /// * [profileRepositories] - The repositories whose profiles' files are
  ///   backed up and restored.
  /// * [pageSize] - Page size used when enumerating folder contents.
  /// * [logger] - Optional logger; defaults to [Logger.instance].
  VaultFilesBackupSource({
    required List<ProfileRepository> profileRepositories,
    int pageSize = 50,
    Logger? logger,
  }) : _profileRepositories = profileRepositories,
       _pageSize = pageSize,
       _logger = logger ?? Logger.instance;

  final List<ProfileRepository> _profileRepositories;
  final int _pageSize;
  final Logger _logger;

  static const String _sectionKey = 'files';
  static const String _idKey = 'id';
  static const String _nameKey = 'name';
  static const String _parentIdKey = 'parentId';
  static const String _typeKey = 'type';
  static const String _contentKey = 'content';
  static const String _folderType = 'folder';
  static const String _fileType = 'file';

  Future<List<Profile>> _allProfiles() async {
    final all = <Profile>[];
    for (final repository in _profileRepositories) {
      all.addAll(await repository.listProfiles());
    }
    return all;
  }

  @override
  Future<Map<String, dynamic>> export() async {
    final byDid = <String, List<dynamic>>{};
    for (final profile in await _allProfiles()) {
      final storage = profile.defaultFileStorage;
      if (storage == null) {
        continue;
      }
      byDid[profile.did] = await _exportItems(storage, rootId: profile.id);
    }
    return {_sectionKey: byDid};
  }

  Future<List<dynamic>> _exportItems(
    FileStorage storage, {
    required String rootId,
  }) async {
    final items = <dynamic>[];
    final pending = <String>[rootId];
    while (pending.isNotEmpty) {
      final folderId = pending.removeLast();
      String? cursor;
      do {
        final page = await storage.getFolder(
          folderId: folderId,
          limit: _pageSize,
          exclusiveStartItemId: cursor,
        );
        for (final item in page.items) {
          // Root-level items are stored with a null parent.
          final parentId = item.parentId == rootId ? null : item.parentId;
          if (item is Folder) {
            pending.add(item.id);
            items.add({
              _idKey: item.id,
              _nameKey: item.name,
              _parentIdKey: parentId,
              _typeKey: _folderType,
            });
          } else if (item is File) {
            final content = await storage.getFileContent(fileId: item.id);
            items.add({
              _idKey: item.id,
              _nameKey: item.name,
              _parentIdKey: parentId,
              _typeKey: _fileType,
              _contentKey: base64Encode(content),
            });
          }
        }
        cursor = page.lastEvaluatedItemId;
      } while (cursor != null);
    }
    return items;
  }

  @override
  Future<void> import(Map<String, dynamic> data) async {
    final section = data[_sectionKey];
    if (section is! Map<String, dynamic>) {
      _logger.warning('Backup is missing the "$_sectionKey" section.');
      throw TdkException(
        message: 'Backup is missing the "$_sectionKey" section.',
        code: TdkExceptionType.invalidBackupFormat.code,
      );
    }

    // Only local profiles are restored; cloud files return with the wallet
    // seed, so writing them again would duplicate the data.
    final profilesByDid = <String, Profile>{};
    for (final repository in _profileRepositories.where(
      (repository) => repository is RestorableProfileRepository,
    )) {
      for (final profile in await repository.listProfiles()) {
        profilesByDid[profile.did] = profile;
      }
    }

    for (final entry in section.entries) {
      final profile = profilesByDid[entry.key];
      final storage = profile?.defaultFileStorage;
      if (profile == null || storage == null) {
        _logger.warning('Skipping files for unknown or storage-less profile.');
        continue;
      }
      final items = entry.value;
      if (items is! List) {
        throw TdkException(
          message: 'The "$_sectionKey" backup section is malformed.',
          code: TdkExceptionType.invalidBackupFormat.code,
        );
      }
      await _importItems(storage, rootId: profile.id, items: items);
    }
  }

  Future<void> _importItems(
    FileStorage storage, {
    required String rootId,
    required List<dynamic> items,
  }) async {
    final typed = <Map<String, dynamic>>[];
    for (final item in items) {
      if (item is! Map<String, dynamic>) {
        throw TdkException(
          message: 'The "$_sectionKey" backup section is malformed.',
          code: TdkExceptionType.invalidBackupFormat.code,
        );
      }
      typed.add(item);
    }

    final folders = typed.where((i) => i[_typeKey] == _folderType).toList();
    final files = typed.where((i) => i[_typeKey] == _fileType).toList();

    // Recreate folders parent-before-child, remapping old ids to new ones.
    final oldToNewFolderId = <String, String>{};
    var remaining = List<Map<String, dynamic>>.of(folders);
    while (remaining.isNotEmpty) {
      final created = <Map<String, dynamic>>[];
      for (final folder in remaining) {
        final parentId = _resolveParent(
          folder[_parentIdKey],
          rootId,
          oldToNewFolderId,
        );
        if (parentId == null) {
          continue;
        }
        final name = folder[_nameKey];
        final oldId = folder[_idKey];
        if (name is! String || oldId is! String) {
          throw TdkException(
            message: 'The "$_sectionKey" backup section is malformed.',
            code: TdkExceptionType.invalidBackupFormat.code,
          );
        }
        final newFolder = await storage.createFolder(
          folderName: name,
          parentFolderId: parentId,
        );
        oldToNewFolderId[oldId] = newFolder.id;
        created.add(folder);
      }
      if (created.isEmpty) {
        _logger.warning('Skipping folders with unresolved parents.');
        break;
      }
      remaining.removeWhere(created.contains);
    }

    for (final file in files) {
      final parentId = _resolveParent(
        file[_parentIdKey],
        rootId,
        oldToNewFolderId,
      );
      if (parentId == null) {
        _logger.warning('Skipping file with an unresolved parent folder.');
        continue;
      }
      final name = file[_nameKey];
      final content = file[_contentKey];
      if (name is! String || content is! String) {
        throw TdkException(
          message: 'The "$_sectionKey" backup section is malformed.',
          code: TdkExceptionType.invalidBackupFormat.code,
        );
      }
      await storage.createFile(
        fileName: name,
        data: base64Decode(content),
        parentFolderId: parentId,
      );
    }
  }

  String? _resolveParent(
    Object? oldParentId,
    String rootId,
    Map<String, String> oldToNewFolderId,
  ) {
    if (oldParentId == null) {
      return rootId;
    }
    return oldToNewFolderId[oldParentId];
  }
}
