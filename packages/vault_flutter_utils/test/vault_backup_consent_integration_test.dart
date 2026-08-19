import 'dart:typed_data';

import 'package:affinidi_tdk_cryptography/affinidi_tdk_cryptography.dart';
import 'package:affinidi_tdk_vault/affinidi_tdk_vault.dart';
import 'package:affinidi_tdk_vault_edge_drift_provider/affinidi_tdk_vault_edge_drift_provider.dart';
import 'package:affinidi_tdk_vault_edge_provider/affinidi_tdk_vault_edge_provider.dart';
import 'package:affinidi_tdk_vault_flutter_utils/vault_flutter_utils.dart';
import 'package:affinidi_tdk_vault_iota/affinidi_tdk_vault_iota.dart';
import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _SecureStorage extends Mock implements FlutterSecureStorage {}

class _MalformedConsent implements Restorable {
  @override
  Future<Map<String, dynamic>> export() async => {
    'version': '1.0.0',
    'records': [42],
  };

  @override
  Future<void> validateImport(Map<String, dynamic> data) async {}

  @override
  Future<bool> isEmpty() async => true;

  @override
  Future<void> import(Map<String, dynamic> data) async {}
}

Future<InMemoryVaultStore> _sourceStore() async {
  final store = InMemoryVaultStore();
  await store.setSeed(Uint8List.fromList(List.generate(32, (index) => index)));
  return store;
}

EdgeProfileRepository _repository({
  required Database database,
  required VaultStore vaultStore,
}) => EdgeProfileRepository(
  'edge',
  EdgeDriftRepositoryFactory(database: database),
  EdgeEncryptionService(vaultStore: vaultStore),
);

FlutterSecureConsentStorage _consentStorage(Map<String, String> values) {
  final secureStorage = _SecureStorage();
  when(secureStorage.readAll).thenAnswer((_) async => Map.of(values));
  when(
    () => secureStorage.write(
      key: any(named: 'key'),
      value: any(named: 'value'),
    ),
  ).thenAnswer((invocation) async {
    final key = invocation.namedArguments[#key] as String;
    final value = invocation.namedArguments[#value] as String;
    values[key] = value;
  });
  return FlutterSecureConsentStorage(secureStorage: secureStorage);
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

  test('restores consent after its referenced profile', () async {
    final sourceDatabase = Database(NativeDatabase.memory());
    final targetDatabase = Database(NativeDatabase.memory());
    addTearDown(sourceDatabase.close);
    addTearDown(targetDatabase.close);
    final sourceStore = await _sourceStore();
    final sourceConsentValues = <String, String>{};
    final sourceConsent = _consentStorage(sourceConsentValues);
    final sourceVault = await Vault.fromVaultStore(
      sourceStore,
      profileRepositories: {
        'edge': _repository(database: sourceDatabase, vaultStore: sourceStore),
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
    final targetConsent = _consentStorage(targetConsentValues);
    final restored = await service.restoreBackup(
      backupData: backup,
      passphrase: 'Correct-horse-staple1',
      vaultStoreFactory: InMemoryVaultStore.new,
      repositoryFactories: {
        'edge': (store) =>
            _repository(database: targetDatabase, vaultStore: store),
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

  test('malformed consent fails before wallet or profile writes', () async {
    final sourceDatabase = Database(NativeDatabase.memory());
    final targetDatabase = Database(NativeDatabase.memory());
    addTearDown(sourceDatabase.close);
    addTearDown(targetDatabase.close);
    final sourceStore = await _sourceStore();
    final sourceVault = await Vault.fromVaultStore(
      sourceStore,
      profileRepositories: {
        'edge': _repository(database: sourceDatabase, vaultStore: sourceStore),
      },
      namedRestorables: {'consentHistory': _MalformedConsent()},
    );
    await sourceVault.ensureInitialized();
    await sourceVault.defaultProfileRepository.createProfile(name: 'Personal');
    final service = VaultBackupService(
      cryptographyService: CryptographyService(),
    );
    final backup = await service.createBackup(
      vault: sourceVault,
      passphrase: 'Correct-horse-staple1',
    );
    final targetStore = InMemoryVaultStore();
    final targetConsent = _consentStorage(<String, String>{});

    await expectLater(
      service.restoreBackup(
        backupData: backup,
        passphrase: 'Correct-horse-staple1',
        vaultStoreFactory: () => targetStore,
        repositoryFactories: {
          'edge': (store) =>
              _repository(database: targetDatabase, vaultStore: store),
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
  });
}
