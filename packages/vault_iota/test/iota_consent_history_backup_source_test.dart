import 'package:affinidi_tdk_vault_iota/affinidi_tdk_vault_iota.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class _MockEnumerableConsentStorage extends Mock
    implements EnumerableConsentStorage {}

IotaConsentRecord _record(String hash) => IotaConsentRecord(
  hash: hash,
  requestHash: 'req-$hash',
  sharedAt: '2024-01-01T00:00:00.000Z',
  profileName: 'Profile',
  profileId: 'p-1',
  clientId: 'did:key:verifier',
  isAutoShareEnabled: true,
  sharedVcIds: const ['vc-1'],
  claimedVcTypesCsv: 'TypeA',
);

void main() {
  group('IotaConsentHistoryBackupSource', () {
    late _MockEnumerableConsentStorage storage;

    final invalidBackupFormat = isA<TdkException>().having(
      (e) => e.code,
      'code',
      equals('invalid_backup_format'),
    );

    setUpAll(() {
      registerFallbackValue(_record('fallback'));
    });

    setUp(() {
      storage = _MockEnumerableConsentStorage();
    });

    IotaConsentHistoryBackupSource buildSource() =>
        IotaConsentHistoryBackupSource(consentStorage: storage);

    test('exports every stored record via toJson', () async {
      final record = _record('h1');
      when(() => storage.listAll()).thenAnswer((_) async => [record]);

      final exported = await buildSource().export();

      expect(exported, {
        'consentHistory': [record.toJson()],
      });
    });

    test('imports records back into storage', () async {
      final record = _record('h1');
      when(() => storage.saveOrUpdate(any())).thenAnswer((_) async {});

      await buildSource().import({
        'consentHistory': [record.toJson()],
      });

      final saved =
          verify(() => storage.saveOrUpdate(captureAny())).captured.single
              as IotaConsentRecord;
      expect(saved.hash, equals('h1'));
    });

    test('throws when the section is missing', () async {
      await expectLater(
        buildSource().import(const {}),
        throwsA(invalidBackupFormat),
      );
    });

    test('throws when an entry is not an object', () async {
      await expectLater(
        buildSource().import({
          'consentHistory': [42],
        }),
        throwsA(invalidBackupFormat),
      );
    });
  });
}
