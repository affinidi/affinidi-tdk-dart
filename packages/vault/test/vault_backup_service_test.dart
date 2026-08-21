import 'dart:collection';
import 'dart:convert';
import 'dart:typed_data';

import 'package:affinidi_tdk_vault/affinidi_tdk_vault.dart';
import 'package:affinidi_tdk_vault/src/backup_data.dart';
import 'package:test/test.dart';

import 'fakes/fake_blocking_vault_store.dart';
import 'fakes/fake_logger.dart';
import 'fakes/fake_partial_import_failure_vault_store.dart';
import 'fakes/fake_profile_repository.dart';
import 'fakes/fake_restorable.dart';
import 'fakes/fake_restorable_profile_repository.dart';
import 'fakes/fake_vault_store.dart';
import 'fixtures/vault_backup_service_fixtures.dart';
import 'mocks/mock_cryptography_service.dart';

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

    group('When creating a vault backup', () {
      test('it creates encrypted file-ready bytes', () async {
        final vault = await VaultBackupServiceFixtures.vault(
          store: await VaultBackupServiceFixtures.store(),
          repositories: {'edge': FakeRestorableProfileRepository('edge')},
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

      test('it derives the key before exporting sensitive state', () async {
        final events = <String>[];
        final store = FakeVaultStore(events: events);
        await store.setSeed(Uint8List.fromList(List.generate(32, (i) => i)));
        await store.setAccountIndex(4);
        final vault = await VaultBackupServiceFixtures.vault(
          store: store,
          repositories: {'edge': FakeRestorableProfileRepository('edge')},
        );
        final orderedService = VaultBackupService(
          cryptographyService: FakeCryptographyService(events: events),
        );

        await orderedService.createBackup(vault: vault, passphrase: passphrase);

        expect(events, ['deriveKey', 'exportVaultStore', 'encrypt']);
      });

      test('it wipes mutable derived key buffers', () async {
        final vault = await VaultBackupServiceFixtures.vault(
          store: await VaultBackupServiceFixtures.store(),
          repositories: {'edge': FakeRestorableProfileRepository('edge')},
        );

        await service.createBackup(vault: vault, passphrase: passphrase);

        expect(cryptographyService.lastDerivedKey, isNotNull);
        expect(cryptographyService.lastDerivedKey, everyElement(0));
      });

      test('it warns when derived key buffers cannot be wiped', () async {
        final logger = FakeLogger();
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
        final vault = await VaultBackupServiceFixtures.vault(
          store: await VaultBackupServiceFixtures.store(),
          repositories: {'edge': FakeRestorableProfileRepository('edge')},
        );

        await warningService.createBackup(vault: vault, passphrase: passphrase);

        expect(logger.warnings, hasLength(1));
        expect(
          logger.warnings.single,
          contains('Unable to wipe derived key material'),
        );
      });

      test('it warns when typed derived key buffers cannot be wiped', () async {
        final logger = FakeLogger();
        final immutableCrypto = FakeCryptographyService(
          keyFactory: (password) => Uint8List.fromList(
            utf8.encode('key-$password'),
          ).asUnmodifiableView(),
        );
        final warningService = VaultBackupService(
          cryptographyService: immutableCrypto,
          logger: logger,
          now: () => DateTime.utc(2024, 1, 2, 3, 4, 5),
        );
        final vault = await VaultBackupServiceFixtures.vault(
          store: await VaultBackupServiceFixtures.store(),
          repositories: {'edge': FakeRestorableProfileRepository('edge')},
        );

        await warningService.createBackup(vault: vault, passphrase: passphrase);

        expect(logger.warnings, hasLength(1));
        expect(
          logger.warnings.single,
          contains('Unable to wipe derived key material'),
        );
      });
    });

    group('When restoring a valid vault backup', () {
      test('it restores and opens a fresh Vault', () async {
        final source = await VaultBackupServiceFixtures.vault(
          store: await VaultBackupServiceFixtures.store(),
          repositories: {
            'edge': FakeRestorableProfileRepository('edge', value: 'profiles'),
          },
          named: {'consentHistory': FakeRestorable(value: 'consent')},
        );
        final bytes = await service.createBackup(
          vault: source,
          passphrase: passphrase,
        );
        final targetRepository = FakeRestorableProfileRepository(
          'edge',
          value: 'empty',
        );
        final targetComponent = FakeRestorable(value: 'empty');

        final restored = await service.restoreBackup(
          backupData: bytes,
          passphrase: passphrase,
          vaultStoreFactory: InMemoryVaultStore.new,
          repositoryFactories: {
            'edge': ProfileRepositoryRegistration.withBackupData(
              id: 'edge',
              factory: (_) => targetRepository,
              asRestorable: restorableIdentity,
            ),
          },
          namedRestorableFactories: {'consentHistory': () => targetComponent},
        );

        expect(restored.profileRepositories.keys, ['edge']);
        expect(targetRepository.imported, isTrue);
        expect(targetRepository.value, 'profiles');
        expect(targetComponent.imported, isTrue);
        expect(targetComponent.value, 'consent');
      });

      test(
        'it carries an adapted repository backup view into the Vault',
        () async {
          final source = await VaultBackupServiceFixtures.vault(
            store: await VaultBackupServiceFixtures.store(),
            repositories: {
              'edge': FakeRestorableProfileRepository(
                'edge',
                value: 'profiles',
              ),
            },
          );
          final bytes = await service.createBackup(
            vault: source,
            passphrase: passphrase,
          );
          final targetRepository = FakeProfileRepository('edge');
          final targetRestorable = FakeRestorable(value: 'empty');

          final restored = await service.restoreBackup(
            backupData: bytes,
            passphrase: passphrase,
            vaultStoreFactory: InMemoryVaultStore.new,
            repositoryFactories: {
              'edge': ProfileRepositoryRegistration.withBackupData(
                id: 'edge',
                factory: (_) => targetRepository,
                asRestorable: (_) => targetRestorable,
              ),
            },
          );

          expect(targetRestorable.imported, isTrue);
          expect(targetRestorable.value, 'profiles');
          expect(restored.profileRepositories['edge'], isA<Restorable>());
        },
      );

      test(
        'it serializes concurrent restores against the same destination',
        () async {
          final source = await VaultBackupServiceFixtures.vault(
            store: await VaultBackupServiceFixtures.store(),
            repositories: {
              'edge': FakeRestorableProfileRepository(
                'edge',
                value: 'profiles',
              ),
            },
          );
          final bytes = await service.createBackup(
            vault: source,
            passphrase: passphrase,
          );
          final targetStore = FakeBlockingVaultStore();
          final targetRepository = FakeRestorableProfileRepository(
            'edge',
            value: 'empty',
          );

          Future<Vault> restore() => service.restoreBackup(
            backupData: bytes,
            passphrase: passphrase,
            vaultStoreFactory: () => targetStore,
            repositoryFactories: {
              'edge': ProfileRepositoryRegistration.withBackupData(
                id: 'edge',
                factory: (_) => targetRepository,
                asRestorable: restorableIdentity,
              ),
            },
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

      test('it supports ByteData views with a non-zero offset', () async {
        final source = await VaultBackupServiceFixtures.vault(
          store: await VaultBackupServiceFixtures.store(),
          repositories: {'edge': FakeRestorableProfileRepository('edge')},
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
          repositoryFactories: {
            'edge': ProfileRepositoryRegistration.withBackupData(
              id: 'edge',
              factory: (_) => FakeRestorableProfileRepository('edge'),
              asRestorable: restorableIdentity,
            ),
          },
        );

        expect(restored.profileRepositories.keys, ['edge']);
      });
    });

    group('When creating a vault backup with a weak passphrase', () {
      test('it rejects the passphrase', () async {
        final vault = await VaultBackupServiceFixtures.vault(
          store: await VaultBackupServiceFixtures.store(),
          repositories: {'edge': FakeRestorableProfileRepository('edge')},
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

      group('and a stricter minimum length is configured', () {
        test('it applies the configured policy', () async {
          final vault = await VaultBackupServiceFixtures.vault(
            store: await VaultBackupServiceFixtures.store(),
            repositories: {'edge': FakeRestorableProfileRepository('edge')},
          );
          final strictService = VaultBackupService(
            cryptographyService: cryptographyService,
            passphrasePolicy: const PassphrasePolicy(minLength: 64),
          );

          await expectLater(
            strictService.createBackup(vault: vault, passphrase: passphrase),
            throwsA(
              isA<TdkException>().having(
                (error) => error.code,
                'code',
                'weak_passphrase',
              ),
            ),
          );
        });
      });
    });

    group('When restoring an invalid vault backup', () {
      test(
        'it fails before factories are called for a wrong passphrase',
        () async {
          final source = await VaultBackupServiceFixtures.vault(
            store: await VaultBackupServiceFixtures.store(),
            repositories: {'edge': FakeRestorableProfileRepository('edge')},
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
              repositoryFactories: {
                'edge': ProfileRepositoryRegistration.withBackupData(
                  id: 'edge',
                  factory: (_) => FakeRestorableProfileRepository('edge'),
                  asRestorable: restorableIdentity,
                ),
              },
            ),
            throwsA(isA<TdkException>()),
          );
          expect(factoryCalls, 0);
        },
      );

      test(
        'it fails before creating storage when the manifest topology differs',
        () async {
          final source = await VaultBackupServiceFixtures.vault(
            store: await VaultBackupServiceFixtures.store(),
            repositories: {'edge': FakeRestorableProfileRepository('edge')},
          );
          final bytes = await service.createBackup(
            vault: source,
            passphrase: passphrase,
          );
          var storeFactoryCalls = 0;
          var repositoryFactoryCalls = 0;

          await expectLater(
            service.restoreBackup(
              backupData: bytes,
              passphrase: passphrase,
              vaultStoreFactory: () {
                storeFactoryCalls++;
                return InMemoryVaultStore();
              },
              repositoryFactories: {
                'edge': ProfileRepositoryRegistration.withoutBackupData(
                  id: 'edge',
                  factory: (_) {
                    repositoryFactoryCalls++;
                    return FakeRestorableProfileRepository('edge');
                  },
                ),
              },
            ),
            throwsA(isA<TdkException>()),
          );

          expect(storeFactoryCalls, 0);
          expect(repositoryFactoryCalls, 0);
        },
      );

      test(
        'it fails before store creation when a factory is missing',
        () async {
          final source = await VaultBackupServiceFixtures.vault(
            store: await VaultBackupServiceFixtures.store(),
            repositories: {'edge': FakeRestorableProfileRepository('edge')},
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
        },
      );

      test(
        'it fails before durable import for an invalid final component',
        () async {
          final source = await VaultBackupServiceFixtures.vault(
            store: await VaultBackupServiceFixtures.store(),
            repositories: {
              'edge': FakeRestorableProfileRepository(
                'edge',
                value: 'profiles',
              ),
            },
            named: {'last': FakeRestorable(value: 'named')},
          );
          final bytes = await service.createBackup(
            vault: source,
            passphrase: passphrase,
          );
          final targetStore = FakeVaultStore();
          final targetRepository = FakeRestorableProfileRepository(
            'edge',
            value: 'empty',
          );

          await expectLater(
            service.restoreBackup(
              backupData: bytes,
              passphrase: passphrase,
              vaultStoreFactory: () => targetStore,
              repositoryFactories: {
                'edge': ProfileRepositoryRegistration.withBackupData(
                  id: 'edge',
                  factory: (_) => targetRepository,
                  asRestorable: restorableIdentity,
                ),
              },
              namedRestorableFactories: {
                'last': () => FakeRestorable(
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
        },
      );

      test(
        'it rolls back repository and store state after a late import failure',
        () async {
          final source = await VaultBackupServiceFixtures.vault(
            store: await VaultBackupServiceFixtures.store(),
            repositories: {
              'edge': FakeRestorableProfileRepository(
                'edge',
                value: 'profiles',
              ),
            },
            named: {'last': FakeRestorable(value: 'named')},
          );
          final bytes = await service.createBackup(
            vault: source,
            passphrase: passphrase,
          );
          final targetStore = FakeVaultStore();
          final targetRepository = FakeRestorableProfileRepository(
            'edge',
            value: 'empty',
          );

          await expectLater(
            service.restoreBackup(
              backupData: bytes,
              passphrase: passphrase,
              vaultStoreFactory: () => targetStore,
              repositoryFactories: {
                'edge': ProfileRepositoryRegistration.withBackupData(
                  id: 'edge',
                  factory: (_) => targetRepository,
                  asRestorable: restorableIdentity,
                ),
              },
              namedRestorableFactories: {
                'last': () => FakeRestorable(
                  importError: TdkException(
                    message: 'late failure',
                    code: 'invalid_backup_format',
                  ),
                ),
              },
            ),
            throwsA(isA<TdkException>()),
          );

          expect(targetStore.imported, isTrue);
          expect(targetStore.cleared, isTrue);
          expect(await targetStore.getSeed(), isNull);
          expect(await targetRepository.isEmpty(), isTrue);
          expect(targetRepository.rollbackCalls, 1);
          expect(targetRepository.imported, isFalse);
        },
      );

      test(
        'it rolls back partial VaultStore writes when store import throws',
        () async {
          final sourceStore = await VaultBackupServiceFixtures.store();
          await sourceStore.setContentKey(Uint8List.fromList([7, 8, 9]));
          final source = await VaultBackupServiceFixtures.vault(
            store: sourceStore,
            repositories: {
              'edge': FakeRestorableProfileRepository(
                'edge',
                value: 'profiles',
              ),
            },
          );
          final bytes = await service.createBackup(
            vault: source,
            passphrase: passphrase,
          );
          final targetStore = FakePartialImportFailureVaultStore();
          final targetRepository = FakeRestorableProfileRepository(
            'edge',
            value: 'empty',
          );

          await expectLater(
            service.restoreBackup(
              backupData: bytes,
              passphrase: passphrase,
              vaultStoreFactory: () => targetStore,
              repositoryFactories: {
                'edge': ProfileRepositoryRegistration.withBackupData(
                  id: 'edge',
                  factory: (_) => targetRepository,
                  asRestorable: restorableIdentity,
                ),
              },
            ),
            throwsA(
              isA<TdkException>().having(
                (error) => error.code,
                'code',
                'secure_storage_failure',
              ),
            ),
          );

          expect(targetStore.imported, isTrue);
          expect(targetStore.cleared, isTrue);
          expect(await targetStore.getSeed(), isNull);
          expect(await targetStore.getContentKey(), isNull);
          expect(await targetStore.getAccountIndex(), 0);
          expect(targetRepository.imported, isFalse);
        },
      );

      test('it fails before store creation when bytes are tampered', () async {
        final source = await VaultBackupServiceFixtures.vault(
          store: await VaultBackupServiceFixtures.store(),
          repositories: {'edge': FakeRestorableProfileRepository('edge')},
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
            repositoryFactories: {
              'edge': ProfileRepositoryRegistration.withBackupData(
                id: 'edge',
                factory: (_) => FakeRestorableProfileRepository('edge'),
                asRestorable: restorableIdentity,
              ),
            },
          ),
          throwsA(isA<TdkException>()),
        );
        expect(storeFactoryCalls, 0);
      });
    });
  });
}
