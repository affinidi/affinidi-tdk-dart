import 'package:affinidi_tdk_vault/affinidi_tdk_vault.dart';

class FakeVaultStore extends InMemoryVaultStore {
  FakeVaultStore({this.events});

  final List<String>? events;
  bool imported = false;
  bool cleared = false;

  @override
  Future<Map<String, dynamic>> export() async {
    events?.add('exportVaultStore');
    return super.export();
  }

  @override
  Future<void> import(Map<String, dynamic> data) async {
    imported = true;
    events?.add('vaultStore');
    await super.import(data);
  }

  @override
  Future<void> clear() async {
    cleared = true;
    await super.clear();
  }
}
