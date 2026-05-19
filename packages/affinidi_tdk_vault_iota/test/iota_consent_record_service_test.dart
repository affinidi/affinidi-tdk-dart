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
          () => store.findByRequestHashAndDid(any(), any()),
        ).thenAnswer((_) async => null);

        await service.saveConsentRecord(
          clientId: IotaConsentRecordFixtures.clientId,
          presentationDefinition: {},
          verifierMetadata: IotaConsentRecordFixtures.verifierMetadata,
          profileId: IotaConsentRecordFixtures.profileId,
          profileName: IotaConsentRecordFixtures.profileName,
          did: IotaConsentRecordFixtures.did,
          sharedVcIds: ['vc-1'],
          sharedVcTypesCsv: 'SomeType',
          isAutoShareEnabled: true,
        );

        final captured = verify(
          () => store.saveOrUpdate(captureAny()),
        ).captured.single as IotaConsentRecord;

        expect(captured.clientId, IotaConsentRecordFixtures.clientId);
        expect(captured.did, IotaConsentRecordFixtures.did);
        expect(captured.isAutoShareEnabled, isTrue);
        expect(captured.sharedVcIds, ['vc-1']);
      });

      test('preserves sharedAt when updating an existing record', () async {
        when(
          () => store.findByRequestHashAndDid(any(), any()),
        ).thenAnswer((_) async => IotaConsentRecordFixtures.existing());

        await service.saveConsentRecord(
          clientId: IotaConsentRecordFixtures.clientId,
          presentationDefinition: {},
          verifierMetadata: IotaConsentRecordFixtures.verifierMetadata,
          profileId: IotaConsentRecordFixtures.profileId,
          profileName: IotaConsentRecordFixtures.profileName,
          did: IotaConsentRecordFixtures.did,
          sharedVcIds: ['vc-1', 'vc-2'],
          sharedVcTypesCsv: 'SomeType',
          isAutoShareEnabled: true,
        );

        final captured = verify(
          () => store.saveOrUpdate(captureAny()),
        ).captured.single as IotaConsentRecord;

        expect(captured.sharedAt, IotaConsentRecordFixtures.sharedAt);
        expect(captured.sharedVcIds, ['vc-1', 'vc-2']);
      });

      test('throws TdkException with failedToPersistConsentRecord when the store throws', () async {
        when(
          () => store.findByRequestHashAndDid(any(), any()),
        ).thenAnswer((_) async => null);

        when(
          () => store.saveOrUpdate(any()),
        ).thenThrow(Exception('db error'));

        await expectLater(
          () => service.saveConsentRecord(
            clientId: IotaConsentRecordFixtures.clientId,
            presentationDefinition: {},
            verifierMetadata: IotaConsentRecordFixtures.verifierMetadata,
            profileId: IotaConsentRecordFixtures.profileId,
            profileName: IotaConsentRecordFixtures.profileName,
            did: IotaConsentRecordFixtures.did,
            sharedVcIds: [],
            sharedVcTypesCsv: '',
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
      });
    });
  });
}
