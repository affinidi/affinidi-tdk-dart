import 'dart:typed_data';

import 'package:affinidi_tdk_vault/affinidi_tdk_vault.dart';

class VaultBackupServiceFixtures {
  static Future<InMemoryVaultStore> store() async {
    final store = InMemoryVaultStore();
    await store.setSeed(
      Uint8List.fromList(List.generate(32, (index) => index)),
    );
    await store.setAccountIndex(4);
    return store;
  }

  static Future<Vault> vault({
    required VaultStore store,
    required Map<String, ProfileRepository> repositories,
    Map<String, Restorable> named = const {},
  }) async {
    final vault = await Vault.fromVaultStore(
      store,
      profileRepositories: repositories,
      namedRestorables: named,
    );
    await vault.ensureInitialized();
    return vault;
  }
}
