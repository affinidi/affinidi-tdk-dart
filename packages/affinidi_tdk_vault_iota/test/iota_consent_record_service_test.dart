import 'package:affinidi_tdk_vault_iota/affinidi_tdk_vault_iota.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import 'fixtures/iota_consent_record_fixtures.dart';
import 'mocks/mock_consent_storage.dart';
import 'mocks/mock_cryptography_service.dart';

void main() {
  late MockConsentStorage store;
  late MockCryptographyService cryptography;
  late IotaConsentRecordService service;

  setUpAll(() {
    registerFallbackValue(IotaConsentRecordFixtures.empty());
  });

  setUp(() {
    store = MockConsentStorage();
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
      test('persists a record with the expected fields', () async {
        await service.saveConsentRecord(
          requestHash: IotaConsentRecordFixtures.requestHash,
          clientId: IotaConsentRecordFixtures.clientId,
          verifierMetadata: IotaConsentRecordFixtures.verifierMetadata,
          profileId: IotaConsentRecordFixtures.profileId,
          profileName: IotaConsentRecordFixtures.profileName,
          vaultId: IotaConsentRecordFixtures.vaultId,
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

      test('always sets sharedAt to the current UTC timestamp', () async {
        final before = DateTime.now();

        await service.saveConsentRecord(
          requestHash: IotaConsentRecordFixtures.requestHash,
          clientId: IotaConsentRecordFixtures.clientId,
          verifierMetadata: IotaConsentRecordFixtures.verifierMetadata,
          profileId: IotaConsentRecordFixtures.profileId,
          profileName: IotaConsentRecordFixtures.profileName,
          vaultId: IotaConsentRecordFixtures.vaultId,
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

      test(
        'assembles the hash source in the expected pipe-delimited format',
        () async {
          await service.saveConsentRecord(
            requestHash: IotaConsentRecordFixtures.requestHash,
            clientId: IotaConsentRecordFixtures.clientId,
            verifierMetadata: IotaConsentRecordFixtures.verifierMetadata,
            profileId: IotaConsentRecordFixtures.profileId,
            profileName: IotaConsentRecordFixtures.profileName,
            vaultId: IotaConsentRecordFixtures.vaultId,
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
            '|${IotaConsentRecordFixtures.vaultId}'
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
            vaultId: IotaConsentRecordFixtures.vaultId,
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
            '|${IotaConsentRecordFixtures.vaultId}'
            '|${IotaConsentRecordFixtures.clientId}'
            '|||'
            '|$expectedVcFingerprint',
          );
        },
      );

      test('preserves VC presentation order in the hash source', () async {
        await service.saveConsentRecord(
          requestHash: IotaConsentRecordFixtures.requestHash,
          clientId: IotaConsentRecordFixtures.clientId,
          verifierMetadata: IotaConsentRecordFixtures.verifierMetadata,
          profileId: IotaConsentRecordFixtures.profileId,
          profileName: IotaConsentRecordFixtures.profileName,
          vaultId: IotaConsentRecordFixtures.vaultId,
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
          await service.saveConsentRecord(
            requestHash: IotaConsentRecordFixtures.requestHash,
            clientId: IotaConsentRecordFixtures.clientId,
            verifierMetadata: IotaConsentRecordFixtures.verifierMetadata,
            profileId: IotaConsentRecordFixtures.profileId,
            profileName: IotaConsentRecordFixtures.profileName,
            vaultId: IotaConsentRecordFixtures.vaultId,
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
            '|${IotaConsentRecordFixtures.vaultId}'
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
          await service.saveConsentRecord(
            requestHash: IotaConsentRecordFixtures.requestHash,
            clientId: IotaConsentRecordFixtures.clientId,
            verifierMetadata: IotaConsentRecordFixtures.verifierMetadata,
            profileId: IotaConsentRecordFixtures.profileId,
            profileName: IotaConsentRecordFixtures.profileName,
            vaultId: IotaConsentRecordFixtures.vaultId,
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
            () => store.saveOrUpdate(any()),
          ).thenThrow(Exception('db error'));

          await expectLater(
            () => service.saveConsentRecord(
              requestHash: IotaConsentRecordFixtures.requestHash,
              clientId: IotaConsentRecordFixtures.clientId,
              verifierMetadata: IotaConsentRecordFixtures.verifierMetadata,
              profileId: IotaConsentRecordFixtures.profileId,
              profileName: IotaConsentRecordFixtures.profileName,
              vaultId: IotaConsentRecordFixtures.vaultId,
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

    group('computeRequestHash', () {
      test('assembles hash source as clientId|jsonEncode(pd)', () {
        service.computeRequestHash(
          clientId: IotaConsentRecordFixtures.clientId,
          presentationDefinition:
              IotaConsentRecordFixtures.presentationDefinition,
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
          '${IotaConsentRecordFixtures.clientId}|{"id":"pd-1","input_descriptors":[]}',
        );
      });

      test('returns the hash produced by the cryptography service', () {
        final result = service.computeRequestHash(
          clientId: IotaConsentRecordFixtures.clientId,
          presentationDefinition:
              IotaConsentRecordFixtures.presentationDefinition,
        );

        expect(result, 'mock_hash');
      });
    });

    group('tryAutomaticConsent', () {
      setUp(() {
        when(
          () => store.findByRequestHash(any()),
        ).thenAnswer((_) async => null);
      });

      test('returns AutoConsentDeclined when no record exists', () async {
        final result = await service.tryAutomaticConsent(
          requestHash: IotaConsentRecordFixtures.requestHash,
          clientId: IotaConsentRecordFixtures.clientId,
          verifierMetadata: IotaConsentRecordFixtures.verifierMetadata,
          profileId: IotaConsentRecordFixtures.profileId,
          vaultId: IotaConsentRecordFixtures.vaultId,
          availableVcs: [IotaConsentRecordFixtures.makeVc()],
        );

        expect(result, isA<AutoConsentDeclined>());
      });

      test(
        'returns AutoConsentDeclined when isAutoShareEnabled is false',
        () async {
          when(
            () => store.findByRequestHash(any()),
          ).thenAnswer((_) async => IotaConsentRecordFixtures.existing());

          final result = await service.tryAutomaticConsent(
            requestHash: IotaConsentRecordFixtures.requestHash,
            clientId: IotaConsentRecordFixtures.clientId,
            verifierMetadata: IotaConsentRecordFixtures.verifierMetadata,
            profileId: IotaConsentRecordFixtures.profileId,
            vaultId: IotaConsentRecordFixtures.vaultId,
            availableVcs: [IotaConsentRecordFixtures.makeVc()],
          );

          expect(result, isA<AutoConsentDeclined>());
        },
      );

      test(
        'returns AutoConsentDeclined when isConsentManagementEnabled is true',
        () async {
          when(() => store.findByRequestHash(any())).thenAnswer(
            (_) async => IotaConsentRecordFixtures.autoShareEnabledWithHash(
              'mock_hash',
            ).copyWith(isConsentManagementEnabled: true),
          );

          final result = await service.tryAutomaticConsent(
            requestHash: IotaConsentRecordFixtures.requestHash,
            clientId: IotaConsentRecordFixtures.clientId,
            verifierMetadata: IotaConsentRecordFixtures.verifierMetadata,
            profileId: IotaConsentRecordFixtures.profileId,
            vaultId: IotaConsentRecordFixtures.vaultId,
            availableVcs: [IotaConsentRecordFixtures.makeVc()],
          );

          expect(result, isA<AutoConsentDeclined>());
        },
      );

      test(
        'returns AutoConsentDeclined when a previously shared VC is missing',
        () async {
          // Record lists two VC IDs but only one is available.
          when(() => store.findByRequestHash(any())).thenAnswer(
            (_) async => IotaConsentRecordFixtures.autoShareEnabledWithHash(
              'mock_hash',
            ).copyWith(sharedVcIds: ['vc-1', 'vc-missing']),
          );

          final result = await service.tryAutomaticConsent(
            requestHash: IotaConsentRecordFixtures.requestHash,
            clientId: IotaConsentRecordFixtures.clientId,
            verifierMetadata: IotaConsentRecordFixtures.verifierMetadata,
            profileId: IotaConsentRecordFixtures.profileId,
            vaultId: IotaConsentRecordFixtures.vaultId,
            availableVcs: [IotaConsentRecordFixtures.makeVc(id: 'vc-1')],
          );

          expect(result, isA<AutoConsentDeclined>());
        },
      );

      test(
        'returns AutoConsentDeclined when the recomputed hash does not match',
        () async {
          // Stored hash is 'stale_hash'; cryptography mock returns 'mock_hash'.
          when(() => store.findByRequestHash(any())).thenAnswer(
            (_) async => IotaConsentRecordFixtures.autoShareEnabledWithHash(
              'stale_hash',
            ),
          );

          final result = await service.tryAutomaticConsent(
            requestHash: IotaConsentRecordFixtures.requestHash,
            clientId: IotaConsentRecordFixtures.clientId,
            verifierMetadata: IotaConsentRecordFixtures.verifierMetadata,
            profileId: IotaConsentRecordFixtures.profileId,
            vaultId: IotaConsentRecordFixtures.vaultId,
            availableVcs: [IotaConsentRecordFixtures.makeVc()],
          );

          expect(result, isA<AutoConsentDeclined>());
        },
      );

      test(
        'returns AutoConsentApproved with the previously shared VCs when all checks pass',
        () async {
          // Stored hash matches the mock cryptography return value.
          when(() => store.findByRequestHash(any())).thenAnswer(
            (_) async => IotaConsentRecordFixtures.autoShareEnabledWithHash(
              'mock_hash',
            ),
          );
          final vc = IotaConsentRecordFixtures.makeVc();

          final result = await service.tryAutomaticConsent(
            requestHash: IotaConsentRecordFixtures.requestHash,
            clientId: IotaConsentRecordFixtures.clientId,
            verifierMetadata: IotaConsentRecordFixtures.verifierMetadata,
            profileId: IotaConsentRecordFixtures.profileId,
            vaultId: IotaConsentRecordFixtures.vaultId,
            availableVcs: [vc],
          );

          expect(result, isA<AutoConsentApproved>());
          final approved = result as AutoConsentApproved;
          expect(approved.vcsToShare, [vc]);
        },
      );

      test(
        'passes the correct requestHash to the store lookup',
        () async {
          await service.tryAutomaticConsent(
            requestHash: IotaConsentRecordFixtures.requestHash,
            clientId: IotaConsentRecordFixtures.clientId,
            verifierMetadata: IotaConsentRecordFixtures.verifierMetadata,
            profileId: IotaConsentRecordFixtures.profileId,
            vaultId: IotaConsentRecordFixtures.vaultId,
            availableVcs: [],
          );

          verify(
            () => store.findByRequestHash(IotaConsentRecordFixtures.requestHash),
          ).called(1);
        },
      );

      test(
        'returns AutoConsentDeclined when the stored record has no shared VC IDs',
        () async {
          when(() => store.findByRequestHash(any())).thenAnswer(
            (_) async => IotaConsentRecordFixtures.autoShareEnabledWithHash(
              'mock_hash',
            ).copyWith(sharedVcIds: []),
          );

          final result = await service.tryAutomaticConsent(
            requestHash: IotaConsentRecordFixtures.requestHash,
            clientId: IotaConsentRecordFixtures.clientId,
            verifierMetadata: IotaConsentRecordFixtures.verifierMetadata,
            profileId: IotaConsentRecordFixtures.profileId,
            vaultId: IotaConsentRecordFixtures.vaultId,
            availableVcs: [],
          );

          expect(result, isA<AutoConsentDeclined>());
        },
      );

      test(
        'throws TdkException with failedToReadConsentRecord when the store throws',
        () async {
          when(
            () => store.findByRequestHash(any()),
          ).thenThrow(Exception('storage unavailable'));

          await expectLater(
            service.tryAutomaticConsent(
              requestHash: IotaConsentRecordFixtures.requestHash,
              clientId: IotaConsentRecordFixtures.clientId,
              verifierMetadata: IotaConsentRecordFixtures.verifierMetadata,
              profileId: IotaConsentRecordFixtures.profileId,
              vaultId: IotaConsentRecordFixtures.vaultId,
              availableVcs: [],
            ),
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
