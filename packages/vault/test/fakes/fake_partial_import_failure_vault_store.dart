import 'dart:typed_data';

import 'package:affinidi_tdk_common/affinidi_tdk_common.dart';

import 'fake_vault_store.dart';

class FakePartialImportFailureVaultStore extends FakeVaultStore {
  FakePartialImportFailureVaultStore({super.events});

  @override
  Future<void> setContentKey(Uint8List key) {
    throw TdkException(
      message: 'secure storage failed on content key',
      code: 'secure_storage_failure',
    );
  }
}
