import 'dart:typed_data';

import 'package:affinidi_tdk_cryptography/affinidi_tdk_cryptography.dart';
import 'package:affinidi_tdk_vault/affinidi_tdk_vault.dart';
import 'package:affinidi_tdk_vault_edge_drift_provider/affinidi_tdk_vault_edge_drift_provider.dart';
import 'package:affinidi_tdk_vault_iota/affinidi_tdk_vault_iota.dart';
import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes/fake_restorable.dart';
import 'fixtures/vault_backup_consent_fixtures.dart';

Future<InMemoryVaultStore> _sourceStore() async {
  final store = InMemoryVaultStore();
  await store.setSeed(Uint8List.fromList(List.generate(32, (index) => index)));
  return store;
}

IotaConsentRecord _record(String profileId) => IotaConsentRecord(
  hash: 'consent-for-$profileId',
  requestHash: 'request-hash',
  sharedAt: '2024-01-01T00:00:00.000Z',
  profileName: 'Personal',
  profileId: profileId,
  clientId: 'did:key:verifier',
  isAutoShareEnabled: false,
  sharedVcIds: const ['vc-1'],
  claimedVcTypesCsv: 'EmailV1VC',
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() {
    drift.driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  });
  tearDownAll(() {
    drift.driftRuntimeOptions.dontWarnAboutMultipleDatabases = false;
  });

  group('When backing up and restoring consent history', () {
    test('it restores consent after its referenced profile', () async {
      final sourceDatabase = Database(NativeDatabase.memory());
      final targetDatabase = Database(NativeDatabase.memory());
      addTearDown(sourceDatabase.close);
      addTearDown(targetDatabase.close);
      final sourceStore = await _sourceStore();
      final sourceConsentValues = <String, String>{};
      final sourceConsent = VaultBackupConsentFixtures.consentStorage(
        sourceConsentValues,
      );
      final sourceVault = await Vault.fromVaultStore(
        sourceStore,
        profileRepositories: {
          'edge': VaultBackupConsentFixtures.repository(
            database: sourceDatabase,
            vaultStore: sourceStore,
          ),
        },
        namedRestorables: {'consentHistory': sourceConsent},
      );
      await sourceVault.ensureInitialized();
      final profile = await sourceVault.defaultProfileRepository.createProfile(
        name: 'Personal',
      );
      final consent = _record(profile.id);
      await sourceConsent.saveOrUpdate(consent);

      final service = VaultBackupService(
        cryptographyService: CryptographyService(),
      );
      final backup = await service.createBackup(
        vault: sourceVault,
        passphrase: 'Correct-horse-staple1',
      );
      final targetConsentValues = <String, String>{};
      final targetConsent = VaultBackupConsentFixtures.consentStorage(
        targetConsentValues,
      );
      final restored = await service.restoreBackup(
        backupData: backup,
        passphrase: 'Correct-horse-staple1',
        vaultStoreFactory: InMemoryVaultStore.new,
        repositoryFactories: {
          'edge': ProfileRepositoryRegistration.withBackupData(
            id: 'edge',
            factory: (store) => VaultBackupConsentFixtures.repository(
              database: targetDatabase,
              vaultStore: store,
            ),
            asRestorable: restorableIdentity,
          ),
        },
        namedRestorableFactories: {'consentHistory': () => targetConsent},
      );

      final restoredConsent = await targetConsent.findByRequestHash(
        consent.requestHash,
      );
      expect(restoredConsent, isNotNull);
      expect(restoredConsent!.profileId, profile.id);
      expect(
        (await restored.getProfileById(restoredConsent.profileId)).id,
        profile.id,
      );
    });

    test(
      'it rejects malformed consent before wallet or profile writes',
      () async {
        final sourceDatabase = Database(NativeDatabase.memory());
        final targetDatabase = Database(NativeDatabase.memory());
        addTearDown(sourceDatabase.close);
        addTearDown(targetDatabase.close);
        final sourceStore = await _sourceStore();
        final sourceVault = await Vault.fromVaultStore(
          sourceStore,
          profileRepositories: {
            'edge': VaultBackupConsentFixtures.repository(
              database: sourceDatabase,
              vaultStore: sourceStore,
            ),
          },
          namedRestorables: {
            'consentHistory': FakeRestorable(
              data: {
                'version': '1.0.0',
                'records': [42],
              },
            ),
          },
        );
        await sourceVault.ensureInitialized();
        await sourceVault.defaultProfileRepository.createProfile(
          name: 'Personal',
        );
        final service = VaultBackupService(
          cryptographyService: CryptographyService(),
        );
        final backup = await service.createBackup(
          vault: sourceVault,
          passphrase: 'Correct-horse-staple1',
        );
        final targetStore = InMemoryVaultStore();
        final targetConsent = VaultBackupConsentFixtures.consentStorage({});

        await expectLater(
          service.restoreBackup(
            backupData: backup,
            passphrase: 'Correct-horse-staple1',
            vaultStoreFactory: () => targetStore,
            repositoryFactories: {
              'edge': ProfileRepositoryRegistration.withBackupData(
                id: 'edge',
                factory: (store) => VaultBackupConsentFixtures.repository(
                  database: targetDatabase,
                  vaultStore: store,
                ),
                asRestorable: restorableIdentity,
              ),
            },
            namedRestorableFactories: {'consentHistory': () => targetConsent},
          ),
          throwsA(isA<TdkException>()),
        );

        expect(await targetStore.getSeed(), isNull);
        expect(
          await EdgeDriftRepositoryFactory(
            database: targetDatabase,
          ).createProfileRepository().listProfiles(),
          isEmpty,
        );
      },
    );
  });
}
