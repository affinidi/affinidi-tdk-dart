import 'dart:convert';
import 'dart:typed_data';

import 'package:affinidi_tdk_vault/affinidi_tdk_vault.dart';
import 'package:dio/dio.dart';
import 'package:synchronized/synchronized.dart';

import '../exceptions/edge_restore_exception.dart';
import '../exceptions/tdk_exception_type.dart';
import '../interfaces/edge_file_repository_interface.dart';
import '../services/edge_encryption_service_interface.dart';

/// An Edge based implementation of [FileStorage] for storing and managing
/// files and folders.
class EdgeFileStorage implements FileStorage, Restorable {
  /// Creates a new instance of [EdgeFileStorage].
  ///
  /// [lock] allows an owning edge profile repository to serialize this
  /// storage with profile and credential operations.
  EdgeFileStorage({
    required EdgeFileRepositoryInterface repository,
    required String id,
    required String profileId,
    required EdgeEncryptionServiceInterface encryptionService,
    FileProviderConfiguration? configuration,
    Lock? lock,
  }) : _repository = repository,
       _id = id,
       _profileId = profileId,
       _encryptionService = encryptionService,
       _lock = lock ?? Lock(reentrant: true),
       _maxFileSize =
           configuration?.maxFileSize ?? FileUtils.defaultMaxFileSize,
       _allowedExtensions =
           configuration?.allowedExtensions ??
           FileUtils.defaultAllowedExtensions;

  final EdgeFileRepositoryInterface _repository;
  final String _id;
  final String _profileId;
  final EdgeEncryptionServiceInterface _encryptionService;
  final Lock _lock;
  final int _maxFileSize;
  final List<String> _allowedExtensions;
  bool _importPendingRollback = false;

  static const _backupVersion = '1.0.0';
  static const _pageSize = 50;

  @override
  String get id => _id;

  // A folderId matching the _profileId should be considered null as it identifies the root folder.
  String? _convertToRootFolderIfNeeded(String? folderId) {
    if (folderId == _profileId || folderId == '') {
      return null;
    }
    return folderId;
  }

  @override
  Future<void> createFile({
    required String fileName,
    required Uint8List data,
    String? parentFolderId,
    VaultCancelToken? cancelToken,
    void Function(int, int)? onSendProgress,
  }) => _lock.synchronized(() async {
    // Validate file size
    if (!FileUtils.isFileSizeValid(data.length, _maxFileSize)) {
      Error.throwWithStackTrace(
        TdkException(
          message: FileUtils.createFileSizeErrorMessage(
            data.length,
            _maxFileSize,
          ),
          code: TdkExceptionType.invalidFileSize.code,
        ),
        StackTrace.current,
      );
    }

    // Validate file type
    if (!FileUtils.isFileExtensionAllowed(fileName, _allowedExtensions)) {
      Error.throwWithStackTrace(
        TdkException(
          message: FileUtils.createFileExtensionErrorMessage(
            fileName,
            _allowedExtensions,
          ),
          code: TdkExceptionType.invalidFileType.code,
        ),
        StackTrace.current,
      );
    }

    final sanitizedParentFolderId = _convertToRootFolderIfNeeded(
      parentFolderId,
    );

    final encryptedContent = await _encryptionService.encryptData(data);
    final encryptedFileName = await _encryptionService.encryptString(fileName);

    // Create the file
    await _repository.createFile(
      profileId: _profileId,
      fileName: encryptedFileName,
      data: encryptedContent,
      parentFolderId: sanitizedParentFolderId,
    );
  });

  @override
  Future<Folder> createFolder({
    required String folderName,
    required String parentFolderId,
    VaultCancelToken? cancelToken,
  }) => _lock.synchronized(() async {
    final sanitizedParentFolderId = _convertToRootFolderIfNeeded(
      parentFolderId,
    );

    final encryptedFolderName = await _encryptionService.encryptString(
      folderName,
    );

    final folderData = await _repository.createFolder(
      profileId: _profileId,
      folderName: encryptedFolderName,
      parentFolderId: sanitizedParentFolderId,
    );

    return Folder(
      id: folderData.id,
      name: await _encryptionService.decryptString(folderData.name),
      createdAt: folderData.createdAt,
      modifiedAt: folderData.modifiedAt,
      parentId: folderData.parentId,
    );
  });

