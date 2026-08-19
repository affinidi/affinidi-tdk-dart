import 'dart:convert';
import 'dart:typed_data';

import 'package:affinidi_tdk_vault/affinidi_tdk_vault.dart' show TdkException;
import 'package:affinidi_tdk_vault_flutter_utils/storages/flutter_secure_vault_store.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  late MockFlutterSecureStorage mockStorage;
  late FlutterSecureVaultStore vaultStore;

  const vaultId = 'testVault';

  setUp(() {
    mockStorage = MockFlutterSecureStorage();
    vaultStore = FlutterSecureVaultStore(vaultId, mockStorage);
  });

  group('When managing seed', () {
    final testSeed = Uint8List.fromList([1, 2, 3, 4]);

    group('and setting the seed', () {
      test('it stores it as base64', () async {
        when(
          () => mockStorage.write(
            key: any(named: 'key'),
            value: any(named: 'value'),
          ),
        ).thenAnswer((_) async {});

        await vaultStore.setSeed(testSeed);

        verify(
          () => mockStorage.write(
            key: '${vaultId}_seed',
            value: base64Encode(testSeed),
          ),
        ).called(1);
      });
    });

    group('and getting the seed', () {
      test('it returns the stored seed', () async {
        when(
          () => mockStorage.read(key: '${vaultId}_seed'),
        ).thenAnswer((_) async => base64Encode(testSeed));

        final result = await vaultStore.getSeed();
        expect(result, testSeed);
      });

      test('it returns null if no seed is stored', () async {
        when(
          () => mockStorage.read(key: '${vaultId}_seed'),
        ).thenAnswer((_) async => null);
        expect(await vaultStore.getSeed(), isNull);
      });
    });
  });

  group('When managing account index', () {
    group('and storing the index', () {
      test('it stores it as a string', () async {
        when(
          () => mockStorage.write(
            key: any(named: 'key'),
            value: any(named: 'value'),
          ),
        ).thenAnswer((_) async {});

        await vaultStore.setAccountIndex(5);
        verify(
          () => mockStorage.write(key: '${vaultId}_accountIndex', value: '5'),
        ).called(1);
      });
    });

    group('and reading the index', () {
      test('it returns the stored integer', () async {
        when(
          () => mockStorage.read(key: '${vaultId}_accountIndex'),
        ).thenAnswer((_) async => '7');
        final index = await vaultStore.getAccountIndex();
        expect(index, 7);
      });

      test('it returns 0 if null or invalid', () async {
        when(
          () => mockStorage.read(key: '${vaultId}_accountIndex'),
        ).thenAnswer((_) async => null);
        expect(await vaultStore.getAccountIndex(), 0);

        when(
          () => mockStorage.read(key: '${vaultId}_accountIndex'),
        ).thenAnswer((_) async => 'invalid');
        expect(await vaultStore.getAccountIndex(), 0);
      });
    });
  });

  group('When managing contentKey', () {
    final testContentKey = Uint8List.fromList([1, 2, 3, 4]);

    group('and setting the content key', () {
      test('it stores it as base64', () async {
        when(
          () => mockStorage.write(
            key: any(named: 'key'),
            value: any(named: 'value'),
          ),
        ).thenAnswer((_) async {});

        await vaultStore.setContentKey(testContentKey);

        verify(
          () => mockStorage.write(
            key: '${vaultId}_contentKey',
            value: base64Encode(testContentKey),
          ),
        ).called(1);
      });
    });

    group('and getting the contentKey', () {
      test('it returns the stored content key', () async {
        when(
          () => mockStorage.read(key: '${vaultId}_contentKey'),
        ).thenAnswer((_) async => base64Encode(testContentKey));

        final result = await vaultStore.getContentKey();
        expect(result, testContentKey);
      });

      test('it returns null if no contentKey is stored', () async {
        when(
          () => mockStorage.read(key: '${vaultId}_contentKey'),
        ).thenAnswer((_) async => null);
        expect(await vaultStore.getContentKey(), isNull);
      });
    });
  });

  group('When clearing vault data', () {
    test('it removes accountIndex and seed', () async {
      when(
        () => mockStorage.delete(key: any(named: 'key')),
      ).thenAnswer((_) async {});

      await vaultStore.clear();
      verify(
        () => mockStorage.delete(key: '${vaultId}_accountIndex'),
      ).called(1);
      verify(() => mockStorage.delete(key: '${vaultId}_seed')).called(1);
      verify(() => mockStorage.delete(key: '${vaultId}_contentKey')).called(1);
    });
  });

  group('When backing up vault data', () {
    final seed = Uint8List.fromList([1, 2, 3, 4]);
    final contentKey = Uint8List.fromList([5, 6, 7, 8]);

    test('it exports secure storage state', () async {
      when(
        () => mockStorage.read(key: '${vaultId}_seed'),
      ).thenAnswer((_) async => base64Encode(seed));
      when(
        () => mockStorage.read(key: '${vaultId}_contentKey'),
      ).thenAnswer((_) async => base64Encode(contentKey));
      when(
        () => mockStorage.read(key: '${vaultId}_accountIndex'),
      ).thenAnswer((_) async => '7');

      expect(await vaultStore.export(), {
        'version': '1.0.0',
        'seed': base64Encode(seed),
        'contentKey': base64Encode(contentKey),
        'accountIndex': 7,
      });
    });

    test('it imports secure storage state into an empty destination', () async {
      when(
        () => mockStorage.read(key: any(named: 'key')),
      ).thenAnswer((_) async => null);
      when(
        () => mockStorage.write(
          key: any(named: 'key'),
          value: any(named: 'value'),
        ),
      ).thenAnswer((_) async {});

      await vaultStore.import({
        'version': '1.0.0',
        'seed': base64Encode(seed),
        'contentKey': base64Encode(contentKey),
        'accountIndex': 7,
      });

      verifyInOrder([
        () => mockStorage.write(
          key: '${vaultId}_seed',
          value: base64Encode(seed),
        ),
        () => mockStorage.write(
          key: '${vaultId}_contentKey',
          value: base64Encode(contentKey),
        ),
        () => mockStorage.write(key: '${vaultId}_accountIndex', value: '7'),
      ]);
      verifyNever(() => mockStorage.delete(key: any(named: 'key')));
    });

    test('it rejects a non-empty secure storage destination', () async {
      when(
        () => mockStorage.read(key: '${vaultId}_seed'),
      ).thenAnswer((_) async => base64Encode(seed));
      when(
        () => mockStorage.read(key: '${vaultId}_contentKey'),
      ).thenAnswer((_) async => null);
      when(
        () => mockStorage.read(key: '${vaultId}_accountIndex'),
      ).thenAnswer((_) async => '0');

      await expectLater(
        vaultStore.import({
          'version': '1.0.0',
          'seed': base64Encode(seed),
          'accountIndex': 0,
        }),
        throwsA(
          isA<TdkException>().having(
            (error) => error.code,
            'code',
            'restore_destination_not_empty',
          ),
        ),
      );

      verifyNever(
        () => mockStorage.write(
          key: any(named: 'key'),
          value: any(named: 'value'),
        ),
      );
    });
  });
}
