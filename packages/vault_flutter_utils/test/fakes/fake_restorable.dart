import 'package:affinidi_tdk_vault/affinidi_tdk_vault.dart';

class FakeRestorable implements Restorable {
  FakeRestorable({required this.data});

  final Map<String, dynamic> data;

  @override
  Future<Map<String, dynamic>> export() async => data;

  @override
  Future<void> validateImport(Map<String, dynamic> data) async {}

  @override
  Future<bool> isEmpty() async => true;

  @override
  Future<void> import(Map<String, dynamic> data) async {}

  @override
  Future<void> rollbackImport() async {}
}