  @override
  Future<void> deleteFile({
    required String fileId,
    VaultCancelToken? cancelToken,
  }) => _lock.synchronized(() async {
    // Check if file exists
    await _repository.getFile(fileId: fileId);
    await _repository.deleteFile(fileId: fileId);
  });

  @override
  Future<void> deleteFolder({
    required String folderId,
    VaultCancelToken? cancelToken,
  }) => _lock.synchronized(() async {
    final success = await _repository.deleteFolder(folderId: folderId);
    if (!success) {
      Error.throwWithStackTrace(
        TdkException(
          message: 'Failed to delete folder',
          code: TdkExceptionType.invalidFolderId.code,
        ),
        StackTrace.current,
      );
    }
  });

  @override
  Future<File> getFile({
    required String fileId,
    VaultCancelToken? cancelToken,
  }) => _lock.synchronized(() async {
    final fileData = await _repository.getFile(fileId: fileId);

    return File(
      id: fileData.id,
      name: await _encryptionService.decryptString(fileData.name),
      createdAt: fileData.createdAt,
      modifiedAt: fileData.modifiedAt,
      parentId: fileData.parentId,
    );
  });

  @override
  Future<Uint8List> getFileContent({
    required String fileId,
    VaultCancelToken? cancelToken,
    ProgressCallback? onReceiveProgress,
  }) => _lock.synchronized(() async {
    final encryptedContent = await _repository.getFileContent(fileId: fileId);

    final decryptedContent = await _encryptionService.decryptData(
      encryptedContent,
    );

    return decryptedContent;
  });

  @override
  Future<PaginatedList<Item>> getFolder({
    String? folderId,
    int? limit,
    String? exclusiveStartItemId,
    VaultCancelToken? cancelToken,
  }) => _lock.synchronized(() async {
    final sanitizedFolderId = _convertToRootFolderIfNeeded(folderId);

    // Get the raw folder data from repository
    final rawFolderData = await _repository.getFolder(
      folderId: sanitizedFolderId,
      limit: limit,
      exclusiveStartItemId: exclusiveStartItemId,
    );

    final decryptedItems = await Future.wait(
      rawFolderData.items.map((item) async {
        final decryptedName = await _encryptionService.decryptString(item.name);

        if (item is Folder) {
          return Folder(
            id: item.id,
            name: decryptedName,
            createdAt: item.createdAt,
            modifiedAt: item.modifiedAt,
            parentId: item.parentId,
          );
        } else {
          return File(
            id: item.id,
            name: decryptedName,
            createdAt: item.createdAt,
            modifiedAt: item.modifiedAt,
            parentId: item.parentId,
          );
        }
      }),
    );

    return PaginatedList(
      items: decryptedItems,
      lastEvaluatedItemId: rawFolderData.lastEvaluatedItemId,
    );
  });

  @override
  Future<void> renameFile({
    required String fileId,
    required String newName,
    VaultCancelToken? cancelToken,
  }) => _lock.synchronized(() async {
    // Check if new name has valid extension
    if (!FileUtils.isFileExtensionAllowed(newName, _allowedExtensions)) {
      Error.throwWithStackTrace(
        TdkException(
          message: FileUtils.createFileExtensionErrorMessage(
            newName,
            _allowedExtensions,
          ),
          code: TdkExceptionType.invalidFileType.code,
        ),
        StackTrace.current,
      );
    }

    final encryptedNewName = await _encryptionService.encryptString(newName);
    await _repository.renameFile(fileId: fileId, newName: encryptedNewName);
  });

