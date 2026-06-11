import 'package:affinidi_tdk_vault_iota/affinidi_tdk_vault_iota.dart';
import 'package:affinidi_tdk_vault_iota/src/services/dcql_share_requirements_matcher_service.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ssi/ssi.dart';
import 'package:test/test.dart';

import 'fixtures/iota_consent_record_fixtures.dart';
import 'fixtures/verifiable_credential_fixtures.dart';
import 'mocks/mock_dcql_share_requirements_matcher.dart';
import 'mocks/mock_pd_classifier.dart';
import 'mocks/mock_share_requirements_matcher.dart';

void main() {
  late MockPDClassifier classifier;
  late MockShareRequirementsMatcher pexMatcher;
  late MockDcqlShareRequirementsMatcher dcqlMatcher;
  late CredentialMatcherService service;

  // Stub results used across tests.
  const stubPexResult = ClaimedCredentialsResult(vcsGroups: {});
  late DcqlMatchedCredentialsResult stubDcqlResult;

  // Fallback requirements returned by the classifier stub.
  const emptyRequirements = PDRequirements(
    claimedDescriptors: [],
    zpdLinkedDescriptors: [],
    idvDescriptors: [],
    dataPoints: {},
    zeroPartyVCs: {},
  );

  setUpAll(() {
    registerFallbackValue(emptyRequirements);
    registerFallbackValue(IotaConsentRecordFixtures.dcqlShareRequest.dcqlQuery);
    registerFallbackValue(<VerifiableCredential>[]);
  });

  setUp(() {
    classifier = MockPDClassifier();
    pexMatcher = MockShareRequirementsMatcher();
    dcqlMatcher = MockDcqlShareRequirementsMatcher();

    stubDcqlResult = DcqlMatchedCredentialsResult(
      vcsGroups: const {},
      dcqlQuery: IotaConsentRecordFixtures.dcqlShareRequest.dcqlQuery,
    );

    service = CredentialMatcherService(
      pdClassifier: classifier,
      pexMatcher: pexMatcher,
      dcqlMatcher: dcqlMatcher,
    );
  });

  group('CredentialMatcherService', () {
    final vcs = [buildTestVc(type: 'UniversityDegree')];

    group('PEX routing', () {
      setUp(() {
        when(() => classifier.classify(any())).thenReturn(emptyRequirements);
        when(
          () => pexMatcher.match(any(), any()),
        ).thenAnswer((_) async => stubPexResult);
      });

      test('classifies the PD and delegates to the pex matcher', () async {
        final pexRequest = IotaConsentRecordFixtures.shareRequest;

        await service.match(pexRequest, vcs);

        verify(
          () => classifier.classify(pexRequest.presentationDefinition),
        ).called(1);
        verify(() => pexMatcher.match(emptyRequirements, vcs)).called(1);
        verifyNever(() => dcqlMatcher.match(any(), any()));
      });

      test('passes the pex matcher result through unchanged', () async {
        final result = await service.match(
          IotaConsentRecordFixtures.shareRequest,
          vcs,
        );

        expect(result, same(stubPexResult));
      });
    });

    group('DCQL routing', () {
      setUp(() {
        when(
          () => dcqlMatcher.match(any(), any()),
        ).thenAnswer((_) async => stubDcqlResult);
      });

      test('delegates to the dcql matcher and skips pex entirely', () async {
        final dcqlRequest = IotaConsentRecordFixtures.dcqlShareRequest;

        await service.match(dcqlRequest, vcs);

        verify(() => dcqlMatcher.match(dcqlRequest.dcqlQuery, vcs)).called(1);
        verifyNever(() => classifier.classify(any()));
        verifyNever(() => pexMatcher.match(any(), any()));
      });

      test('passes the dcql matcher result through unchanged', () async {
        final result = await service.match(
          IotaConsentRecordFixtures.dcqlShareRequest,
          vcs,
        );

        expect(result, same(stubDcqlResult));
      });
    });
  });
}
