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
  late FlutterSecureConsentStorage store;

  const defaultNamespace = 'iota_consent';
  final hash = ConsentRecordFixtures.record().hash;
  final record = ConsentRecordFixtures.record();

  setUp(() {
    mockStorage = MockFlutterSecureStorage();
    store = FlutterSecureConsentStorage(secureStorage: mockStorage);
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
      final customStore = FlutterSecureConsentStorage(
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

    test(
      'throws TdkException with failedToReadConsentRecord when an entry is corrupt',
      () async {
          (_) async => {'${defaultNamespace}_bad': 'not valid json {{{'},
        );

        await expectLater(
          store.findByRequestHash(ConsentRecordFixtures.requestHash),
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
}
