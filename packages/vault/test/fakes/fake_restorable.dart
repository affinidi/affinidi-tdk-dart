import 'package:affinidi_tdk_vault/affinidi_tdk_vault.dart';

class FakeRestorable implements Restorable {
  FakeRestorable({
    this.id,
    String? value,
    this.events,
    this.validationError,
    this.importError,
    this.rollbackError,
    bool isEmpty = true,
  }) : value = value ?? id ?? 'source',
       _empty = isEmpty;

  final String? id;
  String value;
  final List<String>? events;
  final Exception? validationError;
  final Exception? importError;
  final Exception? rollbackError;
  Map<String, dynamic>? importedData;
  int rollbackCalls = 0;
  bool _empty;
  bool _importPendingRollback = false;

  bool get imported => importedData != null;

  @override
  Future<Map<String, dynamic>> export() async => {
    'version': '1.0.0',
    'value': value,
  };

  @override
  Future<void> validateImport(Map<String, dynamic> data) async {
    if (validationError != null) throw validationError!;
  }

  @override
  Future<bool> isEmpty() async => _empty;

  @override
  Future<void> import(Map<String, dynamic> data) async {
    if (importError != null) throw importError!;
    _importPendingRollback = true;
    if (id != null) events?.add(id!);
    importedData = data;
    value = data['value'] as String;
    _empty = false;
  }

  @override
  Future<void> clearAllData() async {
    if (rollbackError != null) throw rollbackError!;
    if (id != null) events?.add('clear:$id');
    importedData = null;
    _empty = true;
    _importPendingRollback = false;
    rollbackCalls++;
  }

  @override
  Future<void> rollbackImport() async {
    if (!_importPendingRollback) return;
    await clearAllData();
  }
}
