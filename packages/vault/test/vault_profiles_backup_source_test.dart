import 'package:affinidi_tdk_vault/affinidi_tdk_vault.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import 'mocks/mock_profile_repository.dart';

void main() {
  group('VaultProfilesBackupSource', () {
    late MockRestorableProfileRepository repository;

    final invalidBackupFormat = isA<TdkException>().having(
      (e) => e.code,
      'code',
      equals('invalid_backup_format'),
    );

    setUpAll(() {
      registerFallbackValue(buildTestProfile(did: 'fallback', accountIndex: 0));
    });

    setUp(() {
      repository = MockRestorableProfileRepository();
    });

    VaultProfilesBackupSource buildSource() =>
        VaultProfilesBackupSource(profileRepositories: [repository]);

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
              'id': 'id-did-1',
              'accountIndex': 1,
              'name': 'Alice',
              'did': 'did-1',
              'description': 'first',
              'profilePictureURI': 'pic',
              'isLocal': true,
            },
          ],
        });
      });

      test('does not back up cloud (non-restorable) profiles', () async {
        final cloudRepository = MockProfileRepository();
        when(() => cloudRepository.listProfiles()).thenAnswer(
          (_) async => [buildTestProfile(did: 'cloud-did', accountIndex: 9)],
        );
        when(() => repository.listProfiles()).thenAnswer(
          (_) async => [buildTestProfile(did: 'did-1', accountIndex: 1)],
        );

        final source = VaultProfilesBackupSource(
          profileRepositories: [cloudRepository, repository],
        );
        final exported = await source.export();

        final profiles = (exported['profiles'] as List)
            .cast<Map<String, dynamic>>();
        expect(profiles.map((p) => p['did']), ['did-1']);
      });
    });

    group('import', () {
      test('restores local profiles in account-index order', () async {
        when(() => repository.listProfiles()).thenAnswer((_) async => const []);
        when(
          () => repository.restoreProfile(
            accountIndex: any(named: 'accountIndex'),
            name: any(named: 'name'),
            description: any(named: 'description'),
          ),
        ).thenAnswer(
          (invocation) async => buildTestProfile(
            did: 'created',
            accountIndex: invocation.namedArguments[#accountIndex] as int,
            name: invocation.namedArguments[#name] as String,
          ),
        );

        await buildSource().import({
          'profiles': [
            {'accountIndex': 2, 'name': 'B', 'did': 'did-2', 'isLocal': true},
            {'accountIndex': 1, 'name': 'A', 'did': 'did-1', 'isLocal': true},
          ],
        });

        final created = verify(
          () => repository.restoreProfile(
            accountIndex: any(named: 'accountIndex'),
            name: captureAny(named: 'name'),
            description: any(named: 'description'),
          ),
        ).captured;
        expect(created, equals(['A', 'B']));
      });

      test('updates the profile picture when present', () async {
        when(() => repository.listProfiles()).thenAnswer((_) async => const []);
        when(
          () => repository.restoreProfile(
            accountIndex: any(named: 'accountIndex'),
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
              'isLocal': true,
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
            {'accountIndex': 1, 'name': 'A', 'did': 'did-1', 'isLocal': true},
          ],
        });

        verifyNever(
          () => repository.restoreProfile(
            accountIndex: any(named: 'accountIndex'),
            name: any(named: 'name'),
            description: any(named: 'description'),
          ),
        );
      });

      test('skips cloud (non-local) profiles', () async {
        when(() => repository.listProfiles()).thenAnswer((_) async => const []);

        await buildSource().import({
          'profiles': [
            {'accountIndex': 1, 'name': 'A', 'did': 'did-1', 'isLocal': false},
          ],
        });

        verifyNever(
          () => repository.restoreProfile(
            accountIndex: any(named: 'accountIndex'),
            name: any(named: 'name'),
            description: any(named: 'description'),
          ),
        );
      });

      test('does nothing without a local repository', () async {
        final cloudOnly = MockProfileRepository();
        when(() => cloudOnly.listProfiles()).thenAnswer((_) async => const []);

        final source = VaultProfilesBackupSource(
          profileRepositories: [cloudOnly],
        );
        await source.import({
          'profiles': [
            {'accountIndex': 1, 'name': 'A', 'did': 'did-1', 'isLocal': true},
          ],
        });

        verifyNever(
          () => cloudOnly.createProfile(
            name: any(named: 'name'),
            description: any(named: 'description'),
          ),
        );
      });

      test(
        'recreates via restoreProfile when the repository supports it',
        () async {
          final restorable = MockRestorableProfileRepository();
          when(
            () => restorable.listProfiles(),
          ).thenAnswer((_) async => const []);
          when(
            () => restorable.restoreProfile(
              accountIndex: any(named: 'accountIndex'),
              name: any(named: 'name'),
              description: any(named: 'description'),
            ),
          ).thenAnswer(
            (_) async => buildTestProfile(did: 'did-1', accountIndex: 7),
          );

          final source = VaultProfilesBackupSource(
            profileRepositories: [restorable],
          );
          await source.import({
            'profiles': [
              {'accountIndex': 7, 'name': 'A', 'did': 'did-1', 'isLocal': true},
            ],
          });

          verify(
            () => restorable.restoreProfile(
              accountIndex: 7,
              name: 'A',
              description: any(named: 'description'),
            ),
          ).called(1);
          verifyNever(
            () => restorable.createProfile(
              name: any(named: 'name'),
              description: any(named: 'description'),
            ),
          );
        },
      );

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
