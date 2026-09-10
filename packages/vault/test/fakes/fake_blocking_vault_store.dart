import 'dart:async';

import 'package:affinidi_tdk_vault/affinidi_tdk_vault.dart';

class FakeBlockingVaultStore extends InMemoryVaultStore {
  final importStarted = Completer<void>();
  final allowImport = Completer<void>();
  int importCalls = 0;

  @override
  Future<void> import(Map<String, dynamic> data) async {
    importCalls++;
    if (!importStarted.isCompleted) {
      importStarted.complete();
    }
    await allowImport.future;
    await super.import(data);
  }
}
