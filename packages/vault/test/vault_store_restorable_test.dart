import 'dart:convert';
import 'dart:typed_data';

import 'package:affinidi_tdk_vault/affinidi_tdk_vault.dart';
import 'package:test/test.dart';

void main() {
  group('VaultStore Restorable', () {
    final seed = Uint8List.fromList([1, 2, 3, 4, 5]);
    final contentKey = Uint8List.fromList([9, 8, 7, 6, 5]);
    const accountIndex = 42;

    final invalidBackupFormat = isA<TdkException>().having(
      (exception) => exception.code,
      'code',
      equals('invalid_backup_format'),
    );

    Future<InMemoryVaultStore> populatedStore() async {
      final store = InMemoryVaultStore();
      await store.setSeed(seed);
      await store.setContentKey(contentKey);
      await store.setAccountIndex(accountIndex);
      return store;
    }

    Future<void> expectOriginalState(InMemoryVaultStore store) async {
      expect(await store.getSeed(), equals(seed));
      expect(await store.getContentKey(), equals(contentKey));
      expect(await store.getAccountIndex(), equals(accountIndex));
    }

    test('exports component-local state', () async {
      final exported = await (await populatedStore()).export();

      expect(exported, {
        'version': '1.0.0',
        'seed': base64Encode(seed),
        'contentKey': base64Encode(contentKey),
        'accountIndex': accountIndex,
      });
    });

    test('exports without an unset content key', () async {
      final store = InMemoryVaultStore();
      await store.setSeed(seed);
      await store.setAccountIndex(accountIndex);

      expect(await store.export(), {
        'version': '1.0.0',
        'seed': base64Encode(seed),
        'accountIndex': accountIndex,
      });
    });

    test('rejects export when the seed is missing', () async {
      await expectLater(
        InMemoryVaultStore().export(),
        throwsA(invalidBackupFormat),
      );
    });

    test('round-trips all state', () async {
      final exported = await (await populatedStore()).export();
      final target = InMemoryVaultStore();

      await target.import(exported);

      expect(await target.getSeed(), equals(seed));
      expect(await target.getContentKey(), equals(contentKey));
      expect(await target.getAccountIndex(), equals(accountIndex));
    });

    test('rejects a non-empty destination without changing it', () async {
      final target = await populatedStore();

      await expectLater(
        target.import({
          'version': '1.0.0',
          'seed': base64Encode(seed),
          'accountIndex': accountIndex,
        }),
        throwsA(
          isA<TdkException>().having(
            (error) => error.code,
            'code',
            'restore_destination_not_empty',
          ),
        ),
      );

      await expectOriginalState(target);
    });

    test('rejects malformed data before writes', () async {
      final store = await populatedStore();

      await expectLater(
        store.import(const {
          'version': '1.0.0',
          'seed': 'AQIDBAU=',
          'contentKey': 'CQgHBgU=',
          'accountIndex': 'not-an-int',
        }),
        throwsA(invalidBackupFormat),
      );

      await expectOriginalState(store);
    });

    test('rejects invalid base64 before writes', () async {
      final store = await populatedStore();

      await expectLater(
        store.import(const {
          'version': '1.0.0',
          'seed': '!!!!',
          'accountIndex': accountIndex,
        }),
        throwsA(invalidBackupFormat),
      );

      await expectOriginalState(store);
    });

    test(
      'rejects unsupported versions and unknown fields before writes',
      () async {
        final store = await populatedStore();

        await expectLater(
          store.import(const {
            'version': '2.0.0',
            'seed': 'AQIDBAU=',
            'accountIndex': accountIndex,
            'unexpected': true,
          }),
          throwsA(invalidBackupFormat),
        );

        await expectOriginalState(store);
      },
    );
  });
}