  @override
  Future<void> renameFolder({
    required String folderId,
    required String newName,
    VaultCancelToken? cancelToken,
  }) => _lock.synchronized(() async {
    final sanitizedFolderId = _convertToRootFolderIfNeeded(folderId);
    if (sanitizedFolderId == null) {
      Error.throwWithStackTrace(
        TdkException(
          message: 'Cannot rename root folder',
          code: TdkExceptionType.invalidFolderId.code,
        ),
        StackTrace.current,
      );
    }

    final encryptedNewName = await _encryptionService.encryptString(newName);
    final success = await _repository.renameFolder(
      folderId: folderId,
      newName: encryptedNewName,
    );
    if (!success) {
      Error.throwWithStackTrace(
        TdkException(
          message: 'Failed to rename folder',
          code: TdkExceptionType.invalidFolderId.code,
        ),
        StackTrace.current,
      );
    }
  });

  @override
  Future<Map<String, dynamic>> export() => _lock.synchronized(() async {
    final items = <Map<String, dynamic>>[];
    final pendingFolders = <String?>[null];
    while (pendingFolders.isNotEmpty) {
      final folderId = pendingFolders.removeLast();
      String? cursor;
      do {
        final page = await getFolder(
          folderId: folderId,
          limit: _pageSize,
          exclusiveStartItemId: cursor,
        );
        for (final item in page.items) {
          final parentId = _convertToRootFolderIfNeeded(item.parentId);
          if (item is Folder) {
            pendingFolders.add(item.id);
            items.add({
              'id': item.id,
              'name': item.name,
              'parentId': parentId,
              'type': 'folder',
            });
          } else if (item is File) {
            items.add({
              'id': item.id,
              'name': item.name,
              'parentId': parentId,
              'type': 'file',
              'content': base64Encode(await getFileContent(fileId: item.id)),
            });
          }
        }
        cursor = page.lastEvaluatedItemId;
      } while (cursor != null);
    }

    return {'version': _backupVersion, 'items': items};
  });

  @override
  Future<void> validateImport(Map<String, dynamic> data) =>
      _lock.synchronized(() async {
        _parseBackup(data);
      });

  @override
  Future<bool> isEmpty() => _lock.synchronized(() async {
    final page = await getFolder(folderId: _profileId, limit: 1);
    return page.items.isEmpty;
  });

  @override
  Future<void> import(Map<String, dynamic> data) =>
      _lock.synchronized(() async {
        final (folders, files) = _parseBackup(data);
        if (!await isEmpty()) {
          throw EdgeRestoreException.destinationNotEmpty('File');
        }
        _importPendingRollback = true;

        final restoredFolderIds = <String, String>{};
        final remainingFolders = List<_BackupFolder>.of(folders);
        while (remainingFolders.isNotEmpty) {
          final restored = <_BackupFolder>[];
          for (final folder in remainingFolders) {
            final parentId = folder.parentId == null
                ? _profileId
                : restoredFolderIds[folder.parentId];
            if (parentId == null) {
              continue;
            }
            final restoredId = (await createFolder(
              folderName: folder.name,
              parentFolderId: parentId,
            )).id;
            restoredFolderIds[folder.id] = restoredId;
            restored.add(folder);
          }
          if (restored.isEmpty) {
            throw EdgeRestoreException.invalidBackupFormat('file storage');
          }
          remainingFolders.removeWhere(restored.contains);
        }

        for (final file in files) {
          final parentId = file.parentId == null
              ? _profileId
              : restoredFolderIds[file.parentId]!;
          await createFile(
            fileName: file.name,
            data: file.content,
            parentFolderId: parentId,
          );
        }
      });

