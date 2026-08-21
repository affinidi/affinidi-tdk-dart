import 'dart:typed_data';

import 'package:affinidi_tdk_vault_edge_provider/affinidi_tdk_vault_edge_provider.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import 'fixtures/credential_fixtures.dart';
import 'mocks/credential_mock_setup.dart';
import 'mocks/mock_edge_credential_repository.dart';
import 'mocks/mock_edge_encryption_service.dart';

void main() {
  late MockEdgeCredentialRepository mockRepository;
  late MockEdgeEncryptionService mockEncryptionService;
  late EdgeCredentialStorage storage;

  setUpAll(CredentialMockSetup.setupFallbackValues);

  setUp(() {
    mockRepository = MockEdgeCredentialRepository();
    mockEncryptionService = MockEdgeEncryptionService();

    storage = EdgeCredentialStorage(
      repository: mockRepository,
      id: CredentialFixtures.storageId,
      profileId: CredentialFixtures.profileId,
      encryptionService: mockEncryptionService,
    );

    CredentialMockSetup.setupCredentialRepositoryMocks(mockRepository);
    MockEncryptionServiceSetup.setupEncryptionServiceDefaults(
      mockEncryptionService,
    );
  });

  group('When performing credential operations', () {
    test('should have correct id', () {
      expect(storage.id, equals(CredentialFixtures.storageId));
    });

    group('When saving credentials', () {
      test('should save credential successfully', () async {
        final mockVC = CredentialFixtures.mockVerifiableCredential;

        await storage.saveCredential(verifiableCredential: mockVC);

        verify(
          () => mockRepository.saveCredentialData(
            profileId: CredentialFixtures.profileId,
            credentialId: any(named: 'credentialId'),
            credentialName: 'UniversityDegree',
            credentialContent: any(named: 'credentialContent'),
            cancelToken: null,
          ),
        ).called(1);
      });

      test('should pass cancel token when provided', () async {
        final mockVC = CredentialFixtures.mockVerifiableCredential;
        final cancelToken = VaultCancelToken();

        await storage.saveCredential(
          verifiableCredential: mockVC,
          cancelToken: cancelToken,
        );

        verify(
          () => mockRepository.saveCredentialData(
            profileId: CredentialFixtures.profileId,
            credentialId: any(named: 'credentialId'),
            credentialName: 'UniversityDegree',
            credentialContent: any(named: 'credentialContent'),
            cancelToken: cancelToken,
          ),
        ).called(1);
      });
    });

    group('When getting credentials', () {
      test('should get credential successfully', () async {
        final result = await storage.getCredential(
          digitalCredentialId: CredentialFixtures.credentialId,
        );

        expect(result.id, equals(CredentialFixtures.credentialId));
        verify(
          () => mockRepository.getCredentialData(
            credentialId: CredentialFixtures.credentialId,
            cancelToken: null,
          ),
        ).called(1);
      });

      test('should throw exception when credential not found', () async {
        when(
          () => mockRepository.getCredentialData(
            credentialId: CredentialFixtures.credentialId,
            cancelToken: any(named: 'cancelToken'),
          ),
        ).thenAnswer((_) async => null);

        expect(
          () => storage.getCredential(
            digitalCredentialId: CredentialFixtures.credentialId,
          ),
          throwsA(
            isA<TdkException>().having(
              (error) => error.code,
              'code',
              TdkExceptionType.credentialNotFound.code,
            ),
          ),
        );
      });

      test('should pass cancel token when provided', () async {
        final cancelToken = VaultCancelToken();

        await storage.getCredential(
          digitalCredentialId: CredentialFixtures.credentialId,
          cancelToken: cancelToken,
        );

        verify(
          () => mockRepository.getCredentialData(
            credentialId: CredentialFixtures.credentialId,
            cancelToken: cancelToken,
          ),
        ).called(1);
      });
    });

    group('When listing credentials', () {
      test('should list credentials successfully', () async {
        final result = await storage.listCredentials();

        expect(result.items.length, equals(2));
        expect(result.items.first.id, equals(CredentialFixtures.credentialId));
        expect(result.items.last.id, equals('test-credential-id-2'));
        expect(result.lastEvaluatedItemId, equals('test-credential-id-2'));
        verify(
          () => mockRepository.listCredentialData(
            profileId: CredentialFixtures.profileId,
            limit: null,
            exclusiveStartItemId: null,
            cancelToken: null,
          ),
        ).called(1);
      });

      test('should handle empty credential list', () async {
        CredentialMockSetup.setupEmptyCredentialListMocks(mockRepository);

        final result = await storage.listCredentials();

        expect(result.items, isEmpty);
        expect(result.lastEvaluatedItemId, isNull);
      });

      test(
        'should pass limit and exclusiveStartItemId when provided',
        () async {
          final result = await storage.listCredentials(
            limit: 10,
            exclusiveStartItemId: 'test-credential-id-1',
          );

          expect(result.items.length, equals(2));
          verify(
            () => mockRepository.listCredentialData(
              profileId: CredentialFixtures.profileId,
              limit: 10,
              exclusiveStartItemId: 'test-credential-id-1',
              cancelToken: null,
            ),
          ).called(1);
        },
      );

      test('should pass cancel token when provided', () async {
        final cancelToken = VaultCancelToken();

        await storage.listCredentials(cancelToken: cancelToken);

        verify(
          () => mockRepository.listCredentialData(
            profileId: CredentialFixtures.profileId,
            limit: null,
            exclusiveStartItemId: null,
            cancelToken: cancelToken,
          ),
        ).called(1);
      });
    });

    group('When deleting credentials', () {
      test('should delete credential successfully', () async {
        await storage.deleteCredential(
          digitalCredentialId: CredentialFixtures.credentialId,
        );

        verify(
          () => mockRepository.getCredentialData(
            credentialId: CredentialFixtures.credentialId,
            cancelToken: null,
          ),
        ).called(1);
        verify(
          () => mockRepository.deleteCredential(
            credentialId: CredentialFixtures.credentialId,
            cancelToken: null,
          ),
        ).called(1);
      });

      test(
        'should throw exception when credential not found for deletion',
        () async {
          when(
            () => mockRepository.getCredentialData(
              credentialId: CredentialFixtures.credentialId,
              cancelToken: any(named: 'cancelToken'),
            ),
          ).thenAnswer((_) async => null);

          expect(
            () => storage.deleteCredential(
              digitalCredentialId: CredentialFixtures.credentialId,
            ),
            throwsA(
              isA<TdkException>().having(
                (error) => error.code,
                'code',
                TdkExceptionType.credentialNotFound.code,
              ),
            ),
          );

          verify(
            () => mockRepository.getCredentialData(
              credentialId: CredentialFixtures.credentialId,
              cancelToken: null,
            ),
          ).called(1);
          verifyNever(
            () => mockRepository.deleteCredential(
              credentialId: any(named: 'credentialId'),
              cancelToken: any(named: 'cancelToken'),
            ),
          );
        },
      );

      test('should pass cancel token when provided', () async {
        final cancelToken = VaultCancelToken();

        await storage.deleteCredential(
          digitalCredentialId: CredentialFixtures.credentialId,
          cancelToken: cancelToken,
        );

        verify(
          () => mockRepository.getCredentialData(
            credentialId: CredentialFixtures.credentialId,
            cancelToken: cancelToken,
          ),
        ).called(1);
        verify(
          () => mockRepository.deleteCredential(
            credentialId: CredentialFixtures.credentialId,
            cancelToken: cancelToken,
          ),
        ).called(1);
      });
    });
  });

  group('When backing up credentials', () {
    final invalidBackupFormat = isA<TdkException>().having(
      (error) => error.code,
      'code',
      'invalid_backup_format',
    );

    test('it exports all credentials across pages', () async {
      when(
        () => mockRepository.listCredentialData(
          profileId: CredentialFixtures.profileId,
          limit: 50,
          exclusiveStartItemId: null,
          cancelToken: null,
        ),
      ).thenAnswer(
        (_) async => PaginatedList(
          items: [CredentialFixtures.mockCredentialData],
          lastEvaluatedItemId: CredentialFixtures.credentialId,
        ),
      );
      when(
        () => mockRepository.listCredentialData(
          profileId: CredentialFixtures.profileId,
          limit: 50,
          exclusiveStartItemId: CredentialFixtures.credentialId,
          cancelToken: null,
        ),
      ).thenAnswer(
        (_) async => PaginatedList(
          items: [CredentialFixtures.drivingLicenseCredentialData],
          lastEvaluatedItemId: null,
        ),
      );

      final exported = await storage.export();

      expect(exported['version'], '1.0.0');
      expect(exported['credentials'], [
        {
          'id': CredentialFixtures.credentialId,
          'verifiableCredential': CredentialFixtures.mockVerifiableCredential
              .toJson(),
        },
        {
          'id': 'test-credential-id-2',
          'verifiableCredential': CredentialFixtures
              .drivingLicenseVerifiableCredential
              .toJson(),
        },
      ]);
    });

    test('it imports credentials with their original storage ids', () async {
      CredentialMockSetup.setupEmptyCredentialListMocks(mockRepository);

      await storage.import({
        'version': '1.0.0',
        'credentials': [
          {
            'id': CredentialFixtures.credentialId,
            'verifiableCredential':
                CredentialFixtures.universityDegreeCredentialJson,
          },
        ],
      });

      verify(
        () => mockRepository.saveCredentialData(
          profileId: CredentialFixtures.profileId,
          credentialId: CredentialFixtures.credentialId,
          credentialName: 'UniversityDegree',
          credentialContent: any(named: 'credentialContent'),
          cancelToken: null,
        ),
      ).called(1);
    });

    test('it rejects a non-empty credential destination', () async {
      when(
        () => mockRepository.listCredentialData(
          profileId: CredentialFixtures.profileId,
          limit: 1,
          exclusiveStartItemId: null,
          cancelToken: null,
        ),
      ).thenAnswer(
        (_) async => PaginatedList(
          items: [CredentialFixtures.mockCredentialData],
          lastEvaluatedItemId: null,
        ),
      );

      await expectLater(
        storage.import({
          'version': '1.0.0',
          'credentials': [
            {
              'id': CredentialFixtures.credentialId,
              'verifiableCredential':
                  CredentialFixtures.universityDegreeCredentialJson,
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
        () => mockRepository.deleteCredential(
          credentialId: any(named: 'credentialId'),
          cancelToken: any(named: 'cancelToken'),
        ),
      );
      verifyNever(
        () => mockRepository.saveCredentialData(
          profileId: any(named: 'profileId'),
          credentialId: any(named: 'credentialId'),
          credentialName: any(named: 'credentialName'),
          credentialContent: any(named: 'credentialContent'),
          cancelToken: any(named: 'cancelToken'),
        ),
      );
    });

    test('it rejects malformed credentials before repository access', () async {
      await expectLater(
        storage.import(const {
          'version': '1.0.0',
          'credentials': [
            {'id': 'credential-id', 'verifiableCredential': 42},
          ],
        }),
        throwsA(invalidBackupFormat),
      );

      verifyNever(
        () => mockRepository.listCredentialData(
          profileId: any(named: 'profileId'),
          limit: any(named: 'limit'),
          exclusiveStartItemId: any(named: 'exclusiveStartItemId'),
          cancelToken: any(named: 'cancelToken'),
        ),
      );
      verifyNever(
        () => mockRepository.saveCredentialData(
          profileId: any(named: 'profileId'),
          credentialId: any(named: 'credentialId'),
          credentialName: any(named: 'credentialName'),
          credentialContent: any(named: 'credentialContent'),
          cancelToken: any(named: 'cancelToken'),
        ),
      );
    });

    test('it rejects unsupported versions before repository access', () async {
      await expectLater(
        storage.validateImport(const {
          'version': '2.0.0',
          'credentials': <dynamic>[],
        }),
        throwsA(invalidBackupFormat),
      );

      verifyNever(
        () => mockRepository.listCredentialData(
          profileId: any(named: 'profileId'),
          limit: any(named: 'limit'),
          exclusiveStartItemId: any(named: 'exclusiveStartItemId'),
          cancelToken: any(named: 'cancelToken'),
        ),
      );
    });

    test(
      'it rolls back all imported credentials across multiple pages',
      () async {
        final storedCredentials = <EdgeCredential>[];
        when(
          () => mockRepository.listCredentialData(
            profileId: CredentialFixtures.profileId,
            limit: any(named: 'limit'),
            exclusiveStartItemId: any(named: 'exclusiveStartItemId'),
            cancelToken: any(named: 'cancelToken'),
          ),
        ).thenAnswer((invocation) async {
          final limit = invocation.namedArguments[#limit] as int?;
          final cursor =
              invocation.namedArguments[#exclusiveStartItemId] as String?;
          final offset = int.tryParse(cursor ?? '') ?? 0;
          final items = limit == null
              ? storedCredentials.skip(offset).toList()
              : storedCredentials.skip(offset).take(limit).toList();
          final lastEvaluatedItemId = limit != null && items.isNotEmpty
              ? (offset + items.length).toString()
              : null;
          return PaginatedList(
            items: items,
            lastEvaluatedItemId: lastEvaluatedItemId,
          );
        });
        when(
          () => mockRepository.saveCredentialData(
            profileId: CredentialFixtures.profileId,
            credentialId: any(named: 'credentialId'),
            credentialName: any(named: 'credentialName'),
            credentialContent: any(named: 'credentialContent'),
            cancelToken: any(named: 'cancelToken'),
          ),
        ).thenAnswer((invocation) async {
          storedCredentials.add(
            EdgeCredential(
              id: invocation.namedArguments[#credentialId] as String,
              content:
                  invocation.namedArguments[#credentialContent] as Uint8List,
            ),
          );
        });
        when(
          () => mockRepository.deleteCredential(
            credentialId: any(named: 'credentialId'),
            cancelToken: any(named: 'cancelToken'),
          ),
        ).thenAnswer((invocation) async {
          final credentialId =
              invocation.namedArguments[#credentialId] as String;
          storedCredentials.removeWhere(
            (credential) => credential.id == credentialId,
          );
        });

        final credentials = List.generate(120, (index) {
          return {
            'id': 'credential-$index',
            'verifiableCredential':
                CredentialFixtures.universityDegreeCredentialJson,
          };
        });

        await storage.import({'version': '1.0.0', 'credentials': credentials});

        expect(storedCredentials, hasLength(120));

        await storage.rollbackImport();

        expect(storedCredentials, isEmpty);
      },
    );
  });
}
