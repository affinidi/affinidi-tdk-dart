import 'dart:convert';

import 'package:affinidi_tdk_vault_iota/affinidi_tdk_vault_iota.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Implementation of [ConsentRecordStore] backed by Flutter's secure storage.
///
/// Each record is stored as a JSON string keyed by its [IotaConsentRecord.requestHash],
/// prefixed with a namespace to avoid collisions with other secure storage entries.
///
/// Parameters:
/// * [namespace] - Prefix applied to every storage key. Defaults to `iota_consent`.
/// * [secureStorage] - Optional [FlutterSecureStorage] instance for testing.
class FlutterSecureConsentRecordStore implements ConsentRecordStore {
  FlutterSecureConsentRecordStore({
    String namespace = 'iota_consent',
    FlutterSecureStorage? secureStorage,
  }) : _namespace = namespace,
       _secureStorage =
           secureStorage ??
           const FlutterSecureStorage(
             aOptions: AndroidOptions(),
             iOptions: IOSOptions(
               accessibility: KeychainAccessibility.unlocked_this_device,
             ),
           );

  final String _namespace;
  final FlutterSecureStorage _secureStorage;

  String _key(String requestHash) => '${_namespace}_$requestHash';

  @override
  Future<void> saveOrUpdate(IotaConsentRecord record) async {
    await _secureStorage.write(
      key: _key(record.requestHash),
      value: jsonEncode(record.toJson()),
    );
  }

  @override
  Future<IotaConsentRecord?> findByRequestHash(String requestHash) async {
    final data = await _secureStorage.read(key: _key(requestHash));
    if (data == null) return null;
    return IotaConsentRecord.fromJson(jsonDecode(data) as Map<String, dynamic>);
  }
}
