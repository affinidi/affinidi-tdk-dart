import 'dart:typed_data';

import 'package:affinidi_tdk_vault/affinidi_tdk_vault.dart';
import 'package:affinidi_tdk_vault_edge_drift_provider/affinidi_tdk_vault_edge_drift_provider.dart';
import 'package:affinidi_tdk_vault_edge_provider/affinidi_tdk_vault_edge_provider.dart';

class VaultBackupFixtures {
  static Future<InMemoryVaultStore> vaultStore() async {
    final store = InMemoryVaultStore();
    await store.setSeed(
      Uint8List.fromList(List.generate(32, (index) => index)),
    );
    return store;
  }

  static EdgeProfileRepository repository({
    required String id,
    required Database database,
    required VaultStore vaultStore,
  }) => EdgeProfileRepository(
    id,
    EdgeDriftRepositoryFactory(database: database),
    EdgeEncryptionService(vaultStore: vaultStore),
  );
}
