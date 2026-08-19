import 'dart:convert';

import 'package:affinidi_tdk_vault_flutter_utils/vault_flutter_utils.dart';
import 'package:affinidi_tdk_vault_iota/affinidi_tdk_vault_iota.dart'
    show TdkException;
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
        when(() => mockStorage.readAll()).thenAnswer(
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

  group('findAllByRequestHash', () {
    test('returns an empty list when no records match', () async {
      when(() => mockStorage.readAll()).thenAnswer((_) async => {});

      final results = await store.findAllByRequestHash(
        ConsentRecordFixtures.requestHash,
      );

      expect(results, isEmpty);
    });

    test(
      'returns all records matching requestHash and ignores others',
      () async {
        final second = ConsentRecordFixtures.secondRecord();
        final unrelated = ConsentRecordFixtures.record().copyWith(
          hash: 'other-hash',
          requestHash: 'different-request-hash',
        );
        when(() => mockStorage.readAll()).thenAnswer(
          (_) async => {
            '${defaultNamespace}_$hash': jsonEncode(record.toJson()),
            '${defaultNamespace}_${second.hash}': jsonEncode(second.toJson()),
            '${defaultNamespace}_other-hash': jsonEncode(unrelated.toJson()),
          },
        );

        final results = await store.findAllByRequestHash(
          ConsentRecordFixtures.requestHash,
        );

        expect(results, hasLength(2));
        expect(
          results.map((r) => r.hash),
          containsAll([record.hash, second.hash]),
        );
      },
    );
  });

  group('backup and restore', () {
    test('exports only records from its namespace', () async {
      final second = ConsentRecordFixtures.secondRecord();
      when(() => mockStorage.readAll()).thenAnswer(
        (_) async => {
          '${defaultNamespace}_$hash': jsonEncode(record.toJson()),
          '${defaultNamespace}_${second.hash}': jsonEncode(second.toJson()),
          'other_namespace_ignored': jsonEncode(record.toJson()),
        },
      );

      final exported = await store.export();

      expect(exported, {
        'version': '1.0.0',
        'records': [record.toJson(), second.toJson()],
      });
    });

    test('imports records through namespaced upsert keys', () async {
      final second = ConsentRecordFixtures.secondRecord();
      when(
        () => mockStorage.write(
          key: any(named: 'key'),
          value: any(named: 'value'),
        ),
      ).thenAnswer((_) async {});

      await store.import({
        'version': '1.0.0',
        'records': [record.toJson(), second.toJson()],
      });

      verify(
        () => mockStorage.write(
          key: '${defaultNamespace}_${record.hash}',
          value: jsonEncode(record.toJson()),
        ),
      ).called(1);
      verify(
        () => mockStorage.write(
          key: '${defaultNamespace}_${second.hash}',
          value: jsonEncode(second.toJson()),
        ),
      ).called(1);
    });

    test(
      're-import updates the same key instead of creating another key',
      () async {
        when(
          () => mockStorage.write(
            key: any(named: 'key'),
            value: any(named: 'value'),
          ),
        ).thenAnswer((_) async {});
        final payload = {
          'version': '1.0.0',
          'records': [record.toJson()],
        };

        await store.import(payload);
        await store.import(payload);

        verify(
          () => mockStorage.write(
            key: '${defaultNamespace}_${record.hash}',
            value: jsonEncode(record.toJson()),
          ),
        ).called(2);
      },
    );

    test('rejects malformed records before any write', () async {
      await expectLater(
        store.import(const {
          'version': '1.0.0',
          'records': [42],
        }),
        throwsA(
          isA<TdkException>().having(
            (error) => error.code,
            'code',
            'invalid_backup_format',
          ),
        ),
      );

      verifyNever(
        () => mockStorage.write(
          key: any(named: 'key'),
          value: any(named: 'value'),
        ),
      );
    });

    test('rejects unsupported versions before any write', () async {
      await expectLater(
        store.validateImport(const {
          'version': '2.0.0',
          'records': <dynamic>[],
        }),
        throwsA(
          isA<TdkException>().having(
            (error) => error.code,
            'code',
            'invalid_backup_format',
          ),
        ),
      );

      verifyNever(
        () => mockStorage.write(
          key: any(named: 'key'),
          value: any(named: 'value'),
        ),
      );
    });
  });
}
