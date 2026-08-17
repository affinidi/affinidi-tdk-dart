import 'dart:convert';
import 'dart:typed_data';

import 'package:affinidi_tdk_vault/affinidi_tdk_vault.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import 'fixtures/file_fixtures.dart';
import 'fixtures/folder_fixtures.dart';
import 'mocks/mock_profile.dart';
import 'mocks/mock_profile_repository.dart';

void main() {
  group('VaultFilesBackupSource', () {
    late MockRestorableProfileRepository repository;
    late MockFileStorage fileStorage;

    const rootId = 'id-did-1';

    final invalidBackupFormat = isA<TdkException>().having(
      (e) => e.code,
      'code',
      equals('invalid_backup_format'),
    );

    setUpAll(() {
      registerFallbackValue(Uint8List(0));
    });

    setUp(() {
      repository = MockRestorableProfileRepository();
      fileStorage = MockFileStorage();
      when(() => repository.listProfiles()).thenAnswer(
        (_) async => [
          buildTestProfile(
            did: 'did-1',
            accountIndex: 1,
            fileStorages: {'s': fileStorage},
          ),
        ],
      );
    });

    VaultFilesBackupSource buildSource() =>
        VaultFilesBackupSource(profileRepositories: [repository]);

    test(
      'exports the folder tree and file content, root parent nulled',
      () async {
        final folder = FolderFixtures.createFolder(
          id: 'fold1',
          name: 'F',
          parentId: rootId,
        );
        final file = FileFixtures.createFile(
          id: 'f1',
          name: 'a.txt',
          parentId: rootId,
        );
        when(
          () => fileStorage.getFolder(
            folderId: any(named: 'folderId'),
            limit: any(named: 'limit'),
            exclusiveStartItemId: any(named: 'exclusiveStartItemId'),
          ),
        ).thenAnswer((invocation) async {
          final folderId = invocation.namedArguments[#folderId] as String?;
          if (folderId == rootId) {
            return PaginatedList<Item>(items: [folder, file]);
          }
          return PaginatedList<Item>(items: const []);
        });
        when(
          () => fileStorage.getFileContent(fileId: 'f1'),
        ).thenAnswer((_) async => Uint8List.fromList([1, 2, 3]));

        final exported = await buildSource().export();

        expect(exported, {
          'files': {
            'did-1': [
              {'id': 'fold1', 'name': 'F', 'parentId': null, 'type': 'folder'},
              {
                'id': 'f1',
                'name': 'a.txt',
                'parentId': null,
                'type': 'file',
                'content': base64Encode([1, 2, 3]),
              },
            ],
          },
        });
      },
    );

    test('recreates folders then files, remapping parents', () async {
      when(
        () => fileStorage.createFolder(
          folderName: any(named: 'folderName'),
          parentFolderId: any(named: 'parentFolderId'),
        ),
      ).thenAnswer(
        (_) async => FolderFixtures.createFolder(id: 'new-fold', name: 'F'),
      );
      when(
        () => fileStorage.createFile(
          fileName: any(named: 'fileName'),
          data: any(named: 'data'),
          parentFolderId: any(named: 'parentFolderId'),
        ),
      ).thenAnswer((_) async {});

      await buildSource().import({
        'files': {
          'did-1': [
            {'id': 'fold1', 'name': 'F', 'parentId': null, 'type': 'folder'},
            {
              'id': 'f1',
              'name': 'a.txt',
              'parentId': 'fold1',
              'type': 'file',
              'content': base64Encode([1, 2, 3]),
            },
          ],
        },
      });

      verify(
        () => fileStorage.createFolder(folderName: 'F', parentFolderId: rootId),
      ).called(1);
      verify(
        () => fileStorage.createFile(
          fileName: 'a.txt',
          data: any(named: 'data'),
          parentFolderId: 'new-fold',
        ),
      ).called(1);
    });

    test('throws when the section is missing', () async {
      await expectLater(
        buildSource().import(const {}),
        throwsA(invalidBackupFormat),
      );
    });
  });
}
