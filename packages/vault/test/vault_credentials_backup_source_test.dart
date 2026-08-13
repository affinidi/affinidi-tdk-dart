import 'package:affinidi_tdk_vault/affinidi_tdk_vault.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import 'mocks/mock_digital_credential.dart';
import 'mocks/mock_profile.dart';
import 'mocks/mock_profile_repository.dart';

void main() {
  group('VaultCredentialsBackupSource', () {
    late MockProfileRepository repository;
    late MockCredentialStorage credentialStorage;

    final invalidBackupFormat = isA<TdkException>().having(
      (e) => e.code,
      'code',
      equals('invalid_backup_format'),
    );

    setUpAll(() {
      registerFallbackValue(MockVerifiableCredential());
    });

    setUp(() {
      repository = MockProfileRepository();
      credentialStorage = MockCredentialStorage();
    });

    VaultCredentialsBackupSource buildSource() =>
        VaultCredentialsBackupSource(profileRepository: repository);

    test('exports credentials grouped by profile did', () async {
      final vc = MockVerifiableCredential();
      when(vc.toJson).thenReturn({'type': 'demo'});
      when(
        () => credentialStorage.listCredentials(
          limit: any(named: 'limit'),
          exclusiveStartItemId: any(named: 'exclusiveStartItemId'),
        ),
      ).thenAnswer(
        (_) async => PaginatedList(
          items: [DigitalCredential(verifiableCredential: vc, id: 'c1')],
        ),
      );
      when(() => repository.listProfiles()).thenAnswer(
        (_) async => [
          buildTestProfile(
            did: 'did-1',
            accountIndex: 1,
            credentialStorages: {'s': credentialStorage},
          ),
        ],
      );

      final exported = await buildSource().export();

      expect(exported, {
        'credentials': {
          'did-1': [
            {'type': 'demo'},
          ],
        },
      });
    });

    test('skips credentials for a did with no matching profile', () async {
      when(() => repository.listProfiles()).thenAnswer(
        (_) async => [buildTestProfile(did: 'did-1', accountIndex: 1)],
      );

      await buildSource().import({
        'credentials': {
          'unknown-did': [
            {'type': 'demo'},
          ],
        },
      });

      verifyNever(
        () => credentialStorage.saveCredential(
          verifiableCredential: any(named: 'verifiableCredential'),
        ),
      );
    });

    test('throws when the section is missing', () async {
      await expectLater(
        buildSource().import(const {}),
        throwsA(invalidBackupFormat),
      );
    });

    test('throws when a credential cannot be parsed', () async {
      when(() => repository.listProfiles()).thenAnswer(
        (_) async => [
          buildTestProfile(
            did: 'did-1',
            accountIndex: 1,
            credentialStorages: {'s': credentialStorage},
          ),
        ],
      );

      await expectLater(
        buildSource().import({
          'credentials': {
            'did-1': [42],
          },
        }),
        throwsA(invalidBackupFormat),
      );
    });
  });
}
