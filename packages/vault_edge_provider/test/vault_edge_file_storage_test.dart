import 'dart:convert';

import 'package:affinidi_tdk_vault_edge_provider/affinidi_tdk_vault_edge_provider.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import 'fixtures/file_fixtures.dart';
import 'mocks/file_mock_setup.dart';
import 'mocks/mock_edge_encryption_service.dart';
import 'mocks/mock_edge_file_repository.dart';

void main() {
  late MockEdgeFileRepositoryInterface mockRepository;
  late MockEdgeEncryptionService mockEncryptionService;
  late EdgeFileStorage storage;

  setUpAll(FileMockSetup.setupFallbackValues);

  setUp(() {
    mockRepository = MockEdgeFileRepositoryInterface();
    mockEncryptionService = MockEdgeEncryptionService();

    storage = EdgeFileStorage(
      repository: mockRepository,
      id: FileFixtures.storageId,
      profileId: FileFixtures.profileId,
      encryptionService: mockEncryptionService,
    );

    FileMockSetup.setupFileRepositoryMocks(mockRepository);
    MockEncryptionServiceSetup.setupEncryptionServiceDefaults(
      mockEncryptionService,
    );
  });

  group('When performing file operations', () {
    group('and creating a file', () {
      test('it creates file with valid size and extension', () async {
        await storage.createFile(
          fileName: FileFixtures.fileName,
          data: FileFixtures.smallFileData,
        );

        verify(
          () => mockRepository.createFile(
            profileId: FileFixtures.profileId,
            fileName: FileFixtures.fileName,
            data: FileFixtures.smallFileData,
            parentFolderId: null,
          ),
        ).called(1);
      });

      test('it throws error when file size exceeds limit', () async {
        expect(
          () => storage.createFile(
            fileName: FileFixtures.fileName,
            data: FileFixtures.largeFileData,
          ),
          throwsA(
            isA<TdkException>().having(
              (error) => error.code,
              'code',
              TdkExceptionType.invalidFileSize.code,
            ),
          ),
        );
      });

      test('it throws error when file extension is not allowed', () async {
        expect(
          () => storage.createFile(
            fileName: 'test.exe',
            data: FileFixtures.invalidFileData,
          ),
          throwsA(
            isA<TdkException>().having(
              (error) => error.code,
              'code',
              TdkExceptionType.invalidFileType.code,
            ),
          ),
        );
      });

      test('it creates file in parent folder', () async {
        when(
          () => mockRepository.getFolder(folderId: FileFixtures.parentFolderId),
        ).thenAnswer(
          (_) async => PaginatedList(
            items: [
              Folder(
                id: FileFixtures.parentFolderId,
                name: FileFixtures.folderName,
                createdAt: DateTime.now(),
                modifiedAt: DateTime.now(),
                parentId: null,
              ),
            ],
            lastEvaluatedItemId: FileFixtures.parentFolderId,
          ),
        );

        await storage.createFile(
          fileName: FileFixtures.fileName,
          data: FileFixtures.invalidFileData,
          parentFolderId: FileFixtures.parentFolderId,
        );

        verify(
          () => mockRepository.createFile(
            profileId: FileFixtures.profileId,
            fileName: FileFixtures.fileName,
            data: FileFixtures.invalidFileData,
            parentFolderId: FileFixtures.parentFolderId,
          ),
        ).called(1);
      });

      test('it throws error when parent folder does not exist', () async {
        when(
          () => mockRepository.createFile(
            profileId: any(named: 'profileId'),
            fileName: any(named: 'fileName'),
            data: any(named: 'data'),
            parentFolderId: 'non-existent-folder',
          ),
        ).thenThrow(
          TdkException(
            message: 'Parent folder does not exist',
            code: TdkExceptionType.invalidParentFolderId.code,
          ),
        );

        expect(
          () => storage.createFile(
            fileName: FileFixtures.fileName,
            data: FileFixtures.invalidFileData,
            parentFolderId: 'non-existent-folder',
          ),
          throwsA(
            isA<TdkException>().having(
              (error) => error.code,
              'code',
              TdkExceptionType.invalidParentFolderId.code,
            ),
          ),
        );
      });
    });

    group('and retrieving a file', () {
      test('it gets file by ID', () async {
        final mockFileData = FileFixtures.createMockFileData();
        when(
          () => mockRepository.getFile(fileId: FileFixtures.fileId),
        ).thenAnswer((_) async => mockFileData);

        final result = await storage.getFile(fileId: FileFixtures.fileId);

        expect(result.id, equals(mockFileData.id));
        expect(result.name, equals(mockFileData.name));
        expect(result.createdAt, equals(mockFileData.createdAt));
        expect(result.modifiedAt, equals(mockFileData.modifiedAt));
        verify(
          () => mockRepository.getFile(fileId: FileFixtures.fileId),
        ).called(1);
      });

      test('it gets file content', () async {
        final result = await storage.getFileContent(
          fileId: FileFixtures.fileId,
        );

        expect(result, equals(FileFixtures.smallFileData));
        verify(
          () => mockRepository.getFileContent(fileId: FileFixtures.fileId),
        ).called(1);
      });
    });

    group('and managing folders', () {
      test('it creates folder', () async {
        final mockFolderData = FileFixtures.createMockFolder();
        when(
          () => mockRepository.createFolder(
            profileId: any(named: 'profileId'),
            folderName: any(named: 'folderName'),
            parentFolderId: any(named: 'parentFolderId'),
          ),
        ).thenAnswer((_) async => mockFolderData);

        final result = await storage.createFolder(
          folderName: FileFixtures.folderName,
          parentFolderId: FileFixtures.parentFolderId,
        );

        expect(result.id, equals(mockFolderData.id));
        expect(result.name, equals(mockFolderData.name));
        expect(result.createdAt, equals(mockFolderData.createdAt));
        expect(result.modifiedAt, equals(mockFolderData.modifiedAt));
        expect(result.parentId, equals(mockFolderData.parentId));
        verify(
          () => mockRepository.createFolder(
            profileId: FileFixtures.profileId,
            folderName: FileFixtures.folderName,
            parentFolderId: FileFixtures.parentFolderId,
          ),
        ).called(1);
      });

      test('it deletes folder', () async {
        await storage.deleteFolder(folderId: FileFixtures.folderId);

        verify(
          () => mockRepository.deleteFolder(folderId: FileFixtures.folderId),
        ).called(1);
      });

      test('it gets folder contents', () async {
        final mockItems = [
          File(
            id: 'file1',
            name: 'test1.txt',
            createdAt: DateTime.now(),
            modifiedAt: DateTime.now(),
            parentId: null,
          ),
          Folder(
            id: 'folder1',
            name: 'subfolder',
            createdAt: DateTime.now(),
            modifiedAt: DateTime.now(),
            parentId: FileFixtures.folderId,
          ),
        ];
        when(
          () => mockRepository.getFolder(
            folderId: any(named: 'folderId'),
            limit: any(named: 'limit'),
            exclusiveStartItemId: any(named: 'exclusiveStartItemId'),
          ),
        ).thenAnswer(
          (_) async => PaginatedList(
            items: mockItems,
            lastEvaluatedItemId: mockItems.last.id,
          ),
        );

        final result = await storage.getFolder(folderId: FileFixtures.folderId);

        expect(result.items.length, equals(mockItems.length));
        expect(result.items.first.id, equals(mockItems.first.id));
        expect(result.lastEvaluatedItemId, equals(mockItems.last.id));
        verify(
          () => mockRepository.getFolder(
            folderId: FileFixtures.folderId,
            limit: null,
            exclusiveStartItemId: null,
          ),
        ).called(1);
      });

      test('it renames folder', () async {
        await storage.renameFolder(
          folderId: FileFixtures.folderId,
          newName: 'renamed-folder',
        );

        verify(
          () => mockRepository.renameFolder(
            folderId: FileFixtures.folderId,
            newName: 'renamed-folder',
          ),
        ).called(1);
      });
    });

    group('and managing files', () {
      test('it deletes file', () async {
        await storage.deleteFile(fileId: FileFixtures.fileId);

        verify(
          () => mockRepository.deleteFile(fileId: FileFixtures.fileId),
        ).called(1);
      });

      test('it renames file', () async {
        await storage.renameFile(
          fileId: FileFixtures.fileId,
          newName: 'renamed-file.txt',
        );

        verify(
          () => mockRepository.renameFile(
            fileId: FileFixtures.fileId,
            newName: 'renamed-file.txt',
          ),
        ).called(1);
      });
    });
  });

  group('When backing up files', () {
    final invalidBackupFormat = isA<TdkException>().having(
      (error) => error.code,
      'code',
      'invalid_backup_format',
    );

    test('it exports root and nested items', () async {
      final folder = FileFixtures.createMockFolder(
        id: 'old-folder',
        name: 'documents',
      );
      final rootFile = FileFixtures.createMockFileData(
        id: 'root-file',
        name: 'root.txt',
      );
      final nestedFile = FileFixtures.createMockFileData(
        id: 'nested-file',
        name: 'nested.txt',
        parentId: 'old-folder',
      );
      when(
        () => mockRepository.getFolder(
          folderId: null,
          limit: 50,
          exclusiveStartItemId: null,
        ),
      ).thenAnswer(
        (_) async =>
            PaginatedList(items: [folder, rootFile], lastEvaluatedItemId: null),
      );
      when(
        () => mockRepository.getFolder(
          folderId: 'old-folder',
          limit: 50,
          exclusiveStartItemId: null,
        ),
      ).thenAnswer(
        (_) async =>
            PaginatedList(items: [nestedFile], lastEvaluatedItemId: null),
      );

      final exported = await storage.export();

      expect(exported['version'], '1.0.0');
      expect(
        exported['items'],
        containsAll([
          {
            'id': 'old-folder',
            'name': 'documents',
            'parentId': null,
            'type': 'folder',
          },
          {
            'id': 'root-file',
            'name': 'root.txt',
            'parentId': null,
            'type': 'file',
            'content': base64Encode(FileFixtures.smallFileData),
          },
          {
            'id': 'nested-file',
            'name': 'nested.txt',
            'parentId': 'old-folder',
            'type': 'file',
            'content': base64Encode(FileFixtures.smallFileData),
          },
        ]),
      );
    });

    test('it remaps file parents to restored folder ids', () async {
      when(
        () => mockRepository.createFolder(
          profileId: FileFixtures.profileId,
          folderName: 'documents',
          parentFolderId: null,
        ),
      ).thenAnswer(
        (_) async =>
            FileFixtures.createMockFolder(id: 'new-folder', name: 'documents'),
      );

      await storage.import({
        'version': '1.0.0',
        'items': [
          {
            'id': 'old-folder',
            'name': 'documents',
            'parentId': null,
            'type': 'folder',
          },
          {
            'id': 'old-file',
            'name': 'document.txt',
            'parentId': 'old-folder',
            'type': 'file',
            'content': base64Encode(FileFixtures.smallFileData),
          },
        ],
      });

      verify(
        () => mockRepository.createFile(
          profileId: FileFixtures.profileId,
          fileName: 'document.txt',
          data: FileFixtures.smallFileData,
          parentFolderId: 'new-folder',
        ),
      ).called(1);
    });

    test('it rejects a non-empty file destination', () async {
      final existingFolder = FileFixtures.createMockFolder(
        id: 'existing-folder',
        name: 'documents',
      );
      final existingFile = FileFixtures.createMockFileData(
        id: 'existing-file',
        name: 'document.txt',
        parentId: 'existing-folder',
      );
      when(
        () => mockRepository.getFolder(
          folderId: null,
          limit: 1,
          exclusiveStartItemId: null,
        ),
      ).thenAnswer(
        (_) async =>
            PaginatedList(items: [existingFolder], lastEvaluatedItemId: null),
      );
      when(
        () => mockRepository.getFolder(
          folderId: 'existing-folder',
          limit: 50,
          exclusiveStartItemId: null,
        ),
      ).thenAnswer(
        (_) async =>
            PaginatedList(items: [existingFile], lastEvaluatedItemId: null),
      );

      await expectLater(
        storage.import({
          'version': '1.0.0',
          'items': [
            {
              'id': 'old-folder',
              'name': 'documents',
              'parentId': null,
              'type': 'folder',
            },
            {
              'id': 'old-file',
              'name': 'document.txt',
              'parentId': 'old-folder',
              'type': 'file',
              'content': base64Encode(FileFixtures.smallFileData),
            },
          ],
        }),
        throwsA(
          isA<TdkException>().having(
            (error) => error.code,
            'code',
            'restore_destination_not_empty',
          ),
        ),
      );

      verifyNever(
        () => mockRepository.deleteFile(fileId: any(named: 'fileId')),
      );
      verifyNever(
        () => mockRepository.deleteFolder(folderId: any(named: 'folderId')),
      );
      verifyNever(
        () => mockRepository.createFolder(
          profileId: any(named: 'profileId'),
          folderName: any(named: 'folderName'),
          parentFolderId: any(named: 'parentFolderId'),
        ),
      );
      verifyNever(
        () => mockRepository.createFile(
          profileId: any(named: 'profileId'),
          fileName: any(named: 'fileName'),
          data: any(named: 'data'),
          parentFolderId: any(named: 'parentFolderId'),
        ),
      );
    });

    test('it rejects folder cycles before repository access', () async {
      await expectLater(
        storage.import(const {
          'version': '1.0.0',
          'items': [
            {
              'id': 'folder-a',
              'name': 'a',
              'parentId': 'folder-b',
              'type': 'folder',
            },
            {
              'id': 'folder-b',
              'name': 'b',
              'parentId': 'folder-a',
              'type': 'folder',
            },
          ],
        }),
        throwsA(invalidBackupFormat),
      );

      verifyNever(
        () => mockRepository.getFolder(
          folderId: any(named: 'folderId'),
          limit: any(named: 'limit'),
          exclusiveStartItemId: any(named: 'exclusiveStartItemId'),
        ),
      );
      verifyNever(
        () => mockRepository.createFolder(
          profileId: any(named: 'profileId'),
          folderName: any(named: 'folderName'),
          parentFolderId: any(named: 'parentFolderId'),
        ),
      );
    });

    test('it rejects unsupported versions before repository access', () async {
      await expectLater(
        storage.validateImport(const {
          'version': '2.0.0',
          'items': <dynamic>[],
        }),
        throwsA(invalidBackupFormat),
      );

      verifyNever(
        () => mockRepository.getFolder(
          folderId: any(named: 'folderId'),
          limit: any(named: 'limit'),
          exclusiveStartItemId: any(named: 'exclusiveStartItemId'),
        ),
      );
    });

    test('it rolls back all imported files across multiple pages', () async {
      final itemsByParent = <String?, List<Item>>{null: []};
      var nextFileId = 0;
      when(
        () => mockRepository.getFolder(
          folderId: any(named: 'folderId'),
          limit: any(named: 'limit'),
          exclusiveStartItemId: any(named: 'exclusiveStartItemId'),
        ),
      ).thenAnswer((invocation) async {
        final folderId = invocation.namedArguments[#folderId] as String?;
        final limit = invocation.namedArguments[#limit] as int?;
        final cursor =
            invocation.namedArguments[#exclusiveStartItemId] as String?;
        final offset = int.tryParse(cursor ?? '') ?? 0;
        final sourceItems = List<Item>.of(itemsByParent[folderId] ?? const []);
        final pageItems = limit == null
            ? sourceItems.skip(offset).toList()
            : sourceItems.skip(offset).take(limit).toList();
        final lastEvaluatedItemId = limit != null && pageItems.isNotEmpty
            ? (offset + pageItems.length).toString()
            : null;
        return PaginatedList(
          items: pageItems,
          lastEvaluatedItemId: lastEvaluatedItemId,
        );
      });
      when(
        () => mockRepository.createFile(
          profileId: FileFixtures.profileId,
          fileName: any(named: 'fileName'),
          data: any(named: 'data'),
          parentFolderId: any(named: 'parentFolderId'),
        ),
      ).thenAnswer((invocation) async {
        final parentFolderId =
            invocation.namedArguments[#parentFolderId] as String?;
        final fileName = invocation.namedArguments[#fileName] as String;
        final now = DateTime(2023, 1, 1);
        itemsByParent
            .putIfAbsent(parentFolderId, () => [])
            .add(
              File(
                id: 'restored-file-${nextFileId++}',
                name: fileName,
                createdAt: now,
                modifiedAt: now,
                parentId: parentFolderId,
              ),
            );
      });
      when(
        () => mockRepository.deleteFile(fileId: any(named: 'fileId')),
      ).thenAnswer((invocation) async {
        final fileId = invocation.namedArguments[#fileId] as String;
        for (final items in itemsByParent.values) {
          items.removeWhere((item) => item.id == fileId);
        }
      });

      final backupItems = List.generate(120, (index) {
        return {
          'id': 'source-file-$index',
          'name': 'file-$index.txt',
          'parentId': null,
          'type': 'file',
          'content': base64Encode(FileFixtures.smallFileData),
        };
      });

      await storage.import({'version': '1.0.0', 'items': backupItems});

      expect(itemsByParent[null], hasLength(120));

      await storage.rollbackImport();

      expect(itemsByParent[null], isEmpty);
    });
  });
}
