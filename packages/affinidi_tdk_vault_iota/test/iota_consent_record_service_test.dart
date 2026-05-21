import 'package:affinidi_tdk_vault_iota/affinidi_tdk_vault_iota.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import 'fixtures/iota_consent_record_fixtures.dart';
import 'mocks/mock_consent_record_store.dart';
import 'mocks/mock_cryptography_service.dart';

void main() {
  late MockConsentRecordStore store;
  late MockCryptographyService cryptography;
  late IotaConsentRecordService service;

  setUpAll(() {
    registerFallbackValue(IotaConsentRecordFixtures.empty());
  });

  setUp(() {
    store = MockConsentRecordStore();
    cryptography = MockCryptographyService();

    when(
      () => cryptography.createHash(hashSource: any(named: 'hashSource')),
    ).thenReturn('mock_hash');

    when(() => store.saveOrUpdate(any())).thenAnswer((_) async {});

    service = IotaConsentRecordService(
      store: store,
      cryptography: cryptography,
    );
  });

  group('IotaConsentRecordService', () {
    group('saveConsentRecord', () {
      test('persists a new record when none exists', () async {
        when(
          () => store.findByRequestHash(any()),
        ).thenAnswer((_) async => null);

        await service.saveConsentRecord(
          requestHash: IotaConsentRecordFixtures.requestHash,
          clientId: IotaConsentRecordFixtures.clientId,
          verifierMetadata: IotaConsentRecordFixtures.verifierMetadata,
          profileId: IotaConsentRecordFixtures.profileId,
          profileName: IotaConsentRecordFixtures.profileName,
          did: IotaConsentRecordFixtures.did,
          sharedVcs: [IotaConsentRecordFixtures.makeVc()],
          claimedVcTypesCsv: 'SomeType',
          isAutoShareEnabled: true,
        );

        final captured =
            verify(() => store.saveOrUpdate(captureAny())).captured.single
                as IotaConsentRecord;

        expect(captured.clientId, IotaConsentRecordFixtures.clientId);
        expect(captured.isAutoShareEnabled, isTrue);
        expect(captured.sharedVcIds, [IotaConsentRecordFixtures.vcId]);
      });

      test('sets sharedAt to a non-empty timestamp for a new record', () async {
        when(
          () => store.findByRequestHash(any()),
        ).thenAnswer((_) async => null);

        final before = DateTime.now();

        await service.saveConsentRecord(
          requestHash: IotaConsentRecordFixtures.requestHash,
          clientId: IotaConsentRecordFixtures.clientId,
          verifierMetadata: IotaConsentRecordFixtures.verifierMetadata,
          profileId: IotaConsentRecordFixtures.profileId,
          profileName: IotaConsentRecordFixtures.profileName,
          did: IotaConsentRecordFixtures.did,
          sharedVcs: [IotaConsentRecordFixtures.makeVc()],
          claimedVcTypesCsv: 'SomeType',
          isAutoShareEnabled: false,
        );

        final after = DateTime.now();

        final captured =
            verify(() => store.saveOrUpdate(captureAny())).captured.single
                as IotaConsentRecord;

        final savedAt = DateTime.parse(captured.sharedAt);
        expect(
          savedAt.isAfter(before.subtract(const Duration(seconds: 1))),
          isTrue,
        );
        expect(savedAt.isBefore(after.add(const Duration(seconds: 1))), isTrue);
        expect(captured.sharedAt, endsWith('Z'));
      });

      test('preserves sharedAt when updating an existing record', () async {
        when(
          () => store.findByRequestHash(any()),
        ).thenAnswer((_) async => IotaConsentRecordFixtures.existing());

        await service.saveConsentRecord(
          requestHash: IotaConsentRecordFixtures.requestHash,
          clientId: IotaConsentRecordFixtures.clientId,
          verifierMetadata: IotaConsentRecordFixtures.verifierMetadata,
          profileId: IotaConsentRecordFixtures.profileId,
          profileName: IotaConsentRecordFixtures.profileName,
          did: IotaConsentRecordFixtures.did,
          sharedVcs: [
            IotaConsentRecordFixtures.makeVc(),
            IotaConsentRecordFixtures.makeVc(id: 'vc-2'),
          ],
          claimedVcTypesCsv: 'SomeType',
          isAutoShareEnabled: true,
        );

        final captured =
            verify(() => store.saveOrUpdate(captureAny())).captured.single
                as IotaConsentRecord;

        expect(captured.sharedAt, IotaConsentRecordFixtures.sharedAt);
        expect(captured.sharedVcIds, ['vc-1', 'vc-2']);
      });

      test(
        'updates isAutoShareEnabled when toggled on an existing record',
        () async {
          when(
            () => store.findByRequestHash(any()),
          ).thenAnswer((_) async => IotaConsentRecordFixtures.existing());

          await service.saveConsentRecord(
            requestHash: IotaConsentRecordFixtures.requestHash,
            clientId: IotaConsentRecordFixtures.clientId,
            verifierMetadata: IotaConsentRecordFixtures.verifierMetadata,
            profileId: IotaConsentRecordFixtures.profileId,
            profileName: IotaConsentRecordFixtures.profileName,
            did: IotaConsentRecordFixtures.did,
            sharedVcs: [IotaConsentRecordFixtures.makeVc()],
            claimedVcTypesCsv: 'SomeType',
            isAutoShareEnabled: true,
          );

          final captured =
              verify(() => store.saveOrUpdate(captureAny())).captured.single
                  as IotaConsentRecord;

          // existing() has isAutoShareEnabled=false; the new call passes true.
          expect(captured.isAutoShareEnabled, isTrue);
          // sharedAt must still be preserved from the existing record.
          expect(captured.sharedAt, IotaConsentRecordFixtures.sharedAt);
        },
      );

      test('throws TdkException when findByRequestHash fails', () async {
        when(
          () => store.findByRequestHash(any()),
        ).thenThrow(Exception('lookup error'));

        await expectLater(
          () => service.saveConsentRecord(
            requestHash: IotaConsentRecordFixtures.requestHash,
            clientId: IotaConsentRecordFixtures.clientId,
            verifierMetadata: IotaConsentRecordFixtures.verifierMetadata,
            profileId: IotaConsentRecordFixtures.profileId,
            profileName: IotaConsentRecordFixtures.profileName,
            did: IotaConsentRecordFixtures.did,
            sharedVcs: [],
            claimedVcTypesCsv: '',
            isAutoShareEnabled: false,
          ),
          throwsA(
            isA<TdkException>().having(
              (e) => e.code,
              'code',
              equals(TdkExceptionType.failedToPersistConsentRecord.code),
            ),
          ),
        );
      });

      test(
        'assembles the hash source in the expected pipe-delimited format',
        () async {
          when(
            () => store.findByRequestHash(any()),
          ).thenAnswer((_) async => null);

          await service.saveConsentRecord(
            requestHash: IotaConsentRecordFixtures.requestHash,
            clientId: IotaConsentRecordFixtures.clientId,
            verifierMetadata: IotaConsentRecordFixtures.verifierMetadata,
            profileId: IotaConsentRecordFixtures.profileId,
            profileName: IotaConsentRecordFixtures.profileName,
            did: IotaConsentRecordFixtures.did,
            sharedVcs: [IotaConsentRecordFixtures.makeVc()],
            claimedVcTypesCsv: 'SomeType',
            isAutoShareEnabled: false,
          );

          final captured =
              verify(
                    () => cryptography.createHash(
                      hashSource: captureAny(named: 'hashSource'),
                    ),
                  ).captured.single
                  as String;

          const expectedVcFingerprint =
              '${IotaConsentRecordFixtures.vcIssuerId}'
              '-${IotaConsentRecordFixtures.vcId}'
              '-2023-01-01T00:00:00.000Z'
              '-{"name":"Alice"}';

          expect(
            captured,
            '${IotaConsentRecordFixtures.profileId}'
            '|${IotaConsentRecordFixtures.did}'
            '|${IotaConsentRecordFixtures.clientId}'
            '|${IotaConsentRecordFixtures.verifierMetadata.name}'
            '|${IotaConsentRecordFixtures.verifierMetadata.logo}'
            '|${IotaConsentRecordFixtures.verifierMetadata.origin}'
            '|$expectedVcFingerprint',
          );
        },
      );

      test(
        'substitutes empty strings for absent verifier metadata fields',
        () async {
          when(
            () => store.findByRequestHash(any()),
          ).thenAnswer((_) async => null);

          await service.saveConsentRecord(
            requestHash: IotaConsentRecordFixtures.requestHash,
            clientId: IotaConsentRecordFixtures.clientId,
            verifierMetadata: const VerifierClientMetadata(
              name: null,
              logo: null,
              origin: null,
            ),
            profileId: IotaConsentRecordFixtures.profileId,
            profileName: IotaConsentRecordFixtures.profileName,
            did: IotaConsentRecordFixtures.did,
            sharedVcs: [IotaConsentRecordFixtures.makeVc()],
            claimedVcTypesCsv: 'SomeType',
            isAutoShareEnabled: false,
          );

          final captured =
              verify(
                    () => cryptography.createHash(
                      hashSource: captureAny(named: 'hashSource'),
                    ),
                  ).captured.single
                  as String;

          const expectedVcFingerprint =
              '${IotaConsentRecordFixtures.vcIssuerId}'
              '-${IotaConsentRecordFixtures.vcId}'
              '-2023-01-01T00:00:00.000Z'
              '-{"name":"Alice"}';

          expect(
            captured,
            '${IotaConsentRecordFixtures.profileId}'
            '|${IotaConsentRecordFixtures.did}'
            '|${IotaConsentRecordFixtures.clientId}'
            '|||'
            '|$expectedVcFingerprint',
          );
        },
      );

      test('preserves VC presentation order in the hash source', () async {
        when(
          () => store.findByRequestHash(any()),
        ).thenAnswer((_) async => null);

        await service.saveConsentRecord(
          requestHash: IotaConsentRecordFixtures.requestHash,
          clientId: IotaConsentRecordFixtures.clientId,
          verifierMetadata: IotaConsentRecordFixtures.verifierMetadata,
          profileId: IotaConsentRecordFixtures.profileId,
          profileName: IotaConsentRecordFixtures.profileName,
          did: IotaConsentRecordFixtures.did,
          sharedVcs: [
            IotaConsentRecordFixtures.makeVc(id: 'vc-3'),
            IotaConsentRecordFixtures.makeVc(id: 'vc-1'),
            IotaConsentRecordFixtures.makeVc(id: 'vc-2'),
          ],
          claimedVcTypesCsv: 'SomeType',
          isAutoShareEnabled: false,
        );

        final captured =
            verify(
                  () => cryptography.createHash(
                    hashSource: captureAny(named: 'hashSource'),
                  ),
                ).captured.single
                as String;

        expect(captured, contains('vc-3'));
        expect(captured, contains('vc-1'));
        expect(captured, contains('vc-2'));
        expect(captured.indexOf('vc-3'), lessThan(captured.indexOf('vc-1')));
        expect(captured.indexOf('vc-1'), lessThan(captured.indexOf('vc-2')));
      });

      test(
        'uses empty string for vcsFingerprint in hash source when sharedVcs is empty',
        () async {
          when(
            () => store.findByRequestHash(any()),
          ).thenAnswer((_) async => null);

          await service.saveConsentRecord(
            requestHash: IotaConsentRecordFixtures.requestHash,
            clientId: IotaConsentRecordFixtures.clientId,
            verifierMetadata: IotaConsentRecordFixtures.verifierMetadata,
            profileId: IotaConsentRecordFixtures.profileId,
            profileName: IotaConsentRecordFixtures.profileName,
            did: IotaConsentRecordFixtures.did,
            sharedVcs: [],
            claimedVcTypesCsv: '',
            isAutoShareEnabled: false,
          );

          final captured =
              verify(
                    () => cryptography.createHash(
                      hashSource: captureAny(named: 'hashSource'),
                    ),
                  ).captured.single
                  as String;

          expect(
            captured,
            '${IotaConsentRecordFixtures.profileId}'
            '|${IotaConsentRecordFixtures.did}'
            '|${IotaConsentRecordFixtures.clientId}'
            '|${IotaConsentRecordFixtures.verifierMetadata.name}'
            '|${IotaConsentRecordFixtures.verifierMetadata.logo}'
            '|${IotaConsentRecordFixtures.verifierMetadata.origin}'
            '|',
          );
        },
      );

      test(
        'encodes nested credential subject JSON correctly in the VC fingerprint',
        () async {
          when(
            () => store.findByRequestHash(any()),
          ).thenAnswer((_) async => null);

          await service.saveConsentRecord(
            requestHash: IotaConsentRecordFixtures.requestHash,
            clientId: IotaConsentRecordFixtures.clientId,
            verifierMetadata: IotaConsentRecordFixtures.verifierMetadata,
            profileId: IotaConsentRecordFixtures.profileId,
            profileName: IotaConsentRecordFixtures.profileName,
            did: IotaConsentRecordFixtures.did,
            sharedVcs: [
              IotaConsentRecordFixtures.makeVc(
                credentialSubject: {
                  'address': {'city': 'Berlin', 'zip': '10115'},
                },
              ),
            ],
            claimedVcTypesCsv: 'SomeType',
            isAutoShareEnabled: false,
          );

          final captured =
              verify(
                    () => cryptography.createHash(
                      hashSource: captureAny(named: 'hashSource'),
                    ),
                  ).captured.single
                  as String;

          expect(
            captured,
            endsWith('-{"address":{"city":"Berlin","zip":"10115"}}'),
          );
        },
      );

      test(
        'throws TdkException with failedToPersistConsentRecord when the store throws',
        () async {
          when(
            () => store.findByRequestHash(any()),
          ).thenAnswer((_) async => null);

          when(
            () => store.saveOrUpdate(any()),
          ).thenThrow(Exception('db error'));

          await expectLater(
            () => service.saveConsentRecord(
              requestHash: IotaConsentRecordFixtures.requestHash,
              clientId: IotaConsentRecordFixtures.clientId,
              verifierMetadata: IotaConsentRecordFixtures.verifierMetadata,
              profileId: IotaConsentRecordFixtures.profileId,
              profileName: IotaConsentRecordFixtures.profileName,
              did: IotaConsentRecordFixtures.did,
              sharedVcs: [],
              claimedVcTypesCsv: '',
              isAutoShareEnabled: false,
            ),
            throwsA(
              isA<TdkException>().having(
                (e) => e.code,
                'code',
                TdkExceptionType.failedToPersistConsentRecord.code,
              ),
            ),
          );
        },
      );
    });
  });
}
