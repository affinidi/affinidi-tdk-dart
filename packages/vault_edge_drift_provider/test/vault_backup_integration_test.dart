import 'dart:typed_data';

import 'package:affinidi_tdk_cryptography/affinidi_tdk_cryptography.dart';
import 'package:affinidi_tdk_vault/affinidi_tdk_vault.dart';
import 'package:affinidi_tdk_vault_edge_drift_provider/affinidi_tdk_vault_edge_drift_provider.dart';
import 'package:affinidi_tdk_vault_edge_provider/affinidi_tdk_vault_edge_provider.dart';
import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:test/test.dart';

class _CloudRepository implements ProfileRepository {
  _CloudRepository(this.id);

  @override
  final String id;

  @override
  Future<void> configure(Object configuration) async {}

  @override
  Future<bool> isConfigured() async => true;

  @override
  Future<List<Profile>> listProfiles({VaultCancelToken? cancelToken}) async =>
      const [];

  @override
  Future<Profile> createProfile({
    required String name,
    String? description,
    VaultCancelToken? cancelToken,
  }) => throw UnsupportedError('cloud test repository');

  @override
  Future<void> updateProfile(
    Profile profile, {
    VaultCancelToken? cancelToken,
  }) => throw UnsupportedError('cloud test repository');

  @override
  Future<void> deleteProfile(
    Profile profile, {
    VaultCancelToken? cancelToken,
  }) => throw UnsupportedError('cloud test repository');
}

Future<InMemoryVaultStore> _vaultStore() async {
  final store = InMemoryVaultStore();
  await store.setSeed(Uint8List.fromList(List.generate(32, (index) => index)));
  return store;
}

EdgeProfileRepository _repository({
  required String id,
  required Database database,
  required VaultStore vaultStore,
}) {
  return EdgeProfileRepository(
    id,
    EdgeDriftRepositoryFactory(database: database),
    EdgeEncryptionService(vaultStore: vaultStore),
  );
}

VerifiableCredential _credential() => UniversalParser.parse('''
{
  "@context": ["https://www.w3.org/2018/credentials/v1"],
  "id": "urn:uuid:backup-credential",
  "type": ["VerifiableCredential", "BackupCredential"],
  "issuer": "did:example:issuer",
  "issuanceDate": "2024-01-01T00:00:00Z",
  "credentialSubject": {
    "id": "did:example:subject",
    "name": "Backup Test"
  },
  "proof": {
    "type": "Ed25519Signature2018",
    "created": "2024-01-01T00:00:00Z",
    "proofPurpose": "assertionMethod",
    "verificationMethod": "did:example:issuer#key-1",
    "jws": "test-signature"
  }
}
''');

void main() {
  test(
    'rejects occupied storage and restores durable edge data into empty storage',
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

      final sourceStore = await _vaultStore();
      final sourceRepository = _repository(
        id: 'edge',
        database: sourceDatabase,
        vaultStore: sourceStore,
      );
      final sourceVault = await Vault.fromVaultStore(
        sourceStore,
        profileRepositories: {
          'edge': sourceRepository,
          'cloud': _CloudRepository('cloud'),
        },
      );
      await sourceVault.ensureInitialized();

      final profile = await sourceVault.defaultProfileRepository.createProfile(
        name: 'Local profile',
        description: 'Restored from backup',
      );
      await profile.defaultCredentialStorage!.saveCredential(
        verifiableCredential: _credential(),
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
      const passphrase = 'Correct-horse-staple1';
      final backup = await service.createBackup(
        vault: sourceVault,
        passphrase: passphrase,
      );

      final occupiedStore = await _vaultStore();
      final occupiedVault = await Vault.fromVaultStore(
        occupiedStore,
        profileRepositories: {
          'edge': _repository(
            id: 'edge',
            database: occupiedDatabase,
            vaultStore: occupiedStore,
          ),
          'cloud': _CloudRepository('cloud'),
        },
      );
      await occupiedVault.ensureInitialized();
      final destinationOnly = await occupiedVault.defaultProfileRepository
          .createProfile(name: 'Destination only');
      await destinationOnly.defaultCredentialStorage!.saveCredential(
        verifiableCredential: _credential(),
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
          passphrase: passphrase,
          vaultStoreFactory: () => rejectionStore,
          repositoryFactories: {
            'edge': (vaultStore) => _repository(
              id: 'edge',
              database: occupiedDatabase,
              vaultStore: vaultStore,
            ),
            'cloud': (_) => _CloudRepository('cloud'),
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
      final preservedRoot = await destinationOnly.defaultFileStorage!.getFolder(
        folderId: destinationOnly.id,
      );
      expect(preservedRoot.items.whereType<Folder>().single.name, 'obsolete');

      final targetStore = InMemoryVaultStore();
      Future<Vault> restore() => service.restoreBackup(
        backupData: backup,
        passphrase: passphrase,
        vaultStoreFactory: () => targetStore,
        repositoryFactories: {
          'edge': (vaultStore) => _repository(
            id: 'edge',
            database: targetDatabase,
            vaultStore: vaultStore,
          ),
          'cloud': (_) => _CloudRepository('cloud'),
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
}
