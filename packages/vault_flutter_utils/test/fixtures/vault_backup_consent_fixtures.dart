import 'package:affinidi_tdk_vault/affinidi_tdk_vault.dart';
import 'package:affinidi_tdk_vault_edge_drift_provider/affinidi_tdk_vault_edge_drift_provider.dart';
import 'package:affinidi_tdk_vault_edge_provider/affinidi_tdk_vault_edge_provider.dart';
import 'package:affinidi_tdk_vault_flutter_utils/vault_flutter_utils.dart';

import '../fakes/fake_flutter_secure_storage.dart';

abstract final class VaultBackupConsentFixtures {
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
