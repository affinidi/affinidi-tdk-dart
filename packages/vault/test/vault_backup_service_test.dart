import 'dart:convert';

import 'package:affinidi_tdk_vault/affinidi_tdk_vault.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import 'mocks/mock_cryptography_service.dart';
import 'mocks/mock_restorable.dart';

void main() {
  group('VaultBackupService', () {
    late MockRestorable restorableA;
    late MockRestorable restorableB;
    late FakeCryptographyService cryptographyService;

    final nonce = utf8.encode('test-nonce-16bytes');
    const passphrase = 'correct-horse-staple';
    const wrongPassphrase = 'incorrect-passphrase';

    VaultBackupService buildService(List<Restorable> restorables) =>
        VaultBackupService(
          restorables: restorables,
          cryptographyService: cryptographyService,
          now: () => DateTime.utc(2024, 1, 2, 3, 4, 5),
        );

    setUp(() {
      restorableA = MockRestorable();
      restorableB = MockRestorable();
      cryptographyService = FakeCryptographyService();
    });

    group('createBackup', () {
      test('produces BackupData with the injected timestamp', () async {
        final service = buildService(const []);

        final backup = await service.createBackup(passphrase: passphrase);

        expect(backup.encryptedBackup, isNotEmpty);
        expect(backup.salt, isNotEmpty);
        expect(backup.timestamp, equals('2024-01-02T03:04:05.000Z'));
      });

      test('rejects a passphrase shorter than the minimum length', () async {
        final service = buildService(const []);

        await expectLater(
          service.createBackup(passphrase: 'short'),
          throwsA(
            isA<TdkException>().having(
              (e) => e.code,
              'code',
              equals('weak_passphrase'),
            ),
          ),
        );
      });

      test('exports every registered restorable', () async {
        when(() => restorableA.export()).thenAnswer((_) async => {'a': 1});
        when(() => restorableB.export()).thenAnswer((_) async => {'b': 2});

        final service = buildService([restorableA, restorableB]);
        await service.createBackup(passphrase: passphrase);

        verify(() => restorableA.export()).called(1);
        verify(() => restorableB.export()).called(1);
      });

      test('wraps a restorable export failure in a TdkException', () async {
        when(() => restorableA.export()).thenThrow(Exception('boom'));

        final service = buildService([restorableA]);

        await expectLater(
          service.createBackup(passphrase: passphrase),
          throwsA(
            isA<TdkException>().having(
              (e) => e.code,
              'code',
              equals('backup_creation_failed'),
            ),
          ),
        );
      });

      test(
        'rethrows a TdkException from a restorable without rewrapping',
        () async {
          final original = TdkException(
            message: 'original',
            code: 'some_other_code',
          );
          when(() => restorableA.export()).thenThrow(original);

          final service = buildService([restorableA]);

          await expectLater(
            service.createBackup(passphrase: passphrase),
            throwsA(
              isA<TdkException>().having(
                (e) => e.code,
                'code',
                'some_other_code',
              ),
            ),
          );
        },
      );
    });

    group('restoreFromBackup', () {
      test('round-trips merged sections back to every restorable', () async {
        when(() => restorableA.export()).thenAnswer((_) async => {'a': 1});
        when(() => restorableB.export()).thenAnswer((_) async => {'b': 2});
        when(() => restorableA.import(any())).thenAnswer((_) async {});
        when(() => restorableB.import(any())).thenAnswer((_) async {});

        final service = buildService([restorableA, restorableB]);
        final backup = await service.createBackup(passphrase: passphrase);
        await service.restoreFromBackup(
          backupData: backup,
          passphrase: passphrase,
        );

        final capturedA = verify(
          () => restorableA.import(captureAny()),
        ).captured.single;
        final capturedB = verify(
          () => restorableB.import(captureAny()),
        ).captured.single;
        expect(capturedA, equals({'a': 1, 'b': 2}));
        expect(capturedB, equals({'a': 1, 'b': 2}));
      });

      test('does not call import when no restorables are registered', () async {
        final service = buildService(const []);
        final backup = await service.createBackup(passphrase: passphrase);

        await expectLater(
          service.restoreFromBackup(backupData: backup, passphrase: passphrase),
          completes,
        );
      });

      test('throws TdkException on an incorrect passphrase', () async {
        when(() => restorableA.export()).thenAnswer((_) async => {'a': 1});

        final service = buildService([restorableA]);
        final backup = await service.createBackup(passphrase: passphrase);

        await expectLater(
          service.restoreFromBackup(
            backupData: backup,
            passphrase: wrongPassphrase,
          ),
          throwsA(isA<TdkException>()),
        );
        verifyNever(() => restorableA.import(any()));
      });

      test(
        'throws TdkException when the decrypted payload is not a backup',
        () async {
          final key = await cryptographyService.Pbkdf2(
            password: passphrase,
            nonce: nonce,
          );
          final malformed = BackupData(
            encryptedBackup: await cryptographyService.Aes256EncryptStringToHex(
              key: key,
              data: jsonEncode({'unexpected': true}),
            ),
            salt: base64Encode(nonce),
            timestamp: '2024-01-02T03:04:05.000Z',
          );

          final service = buildService([restorableA]);

          await expectLater(
            service.restoreFromBackup(
              backupData: malformed,
              passphrase: passphrase,
            ),
            throwsA(
              isA<TdkException>().having(
                (e) => e.code,
                'code',
                equals('invalid_backup_format'),
              ),
            ),
          );
          verifyNever(() => restorableA.import(any()));
        },
      );

      test('throws TdkException when the ciphertext is malformed', () async {
        final malformed = BackupData(
          encryptedBackup: '!!!not-decodable!!!',
          salt: base64Encode(nonce),
          timestamp: '2024-01-02T03:04:05.000Z',
        );

        final service = buildService([restorableA]);

        await expectLater(
          service.restoreFromBackup(
            backupData: malformed,
            passphrase: passphrase,
          ),
          throwsA(
            isA<TdkException>().having(
              (e) => e.code,
              'code',
              equals('invalid_backup_format'),
            ),
          ),
        );
        verifyNever(() => restorableA.import(any()));
      });

      test(
        'throws TdkException when the decrypted payload is not an object',
        () async {
          final key = await cryptographyService.Pbkdf2(
            password: passphrase,
            nonce: nonce,
          );
          final notAnObject = BackupData(
            encryptedBackup: await cryptographyService.Aes256EncryptStringToHex(
              key: key,
              data: jsonEncode([1, 2, 3]),
            ),
            salt: base64Encode(nonce),
            timestamp: '2024-01-02T03:04:05.000Z',
          );

          final service = buildService([restorableA]);

          await expectLater(
            service.restoreFromBackup(
              backupData: notAnObject,
              passphrase: passphrase,
            ),
            throwsA(isA<TdkException>()),
          );
          verifyNever(() => restorableA.import(any()));
        },
      );

      test(
        'later restorable overwrites earlier sections on key collision',
        () async {
          when(
            () => restorableA.export(),
          ).thenAnswer((_) async => {'shared': 'from-a', 'only-a': true});
          when(
            () => restorableB.export(),
          ).thenAnswer((_) async => {'shared': 'from-b', 'only-b': true});
          when(() => restorableA.import(any())).thenAnswer((_) async {});
          when(() => restorableB.import(any())).thenAnswer((_) async {});

          final service = buildService([restorableA, restorableB]);
          final backup = await service.createBackup(passphrase: passphrase);
          await service.restoreFromBackup(
            backupData: backup,
            passphrase: passphrase,
          );

          final captured =
              verify(() => restorableB.import(captureAny())).captured.single
                  as Map<String, dynamic>;
          expect(captured['shared'], equals('from-b'));
          expect(captured['only-a'], isTrue);
          expect(captured['only-b'], isTrue);
        },
      );

      test('passes an unmodifiable snapshot to each restorable', () async {
        when(() => restorableA.export()).thenAnswer((_) async => {'a': 1});
        when(() => restorableA.import(any())).thenAnswer((_) async {});

        final service = buildService([restorableA]);
        final backup = await service.createBackup(passphrase: passphrase);
        await service.restoreFromBackup(
          backupData: backup,
          passphrase: passphrase,
        );

        final captured =
            verify(() => restorableA.import(captureAny())).captured.single
                as Map<String, dynamic>;
        expect(() => captured['mutate'] = true, throwsUnsupportedError);
      });
    });
  });
}
