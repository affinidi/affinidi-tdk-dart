import 'package:affinidi_tdk_vault/affinidi_tdk_vault.dart';
import 'package:affinidi_tdk_vault_edge_provider/affinidi_tdk_vault_edge_provider.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import 'fixtures/profile_fixtures.dart';
import 'fixtures/wallet_fixtures.dart';
import 'mocks/credential_mock_setup.dart';
import 'mocks/file_mock_setup.dart';
import 'mocks/mock_edge_credential_repository.dart';
import 'mocks/mock_edge_encryption_service.dart';
import 'mocks/mock_edge_file_repository.dart';
import 'mocks/mock_edge_profile_repository.dart';
import 'mocks/mock_edge_repository_factory.dart';

void main() {
  late MockEdgeProfileRepository mockRepository;
  late MockEdgeFileRepositoryInterface mockFileRepository;
  late MockEdgeCredentialRepository mockCredentialRepository;
  late MockEdgeRepositoryFactory mockEdgeRepositoryFactory;
  late MockEdgeEncryptionService mockEncryptionService;
  late InMemoryVaultStore vaultStore;
  late EdgeProfileRepository sut;

  setUpAll(FileMockSetup.setupFallbackValues);

  setUp(() {
    mockRepository = MockEdgeProfileRepository();
    mockCredentialRepository = MockEdgeCredentialRepository();
    mockFileRepository = MockEdgeFileRepositoryInterface();

    mockEdgeRepositoryFactory = MockEdgeRepositoryFactory(
      profileRepository: mockRepository,
      fileRepository: mockFileRepository,
      credentialRepository: mockCredentialRepository,
    );

    mockEncryptionService = MockEdgeEncryptionService();
    vaultStore = InMemoryVaultStore();

    CredentialMockSetup.setupEmptyCredentialListMocks(mockCredentialRepository);
    FileMockSetup.setupFileRepositoryMocks(mockFileRepository);
    MockEncryptionServiceSetup.setupEncryptionServiceDefaults(
      mockEncryptionService,
    );

    sut = EdgeProfileRepository(
      'sut',
      mockEdgeRepositoryFactory,
      mockEncryptionService,
    );
  });

  group('When edge profile repository is not configured', () {
    group('and creates a profile', () {
      test('it throws an exception', () {
        expect(
          () async => await sut.createProfile(name: 'Name'),
          throwsA(
            isA<TdkException>().having(
              (error) => error.code,
              'code',
              TdkExceptionType.profileNotConfigured.code,
            ),
          ),
        );
      });
    });

    group('and deletes a profile', () {
      test('it throws an exception', () {
        expect(
          () async => await sut.deleteProfile(ProfileFixtures.profile),
          throwsA(
            isA<TdkException>().having(
              (error) => error.code,
              'code',
              TdkExceptionType.profileNotConfigured.code,
            ),
          ),
        );
      });
    });

    group('and updates a profile', () {
      test('it throws an exception', () {
        expect(
          () async => await sut.updateProfile(ProfileFixtures.profile),
          throwsA(
            isA<TdkException>().having(
              (error) => error.code,
              'code',
              TdkExceptionType.profileNotConfigured.code,
            ),
          ),
        );
      });
    });

    group('and retrieves profiles', () {
      test('it throws an exception', () {
        expect(
          () async => await sut.listProfiles(),
          throwsA(
            isA<TdkException>().having(
              (error) => error.code,
              'code',
              TdkExceptionType.profileNotConfigured.code,
            ),
          ),
        );
      });
    });

    group('and configuring with invalid configuration', () {
      test('it throws error when keyStorage is null', () async {
        expect(
          () async => await sut.configure(
            RepositoryConfiguration(
              wallet: WalletFixtures.wallet,
              keyStorage: null,
            ),
          ),
          throwsA(
            isA<TdkException>().having(
              (error) => error.code,
              'code',
              TdkExceptionType.missingVaultStore.code,
            ),
          ),
        );
      });

      test('it throws error when configuration is wrong type', () async {
        expect(
          () async => await sut.configure('invalid configuration'),
          throwsA(
            isA<TdkException>().having(
              (error) => error.code,
              'code',
              TdkExceptionType.invalidRepositoryConfigurationType.code,
            ),
          ),
        );
      });
    });
  });

  group('When edge profile repository is configured', () {
    setUp(() async {
      await sut.configure(
        RepositoryConfiguration(
          wallet: WalletFixtures.wallet,
          keyStorage: vaultStore,
        ),
      );
    });

    test('it is configured with keyStorage', () async {
      final isConfigured = await sut.isConfigured();
      expect(isConfigured, isTrue);
    });

    test('it returns the correct id', () async {
      expect(sut.id, equals('sut'));
    });

    group('and creates a profile', () {
      test('it calls the repository with the correct parameters', () async {
        final name = 'name';
        final description = 'Description';

        await sut.createProfile(name: name, description: description);
        expect(mockRepository.lastCalledCreateProfileName, equals(name));
        expect(
          mockRepository.lastCalledCreateProfileDescription,
          equals(description),
        );
        expect(mockRepository.lastCalledCreateProfileAccountIndex, isNotNull);
      });
    });

    group('and deletes a profile', () {
      final profile = ProfileFixtures.profile;

      group('and the profile does not have any associated content', () {
        setUp(() {
          mockRepository.hasAnyContentReturnValue = false;
        });
        test('it calls the repository with the correct parameters', () async {
          await sut.deleteProfile(profile);

          expect(
            mockRepository.lastCalledHasAnyContentProfileId,
            equals(profile.id),
          );
          expect(mockRepository.lastCalledDeletedProfileId, equals(profile.id));
        });
      });

      group('and the profile has some associated content', () {
        setUp(() {
          mockRepository.hasAnyContentReturnValue = true;
        });

        test(
          'it throws an exception with code unable_to_delete_profile_with_content',
          () async {
            expect(
              () async => await sut.deleteProfile(profile),
              throwsA(
                isA<TdkException>().having(
                  (error) => error.code,
                  'code',
                  TdkExceptionType.unableToDeleteProfileWithContent.code,
                ),
              ),
            );
            expect(
              mockRepository.lastCalledHasAnyContentProfileId,
              equals(profile.id),
            );
            expect(mockRepository.lastCalledDeletedProfileId, isNull);
          },
        );
      });
    });

    group('and lists profiles', () {
      test('it returns profiles with file storage', () async {
        // Arrange
        final mockProfile = const EdgeProfile(
          id: '1',
          name: 'Test Profile',
          description: 'Test Description',
          accountIndex: 1,
        );
        mockRepository.listProfilesReturnValue = [mockProfile];

        // Act
        final profiles = await sut.listProfiles();

        // Assert
        expect(profiles.length, equals(1));
        final profile = profiles.first;
        expect(profile.defaultFileStorage, isNotNull);
        expect(profile.defaultFileStorage!.id, equals('sut'));
      });

      test('it returns multiple profiles with file storage', () async {
        // Arrange
        final mockProfiles = [
          const EdgeProfile(
            id: '1',
            name: 'Test Profile 1',
            description: 'Test Description 1',
            accountIndex: 1,
          ),
          const EdgeProfile(
            id: '2',
            name: 'Test Profile 2',
            description: 'Test Description 2',
            accountIndex: 2,
          ),
        ];
        mockRepository.listProfilesReturnValue = mockProfiles;

        // Act
        final profiles = await sut.listProfiles();

        // Assert
        expect(profiles.length, equals(2));

        // Verify each profile has its own file storage
        for (final profile in profiles) {
          expect(profile.defaultFileStorage, isNotNull);
          expect(profile.defaultFileStorage!.id, equals('sut'));
        }
      });
    });

    group('and updates a profile', () {
      test('it calls the repository with the correct parameters', () async {
        final profile = ProfileFixtures.profile;

        await sut.updateProfile(profile);

        expect(mockRepository.lastCalledUpdateProfile, isNotNull);
        expect(
          mockRepository.lastCalledUpdateProfile!.name,
          equals(profile.name),
        );
        expect(
          mockRepository.lastCalledUpdateProfile!.description,
          equals(profile.description),
        );
      });
    });

    group('and backing up profiles', () {
      Future<(EdgeProfile, String)> profileAndDid() async {
        const profile = EdgeProfile(
          id: 'profile-1',
          accountIndex: 3,
          name: 'Profile One',
          description: 'Description',
        );
        mockRepository.listProfilesReturnValue = [profile];
        final did = (await sut.listProfiles()).single.did;
        return (profile, did);
      }

      test('it exports durable profile and nested storage state', () async {
        final (profile, did) = await profileAndDid();

        final exported = await sut.export();

        expect(exported, {
          'version': '1.0.0',
          'profiles': [
            {
              'id': profile.id,
              'accountIndex': profile.accountIndex,
              'name': profile.name,
              'did': did,
              'description': profile.description,
              'fileStorages': {
                'sut': {'version': '1.0.0', 'items': <dynamic>[]},
              },
              'credentialStorages': {
                'sut': {'version': '1.0.0', 'credentials': <dynamic>[]},
              },
              'sharedStorages': <String, dynamic>{},
            },
          ],
        });
      });

      test('it restores the original profile id and account index', () async {
        final (profile, did) = await profileAndDid();
        mockRepository.listProfilesReturnValue = [];

        await sut.import({
          'version': '1.0.0',
          'profiles': [
            {
              'id': profile.id,
              'accountIndex': profile.accountIndex,
              'name': profile.name,
              'did': did,
              'description': profile.description,
              'fileStorages': {
                'sut': {'version': '1.0.0', 'items': <dynamic>[]},
              },
              'credentialStorages': {
                'sut': {'version': '1.0.0', 'credentials': <dynamic>[]},
              },
              'sharedStorages': <String, dynamic>{},
            },
          ],
        });

        expect(mockRepository.lastCalledCreateProfileId, profile.id);
        expect(
          mockRepository.lastCalledCreateProfileAccountIndex,
          profile.accountIndex,
        );
        expect(await vaultStore.getAccountIndex(), profile.accountIndex);
      });

      test('it does not recreate an existing matching profile', () async {
        final (profile, did) = await profileAndDid();

        await sut.import({
          'version': '1.0.0',
          'profiles': [
            {
              'id': profile.id,
              'accountIndex': profile.accountIndex,
              'name': profile.name,
              'did': did,
              'description': profile.description,
              'fileStorages': {
                'sut': {'version': '1.0.0', 'items': <dynamic>[]},
              },
              'credentialStorages': {
                'sut': {'version': '1.0.0', 'credentials': <dynamic>[]},
              },
              'sharedStorages': <String, dynamic>{},
            },
          ],
        });

        expect(mockRepository.lastCalledCreateProfileId, isNull);
      });

      test(
        'it rejects a profile DID from another wallet before writes',
        () async {
          final (profile, _) = await profileAndDid();
          mockRepository.listProfilesReturnValue = [];

          await expectLater(
            sut.import({
              'version': '1.0.0',
              'profiles': [
                {
                  'id': profile.id,
                  'accountIndex': profile.accountIndex,
                  'name': profile.name,
                  'did': 'did:key:wrong-wallet',
                  'description': profile.description,
                  'fileStorages': <String, dynamic>{},
                  'credentialStorages': <String, dynamic>{},
                  'sharedStorages': <String, dynamic>{},
                },
              ],
            }),
            throwsA(
              isA<TdkException>().having(
                (error) => error.code,
                'code',
                'invalid_backup_format',
              ),
            ),
          );

          expect(mockRepository.lastCalledCreateProfileId, isNull);
          verifyNever(
            () => mockFileRepository.createFolder(
              profileId: any(named: 'profileId'),
              folderName: any(named: 'folderName'),
              parentFolderId: any(named: 'parentFolderId'),
            ),
          );
        },
      );
    });
  });
}
