import 'package:affinidi_tdk_vault_iota/affinidi_tdk_vault_iota.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ssi/ssi.dart' show ParsedVerifiableCredential;
import 'package:test/test.dart';

import 'fixtures/iota_consent_record_fixtures.dart';
import 'mocks/mock_consent_storage.dart';
import 'mocks/mock_cryptography_service.dart';
import 'mocks/mock_iota_share_response_service.dart';

void main() {
  late MockConsentStorage store;
  late MockCryptographyService cryptography;
  late MockIotaShareResponseService shareResponseService;
  late IotaConsentRecordService service;

  setUpAll(() {
    registerFallbackValue(IotaConsentRecordFixtures.empty());
    registerFallbackValue(VpDataModel.v1);
  });

  setUp(() {
    store = MockConsentStorage();
    cryptography = MockCryptographyService();
    shareResponseService = MockIotaShareResponseService();

    when(
      () => cryptography.createHash(hashSource: any(named: 'hashSource')),
    ).thenReturn('mock_hash');

    when(() => store.saveOrUpdate(any())).thenAnswer((_) async {});

    when(
      () => shareResponseService.submitShareResponse(
        state: any(named: 'state'),
        nonce: any(named: 'nonce'),
        clientId: any(named: 'clientId'),
        definitionId: any(named: 'definitionId'),
        selectedCredentials: any(named: 'selectedCredentials'),
        dataModel: any(named: 'dataModel'),
      ),
    ).thenAnswer((_) async => null);

    service = IotaConsentRecordService(
      store: store,
      cryptography: cryptography,
      shareResponseService: shareResponseService,
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

    group('tryAutomaticConsent', () {
      setUp(() {
        when(
          () => store.findByRequestHash(any()),
        ).thenAnswer((_) async => null);
      });

      test(
        'returns AutoConsentDeclined when isConsentManagementEnabled is true',
        () async {
          final result = await service.tryAutomaticConsent(
            requestHash: IotaConsentRecordFixtures.requestHash,
            matchedCredentials: [
              (
                descriptor: IotaConsentRecordFixtures.pdDescriptor,
                credential: IotaConsentRecordFixtures.makeParsedVc(),
              ),
            ],
            verifierMetadata: IotaConsentRecordFixtures.verifierMetadata,
            profileId: IotaConsentRecordFixtures.profileId,
            vaultId: IotaConsentRecordFixtures.vaultId,
            state: 'test_state',
            nonce: 'test_nonce',
            definitionId: 'def-1',
            dataModel: VpDataModel.v1,
            isConsentManagementEnabled: true,
          );

          expect(result, isA<AutoConsentDeclined>());
          verifyNever(() => store.findByRequestHash(any()));
          verifyNever(
            () => shareResponseService.submitShareResponse(
              state: any(named: 'state'),
              nonce: any(named: 'nonce'),
              clientId: any(named: 'clientId'),
              definitionId: any(named: 'definitionId'),
              selectedCredentials: any(named: 'selectedCredentials'),
              dataModel: any(named: 'dataModel'),
            ),
          );
        },
      );

      test(
        'returns AutoConsentDeclined when no matching record exists',
        () async {
          final result = await service.tryAutomaticConsent(
            requestHash: IotaConsentRecordFixtures.requestHash,
            matchedCredentials: [
              (
                descriptor: IotaConsentRecordFixtures.pdDescriptor,
                credential: IotaConsentRecordFixtures.makeParsedVc(),
              ),
            ],
            verifierMetadata: IotaConsentRecordFixtures.verifierMetadata,
            profileId: IotaConsentRecordFixtures.profileId,
            vaultId: IotaConsentRecordFixtures.vaultId,
            state: 'test_state',
            nonce: 'test_nonce',
            definitionId: 'def-1',
            dataModel: VpDataModel.v1,
          );

          expect(result, isA<AutoConsentDeclined>());
        },
      );

      test(
        'returns AutoConsentDeclined when isAutoShareEnabled is false',
        () async {
          when(() => store.findByRequestHash(any())).thenAnswer(
            (_) async => IotaConsentRecordFixtures.autoShareDisabled(),
          );

          final result = await service.tryAutomaticConsent(
            requestHash: IotaConsentRecordFixtures.requestHash,
            matchedCredentials: [
              (
                descriptor: IotaConsentRecordFixtures.pdDescriptor,
                credential: IotaConsentRecordFixtures.makeParsedVc(),
              ),
            ],
            verifierMetadata: IotaConsentRecordFixtures.verifierMetadata,
            profileId: IotaConsentRecordFixtures.profileId,
            vaultId: IotaConsentRecordFixtures.vaultId,
            state: 'test_state',
            nonce: 'test_nonce',
            definitionId: 'def-1',
            dataModel: VpDataModel.v1,
          );

          expect(result, isA<AutoConsentDeclined>());
        },
      );

      test(
        'returns AutoConsentDeclined when the stored record has consent management enabled',
        () async {
          when(() => store.findByRequestHash(any())).thenAnswer(
            (_) async => IotaConsentRecordFixtures.consentManagementEnabled(),
          );

          final result = await service.tryAutomaticConsent(
            requestHash: IotaConsentRecordFixtures.requestHash,
            matchedCredentials: [
              (
                descriptor: IotaConsentRecordFixtures.pdDescriptor,
                credential: IotaConsentRecordFixtures.makeParsedVc(),
              ),
            ],
            verifierMetadata: IotaConsentRecordFixtures.verifierMetadata,
            profileId: IotaConsentRecordFixtures.profileId,
            vaultId: IotaConsentRecordFixtures.vaultId,
            state: 'test_state',
            nonce: 'test_nonce',
            definitionId: 'def-1',
            dataModel: VpDataModel.v1,
          );

          expect(result, isA<AutoConsentDeclined>());
        },
      );

      test(
        'returns AutoConsentDeclined when a previously shared VC is no longer available',
        () async {
          when(() => store.findByRequestHash(any())).thenAnswer(
            (_) async =>
                IotaConsentRecordFixtures.autoShareEnabledMatchingHash(),
          );

          final result = await service.tryAutomaticConsent(
            requestHash: IotaConsentRecordFixtures.requestHash,
            matchedCredentials: [],
            verifierMetadata: IotaConsentRecordFixtures.verifierMetadata,
            profileId: IotaConsentRecordFixtures.profileId,
            vaultId: IotaConsentRecordFixtures.vaultId,
            state: 'test_state',
            nonce: 'test_nonce',
            definitionId: 'def-1',
            dataModel: VpDataModel.v1,
          );

          expect(result, isA<AutoConsentDeclined>());
        },
      );

      test(
        'returns AutoConsentDeclined when the share fingerprint has changed',
        () async {
          when(() => store.findByRequestHash(any())).thenAnswer(
            (_) async => IotaConsentRecordFixtures.autoShareEnabled(),
          );

          final result = await service.tryAutomaticConsent(
            requestHash: IotaConsentRecordFixtures.requestHash,
            matchedCredentials: [
              (
                descriptor: IotaConsentRecordFixtures.pdDescriptor,
                credential: IotaConsentRecordFixtures.makeParsedVc(),
              ),
            ],
            verifierMetadata: IotaConsentRecordFixtures.verifierMetadata,
            profileId: IotaConsentRecordFixtures.profileId,
            vaultId: IotaConsentRecordFixtures.vaultId,
            state: 'test_state',
            nonce: 'test_nonce',
            definitionId: 'def-1',
            dataModel: VpDataModel.v1,
          );

          expect(result, isA<AutoConsentDeclined>());
        },
      );

      test(
        'returns AutoConsentApproved with the redirect URI when all checks pass',
        () async {
          final redirectUri = Uri.parse(
            'https://verifier.example.com/callback',
          );

          when(() => store.findByRequestHash(any())).thenAnswer(
            (_) async =>
                IotaConsentRecordFixtures.autoShareEnabledMatchingHash(),
          );

          when(
            () => shareResponseService.submitShareResponse(
              state: any(named: 'state'),
              nonce: any(named: 'nonce'),
              clientId: any(named: 'clientId'),
              definitionId: any(named: 'definitionId'),
              selectedCredentials: any(named: 'selectedCredentials'),
              dataModel: any(named: 'dataModel'),
            ),
          ).thenAnswer((_) async => redirectUri);

          final result = await service.tryAutomaticConsent(
            requestHash: IotaConsentRecordFixtures.requestHash,
            matchedCredentials: [
              (
                descriptor: IotaConsentRecordFixtures.pdDescriptor,
                credential: IotaConsentRecordFixtures.makeParsedVc(),
              ),
            ],
            verifierMetadata: IotaConsentRecordFixtures.verifierMetadata,
            profileId: IotaConsentRecordFixtures.profileId,
            vaultId: IotaConsentRecordFixtures.vaultId,
            state: 'test_state',
            nonce: 'test_nonce',
            definitionId: 'def-1',
            dataModel: VpDataModel.v1,
          );

          expect(result, isA<AutoConsentApproved>());
          expect((result as AutoConsentApproved).redirectUri, redirectUri);
        },
      );

      test(
        'preserves the VC lookup order from the stored sharedVcIds list',
        () async {
          final vc1 = IotaConsentRecordFixtures.makeParsedVc(id: 'vc-1');
          final vc2 = IotaConsentRecordFixtures.makeParsedVc(id: 'vc-2');
          final desc1 = PDDescriptor.fromJson({'id': 'desc-1'});
          final desc2 = PDDescriptor.fromJson({'id': 'desc-2'});

          when(() => store.findByRequestHash(any())).thenAnswer(
            (_) async => const IotaConsentRecord(
              hash: 'mock_hash',
              requestHash: IotaConsentRecordFixtures.requestHash,
              sharedAt: IotaConsentRecordFixtures.sharedAt,
              profileName: IotaConsentRecordFixtures.profileName,
              profileId: IotaConsentRecordFixtures.profileId,
              clientId: IotaConsentRecordFixtures.clientId,
              isAutoShareEnabled: true,
              isConsentManagementEnabled: false,
              sharedVcIds: ['vc-2', 'vc-1'],
              claimedVcTypesCsv: 'SomeType',
            ),
          );

          await service.tryAutomaticConsent(
            requestHash: IotaConsentRecordFixtures.requestHash,
            matchedCredentials: [
              (descriptor: desc1, credential: vc1),
              (descriptor: desc2, credential: vc2),
            ],
            verifierMetadata: IotaConsentRecordFixtures.verifierMetadata,
            profileId: IotaConsentRecordFixtures.profileId,
            vaultId: IotaConsentRecordFixtures.vaultId,
            state: 'test_state',
            nonce: 'test_nonce',
            definitionId: 'def-1',
            dataModel: VpDataModel.v1,
          );

          final captured =
              verify(
                    () => shareResponseService.submitShareResponse(
                      state: any(named: 'state'),
                      nonce: any(named: 'nonce'),
                      clientId: any(named: 'clientId'),
                      definitionId: any(named: 'definitionId'),
                      selectedCredentials: captureAny(
                        named: 'selectedCredentials',
                      ),
                      dataModel: any(named: 'dataModel'),
                    ),
                  ).captured.single
                  as List<
                    ({
                      PDDescriptor descriptor,
                      ParsedVerifiableCredential<dynamic> credential,
                    })
                  >;

          expect(captured.map((e) => e.credential.id?.toString()), [
            'vc-2',
            'vc-1',
          ]);
        },
      );

      test(
        'throws TdkException with failedToReadConsentRecord when the store throws',
        () async {
          when(
            () => store.findByRequestHash(any()),
          ).thenThrow(Exception('storage error'));

          await expectLater(
            () => service.tryAutomaticConsent(
              requestHash: IotaConsentRecordFixtures.requestHash,
              matchedCredentials: [],
              verifierMetadata: IotaConsentRecordFixtures.verifierMetadata,
              profileId: IotaConsentRecordFixtures.profileId,
              vaultId: IotaConsentRecordFixtures.vaultId,
              state: 'test_state',
              nonce: 'test_nonce',
              definitionId: 'def-1',
              dataModel: VpDataModel.v1,
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
