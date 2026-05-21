import 'dart:convert';

import 'package:affinidi_tdk_vault_flutter_utils/vault_flutter_utils.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'fixtures/consent_record_fixtures.dart';

class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockFlutterSecureStorage mockStorage;
  late FlutterSecureConsentRecordStore store;

  const defaultNamespace = 'iota_consent';
  final hash = ConsentRecordFixtures.record().hash;
  final record = ConsentRecordFixtures.record();

  setUp(() {
    mockStorage = MockFlutterSecureStorage();
    store = FlutterSecureConsentRecordStore(secureStorage: mockStorage);
  });

  group('saveOrUpdate', () {
    test('writes the record as JSON under the namespaced hash key', () async {
      when(
        () => mockStorage.write(
          key: any(named: 'key'),
          value: any(named: 'value'),
        ),
      ).thenAnswer((_) async {});

      await store.saveOrUpdate(record);

      verify(
        () => mockStorage.write(
          key: '${defaultNamespace}_$hash',
          value: jsonEncode(record.toJson()),
        ),
      ).called(1);
    });

    test('uses a custom namespace when provided', () async {
      const customNamespace = 'my_app_consent';
      final customStore = FlutterSecureConsentRecordStore(
        namespace: customNamespace,
        secureStorage: mockStorage,
      );

      when(
        () => mockStorage.write(
          key: any(named: 'key'),
          value: any(named: 'value'),
        ),
      ).thenAnswer((_) async {});

      await customStore.saveOrUpdate(record);

      verify(
        () => mockStorage.write(
          key: '${customNamespace}_$hash',
          value: any(named: 'value'),
        ),
      ).called(1);
    });
  });

  group('findByHash', () {
    test('returns null when no record exists for the given key', () async {
      when(
        () => mockStorage.read(key: '${defaultNamespace}_$hash'),
      ).thenAnswer((_) async => null);

      final result = await store.findByHash(hash);

      expect(result, isNull);
    });

    test('deserializes and returns the record when found', () async {
      when(
        () => mockStorage.read(key: '${defaultNamespace}_$hash'),
      ).thenAnswer((_) async => jsonEncode(record.toJson()));

      final result = await store.findByHash(hash);

      expect(result, isNotNull);
      expect(result!.hash, hash);
      expect(result.clientId, record.clientId);
      expect(result.profileName, record.profileName);
      expect(result.sharedVcIds, record.sharedVcIds);
      expect(result.isAutoShareEnabled, record.isAutoShareEnabled);
    });
  });

  group('findByRequestHash', () {
    test('returns null when no records exist in the namespace', () async {
      when(() => mockStorage.readAll()).thenAnswer((_) async => {});

      final result = await store.findByRequestHash(
        ConsentRecordFixtures.requestHash,
      );

      expect(result, isNull);
    });

    test('returns the record matching requestHash when found', () async {
      when(() => mockStorage.readAll()).thenAnswer(
        (_) async => {'${defaultNamespace}_$hash': jsonEncode(record.toJson())},
      );

      final result = await store.findByRequestHash(
        ConsentRecordFixtures.requestHash,
      );

      expect(result, isNotNull);
      expect(result!.requestHash, ConsentRecordFixtures.requestHash);
      expect(result.clientId, record.clientId);
    });

    test('ignores entries from other namespaces', () async {
      when(() => mockStorage.readAll()).thenAnswer(
        (_) async => {'other_namespace_$hash': jsonEncode(record.toJson())},
      );

      final result = await store.findByRequestHash(
        ConsentRecordFixtures.requestHash,
      );

      expect(result, isNull);
    });
  });
}
