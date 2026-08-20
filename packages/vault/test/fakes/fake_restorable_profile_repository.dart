import 'package:affinidi_tdk_vault/affinidi_tdk_vault.dart';

import 'fake_profile_repository.dart';

class FakeRestorableProfileRepository extends FakeProfileRepository
    implements Restorable {
  FakeRestorableProfileRepository(
    super.id, {
    this.value = 'source',
    this.events,
  });

  String value;
  final List<String>? events;
  Map<String, dynamic>? importedData;
  int rollbackCalls = 0;
  bool _empty = true;
  bool _importPendingRollback = false;

  bool get imported => importedData != null;

  @override
  Future<Map<String, dynamic>> export() async => {
    'version': '1.0.0',
    'value': value,
  };

  @override
  Future<void> validateImport(Map<String, dynamic> data) async {}

  @override
  Future<bool> isEmpty() async => _empty;

  @override
  Future<void> import(Map<String, dynamic> data) async {
    _importPendingRollback = true;
    events?.add(id);
    importedData = data;
    value = data['value'] as String;
    _empty = false;
  }

  @override
  Future<void> rollbackImport() async {
    if (!_importPendingRollback) return;
    importedData = null;
    _empty = true;
    _importPendingRollback = false;
    rollbackCalls++;
  }
}
