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
    when(() => mockStorage.readAll()).thenAnswer((_) async => {});
    when(
      () => mockStorage.delete(key: any(named: 'key')),
    ).thenAnswer((_) async {});
  });

  group('When saving or updating a consent record', () {
    test(
      'it writes the record as JSON under the namespaced hash key',
      () async {
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
      },
    );

    test('it uses a custom namespace when provided', () async {
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

  group('When finding a consent record by request hash', () {
    test('it returns null when no records exist in the namespace', () async {
      when(() => mockStorage.readAll()).thenAnswer((_) async => {});

      final result = await store.findByRequestHash(
        ConsentRecordFixtures.requestHash,
      );

      expect(result, isNull);
    });

    test('it returns the matching record when found', () async {
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

    test('it ignores entries from other namespaces', () async {
      when(() => mockStorage.readAll()).thenAnswer(
        (_) async => {'other_namespace_$hash': jsonEncode(record.toJson())},
      );

      final result = await store.findByRequestHash(
        ConsentRecordFixtures.requestHash,
      );

      expect(result, isNull);
    });

    test(
      'it throws failedToReadConsentRecord when an entry is corrupt',
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

  group('When finding all consent records by request hash', () {
    test('it returns an empty list when no records match', () async {
      when(() => mockStorage.readAll()).thenAnswer((_) async => {});

      final results = await store.findAllByRequestHash(
        ConsentRecordFixtures.requestHash,
      );

      expect(results, isEmpty);
    });

    test('it returns all matching records and ignores others', () async {
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
    });
  });

  group('When listing all consent records', () {
    test(
      'it returns all records from its namespace and ignores others',
      () async {
        final second = ConsentRecordFixtures.secondRecord();
        when(() => mockStorage.readAll()).thenAnswer(
          (_) async => {
            '${defaultNamespace}_$hash': jsonEncode(record.toJson()),
            '${defaultNamespace}_${second.hash}': jsonEncode(second.toJson()),
            'other_namespace_ignored': jsonEncode(record.toJson()),
          },
        );

        final results = await store.listAll();

        expect(results, hasLength(2));
        expect(
          results.map((r) => r.hash),
          containsAll([record.hash, second.hash]),
        );
      },
    );
  });

  group('When backing up and restoring consent records', () {
    test('it exports only records from its namespace', () async {
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

    test('it imports records through namespaced upsert keys', () async {
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

    test('it rejects and preserves destination-only records', () async {
      when(() => mockStorage.readAll()).thenAnswer(
        (_) async => {
          '${defaultNamespace}_destination-only': jsonEncode(record.toJson()),
          'other_namespace_untouched': jsonEncode(record.toJson()),
        },
      );
      when(
        () => mockStorage.write(
          key: any(named: 'key'),
          value: any(named: 'value'),
        ),
      ).thenAnswer((_) async {});

      await expectLater(
        store.import({
          'version': '1.0.0',
          'records': [record.toJson()],
        }),
        throwsA(
          isA<TdkException>().having(
            (error) => error.code,
            'code',
            'restore_destination_not_empty',
          ),
        ),
      );

      verifyNever(
        () => mockStorage.delete(key: '${defaultNamespace}_destination-only'),
      );
      verifyNever(() => mockStorage.delete(key: 'other_namespace_untouched'));
      verifyNever(
        () => mockStorage.write(
          key: '${defaultNamespace}_${record.hash}',
          value: jsonEncode(record.toJson()),
        ),
      );
    });

    test('it rejects re-import after the first import', () async {
      var stored = false;
      when(() => mockStorage.readAll()).thenAnswer(
        (_) async => stored
            ? {
                '${defaultNamespace}_${record.hash}': jsonEncode(
                  record.toJson(),
                ),
              }
            : {},
      );
      when(
        () => mockStorage.write(
          key: any(named: 'key'),
          value: any(named: 'value'),
        ),
      ).thenAnswer((_) async => stored = true);
      final payload = {
        'version': '1.0.0',
        'records': [record.toJson()],
      };

      await store.import(payload);
      await expectLater(
        store.import(payload),
        throwsA(
          isA<TdkException>().having(
            (error) => error.code,
            'code',
            'restore_destination_not_empty',
          ),
        ),
      );

      verify(
        () => mockStorage.write(
          key: '${defaultNamespace}_${record.hash}',
          value: jsonEncode(record.toJson()),
        ),
      ).called(1);
    });

    test('it rejects malformed records before any write', () async {
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

    test('it rejects unsupported versions before any write', () async {
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
