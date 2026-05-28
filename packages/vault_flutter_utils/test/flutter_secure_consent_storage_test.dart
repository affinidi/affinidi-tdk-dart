import 'dart:convert';

import 'package:affinidi_tdk_vault_iota/affinidi_tdk_vault_iota.dart'
    hide TdkExceptionType;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../src/exceptions/tdk_exception_type.dart';
import 'fixtures/consent_record_fixtures.dart';

class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}

/// Implementation of [ConsentStorage] backed by Flutter's secure storage.
///
/// Each record is stored as a JSON string keyed by its [IotaConsentRecord.hash],
/// prefixed with `namespace` to avoid collisions with other secure-storage entries.
///
/// This implementation mirrors the `FlutterSecureConsentRecordStore` that will be
/// shipped in a future version of `affinidi_tdk_vault_flutter_utils`.
class FlutterSecureConsentRecordStore implements ConsentStorage {
  /// Creates a [FlutterSecureConsentRecordStore].
  ///
  /// Parameters:
  /// * [namespace] - Prefix applied to every storage key. Defaults to `iota_consent`.
  /// * [secureStorage] - Optional [FlutterSecureStorage] instance for testing.
  FlutterSecureConsentRecordStore({
    String namespace = 'iota_consent',
    FlutterSecureStorage? secureStorage,
  })  : _namespace = namespace,
        _secureStorage = secureStorage ??
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
          message:
              'Failed to deserialize consent record for key "${entry.key}".',
          code: TdkExceptionType.failedToReadConsentRecord.code,
          originalMessage: e.toString(),
        );
      }
    }
    return null;
  }

  /// Returns all stored consent records across all profiles.
  Future<List<IotaConsentRecord>> listAll() async {
    final all = await _secureStorage.readAll();
    final prefix = '${_namespace}_';
    final records = <IotaConsentRecord>[];
    for (final entry in all.entries) {
      if (!entry.key.startsWith(prefix)) continue;
      try {
        records.add(
          IotaConsentRecord.fromJson(
            jsonDecode(entry.value) as Map<String, dynamic>,
          ),
        );
      } catch (_) {
        continue;
      }
    }
    return records;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockFlutterSecureStorage mockStorage;
  late FlutterSecureConsentRecordStore store;

  const defaultNamespace = 'iota_consent';

  setUp(() {
    mockStorage = MockFlutterSecureStorage();
    store = FlutterSecureConsentRecordStore(
      namespace: defaultNamespace,
      secureStorage: mockStorage,
    );
  });

  group('FlutterSecureConsentRecordStore', () {
    group('findByRequestHash', () {
      test(
        'throws TdkException with failedToReadConsentRecord when an entry is corrupt',
        () async {
          when(() => mockStorage.readAll()).thenAnswer(
            (_) async => {'${defaultNamespace}_bad': 'not valid json {{{'},
          );

          await expectLater(
            () => store.findByRequestHash(ConsentRecordFixtures.requestHash),
            throwsA(
              isA<TdkException>().having(
                (e) => e.code,
                'code',
                TdkExceptionType.failedToReadConsentRecord.code,
              ),
            ),
          );
        },
      );
    });
  });
}
