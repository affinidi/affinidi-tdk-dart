import 'dart:async';
import 'dart:convert';
import 'dart:collection';
import 'dart:typed_data';

import 'package:affinidi_tdk_common/affinidi_tdk_common.dart';
import 'package:affinidi_tdk_vault/affinidi_tdk_vault.dart';
import 'package:affinidi_tdk_vault/src/backup_data.dart';
import 'package:test/test.dart';

import 'mocks/mock_cryptography_service.dart';

class _Repository implements ProfileRepository, Restorable {
  _Repository(this.id, {this.value = 'source'});

  @override
  final String id;
  String value;
  bool imported = false;

  @override
  Future<Map<String, dynamic>> export() async => {
    'version': '1.0.0',
    'value': value,
  };

  @override
  Future<void> validateImport(Map<String, dynamic> data) async {}

  @override
  Future<bool> isEmpty() async => true;

  @override
  Future<void> import(Map<String, dynamic> data) async {
    value = data['value'] as String;
    imported = true;
  }

  @override
  Future<void> configure(Object configuration) async {}

  @override
  Future<bool> isConfigured() async => true;

  @override
  Future<List<Profile>> listProfiles({VaultCancelToken? cancelToken}) async =>
      const [];

  @override
  Future<Profile> createProfile({
    required String name,
    String? description,
    VaultCancelToken? cancelToken,
  }) => throw UnimplementedError();

  @override
  Future<void> updateProfile(
    Profile profile, {
    VaultCancelToken? cancelToken,
  }) => throw UnimplementedError();

  @override
  Future<void> deleteProfile(
    Profile profile, {
    VaultCancelToken? cancelToken,
  }) => throw UnimplementedError();
}

class _NamedComponent implements Restorable {
  _NamedComponent({this.value = 'source', this.validationError});

  String value;
  final Exception? validationError;
  bool imported = false;

  @override
  Future<Map<String, dynamic>> export() async => {
    'version': '1.0.0',
    'value': value,
  };

  @override
  Future<void> validateImport(Map<String, dynamic> data) async {
    if (validationError != null) throw validationError!;
  }

  @override
  Future<bool> isEmpty() async => true;

  @override
  Future<void> import(Map<String, dynamic> data) async {
    value = data['value'] as String;
    imported = true;
  }
}

class _TrackingStore extends InMemoryVaultStore {
  bool imported = false;

  @override
  Future<void> import(Map<String, dynamic> data) async {
    imported = true;
    await super.import(data);
  }
}

class _BlockingStore extends InMemoryVaultStore {
  final importStarted = Completer<void>();
  final allowImport = Completer<void>();
  int importCalls = 0;

  @override
  Future<void> import(Map<String, dynamic> data) async {
    importCalls++;
    if (!importStarted.isCompleted) {
      importStarted.complete();
    }
    await allowImport.future;
    await super.import(data);
  }
}

Future<InMemoryVaultStore> _store() async {
  final store = InMemoryVaultStore();
  await store.setSeed(Uint8List.fromList(List.generate(32, (index) => index)));
  await store.setAccountIndex(4);
  return store;
}

Future<Vault> _vault({
  required VaultStore store,
  required Map<String, ProfileRepository> repositories,
  Map<String, Restorable> named = const {},
}) async {
  final vault = await Vault.fromVaultStore(
    store,
    profileRepositories: repositories,
    namedRestorables: named,
  );
  await vault.ensureInitialized();
  return vault;
}

class _TestLogger extends Logger {
  _TestLogger()
    : super(Environment.getEnvironmentConfig(EnvironmentType.local));

  final List<String> warnings = [];

  @override
  void warning(Object? message, {String? component}) {
    warnings.add(message.toString());
  }
}

