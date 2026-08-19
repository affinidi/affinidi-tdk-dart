import 'package:affinidi_tdk_vault/affinidi_tdk_vault.dart';
import 'package:affinidi_tdk_vault/src/repository_decorators/cache_invalidating_profile_repository.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class _RestorableProfileRepository extends Mock
    implements ProfileRepository, RestorableProfileRepository, Restorable {}

void main() {
  test('delegates state and invalidates profiles after import', () async {
    final repository = _RestorableProfileRepository();
    var invalidations = 0;
    final decorated = CacheInvalidatingRestorableProfileRepository(
      repository,
      onProfilesMutated: () => invalidations++,
    );
    const payload = <String, dynamic>{'version': '1.0.0'};
    when(repository.export).thenAnswer((_) async => payload);
    when(() => repository.import(payload)).thenAnswer((_) async {});

    expect(await decorated.export(), payload);
    expect(invalidations, 0);

    await decorated.import(payload);

    verify(() => repository.import(payload)).called(1);
    expect(invalidations, 1);
  });
}