  @override
  Future<void> rollbackImport() => _lock.synchronized(() async {
    if (!_importPendingRollback) return;
    final folderIds = <String>[];
    final pendingFolders = <String?>[null];
    while (pendingFolders.isNotEmpty) {
      final folderId = pendingFolders.removeLast();
      final items = <Item>[];
      String? cursor;
      do {
        final page = await getFolder(
          folderId: folderId,
          limit: _pageSize,
          exclusiveStartItemId: cursor,
        );
        items.addAll(page.items);
        cursor = page.lastEvaluatedItemId;
      } while (cursor != null);

      for (final item in items) {
        if (item is Folder) {
          folderIds.add(item.id);
          pendingFolders.add(item.id);
        } else if (item is File) {
          await _repository.deleteFile(fileId: item.id);
        }
      }
    }

    for (final folderId in folderIds.reversed) {
      await _repository.deleteFolder(folderId: folderId);
    }
    _importPendingRollback = false;
  });

  (List<_BackupFolder>, List<_BackupFile>) _parseBackup(
    Map<String, dynamic> data,
  ) {
    const allowedKeys = {'version', 'items'};
    final rawItems = data['items'];
    if (data.keys.any((key) => !allowedKeys.contains(key)) ||
        data['version'] != _backupVersion ||
        rawItems is! List) {
      throw EdgeRestoreException.invalidBackupFormat('file storage');
    }

    final folders = <_BackupFolder>[];
    final files = <_BackupFile>[];
    final itemIds = <String>{};
    for (final rawItem in rawItems) {
      if (rawItem is! Map<String, dynamic>) {
        throw EdgeRestoreException.invalidBackupFormat('file storage');
      }
      final id = rawItem['id'];
      final name = rawItem['name'];
      final parentId = rawItem['parentId'];
      final type = rawItem['type'];
      if (id is! String ||
          id.isEmpty ||
          !itemIds.add(id) ||
          name is! String ||
          name.isEmpty ||
          (parentId != null && parentId is! String)) {
        throw EdgeRestoreException.invalidBackupFormat('file storage');
      }
      final parsedParentId = parentId is String ? parentId : null;

      if (type == 'folder' &&
          rawItem.length == 4 &&
          !rawItem.containsKey('content')) {
        folders.add(
          _BackupFolder(id: id, name: name, parentId: parsedParentId),
        );
      } else if (type == 'file' &&
          rawItem.length == 5 &&
          rawItem['content'] is String) {
        final Uint8List content;
        try {
          content = base64Decode(rawItem['content'] as String);
        } on FormatException catch (error) {
          throw EdgeRestoreException.invalidBackupFormat(
            'file storage',
            originalMessage: error.toString(),
          );
        }
        if (!FileUtils.isFileSizeValid(content.length, _maxFileSize) ||
            !FileUtils.isFileExtensionAllowed(name, _allowedExtensions)) {
          throw EdgeRestoreException.invalidBackupFormat('file storage');
        }
        files.add(
          _BackupFile(
            id: id,
            name: name,
            parentId: parsedParentId,
            content: content,
          ),
        );
      } else {
        throw EdgeRestoreException.invalidBackupFormat('file storage');
      }
    }

    final foldersById = {for (final folder in folders) folder.id: folder};
    for (final folder in folders) {
      final visited = <String>{folder.id};
      var parentId = folder.parentId;
      while (parentId != null) {
        if (!visited.add(parentId)) {
          throw EdgeRestoreException.invalidBackupFormat('file storage');
        }
        final parent = foldersById[parentId];
        if (parent == null) {
          throw EdgeRestoreException.invalidBackupFormat('file storage');
        }
        parentId = parent.parentId;
      }
    }
    for (final file in files) {
      if (file.parentId != null && !foldersById.containsKey(file.parentId)) {
        throw EdgeRestoreException.invalidBackupFormat('file storage');
      }
    }

    return (folders, files);
  }
}

class _BackupFolder {
  const _BackupFolder({
    required this.id,
    required this.name,
    required this.parentId,
  });

  final String id;
  final String name;
  final String? parentId;
}

class _BackupFile {
  const _BackupFile({
    required this.id,
    required this.name,
    required this.parentId,
    required this.content,
  });

  final String id;
  final String name;
  final String? parentId;
  final Uint8List content;
}
