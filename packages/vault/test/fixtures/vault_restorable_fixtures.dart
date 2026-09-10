import 'dart:typed_data';

import 'package:affinidi_tdk_vault/affinidi_tdk_vault.dart';

import '../fakes/fake_vault_store.dart';

class VaultRestorableFixtures {
  static Future<FakeVaultStore> store(
    List<String> events, {
    int seedOffset = 0,
  }) async {
    final store = FakeVaultStore(events: events);
    await store.setSeed(
      Uint8List.fromList(List.generate(32, (index) => index + seedOffset)),
    );
    await store.setAccountIndex(3);
    return store;
  }

  static Future<Vault> vault({
    required FakeVaultStore store,
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
