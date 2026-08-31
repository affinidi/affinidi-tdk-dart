import 'package:affinidi_tdk_vault/affinidi_tdk_vault.dart';
import 'package:affinidi_tdk_vault/src/repository_decorators/cache_invalidating_profile_repository.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class _Repository extends Mock implements ProfileRepository, Restorable {}

void main() {
  group('When importing through a cache-invalidating repository', () {
    test('it delegates state and invalidates profiles', () async {
      final repository = _Repository();
      var invalidations = 0;
      final decorated = CacheInvalidatingRestorableRepository(
        repository,
        onProfilesMutated: () => invalidations++,
      );
      const payload = <String, dynamic>{'schemaVersion': '1.0.0'};
      when(repository.export).thenAnswer((_) async => payload);
      when(() => repository.import(payload)).thenAnswer((_) async {});

      expect(await decorated.export(), payload);
      expect(invalidations, 0);

      await decorated.import(payload);

      verify(() => repository.import(payload)).called(1);
      expect(invalidations, 1);
    });
  });
}
