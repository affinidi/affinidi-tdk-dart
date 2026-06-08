import 'package:affinidi_tdk_vault_iota/affinidi_tdk_vault_iota.dart';
import 'package:affinidi_tdk_vault_iota/src/models/share_requirements.dart'
    show DcqlShareRequest, PexShareRequest;
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
    registerFallbackValue(IotaConsentRecordFixtures.shareRequest);
    registerFallbackValue(<ParsedVerifiableCredential<dynamic>>[]);
    registerFallbackValue(IotaConsentRecordFixtures.dcqlShareRequest);
    registerFallbackValue(IotaConsentRecordFixtures.dcqlShareRequestWithSets);
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
        shareRequest: any(named: 'shareRequest'),
        selectedCredentials: any(named: 'selectedCredentials'),
        acceptResponseUri: any(named: 'acceptResponseUri'),
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
      test('should persist a record with the expected fields', () async {
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

      test('should always set sharedAt to the current UTC timestamp', () async {
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
        'should assemble the hash source in the expected pipe-delimited format',
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
        'should substitute empty strings for absent verifier metadata fields',
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

      test(
        'should preserve VC presentation order in the hash source',
        () async {
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
        },
      );

      test(
        'should use empty string for vcsFingerprint in hash source when sharedVcs is empty',
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
        'should encode nested credential subject JSON correctly in the VC fingerprint',
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
        'should throw TdkException with failedToPersistConsentRecord when the store throws',
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
          () => store.findAllByRequestHash(any()),
        ).thenAnswer((_) async => <IotaConsentRecord>[]);
      });

      test(
        'should return AutoConsentDeclined when no matching record exists',
        () async {
          final result = await service.tryAutomaticConsent(
            shareRequest: IotaConsentRecordFixtures.shareRequest,
            matchedCredentials: IotaConsentRecordFixtures.claimedCredentials(),
            verifierMetadata: IotaConsentRecordFixtures.verifierMetadata,
            vaultId: IotaConsentRecordFixtures.vaultId,
            requestHash: IotaConsentRecordFixtures.requestHash,
          );

          expect(result, isA<AutoConsentDeclined>());
        },
      );

      test(
        'should return AutoConsentDeclined when isAutoShareEnabled is false',
        () async {
          when(() => store.findAllByRequestHash(any())).thenAnswer(
            (_) async => [IotaConsentRecordFixtures.autoShareDisabled()],
          );

          final result = await service.tryAutomaticConsent(
            shareRequest: IotaConsentRecordFixtures.shareRequest,
            matchedCredentials: IotaConsentRecordFixtures.claimedCredentials(),
            verifierMetadata: IotaConsentRecordFixtures.verifierMetadata,
            vaultId: IotaConsentRecordFixtures.vaultId,
            requestHash: IotaConsentRecordFixtures.requestHash,
          );

          expect(result, isA<AutoConsentDeclined>());
        },
      );

      test(
        'should return AutoConsentDeclined when the stored record has consent management enabled',
        () async {
          when(() => store.findAllByRequestHash(any())).thenAnswer(
            (_) async => [IotaConsentRecordFixtures.consentManagementEnabled()],
          );

          final result = await service.tryAutomaticConsent(
            shareRequest: IotaConsentRecordFixtures.shareRequest,
            matchedCredentials: IotaConsentRecordFixtures.claimedCredentials(),
            verifierMetadata: IotaConsentRecordFixtures.verifierMetadata,
            vaultId: IotaConsentRecordFixtures.vaultId,
            requestHash: IotaConsentRecordFixtures.requestHash,
          );

          expect(result, isA<AutoConsentDeclined>());
        },
      );

      test(
        'should return AutoConsentDeclined when a previously shared VC is no longer available',
        () async {
          when(() => store.findAllByRequestHash(any())).thenAnswer(
            (_) async => [
              IotaConsentRecordFixtures.autoShareEnabledMatchingHash(),
            ],
          );

          // claimedCredentials is empty — 'vc-1' cannot be found
          final result = await service.tryAutomaticConsent(
            shareRequest: IotaConsentRecordFixtures.shareRequest,
            matchedCredentials: IotaConsentRecordFixtures.claimedCredentials(),
            verifierMetadata: IotaConsentRecordFixtures.verifierMetadata,
            vaultId: IotaConsentRecordFixtures.vaultId,
            requestHash: IotaConsentRecordFixtures.requestHash,
          );

          expect(result, isA<AutoConsentDeclined>());
        },
      );

      test(
        'should return AutoConsentDeclined when the share fingerprint has changed',
        () async {
          when(() => store.findAllByRequestHash(any())).thenAnswer(
            (_) async => [IotaConsentRecordFixtures.autoShareEnabled()],
          );

          final result = await service.tryAutomaticConsent(
            shareRequest: IotaConsentRecordFixtures.shareRequest,
            matchedCredentials: IotaConsentRecordFixtures.claimedCredentials(
              available: [IotaConsentRecordFixtures.makeParsedVc()],
            ),
            verifierMetadata: IotaConsentRecordFixtures.verifierMetadata,
            vaultId: IotaConsentRecordFixtures.vaultId,
            requestHash: IotaConsentRecordFixtures.requestHash,
          );

          expect(result, isA<AutoConsentDeclined>());
        },
      );

      test(
        'should return AutoConsentDeclined when the stored clientId differs from the request',
        () async {
          when(() => store.findAllByRequestHash(any())).thenAnswer(
            (_) async => [
              IotaConsentRecordFixtures.autoShareEnabledMatchingHash(),
            ],
          );

          final shareRequestDifferentClient = PexShareRequest(
            request: IotaRequest(
              responseType:
                  IotaConsentRecordFixtures.shareRequest.request.responseType,
              responseMode:
                  IotaConsentRecordFixtures.shareRequest.request.responseMode,
              acceptResponseUri: IotaConsentRecordFixtures
                  .shareRequest
                  .request
                  .acceptResponseUri,
              rejectResponseUri: IotaConsentRecordFixtures
                  .shareRequest
                  .request
                  .rejectResponseUri,
              state: IotaConsentRecordFixtures.shareRequest.request.state,
              nonce: IotaConsentRecordFixtures.shareRequest.request.nonce,
              clientId: 'did:key:different-verifier',
            ),
            presentationDefinition:
                IotaConsentRecordFixtures.shareRequest.presentationDefinition,
            jwtAssertion: IotaConsentRecordFixtures.shareRequest.jwtAssertion,
          );

          final result = await service.tryAutomaticConsent(
            shareRequest: shareRequestDifferentClient,
            matchedCredentials: IotaConsentRecordFixtures.claimedCredentials(
              available: [IotaConsentRecordFixtures.makeParsedVc()],
            ),
            verifierMetadata: IotaConsentRecordFixtures.verifierMetadata,
            vaultId: IotaConsentRecordFixtures.vaultId,
            requestHash: IotaConsentRecordFixtures.requestHash,
          );

          expect(result, isA<AutoConsentDeclined>());
        },
      );

      test(
        'should return AutoConsentDeclined when the VC no longer satisfies the descriptor constraints',
        () async {
          // The stored record points to 'vc-1'. The VC is still available,
          // but the PD now requires $.type to contain 'EmailCredential' —
          // a constraint the fixture VC (type: ['VerifiableCredential']) cannot satisfy.
          when(() => store.findAllByRequestHash(any())).thenAnswer(
            (_) async => [
              IotaConsentRecordFixtures.autoShareEnabledMatchingHash(),
            ],
          );

          final shareRequestWithConstraint = PexShareRequest(
            request: IotaConsentRecordFixtures.shareRequest.request,
            presentationDefinition: const {
              'id': 'def-1',
              'input_descriptors': [
                {
                  'id': 'descriptor-1',
                  'constraints': {
                    'fields': [
                      {
                        'path': [r'$.type'],
                        'filter': {
                          'type': 'array',
                          'contains': {'const': 'EmailCredential'},
                        },
                      },
                    ],
                  },
                },
              ],
            },
            jwtAssertion: IotaConsentRecordFixtures.shareRequest.jwtAssertion,
          );

          final result = await service.tryAutomaticConsent(
            shareRequest: shareRequestWithConstraint,
            matchedCredentials: IotaConsentRecordFixtures.claimedCredentials(
              available: [IotaConsentRecordFixtures.makeParsedVc()],
            ),
            verifierMetadata: IotaConsentRecordFixtures.verifierMetadata,
            vaultId: IotaConsentRecordFixtures.vaultId,
            requestHash: IotaConsentRecordFixtures.requestHash,
          );

          expect(result, isA<AutoConsentDeclined>());
        },
      );

      test(
        'should return AutoConsentApproved with the redirect URI when all checks pass',
        () async {
          final redirectUri = Uri.parse(
            'https://verifier.example.com/callback',
          );

          when(() => store.findAllByRequestHash(any())).thenAnswer(
            (_) async => [
              IotaConsentRecordFixtures.autoShareEnabledMatchingHash(),
            ],
          );

          when(
            () => shareResponseService.submitShareResponse(
              shareRequest: any(named: 'shareRequest'),
              selectedCredentials: any(named: 'selectedCredentials'),
              acceptResponseUri: any(named: 'acceptResponseUri'),
            ),
          ).thenAnswer((_) async => redirectUri);

          final result = await service.tryAutomaticConsent(
            shareRequest: IotaConsentRecordFixtures.shareRequest,
            matchedCredentials: IotaConsentRecordFixtures.claimedCredentials(
              available: [IotaConsentRecordFixtures.makeParsedVc()],
            ),
            verifierMetadata: IotaConsentRecordFixtures.verifierMetadata,
            vaultId: IotaConsentRecordFixtures.vaultId,
            requestHash: IotaConsentRecordFixtures.requestHash,
          );

          expect(result, isA<AutoConsentApproved>());
          expect((result as AutoConsentApproved).redirectUri, redirectUri);
        },
      );

      test(
        'should preserve the VC lookup order from the stored sharedVcIds list',
        () async {
          final vc1 = IotaConsentRecordFixtures.makeParsedVc(id: 'vc-1');
          final vc2 = IotaConsentRecordFixtures.makeParsedVc(id: 'vc-2');

          when(() => store.findAllByRequestHash(any())).thenAnswer(
            (_) async => [
              const IotaConsentRecord(
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
            ],
          );

          final shareRequestWith2Descriptors = PexShareRequest(
            request: IotaConsentRecordFixtures.shareRequest.request,
            presentationDefinition: const {
              'id': 'def-1',
              'input_descriptors': [
                {'id': 'desc-1'},
                {'id': 'desc-2'},
              ],
            },
            jwtAssertion: IotaConsentRecordFixtures.shareRequest.jwtAssertion,
          );

          await service.tryAutomaticConsent(
            shareRequest: shareRequestWith2Descriptors,
            matchedCredentials: IotaConsentRecordFixtures.claimedCredentials(
              available: [vc1, vc2],
            ),
            verifierMetadata: IotaConsentRecordFixtures.verifierMetadata,
            vaultId: IotaConsentRecordFixtures.vaultId,
            requestHash: IotaConsentRecordFixtures.requestHash,
          );

          final captured =
              verify(
                    () => shareResponseService.submitShareResponse(
                      shareRequest: any(named: 'shareRequest'),
                      selectedCredentials: captureAny(
                        named: 'selectedCredentials',
                      ),
                      acceptResponseUri: any(named: 'acceptResponseUri'),
                    ),
                  ).captured.single
                  as List<ParsedVerifiableCredential<dynamic>>;

          expect(captured.map((e) => e.id?.toString()), ['vc-2', 'vc-1']);
        },
      );

      test(
        'should return AutoConsentDeclined when the PD has more descriptors than previously shared VCs',
        () async {
          // Record has 1 VC; PD now has 2 descriptors — count mismatch.
          when(() => store.findAllByRequestHash(any())).thenAnswer(
            (_) async => [
              IotaConsentRecordFixtures.autoShareEnabledMatchingHash(),
            ],
          );

          final twoDescriptorRequest = PexShareRequest(
            request: IotaConsentRecordFixtures.shareRequest.request,
            presentationDefinition: const {
              'id': 'def-1',
              'input_descriptors': [
                {'id': 'desc-1'},
                {'id': 'desc-2'},
              ],
            },
            jwtAssertion: IotaConsentRecordFixtures.shareRequest.jwtAssertion,
          );

          final result = await service.tryAutomaticConsent(
            shareRequest: twoDescriptorRequest,
            matchedCredentials: IotaConsentRecordFixtures.claimedCredentials(
              available: [IotaConsentRecordFixtures.makeParsedVc()],
            ),
            verifierMetadata: IotaConsentRecordFixtures.verifierMetadata,
            vaultId: IotaConsentRecordFixtures.vaultId,
            requestHash: IotaConsentRecordFixtures.requestHash,
          );

          expect(result, isA<AutoConsentDeclined>());
          verifyNever(
            () => shareResponseService.submitShareResponse(
              shareRequest: any(named: 'shareRequest'),
              selectedCredentials: any(named: 'selectedCredentials'),
              acceptResponseUri: any(named: 'acceptResponseUri'),
            ),
          );
        },
      );

      test(
        'should return AutoConsentDeclined when the PD has fewer descriptors than previously shared VCs',
        () async {
          // Record has 2 VCs; PD now has only 1 descriptor — count mismatch.
          when(() => store.findAllByRequestHash(any())).thenAnswer(
            (_) async => [
              const IotaConsentRecord(
                hash: 'mock_hash',
                requestHash: IotaConsentRecordFixtures.requestHash,
                sharedAt: IotaConsentRecordFixtures.sharedAt,
                profileName: IotaConsentRecordFixtures.profileName,
                profileId: IotaConsentRecordFixtures.profileId,
                clientId: IotaConsentRecordFixtures.clientId,
                isAutoShareEnabled: true,
                isConsentManagementEnabled: false,
                sharedVcIds: ['vc-1', 'vc-2'],
                claimedVcTypesCsv: 'SomeType',
              ),
            ],
          );

          final result = await service.tryAutomaticConsent(
            shareRequest: IotaConsentRecordFixtures.shareRequest,
            matchedCredentials: IotaConsentRecordFixtures.claimedCredentials(
              available: [
                IotaConsentRecordFixtures.makeParsedVc(id: 'vc-1'),
                IotaConsentRecordFixtures.makeParsedVc(id: 'vc-2'),
              ],
            ),
            verifierMetadata: IotaConsentRecordFixtures.verifierMetadata,
            vaultId: IotaConsentRecordFixtures.vaultId,
            requestHash: IotaConsentRecordFixtures.requestHash,
          );

          expect(result, isA<AutoConsentDeclined>());
          verifyNever(
            () => shareResponseService.submitShareResponse(
              shareRequest: any(named: 'shareRequest'),
              selectedCredentials: any(named: 'selectedCredentials'),
              acceptResponseUri: any(named: 'acceptResponseUri'),
            ),
          );
        },
      );

      test(
        'should throw TdkException with invalidPresentationDefinition when an input_descriptors entry is malformed',
        () async {
          when(() => store.findAllByRequestHash(any())).thenAnswer(
            (_) async => [
              IotaConsentRecordFixtures.autoShareEnabledMatchingHash(),
            ],
          );

          final shareRequestMalformed = PexShareRequest(
            request: IotaConsentRecordFixtures.shareRequest.request,
            presentationDefinition: const {
              'id': 'def-1',
              'input_descriptors': [42],
            },
            jwtAssertion: IotaConsentRecordFixtures.shareRequest.jwtAssertion,
          );

          await expectLater(
            () => service.tryAutomaticConsent(
              shareRequest: shareRequestMalformed,
              matchedCredentials: IotaConsentRecordFixtures.claimedCredentials(
                available: [IotaConsentRecordFixtures.makeParsedVc()],
              ),
              verifierMetadata: IotaConsentRecordFixtures.verifierMetadata,
              vaultId: IotaConsentRecordFixtures.vaultId,
              requestHash: IotaConsentRecordFixtures.requestHash,
            ),
            throwsA(
              isA<TdkException>().having(
                (e) => e.code,
                'code',
                TdkExceptionType.invalidPresentationDefinition.code,
              ),
            ),
          );
        },
      );

      test(
        'should pass the definitionId from the PD to submitShareResponse',
        () async {
          when(() => store.findAllByRequestHash(any())).thenAnswer(
            (_) async => [
              IotaConsentRecordFixtures.autoShareEnabledMatchingHash(),
            ],
          );

          await service.tryAutomaticConsent(
            shareRequest: IotaConsentRecordFixtures.shareRequest,
            matchedCredentials: IotaConsentRecordFixtures.claimedCredentials(
              available: [IotaConsentRecordFixtures.makeParsedVc()],
            ),
            verifierMetadata: IotaConsentRecordFixtures.verifierMetadata,
            vaultId: IotaConsentRecordFixtures.vaultId,
            requestHash: IotaConsentRecordFixtures.requestHash,
          );

          final captured =
              verify(
                    () => shareResponseService.submitShareResponse(
                      shareRequest: captureAny(named: 'shareRequest'),
                      selectedCredentials: any(named: 'selectedCredentials'),
                      acceptResponseUri: any(named: 'acceptResponseUri'),
                    ),
                  ).captured.single
                  as Oid4vpShareRequest;

          expect(
            (captured as PexShareRequest).presentationDefinition['id'],
            'def-1',
          );
        },
      );

      test(
        'should throw TdkException with failedToReadConsentRecord when the store throws',
        () async {
          when(
            () => store.findAllByRequestHash(any()),
          ).thenThrow(Exception('storage error'));

          await expectLater(
            () => service.tryAutomaticConsent(
              shareRequest: IotaConsentRecordFixtures.shareRequest,
              matchedCredentials:
                  IotaConsentRecordFixtures.claimedCredentials(),
              verifierMetadata: IotaConsentRecordFixtures.verifierMetadata,
              vaultId: IotaConsentRecordFixtures.vaultId,
              requestHash: IotaConsentRecordFixtures.requestHash,
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

      test(
        'should rethrow a TdkException from the store without wrapping',
        () async {
          final original = TdkException(
            message: 'Deserialization failed: unexpected null field.',
            code: TdkExceptionType.failedToReadConsentRecord.code,
          );

          when(() => store.findAllByRequestHash(any())).thenThrow(original);

          await expectLater(
            () => service.tryAutomaticConsent(
              shareRequest: IotaConsentRecordFixtures.shareRequest,
              matchedCredentials:
                  IotaConsentRecordFixtures.claimedCredentials(),
              verifierMetadata: IotaConsentRecordFixtures.verifierMetadata,
              vaultId: IotaConsentRecordFixtures.vaultId,
              requestHash: IotaConsentRecordFixtures.requestHash,
            ),
            throwsA(same(original)),
          );
        },
      );

      test(
        'should throw TdkException with invalidPresentationDefinition when definition id is missing',
        () async {
          when(() => store.findAllByRequestHash(any())).thenAnswer(
            (_) async => [
              IotaConsentRecordFixtures.autoShareEnabledMatchingHash(),
            ],
          );

          final shareRequestWithoutId = PexShareRequest(
            request: IotaConsentRecordFixtures.shareRequest.request,
            presentationDefinition: const {
              // no 'id' key — triggers the invalidPresentationDefinition guard
              'input_descriptors': [
                {'id': 'descriptor-0'},
              ],
            },
            jwtAssertion: IotaConsentRecordFixtures.shareRequest.jwtAssertion,
          );

          await expectLater(
            () => service.tryAutomaticConsent(
              shareRequest: shareRequestWithoutId,
              matchedCredentials: IotaConsentRecordFixtures.claimedCredentials(
                available: [IotaConsentRecordFixtures.makeParsedVc()],
              ),
              verifierMetadata: IotaConsentRecordFixtures.verifierMetadata,
              vaultId: IotaConsentRecordFixtures.vaultId,
              requestHash: IotaConsentRecordFixtures.requestHash,
            ),
            throwsA(
              isA<TdkException>().having(
                (e) => e.code,
                'code',
                TdkExceptionType.invalidPresentationDefinition.code,
              ),
            ),
          );
        },
      );

      test(
        'should throw TdkException with invalidPresentationDefinition when input_descriptors is missing',
        () async {
          when(() => store.findAllByRequestHash(any())).thenAnswer(
            (_) async => [
              IotaConsentRecordFixtures.autoShareEnabledMatchingHash(),
            ],
          );

          final shareRequestWithoutDescriptors = PexShareRequest(
            request: IotaConsentRecordFixtures.shareRequest.request,
            presentationDefinition: const {'id': 'def-1'},
            jwtAssertion: IotaConsentRecordFixtures.shareRequest.jwtAssertion,
          );

          await expectLater(
            () => service.tryAutomaticConsent(
              shareRequest: shareRequestWithoutDescriptors,
              matchedCredentials: IotaConsentRecordFixtures.claimedCredentials(
                available: [IotaConsentRecordFixtures.makeParsedVc()],
              ),
              verifierMetadata: IotaConsentRecordFixtures.verifierMetadata,
              vaultId: IotaConsentRecordFixtures.vaultId,
              requestHash: IotaConsentRecordFixtures.requestHash,
            ),
            throwsA(
              isA<TdkException>().having(
                (e) => e.code,
                'code',
                TdkExceptionType.invalidPresentationDefinition.code,
              ),
            ),
          );
        },
      );

      test(
        'should return AutoConsentDeclined when the descriptor constraint was tightened since the original share',
        () async {
          // Record has vc-1 (type: VerifiableCredential). The descriptor id
          // is the same ("descriptor-1"), but the verifier tightened the
          // constraint to require PhoneCredential since the original share.
          // The PEX loop must reject it even though the descriptor id matches.
          when(() => store.findAllByRequestHash(any())).thenAnswer(
            (_) async => [
              IotaConsentRecordFixtures.autoShareEnabledMatchingHash(),
            ],
          );

          final shareRequestChangedConstraint = PexShareRequest(
            request: IotaConsentRecordFixtures.shareRequest.request,
            presentationDefinition: const {
              'id': 'def-1',
              'input_descriptors': [
                {
                  'id': 'descriptor-1',
                  'constraints': {
                    'fields': [
                      {
                        'path': [r'$.type'],
                        'filter': {
                          'type': 'array',
                          'contains': {'const': 'PhoneCredential'},
                        },
                      },
                    ],
                  },
                },
              ],
            },
            jwtAssertion: IotaConsentRecordFixtures.shareRequest.jwtAssertion,
          );

          final result = await service.tryAutomaticConsent(
            shareRequest: shareRequestChangedConstraint,
            matchedCredentials: IotaConsentRecordFixtures.claimedCredentials(
              available: [IotaConsentRecordFixtures.makeParsedVc()],
            ),
            verifierMetadata: IotaConsentRecordFixtures.verifierMetadata,
            vaultId: IotaConsentRecordFixtures.vaultId,
            requestHash: IotaConsentRecordFixtures.requestHash,
          );

          expect(result, isA<AutoConsentDeclined>());
          verifyNever(
            () => shareResponseService.submitShareResponse(
              shareRequest: any(named: 'shareRequest'),
              selectedCredentials: any(named: 'selectedCredentials'),
              acceptResponseUri: any(named: 'acceptResponseUri'),
            ),
          );
        },
      );
    });

    group('tryAutomaticConsent (DCQL)', () {
      test(
        'returns AutoConsentDeclined when no stored records match',
        () async {
          when(
            () => store.findAllByRequestHash(any()),
          ).thenAnswer((_) async => []);

          final result = await service.tryAutomaticConsent(
            shareRequest: IotaConsentRecordFixtures.dcqlShareRequest,
            matchedCredentials: IotaConsentRecordFixtures.claimedCredentials(),
            verifierMetadata: IotaConsentRecordFixtures.verifierMetadata,
            vaultId: IotaConsentRecordFixtures.vaultId,
            requestHash: IotaConsentRecordFixtures.requestHash,
          );

          expect(result, isA<AutoConsentDeclined>());
        },
      );

      test('returns AutoConsentApproved when all guards pass', () async {
        when(() => store.findAllByRequestHash(any())).thenAnswer(
          (_) async => [
            IotaConsentRecordFixtures.dcqlAutoShareEnabledMatchingHash(),
          ],
        );

        final result = await service.tryAutomaticConsent(
          shareRequest: IotaConsentRecordFixtures.dcqlShareRequest,
          matchedCredentials: IotaConsentRecordFixtures.claimedCredentials(
            available: [IotaConsentRecordFixtures.makeParsedVc()],
          ),
          verifierMetadata: IotaConsentRecordFixtures.verifierMetadata,
          vaultId: IotaConsentRecordFixtures.vaultId,
          requestHash: IotaConsentRecordFixtures.requestHash,
        );

        expect(result, isA<AutoConsentApproved>());
        verify(
          () => shareResponseService.submitShareResponse(
            shareRequest: any(named: 'shareRequest'),
            selectedCredentials: any(named: 'selectedCredentials'),
            acceptResponseUri: any(named: 'acceptResponseUri'),
          ),
        ).called(1);
      });

      test(
        'returns AutoConsentDeclined when a previously shared VC is no longer in the vault',
        () async {
          when(() => store.findAllByRequestHash(any())).thenAnswer(
            (_) async => [
              IotaConsentRecordFixtures.dcqlAutoShareEnabledMatchingHash(),
            ],
          );

          // Vault is empty — the previously shared VC is gone.
          final result = await service.tryAutomaticConsent(
            shareRequest: IotaConsentRecordFixtures.dcqlShareRequest,
            matchedCredentials: IotaConsentRecordFixtures.claimedCredentials(),
            verifierMetadata: IotaConsentRecordFixtures.verifierMetadata,
            vaultId: IotaConsentRecordFixtures.vaultId,
            requestHash: IotaConsentRecordFixtures.requestHash,
          );

          expect(result, isA<AutoConsentDeclined>());
          verifyNever(
            () => shareResponseService.submitShareResponse(
              shareRequest: any(named: 'shareRequest'),
              selectedCredentials: any(named: 'selectedCredentials'),
              acceptResponseUri: any(named: 'acceptResponseUri'),
            ),
          );
        },
      );

      test(
        'returns AutoConsentDeclined when credential query count differs from stored VC count',
        () async {
          final twoQueryRequest = DcqlShareRequest(
            request: IotaConsentRecordFixtures.dcqlShareRequest.request,
            dcqlQuery: const DcqlQuery(
              credentials: [
                DcqlCredentialQuery(id: 'query-1'),
                DcqlCredentialQuery(id: 'query-2'),
              ],
            ),
            jwtAssertion:
                IotaConsentRecordFixtures.dcqlShareRequest.jwtAssertion,
          );
          when(() => store.findAllByRequestHash(any())).thenAnswer(
            (_) async => [
              // Record has one VC, but the new request has two queries.
              IotaConsentRecordFixtures.dcqlAutoShareEnabledMatchingHash(),
            ],
          );

          final result = await service.tryAutomaticConsent(
            shareRequest: twoQueryRequest,
            matchedCredentials: IotaConsentRecordFixtures.claimedCredentials(
              available: [IotaConsentRecordFixtures.makeParsedVc()],
            ),
            verifierMetadata: IotaConsentRecordFixtures.verifierMetadata,
            vaultId: IotaConsentRecordFixtures.vaultId,
            requestHash: IotaConsentRecordFixtures.requestHash,
          );

          expect(result, isA<AutoConsentDeclined>());
          verifyNever(
            () => shareResponseService.submitShareResponse(
              shareRequest: any(named: 'shareRequest'),
              selectedCredentials: any(named: 'selectedCredentials'),
              acceptResponseUri: any(named: 'acceptResponseUri'),
            ),
          );
        },
      );

      test(
        'returns AutoConsentDeclined when the VC does not match the credential query',
        () async {
          // Query requires type EmailV1 but the vault VC has no type filter match.
          final strictTypeRequest = DcqlShareRequest(
            request: IotaConsentRecordFixtures.dcqlShareRequest.request,
            dcqlQuery: const DcqlQuery(
              credentials: [
                DcqlCredentialQuery(
                  id: 'query-1',
                  meta: DcqlCredentialMeta(
                    typeValues: [
                      ['EmailV1'],
                    ],
                  ),
                ),
              ],
            ),
            jwtAssertion:
                IotaConsentRecordFixtures.dcqlShareRequest.jwtAssertion,
          );
          when(() => store.findAllByRequestHash(any())).thenAnswer(
            (_) async => [
              IotaConsentRecordFixtures.dcqlAutoShareEnabledMatchingHash(),
            ],
          );

          final result = await service.tryAutomaticConsent(
            shareRequest: strictTypeRequest,
            matchedCredentials: IotaConsentRecordFixtures.claimedCredentials(
              // VC has no EmailV1 type — will not match the query.
              available: [IotaConsentRecordFixtures.makeParsedVc()],
            ),
            verifierMetadata: IotaConsentRecordFixtures.verifierMetadata,
            vaultId: IotaConsentRecordFixtures.vaultId,
            requestHash: IotaConsentRecordFixtures.requestHash,
          );

          expect(result, isA<AutoConsentDeclined>());
          verifyNever(
            () => shareResponseService.submitShareResponse(
              shareRequest: any(named: 'shareRequest'),
              selectedCredentials: any(named: 'selectedCredentials'),
              acceptResponseUri: any(named: 'acceptResponseUri'),
            ),
          );
        },
      );

      test('returns AutoConsentDeclined when clientId has changed', () async {
        final differentClientRequest = DcqlShareRequest(
          request: const IotaRequest(
            responseType: 'vp_token',
            responseMode: 'direct_post',
            acceptResponseUri: 'https://verifier.example.com/accept',
            rejectResponseUri: 'https://verifier.example.com/reject',
            state: 'test_state',
            nonce: 'test_nonce',
            clientId: 'did:key:differentVerifier',
          ),
          dcqlQuery: IotaConsentRecordFixtures.dcqlShareRequest.dcqlQuery,
          jwtAssertion: IotaConsentRecordFixtures.dcqlShareRequest.jwtAssertion,
        );
        when(() => store.findAllByRequestHash(any())).thenAnswer(
          (_) async => [
            IotaConsentRecordFixtures.dcqlAutoShareEnabledMatchingHash(),
          ],
        );

        final result = await service.tryAutomaticConsent(
          shareRequest: differentClientRequest,
          matchedCredentials: IotaConsentRecordFixtures.claimedCredentials(
            available: [IotaConsentRecordFixtures.makeParsedVc()],
          ),
          verifierMetadata: IotaConsentRecordFixtures.verifierMetadata,
          vaultId: IotaConsentRecordFixtures.vaultId,
          requestHash: IotaConsentRecordFixtures.requestHash,
        );

        expect(result, isA<AutoConsentDeclined>());
        verifyNever(
          () => shareResponseService.submitShareResponse(
            shareRequest: any(named: 'shareRequest'),
            selectedCredentials: any(named: 'selectedCredentials'),
            acceptResponseUri: any(named: 'acceptResponseUri'),
          ),
        );
      });

      test(
        'returns AutoConsentDeclined when the verifier fingerprint has changed',
        () async {
          when(() => store.findAllByRequestHash(any())).thenAnswer(
            (_) async => [
              IotaConsentRecordFixtures.dcqlAutoShareEnabledMatchingHash(),
            ],
          );
          // Mock returns a hash that does not equal record.hash ('mock_hash').
          when(
            () => cryptography.createHash(hashSource: any(named: 'hashSource')),
          ).thenReturn('different_hash');

          final result = await service.tryAutomaticConsent(
            shareRequest: IotaConsentRecordFixtures.dcqlShareRequest,
            matchedCredentials: IotaConsentRecordFixtures.claimedCredentials(
              available: [IotaConsentRecordFixtures.makeParsedVc()],
            ),
            verifierMetadata: IotaConsentRecordFixtures.verifierMetadata,
            vaultId: IotaConsentRecordFixtures.vaultId,
            requestHash: IotaConsentRecordFixtures.requestHash,
          );

          expect(result, isA<AutoConsentDeclined>());
          verifyNever(
            () => shareResponseService.submitShareResponse(
              shareRequest: any(named: 'shareRequest'),
              selectedCredentials: any(named: 'selectedCredentials'),
              acceptResponseUri: any(named: 'acceptResponseUri'),
            ),
          );
        },
      );
    });

    group('tryAutomaticConsent (DCQL with credential_sets)', () {
      test(
        'returns AutoConsentApproved when stored VC satisfies one option of a required set',
        () async {
          // vc-1 matches query-1; the set has options [[query-1], [query-2]]
          // so covering query-1 is enough.
          when(() => store.findAllByRequestHash(any())).thenAnswer(
            (_) async => [
              IotaConsentRecordFixtures.dcqlWithSetsAutoShareMatchingHash(),
            ],
          );

          final result = await service.tryAutomaticConsent(
            shareRequest: IotaConsentRecordFixtures.dcqlShareRequestWithSets,
            matchedCredentials: IotaConsentRecordFixtures.claimedCredentials(
              available: [IotaConsentRecordFixtures.makeParsedVc()],
            ),
            verifierMetadata: IotaConsentRecordFixtures.verifierMetadata,
            vaultId: IotaConsentRecordFixtures.vaultId,
            requestHash: IotaConsentRecordFixtures.requestHash,
          );

          expect(result, isA<AutoConsentApproved>());
        },
      );

      test(
        'returns AutoConsentDeclined when the stored VC no longer matches any credential query',
        () async {
          // Both queries now require EmailV1 type; vc-1 has no such type.
          final strictRequest = DcqlShareRequest(
            request: IotaConsentRecordFixtures.dcqlShareRequestWithSets.request,
            dcqlQuery: const DcqlQuery(
              credentials: [
                DcqlCredentialQuery(
                  id: 'query-1',
                  meta: DcqlCredentialMeta(
                    typeValues: [
                      ['EmailV1'],
                    ],
                  ),
                ),
                DcqlCredentialQuery(
                  id: 'query-2',
                  meta: DcqlCredentialMeta(
                    typeValues: [
                      ['EmailV1'],
                    ],
                  ),
                ),
              ],
              credentialSets: [
                DcqlCredentialSetQuery(
                  options: [
                    ['query-1'],
                    ['query-2'],
                  ],
                ),
              ],
            ),
            jwtAssertion: 'test_jwt',
          );
          when(() => store.findAllByRequestHash(any())).thenAnswer(
            (_) async => [
              IotaConsentRecordFixtures.dcqlWithSetsAutoShareMatchingHash(),
            ],
          );

          final result = await service.tryAutomaticConsent(
            shareRequest: strictRequest,
            matchedCredentials: IotaConsentRecordFixtures.claimedCredentials(
              available: [IotaConsentRecordFixtures.makeParsedVc()],
            ),
            verifierMetadata: IotaConsentRecordFixtures.verifierMetadata,
            vaultId: IotaConsentRecordFixtures.vaultId,
            requestHash: IotaConsentRecordFixtures.requestHash,
          );

          expect(result, isA<AutoConsentDeclined>());
          verifyNever(
            () => shareResponseService.submitShareResponse(
              shareRequest: any(named: 'shareRequest'),
              selectedCredentials: any(named: 'selectedCredentials'),
              acceptResponseUri: any(named: 'acceptResponseUri'),
            ),
          );
        },
      );

      test(
        'returns AutoConsentDeclined when stored VCs do not satisfy any option of a required set',
        () async {
          // Set requires both query-1 AND query-2 together (AND-option); only
          // vc-1 (matching query-1) is stored, so the AND option is not met.
          final andOptionRequest = DcqlShareRequest(
            request: IotaConsentRecordFixtures.dcqlShareRequestWithSets.request,
            dcqlQuery: const DcqlQuery(
              credentials: [
                DcqlCredentialQuery(id: 'query-1'),
                DcqlCredentialQuery(id: 'query-2'),
              ],
              credentialSets: [
                DcqlCredentialSetQuery(
                  options: [
                    ['query-1', 'query-2'],
                  ],
                ),
              ],
            ),
            jwtAssertion: 'test_jwt',
          );
          when(() => store.findAllByRequestHash(any())).thenAnswer(
            (_) async => [
              IotaConsentRecordFixtures.dcqlWithSetsAutoShareMatchingHash(),
            ],
          );

          final result = await service.tryAutomaticConsent(
            shareRequest: andOptionRequest,
            matchedCredentials: IotaConsentRecordFixtures.claimedCredentials(
              available: [IotaConsentRecordFixtures.makeParsedVc()],
            ),
            verifierMetadata: IotaConsentRecordFixtures.verifierMetadata,
            vaultId: IotaConsentRecordFixtures.vaultId,
            requestHash: IotaConsentRecordFixtures.requestHash,
          );

          expect(result, isA<AutoConsentDeclined>());
          verifyNever(
            () => shareResponseService.submitShareResponse(
              shareRequest: any(named: 'shareRequest'),
              selectedCredentials: any(named: 'selectedCredentials'),
              acceptResponseUri: any(named: 'acceptResponseUri'),
            ),
          );
        },
      );

      test(
        'returns AutoConsentApproved when an optional set is not satisfied but the required set is',
        () async {
          // required set: options [[query-1], [query-2]] — vc-1 satisfies via query-1
          // optional set: options [[query-2]] — not covered, but required:false
          final optionalSetRequest = DcqlShareRequest(
            request: IotaConsentRecordFixtures.dcqlShareRequestWithSets.request,
            dcqlQuery: const DcqlQuery(
              credentials: [
                DcqlCredentialQuery(id: 'query-1'),
                DcqlCredentialQuery(id: 'query-2'),
              ],
              credentialSets: [
                DcqlCredentialSetQuery(
                  options: [
                    ['query-1'],
                    ['query-2'],
                  ],
                ),
                DcqlCredentialSetQuery(
                  options: [
                    ['query-2'],
                  ],
                  required: false,
                ),
              ],
            ),
            jwtAssertion: 'test_jwt',
          );
          when(() => store.findAllByRequestHash(any())).thenAnswer(
            (_) async => [
              IotaConsentRecordFixtures.dcqlWithSetsAutoShareMatchingHash(),
            ],
          );

          final result = await service.tryAutomaticConsent(
            shareRequest: optionalSetRequest,
            matchedCredentials: IotaConsentRecordFixtures.claimedCredentials(
              available: [IotaConsentRecordFixtures.makeParsedVc()],
            ),
            verifierMetadata: IotaConsentRecordFixtures.verifierMetadata,
            vaultId: IotaConsentRecordFixtures.vaultId,
            requestHash: IotaConsentRecordFixtures.requestHash,
          );

          expect(result, isA<AutoConsentApproved>());
        },
      );
    });
  });
}
