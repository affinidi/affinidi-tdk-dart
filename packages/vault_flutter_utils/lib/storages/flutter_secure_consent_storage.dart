import 'dart:convert';

import 'package:affinidi_tdk_vault_iota/affinidi_tdk_vault_iota.dart'
    hide TdkExceptionType;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../src/exceptions/tdk_exception_type.dart';

/// Implementation of [ConsentStorage] backed by Flutter's secure storage.
///
/// Each record is stored as a JSON string keyed by its [IotaConsentRecord.hash],
/// prefixed with a namespace to avoid collisions with other secure storage entries.
class FlutterSecureConsentStorage implements ConsentStorage {
  /// Creates a [FlutterSecureConsentStorage].
  ///
  /// Parameters:
  /// * [namespace] - Prefix applied to every storage key. Defaults to `iota_consent`.
  /// * [secureStorage] - Optional [FlutterSecureStorage] instance for testing.
  FlutterSecureConsentStorage({
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

  String _key(String hash) => '${_namespace}_$hash';

  @override
  Future<void> saveOrUpdate(IotaConsentRecord record) async {
    await _secureStorage.write(
      key: _key(record.hash),
      value: jsonEncode(record.toJson()),
    );
  }

  @override
  Future<IotaConsentRecord?> findByRequestHash(String requestHash) async {
    final all = await _secureStorage.readAll();
    final prefix = '${_namespace}_';
    for (final entry in all.entries) {
      if (!entry.key.startsWith(prefix)) continue;
      try {
        final record = IotaConsentRecord.fromJson(
          jsonDecode(entry.value) as Map<String, dynamic>,
        );
        if (record.requestHash == requestHash) return record;
      } catch (e) {
        throw TdkException(
          message: 'Failed to deserialize consent record for key "${entry.key}".',
          code: TdkExceptionType.failedToReadConsentRecord.code,
          originalMessage: e.toString(),
        );
      }
    }
    return null;
  }
}