void main() {
  group('VaultBackupService', () {
    const passphrase = 'Correct-horse-staple1';
    late VaultBackupService service;
    late FakeCryptographyService cryptographyService;

    setUp(() {
      cryptographyService = FakeCryptographyService();
      service = VaultBackupService(
        cryptographyService: cryptographyService,
        now: () => DateTime.utc(2024, 1, 2, 3, 4, 5),
      );
    });

    test('creates encrypted file-ready bytes', () async {
      final vault = await _vault(
        store: await _store(),
        repositories: {'edge': _Repository('edge')},
      );

      final bytes = await service.createBackup(
        vault: vault,
        passphrase: passphrase,
      );
      final encoded = utf8.decode(
        bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
      );
      final envelope = BackupData.fromJson(
        jsonDecode(encoded) as Map<String, dynamic>,
      );

      expect(envelope.encryptedBackup, isNotEmpty);
      expect(envelope.salt, isNotEmpty);
      expect(envelope.timestamp, '2024-01-02T03:04:05.000Z');
    });

    test('wipes derived key buffers returned as mutable List<int>', () async {
      final vault = await _vault(
        store: await _store(),
        repositories: {'edge': _Repository('edge')},
      );

      await service.createBackup(vault: vault, passphrase: passphrase);

      expect(cryptographyService.lastDerivedKey, isNotNull);
      expect(cryptographyService.lastDerivedKey, everyElement(0));
    });

    test('warns when derived key buffers cannot be wiped in place', () async {
      final logger = _TestLogger();
      final immutableCrypto = FakeCryptographyService(
        keyFactory: (password) => UnmodifiableListView<int>(
          List<int>.from(utf8.encode('key-$password')),
        ),
      );
      final warningService = VaultBackupService(
        cryptographyService: immutableCrypto,
        logger: logger,
        now: () => DateTime.utc(2024, 1, 2, 3, 4, 5),
      );
      final vault = await _vault(
        store: await _store(),
        repositories: {'edge': _Repository('edge')},
      );

      await warningService.createBackup(vault: vault, passphrase: passphrase);

      expect(logger.warnings, hasLength(1));
      expect(
        logger.warnings.single,
        contains('Unable to wipe derived key material'),
      );
    });

    test('restores and opens a fresh Vault', () async {
      final source = await _vault(
        store: await _store(),
        repositories: {'edge': _Repository('edge', value: 'profiles')},
        named: {'consentHistory': _NamedComponent(value: 'consent')},
      );
      final bytes = await service.createBackup(
        vault: source,
        passphrase: passphrase,
      );
      final targetRepository = _Repository('edge', value: 'empty');
      final targetComponent = _NamedComponent(value: 'empty');

      final restored = await service.restoreBackup(
        backupData: bytes,
        passphrase: passphrase,
        vaultStoreFactory: InMemoryVaultStore.new,
        repositoryFactories: {'edge': (_) => targetRepository},
        namedRestorableFactories: {'consentHistory': () => targetComponent},
      );

      expect(restored.profileRepositories.keys, ['edge']);
      expect(targetRepository.imported, isTrue);
      expect(targetRepository.value, 'profiles');
      expect(targetComponent.imported, isTrue);
      expect(targetComponent.value, 'consent');
    });

    test(
      'serializes concurrent restores against the same destination',
      () async {
        final source = await _vault(
          store: await _store(),
          repositories: {'edge': _Repository('edge', value: 'profiles')},
        );
        final bytes = await service.createBackup(
          vault: source,
          passphrase: passphrase,
        );
        final targetStore = _BlockingStore();
        final targetRepository = _Repository('edge', value: 'empty');

        Future<Vault> restore() => service.restoreBackup(
          backupData: bytes,
          passphrase: passphrase,
          vaultStoreFactory: () => targetStore,
          repositoryFactories: {'edge': (_) => targetRepository},
        );

        final firstRestore = restore();
        await targetStore.importStarted.future;

        var secondCompleted = false;
        final secondRestore = restore().whenComplete(() {
          secondCompleted = true;
        });

        await Future<void>.microtask(() {});
        await Future<void>.microtask(() {});

        expect(targetStore.importCalls, 1);
        expect(secondCompleted, isFalse);

        targetStore.allowImport.complete();

        final restored = await firstRestore;
        await expectLater(
          secondRestore,
          throwsA(
            isA<TdkException>().having(
              (error) => error.code,
              'code',
              'restore_destination_not_empty',
            ),
          ),
        );

        expect(restored.profileRepositories.keys, ['edge']);
        expect(targetRepository.imported, isTrue);
        expect(targetRepository.value, 'profiles');
      },
    );

    test('supports ByteData views with a non-zero offset', () async {
      final source = await _vault(
        store: await _store(),
        repositories: {'edge': _Repository('edge')},
      );
      final bytes = await service.createBackup(
        vault: source,
        passphrase: passphrase,
      );
      final padded = Uint8List(bytes.lengthInBytes + 8);
      padded.setRange(
        4,
        4 + bytes.lengthInBytes,
        bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
      );

      final restored = await service.restoreBackup(
        backupData: ByteData.view(padded.buffer, 4, bytes.lengthInBytes),
        passphrase: passphrase,
        vaultStoreFactory: InMemoryVaultStore.new,
        repositoryFactories: {'edge': (_) => _Repository('edge')},
      );

      expect(restored.profileRepositories.keys, ['edge']);
    });

    test('rejects a weak passphrase', () async {
      final vault = await _vault(
        store: await _store(),
        repositories: {'edge': _Repository('edge')},
      );

      await expectLater(
        service.createBackup(vault: vault, passphrase: 'short'),
        throwsA(
          isA<TdkException>().having(
            (error) => error.code,
            'code',
            'weak_passphrase',
          ),
        ),
      );
    });

    test('wrong passphrase fails before factories are called', () async {
      final source = await _vault(
        store: await _store(),
        repositories: {'edge': _Repository('edge')},
      );
      final bytes = await service.createBackup(
        vault: source,
        passphrase: passphrase,
      );
      var factoryCalls = 0;

      await expectLater(
        service.restoreBackup(
          backupData: bytes,
          passphrase: 'Incorrect-passphrase1',
          vaultStoreFactory: () {
            factoryCalls++;
            return InMemoryVaultStore();
          },
          repositoryFactories: {'edge': (_) => _Repository('edge')},
        ),
        throwsA(isA<TdkException>()),
      );
      expect(factoryCalls, 0);
    });

    test('missing repository factory fails before store creation', () async {
      final source = await _vault(
        store: await _store(),
        repositories: {'edge': _Repository('edge')},
      );
      final bytes = await service.createBackup(
        vault: source,
        passphrase: passphrase,
      );
      var storeFactoryCalls = 0;

      await expectLater(
        service.restoreBackup(
          backupData: bytes,
          passphrase: passphrase,
          vaultStoreFactory: () {
            storeFactoryCalls++;
            return InMemoryVaultStore();
          },
          repositoryFactories: const {},
        ),
        throwsA(isA<TdkException>()),
      );
      expect(storeFactoryCalls, 0);
    });

    test('invalid final component fails before any durable import', () async {
      final source = await _vault(
        store: await _store(),
        repositories: {'edge': _Repository('edge', value: 'profiles')},
        named: {'last': _NamedComponent(value: 'named')},
      );
      final bytes = await service.createBackup(
        vault: source,
        passphrase: passphrase,
      );
      final targetStore = _TrackingStore();
      final targetRepository = _Repository('edge', value: 'empty');

      await expectLater(
        service.restoreBackup(
          backupData: bytes,
          passphrase: passphrase,
          vaultStoreFactory: () => targetStore,
          repositoryFactories: {'edge': (_) => targetRepository},
          namedRestorableFactories: {
            'last': () => _NamedComponent(
              validationError: TdkException(
                message: 'Malformed named component',
                code: 'invalid_backup_format',
              ),
            ),
          },
        ),
        throwsA(isA<TdkException>()),
      );

      expect(targetStore.imported, isFalse);
      expect(await targetStore.getSeed(), isNull);
      expect(targetRepository.imported, isFalse);
    });

    test('tampered bytes fail before store creation', () async {
      final source = await _vault(
        store: await _store(),
        repositories: {'edge': _Repository('edge')},
      );
      final bytes = await service.createBackup(
        vault: source,
        passphrase: passphrase,
      );
      final tampered = Uint8List.fromList(
        bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
      );
      tampered[tampered.length ~/ 2] ^= 1;
      var storeFactoryCalls = 0;

      await expectLater(
        service.restoreBackup(
          backupData: ByteData.sublistView(tampered),
          passphrase: passphrase,
          vaultStoreFactory: () {
            storeFactoryCalls++;
            return InMemoryVaultStore();
          },
          repositoryFactories: {'edge': (_) => _Repository('edge')},
        ),
        throwsA(isA<TdkException>()),
      );
      expect(storeFactoryCalls, 0);
    });
  });
}
