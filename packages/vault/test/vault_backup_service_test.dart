import 'dart:convert';
import 'dart:typed_data';

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

    final nonce = utf8.encode('test-nonce');

    VaultBackupService buildService(List<Restorable> restorables) =>
        VaultBackupService(
          restorables: restorables,
          cryptographyService: cryptographyService,
          nonce: nonce,
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

        final backup = await service.createBackup(passphrase: 'pw');

        expect(backup.encryptedBackup, isNotEmpty);
        expect(backup.encryptionKey, isNotEmpty);
        expect(backup.timestamp, equals('2024-01-02T03:04:05.000Z'));
      });

      test('exports every registered restorable', () async {
        when(() => restorableA.export()).thenAnswer((_) async => {'a': 1});
        when(() => restorableB.export()).thenAnswer((_) async => {'b': 2});

        final service = buildService([restorableA, restorableB]);
        await service.createBackup(passphrase: 'pw');

        verify(() => restorableA.export()).called(1);
        verify(() => restorableB.export()).called(1);
      });

      test('wraps a restorable export failure in a TdkException', () async {
        when(() => restorableA.export()).thenThrow(Exception('boom'));

        final service = buildService([restorableA]);

        await expectLater(
          service.createBackup(passphrase: 'pw'),
          throwsA(
            isA<TdkException>().having(
              (e) => e.code,
              'code',
              equals('invalid_backup_format'),
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
            service.createBackup(passphrase: 'pw'),
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
        final backup = await service.createBackup(passphrase: 'pw');
        await service.restoreFromBackup(backupData: backup, passphrase: 'pw');

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
        final backup = await service.createBackup(passphrase: 'pw');

        await expectLater(
          service.restoreFromBackup(backupData: backup, passphrase: 'pw'),
          completes,
        );
      });

      test('throws TdkException on an incorrect passphrase', () async {
        when(() => restorableA.export()).thenAnswer((_) async => {'a': 1});

        final service = buildService([restorableA]);
        final backup = await service.createBackup(passphrase: 'right');

        await expectLater(
          service.restoreFromBackup(backupData: backup, passphrase: 'wrong'),
          throwsA(isA<TdkException>()),
        );
        verifyNever(() => restorableA.import(any()));
      });

      test(
        'throws TdkException when the decrypted payload is not a backup',
        () async {
          final key = await cryptographyService.Pbkdf2(
            password: 'pw',
            nonce: nonce,
          );
          final malformed = BackupData(
            encryptedBackup: cryptographyService.encryptToHex(
              Uint8List.fromList(key),
              Uint8List.fromList(utf8.encode(jsonEncode({'unexpected': true}))),
            ),
            encryptionKey: Uint8List.fromList(key),
            timestamp: '2024-01-02T03:04:05.000Z',
          );

          final service = buildService([restorableA]);

          await expectLater(
            service.restoreFromBackup(backupData: malformed, passphrase: 'pw'),
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
          encryptionKey: Uint8List.fromList(utf8.encode('key')),
          timestamp: '2024-01-02T03:04:05.000Z',
        );

        final service = buildService([restorableA]);

        await expectLater(
          service.restoreFromBackup(backupData: malformed, passphrase: 'pw'),
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
            password: 'pw',
            nonce: nonce,
          );
          final notAnObject = BackupData(
            encryptedBackup: cryptographyService.encryptToHex(
              Uint8List.fromList(key),
              Uint8List.fromList(utf8.encode(jsonEncode([1, 2, 3]))),
            ),
            encryptionKey: Uint8List.fromList(key),
            timestamp: '2024-01-02T03:04:05.000Z',
          );

          final service = buildService([restorableA]);

          await expectLater(
            service.restoreFromBackup(
              backupData: notAnObject,
              passphrase: 'pw',
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
          final backup = await service.createBackup(passphrase: 'pw');
          await service.restoreFromBackup(backupData: backup, passphrase: 'pw');

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
        final backup = await service.createBackup(passphrase: 'pw');
        await service.restoreFromBackup(backupData: backup, passphrase: 'pw');

        final captured =
            verify(() => restorableA.import(captureAny())).captured.single
                as Map<String, dynamic>;
        expect(() => captured['mutate'] = true, throwsUnsupportedError);
      });
    });
  });
}
