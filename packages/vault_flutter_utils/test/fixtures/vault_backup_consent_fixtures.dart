import 'dart:typed_data';

import 'package:affinidi_tdk_vault/affinidi_tdk_vault.dart';
import 'package:affinidi_tdk_vault_edge_drift_provider/affinidi_tdk_vault_edge_drift_provider.dart';
import 'package:affinidi_tdk_vault_edge_provider/affinidi_tdk_vault_edge_provider.dart';
import 'package:affinidi_tdk_vault_flutter_utils/vault_flutter_utils.dart';
import 'package:affinidi_tdk_vault_iota/affinidi_tdk_vault_iota.dart';

import '../fakes/fake_flutter_secure_storage.dart';

abstract final class VaultBackupConsentFixtures {
  static Future<InMemoryVaultStore> sourceStore() async {
    final store = InMemoryVaultStore();
    await store.setSeed(
      Uint8List.fromList(List.generate(32, (index) => index)),
    );
    return store;
  }

  static IotaConsentRecord record(String profileId) => IotaConsentRecord(
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

  static EdgeProfileRepository repository({
    required Database database,
    required VaultStore vaultStore,
  }) => EdgeProfileRepository(
    'edge',
    EdgeDriftRepositoryFactory(database: database),
    EdgeEncryptionService(vaultStore: vaultStore),
  );

  static FlutterSecureConsentStorage consentStorage(
    Map<String, String> values,
  ) => FlutterSecureConsentStorage(
    secureStorage: FakeFlutterSecureStorage(values),
  );
}
