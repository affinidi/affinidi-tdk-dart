import 'package:affinidi_tdk_vault/affinidi_tdk_vault.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import 'mocks/mock_profile_repository.dart';

void main() {
  group('VaultProfilesBackupSource', () {
    late MockProfileRepository repository;

    final invalidBackupFormat = isA<TdkException>().having(
      (e) => e.code,
      'code',
      equals('invalid_backup_format'),
    );

    setUpAll(() {
      registerFallbackValue(buildTestProfile(did: 'fallback', accountIndex: 0));
    });

    setUp(() {
      repository = MockProfileRepository();
    });

    VaultProfilesBackupSource buildSource() =>
        VaultProfilesBackupSource(profileRepository: repository);

    group('export', () {
      test('serialises each profile keyed by did', () async {
        when(() => repository.listProfiles()).thenAnswer(
          (_) async => [
            buildTestProfile(
              did: 'did-1',
              accountIndex: 1,
              name: 'Alice',
              description: 'first',
              profilePictureURI: 'pic',
            ),
          ],
        );

        final exported = await buildSource().export();

        expect(exported, {
          'profiles': [
            {
              'accountIndex': 1,
              'name': 'Alice',
              'did': 'did-1',
              'description': 'first',
              'profilePictureURI': 'pic',
            },
          ],
        });
      });
    });

    group('import', () {
      test('creates missing profiles in account-index order', () async {
        when(() => repository.listProfiles()).thenAnswer((_) async => const []);
        when(
          () => repository.createProfile(
            name: any(named: 'name'),
            description: any(named: 'description'),
          ),
        ).thenAnswer(
          (invocation) async => buildTestProfile(
            did: 'created',
            accountIndex: 1,
            name: invocation.namedArguments[#name] as String,
          ),
        );

        await buildSource().import({
          'profiles': [
            {'accountIndex': 2, 'name': 'B', 'did': 'did-2'},
            {'accountIndex': 1, 'name': 'A', 'did': 'did-1'},
          ],
        });

        final created = verify(
          () => repository.createProfile(
            name: captureAny(named: 'name'),
            description: any(named: 'description'),
          ),
        ).captured;
        expect(created, equals(['A', 'B']));
      });

      test('updates the profile picture when present', () async {
        when(() => repository.listProfiles()).thenAnswer((_) async => const []);
        when(
          () => repository.createProfile(
            name: any(named: 'name'),
            description: any(named: 'description'),
          ),
        ).thenAnswer(
          (_) async => buildTestProfile(did: 'did-1', accountIndex: 1),
        );
        when(() => repository.updateProfile(any())).thenAnswer((_) async {});

        await buildSource().import({
          'profiles': [
            {
              'accountIndex': 1,
              'name': 'A',
              'did': 'did-1',
              'profilePictureURI': 'pic',
            },
          ],
        });

        final updated =
            verify(() => repository.updateProfile(captureAny())).captured.single
                as Profile;
        expect(updated.profilePictureURI, equals('pic'));
      });

      test('skips profiles whose did already exists', () async {
        when(() => repository.listProfiles()).thenAnswer(
          (_) async => [buildTestProfile(did: 'did-1', accountIndex: 1)],
        );

        await buildSource().import({
          'profiles': [
            {'accountIndex': 1, 'name': 'A', 'did': 'did-1'},
          ],
        });

        verifyNever(
          () => repository.createProfile(
            name: any(named: 'name'),
            description: any(named: 'description'),
          ),
        );
      });

      test('throws when the section is missing', () async {
        await expectLater(
          buildSource().import(const {}),
          throwsA(invalidBackupFormat),
        );
      });

      test('throws when an entry is malformed', () async {
        await expectLater(
          buildSource().import({
            'profiles': [
              {'name': 'A'},
            ],
          }),
          throwsA(invalidBackupFormat),
        );
      });
    });
  });
}
