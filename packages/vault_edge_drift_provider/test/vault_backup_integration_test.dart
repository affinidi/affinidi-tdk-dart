import 'dart:convert';
import 'dart:typed_data';

import 'package:affinidi_tdk_cryptography/affinidi_tdk_cryptography.dart';
import 'package:affinidi_tdk_vault/affinidi_tdk_vault.dart';
import 'package:affinidi_tdk_vault_edge_drift_provider/affinidi_tdk_vault_edge_drift_provider.dart';
import 'package:affinidi_tdk_vault_edge_provider/affinidi_tdk_vault_edge_provider.dart';
import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:test/test.dart';

import 'fakes/fake_cloud_repository.dart';
import 'fixtures/credential_fixtures.dart';
import 'fixtures/vault_backup_fixtures.dart';

/// A fresh buffer per call, because PBKDF2 wipes the passphrase it is given.
Uint8List _passphrase() =>
    Uint8List.fromList(utf8.encode('Correct-horse-staple1'));

void main() {
  group('When backing up and restoring durable edge data', () {
    test(
      'it rejects occupied storage and restores into empty storage',
      () async {
        drift.driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
        addTearDown(() {
          drift.driftRuntimeOptions.dontWarnAboutMultipleDatabases = false;
        });
        final sourceDatabase = Database(NativeDatabase.memory());
        final occupiedDatabase = Database(NativeDatabase.memory());
        final targetDatabase = Database(NativeDatabase.memory());
        addTearDown(sourceDatabase.close);
        addTearDown(occupiedDatabase.close);
        addTearDown(targetDatabase.close);

        final sourceStore = await VaultBackupFixtures.vaultStore();
        final sourceRepository = VaultBackupFixtures.repository(
          id: 'edge',
          database: sourceDatabase,
          vaultStore: sourceStore,
        );
        final sourceVault = await Vault.fromVaultStore(
          sourceStore,
          profileRepositories: {
            'edge': sourceRepository,
            'cloud': FakeCloudRepository('cloud'),
          },
        );
        await sourceVault.ensureInitialized();

        final profile = await sourceVault.defaultProfileRepository
            .createProfile(
              name: 'Local profile',
              description: 'Restored from backup',
            );
        await profile.defaultCredentialStorage!.saveCredential(
          verifiableCredential: CredentialFixtures.backupCredential(),
        );
        final folder = await profile.defaultFileStorage!.createFolder(
          folderName: 'documents',
          parentFolderId: profile.id,
        );
        final fileContent = Uint8List.fromList([1, 3, 3, 7]);
        await profile.defaultFileStorage!.createFile(
          fileName: 'backup.txt',
          data: fileContent,
          parentFolderId: folder.id,
        );

        final service = VaultBackupService(
          cryptographyService: CryptographyService(),
        );
        final backup = await service.createBackup(
          vault: sourceVault,
          passphrase: _passphrase(),
        );

        final occupiedStore = await VaultBackupFixtures.vaultStore();
        final occupiedVault = await Vault.fromVaultStore(
          occupiedStore,
          profileRepositories: {
            'edge': VaultBackupFixtures.repository(
              id: 'edge',
              database: occupiedDatabase,
              vaultStore: occupiedStore,
            ),
            'cloud': FakeCloudRepository('cloud'),
          },
        );
        await occupiedVault.ensureInitialized();
        final destinationOnly = await occupiedVault.defaultProfileRepository
            .createProfile(name: 'Destination only');
        await destinationOnly.defaultCredentialStorage!.saveCredential(
          verifiableCredential: CredentialFixtures.backupCredential(),
        );
        final obsoleteFolder = await destinationOnly.defaultFileStorage!
            .createFolder(
              folderName: 'obsolete',
              parentFolderId: destinationOnly.id,
            );
        await destinationOnly.defaultFileStorage!.createFile(
          fileName: 'obsolete.txt',
          data: Uint8List.fromList([9, 9, 9]),
          parentFolderId: obsoleteFolder.id,
        );

        final rejectionStore = InMemoryVaultStore();
        await expectLater(
          service.restoreBackup(
            backupData: backup,
            passphrase: _passphrase(),
            vaultStoreFactory: () => rejectionStore,
            repositoryFactories: {
              'edge': ProfileRepositoryRegistration.withBackupData(
                id: 'edge',
                factory: (vaultStore) => VaultBackupFixtures.repository(
                  id: 'edge',
                  database: occupiedDatabase,
                  vaultStore: vaultStore,
                ),
                asRestorable: restorableIdentity,
              ),
              'cloud': ProfileRepositoryRegistration.withoutBackupData(
                id: 'cloud',
                factory: (_) => FakeCloudRepository('cloud'),
              ),
            },
          ),
          throwsA(
            isA<TdkException>().having(
              (error) => error.code,
              'code',
              'restore_destination_not_empty',
            ),
          ),
        );
        expect(await rejectionStore.getSeed(), isNull);
        final preservedProfiles = await occupiedVault.listProfiles();
        expect(preservedProfiles.map((profile) => profile.id), [
          destinationOnly.id,
        ]);
        final preservedRoot = await destinationOnly.defaultFileStorage!
            .getFolder(folderId: destinationOnly.id);
        expect(preservedRoot.items.whereType<Folder>().single.name, 'obsolete');

        final targetStore = InMemoryVaultStore();
        Future<Vault> restore() => service.restoreBackup(
          backupData: backup,
          passphrase: _passphrase(),
          vaultStoreFactory: () => targetStore,
          repositoryFactories: {
            'edge': ProfileRepositoryRegistration.withBackupData(
              id: 'edge',
              factory: (vaultStore) => VaultBackupFixtures.repository(
                id: 'edge',
                database: targetDatabase,
                vaultStore: vaultStore,
              ),
              asRestorable: restorableIdentity,
            ),
            'cloud': ProfileRepositoryRegistration.withoutBackupData(
              id: 'cloud',
              factory: (_) => FakeCloudRepository('cloud'),
            ),
          },
        );

        final restoredVault = await restore();
        await expectLater(
          restore(),
          throwsA(
            isA<TdkException>().having(
              (error) => error.code,
              'code',
              'restore_destination_not_empty',
            ),
          ),
        );
        final restoredProfiles = await restoredVault.listProfiles();

        expect(
          restoredVault.profileRepositories.keys,
          containsAll(['edge', 'cloud']),
        );
        expect(restoredProfiles, hasLength(1));
        final restoredProfile = restoredProfiles.single;
        expect(restoredProfile.id, profile.id);
        expect(restoredProfile.accountIndex, profile.accountIndex);
        expect(restoredProfile.did, profile.did);
        expect(restoredProfile.name, profile.name);
        expect(restoredProfile.description, profile.description);

        final credentials = await restoredProfile.defaultCredentialStorage!
            .listCredentials();
        expect(credentials.items, hasLength(1));
        expect(
          credentials.items.single.verifiableCredential.id?.toString(),
          'urn:uuid:backup-credential',
        );

        final root = await restoredProfile.defaultFileStorage!.getFolder(
          folderId: restoredProfile.id,
        );
        final restoredFolder = root.items.whereType<Folder>().single;
        expect(restoredFolder.name, 'documents');
        final children = await restoredProfile.defaultFileStorage!.getFolder(
          folderId: restoredFolder.id,
        );
        final restoredFile = children.items.whereType<File>().single;
        expect(restoredFile.name, 'backup.txt');
        expect(
          await restoredProfile.defaultFileStorage!.getFileContent(
            fileId: restoredFile.id,
          ),
          fileContent,
        );
      },
    );

    test(
      'it isolates colliding repository IDs and restores the default repository',
      () async {
        drift.driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
        addTearDown(() {
          drift.driftRuntimeOptions.dontWarnAboutMultipleDatabases = false;
        });
        final sourceDatabaseA = Database(NativeDatabase.memory());
        final sourceDatabaseB = Database(NativeDatabase.memory());
        final targetDatabaseA = Database(NativeDatabase.memory());
        final targetDatabaseB = Database(NativeDatabase.memory());
        addTearDown(sourceDatabaseA.close);
        addTearDown(sourceDatabaseB.close);
        addTearDown(targetDatabaseA.close);
        addTearDown(targetDatabaseB.close);

        const profileId = 'shared-profile-id';
        const accountIndex = 1;
        const credentialStorageId = 'shared-credential-id';
        final sourceStore = await VaultBackupFixtures.vaultStore();
        await sourceStore.setAccountIndex(accountIndex);
        final factoryA = EdgeDriftRepositoryFactory(database: sourceDatabaseA);
        final factoryB = EdgeDriftRepositoryFactory(database: sourceDatabaseB);
        await factoryA.createProfileRepository().createProfile(
          id: profileId,
          name: 'Repository A',
          accountIndex: accountIndex,
        );
        await factoryB.createProfileRepository().createProfile(
          id: profileId,
          name: 'Repository B',
          accountIndex: accountIndex,
        );

        final encryption = EdgeEncryptionService(vaultStore: sourceStore);
        final codec = CredentialCodec();
        final credentialA = CredentialFixtures.backupCredential(
          id: 'urn:uuid:credential-a',
          type: 'RepositoryACredential',
          name: 'A',
        );
        final credentialB = CredentialFixtures.backupCredential(
          id: 'urn:uuid:credential-b',
          type: 'RepositoryBCredential',
          name: 'B',
        );
        await factoryA
            .createCredentialRepository(profileId: profileId)
            .saveCredentialData(
              profileId: profileId,
              credentialId: credentialStorageId,
              credentialName: 'RepositoryACredential',
              credentialContent: await encryption.encryptData(
                codec.encode(credentialA),
              ),
            );
        await factoryB
            .createCredentialRepository(profileId: profileId)
            .saveCredentialData(
              profileId: profileId,
              credentialId: credentialStorageId,
              credentialName: 'RepositoryBCredential',
              credentialContent: await encryption.encryptData(
                codec.encode(credentialB),
              ),
            );

        final repositoryA = EdgeProfileRepository(
          'edge-a',
          factoryA,
          encryption,
        );
        final repositoryB = EdgeProfileRepository(
          'edge-b',
          factoryB,
          encryption,
        );
        final sourceVault = await Vault.fromVaultStore(
          sourceStore,
          profileRepositories: {'edge-a': repositoryA, 'edge-b': repositoryB},
          defaultProfileRepositoryId: 'edge-b',
        );
        await sourceVault.ensureInitialized();
        final profileA = (await repositoryA.listProfiles()).single;
        final profileB = (await repositoryB.listProfiles()).single;
        expect(profileA.did, profileB.did);

        for (final entry in <(Profile, Uint8List)>[
          (profileA, Uint8List.fromList([1, 1, 1])),
          (profileB, Uint8List.fromList([2, 2, 2])),
        ]) {
          final folder = await entry.$1.defaultFileStorage!.createFolder(
            folderName: 'documents',
            parentFolderId: profileId,
          );
          await entry.$1.defaultFileStorage!.createFile(
            fileName: 'same-name.txt',
            data: entry.$2,
            parentFolderId: folder.id,
          );
        }

        final service = VaultBackupService(
          cryptographyService: CryptographyService(),
        );
        final backup = await service.createBackup(
          vault: sourceVault,
          passphrase: _passphrase(),
        );
        final targetStore = InMemoryVaultStore();
        final restored = await service.restoreBackup(
          backupData: backup,
          passphrase: _passphrase(),
          vaultStoreFactory: () => targetStore,
          repositoryFactories: {
            'edge-a': ProfileRepositoryRegistration.withBackupData(
              id: 'edge-a',
              factory: (store) => VaultBackupFixtures.repository(
                id: 'edge-a',
                database: targetDatabaseA,
                vaultStore: store,
              ),
              asRestorable: restorableIdentity,
            ),
            'edge-b': ProfileRepositoryRegistration.withBackupData(
              id: 'edge-b',
              factory: (store) => VaultBackupFixtures.repository(
                id: 'edge-b',
                database: targetDatabaseB,
                vaultStore: store,
              ),
              asRestorable: restorableIdentity,
            ),
          },
        );

        expect(restored.defaultProfileRepository.id, 'edge-b');
        final restoredA =
            (await restored.profileRepositories['edge-a']!.listProfiles())
                .single;
        final restoredB =
            (await restored.profileRepositories['edge-b']!.listProfiles())
                .single;
        expect(restoredA.id, profileId);
        expect(restoredB.id, profileId);
        expect(restoredA.accountIndex, accountIndex);
        expect(restoredB.accountIndex, accountIndex);
        expect(restoredA.did, restoredB.did);

        Future<(String, String, Uint8List)> restoredContent(
          Profile profile,
        ) async {
          final credentials = await profile.defaultCredentialStorage!
              .listCredentials();
          final root = await profile.defaultFileStorage!.getFolder(
            folderId: profileId,
          );
          final folder = root.items.whereType<Folder>().single;
          final children = await profile.defaultFileStorage!.getFolder(
            folderId: folder.id,
          );
          final file = children.items.whereType<File>().single;
          return (
            credentials.items.single.id,
            credentials.items.single.verifiableCredential.id.toString(),
            await profile.defaultFileStorage!.getFileContent(fileId: file.id),
          );
        }

        final contentA = await restoredContent(restoredA);
        final contentB = await restoredContent(restoredB);
        expect(contentA.$1, credentialStorageId);
        expect(contentB.$1, credentialStorageId);
        expect(contentA.$2, 'urn:uuid:credential-a');
        expect(contentB.$2, 'urn:uuid:credential-b');
        expect(contentA.$3, orderedEquals([1, 1, 1]));
        expect(contentB.$3, orderedEquals([2, 2, 2]));
      },
    );
  });
}
