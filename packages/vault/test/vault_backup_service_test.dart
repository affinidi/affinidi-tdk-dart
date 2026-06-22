import 'package:affinidi_tdk_vault/affinidi_tdk_vault.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import 'mocks/mock_restorable.dart';

void main() {
  group('VaultBackupService', () {
    late MockRestorable restorableA;
    late MockRestorable restorableB;

    setUp(() {
      restorableA = MockRestorable();
      restorableB = MockRestorable();
    });

    group('createBackup', () {
      test('returns empty map when no restorables are registered', () async {
        final service = VaultBackupService(restorables: const []);
        expect(await service.createBackup(), isEmpty);
      });

      test('returns merged export from a single restorable', () async {
        when(
          () => restorableA.export(),
        ).thenAnswer((_) async => {'key': 'value'});

        final service = VaultBackupService(restorables: [restorableA]);
        final backup = await service.createBackup();

        expect(backup, equals({'key': 'value'}));
        verify(() => restorableA.export()).called(1);
      });

      test('merges exports from multiple restorables', () async {
        when(() => restorableA.export()).thenAnswer((_) async => {'a': 1});
        when(() => restorableB.export()).thenAnswer((_) async => {'b': 2});

        final service = VaultBackupService(
          restorables: [restorableA, restorableB],
        );
        final backup = await service.createBackup();

        expect(backup, equals({'a': 1, 'b': 2}));
        verify(() => restorableA.export()).called(1);
        verify(() => restorableB.export()).called(1);
      });

      test('later component overwrites earlier on key collision', () async {
        when(
          () => restorableA.export(),
        ).thenAnswer((_) async => {'shared': 'from-a', 'only-a': true});
        when(
          () => restorableB.export(),
        ).thenAnswer((_) async => {'shared': 'from-b', 'only-b': true});

        final service = VaultBackupService(
          restorables: [restorableA, restorableB],
        );
        final backup = await service.createBackup();

        expect(backup['shared'], equals('from-b'));
        expect(backup['only-a'], isTrue);
        expect(backup['only-b'], isTrue);
      });
    });

    group('restoreFromBackup', () {
      test('calls import on no restorables without error', () async {
        final service = VaultBackupService(restorables: const []);
        await expectLater(
          service.restoreFromBackup({'key': 'value'}),
          completes,
        );
      });

      test('passes data to a single restorable', () async {
        final data = {'key': 'value'};
        when(() => restorableA.import(data)).thenAnswer((_) async {});

        final service = VaultBackupService(restorables: [restorableA]);
        await service.restoreFromBackup(data);

        verify(() => restorableA.import(data)).called(1);
      });

      test('passes the same data map to every restorable', () async {
        final data = {'a': 1, 'b': 2};
        when(() => restorableA.import(data)).thenAnswer((_) async {});
        when(() => restorableB.import(data)).thenAnswer((_) async {});

        final service = VaultBackupService(
          restorables: [restorableA, restorableB],
        );
        await service.restoreFromBackup(data);

        verify(() => restorableA.import(data)).called(1);
        verify(() => restorableB.import(data)).called(1);
      });

      test('calls import on each restorable exactly once', () async {
        final data = <String, dynamic>{};
        when(() => restorableA.import(any())).thenAnswer((_) async {});
        when(() => restorableB.import(any())).thenAnswer((_) async {});

        final service = VaultBackupService(
          restorables: [restorableA, restorableB],
        );
        await service.restoreFromBackup(data);

        verifyNever(() => restorableA.export());
        verifyNever(() => restorableB.export());
        verify(() => restorableA.import(any())).called(1);
        verify(() => restorableB.import(any())).called(1);
      });
    });
  });
}
