import 'dart:convert';
import 'dart:typed_data';

import 'package:affinidi_tdk_vault/affinidi_tdk_vault.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import 'mocks/mock_vault_store.dart';

void main() {
  group('VaultStoreBackupSource', () {
    final seed = Uint8List.fromList([1, 2, 3, 4, 5]);
    final contentKey = Uint8List.fromList([9, 8, 7, 6, 5]);
    const accountIndex = 42;

    final invalidBackupFormat = isA<TdkException>().having(
      (e) => e.code,
      'code',
      equals('invalid_backup_format'),
    );

    setUpAll(() {
      registerFallbackValue(Uint8List(0));
    });

    Future<InMemoryVaultStore> populatedStore() async {
      final store = InMemoryVaultStore();
      await store.setSeed(seed);
      await store.setContentKey(contentKey);
      await store.setAccountIndex(accountIndex);
      return store;
    }

    group('when exporting', () {
      test('should serialise seed, content key and account index', () async {
        final source = VaultStoreBackupSource(
          vaultStore: await populatedStore(),
        );

        final exported = await source.export();

        expect(exported, {
          'wallet': {
            'seed': base64Encode(seed),
            'contentKey': base64Encode(contentKey),
            'accountIndex': accountIndex,
          },
        });
      });

      group('and the seed is missing', () {
        test('should throw a TdkException', () async {
          final store = InMemoryVaultStore();
          await store.setContentKey(contentKey);
          final source = VaultStoreBackupSource(vaultStore: store);

          await expectLater(source.export(), throwsA(invalidBackupFormat));
        });
      });

      group('and the content key is missing', () {
        test('should throw a TdkException', () async {
          final store = InMemoryVaultStore();
          await store.setSeed(seed);
          final source = VaultStoreBackupSource(vaultStore: store);

          await expectLater(source.export(), throwsA(invalidBackupFormat));
        });
      });
    });

    group('when importing', () {
      test('should restore seed, content key and account index', () async {
        final exported = await VaultStoreBackupSource(
          vaultStore: await populatedStore(),
        ).export();

        final target = InMemoryVaultStore();
        await VaultStoreBackupSource(vaultStore: target).import(exported);

        expect(await target.getSeed(), equals(seed));
        expect(await target.getContentKey(), equals(contentKey));
        expect(await target.getAccountIndex(), equals(accountIndex));
      });

      group('and the wallet section is missing', () {
        test('should throw and write nothing', () async {
          final store = MockVaultStore();
          final source = VaultStoreBackupSource(vaultStore: store);

          await expectLater(
            source.import(const {}),
            throwsA(invalidBackupFormat),
          );
          verifyNever(() => store.setSeed(any()));
          verifyNever(() => store.setContentKey(any()));
          verifyNever(() => store.setAccountIndex(any()));
        });
      });

      group('and the wallet section is malformed', () {
        test('should throw and write nothing', () async {
          final store = MockVaultStore();
          final source = VaultStoreBackupSource(vaultStore: store);

          await expectLater(
            source.import(const {
              'wallet': {
                'seed': 'AQIDBAU=',
                'contentKey': 'CQgHBgU=',
                'accountIndex': 'not-an-int',
              },
            }),
            throwsA(invalidBackupFormat),
          );
          verifyNever(() => store.setSeed(any()));
          verifyNever(() => store.setContentKey(any()));
          verifyNever(() => store.setAccountIndex(any()));
        });
      });

      group('and the base64 data is invalid', () {
        test('should throw and write nothing', () async {
          final store = MockVaultStore();
          final source = VaultStoreBackupSource(vaultStore: store);

          await expectLater(
            source.import(const {
              'wallet': {
                'seed': '!!!!',
                'contentKey': 'CQgHBgU=',
                'accountIndex': accountIndex,
              },
            }),
            throwsA(invalidBackupFormat),
          );
          verifyNever(() => store.setSeed(any()));
          verifyNever(() => store.setContentKey(any()));
          verifyNever(() => store.setAccountIndex(any()));
        });
      });
    });
  });
}
