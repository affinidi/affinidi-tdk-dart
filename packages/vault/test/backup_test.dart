import 'package:affinidi_tdk_vault/affinidi_tdk_vault.dart';
import 'package:affinidi_tdk_vault/src/backup.dart';
import 'package:affinidi_tdk_vault/src/backup_data.dart';
import 'package:test/test.dart';

void main() {
  group('When working with a backup', () {
    group('and serializing then deserializing it', () {
      test('it preserves the version and data', () {
        final backup = Backup(
          version: Backup.currentVersion,
          data: {'edge': 1},
        );

        final restored = Backup.fromJson(backup.toJson());

        expect(restored.version, equals(Backup.currentVersion));
        expect(restored.data, equals({'edge': 1}));
      });
    });

    group('and deserializing an unsupported version', () {
      test('it throws an invalid backup format exception', () {
        expect(
          () => Backup.fromJson({
            'version': '99.0.0',
            'data': <String, dynamic>{},
          }),
          throwsA(
            isA<TdkException>().having(
              (e) => e.code,
              'code',
              equals('invalid_backup_format'),
            ),
          ),
        );
      });
    });

    group('and creating it without a version', () {
      test('it defaults to the current version', () {
        final backup = Backup(data: const {});

        expect(backup.version, equals(Backup.currentVersion));
      });
    });

    group('and modifying its data', () {
      test('it prevents the modification', () {
        final backup = Backup(data: {'a': 1});

        expect(() => backup.data['b'] = 2, throwsUnsupportedError);
      });
    });

    group('and deserializing it without a version', () {
      test('it throws an invalid backup format exception', () {
        expect(
          () => Backup.fromJson({'data': <String, dynamic>{}}),
          throwsA(
            isA<TdkException>().having(
              (e) => e.code,
              'code',
              equals('invalid_backup_format'),
            ),
          ),
        );
      });
    });

    group('and deserializing it with a non-string version', () {
      test('it throws a TdkException', () {
        expect(
          () => Backup.fromJson({'version': 1, 'data': <String, dynamic>{}}),
          throwsA(isA<TdkException>()),
        );
      });
    });

    group('and deserializing it without data', () {
      test('it throws an invalid backup format exception', () {
        expect(
          () => Backup.fromJson({'version': '1.0.0'}),
          throwsA(
            isA<TdkException>().having(
              (e) => e.code,
              'code',
              equals('invalid_backup_format'),
            ),
          ),
        );
      });
    });

    group('and deserializing it with non-map data', () {
      test('it throws a TdkException', () {
        expect(
          () => Backup.fromJson({'version': '1.0.0', 'data': 'nope'}),
          throwsA(isA<TdkException>()),
        );
      });
    });

    group('and creating it with the vault schema', () {
      Map<String, dynamic> component([String value = 'value']) => {
        'version': '1.0.0',
        'value': value,
      };

      test('it creates a repository-scoped backup', () {
        final backup = Backup.vault(
          vaultStore: component('wallet'),
          repositoryManifest: const [
            {'id': 'cloud', 'restorable': false},
            {'id': 'edge', 'restorable': true},
          ],
          repositoryData: {'edge': component('profiles')},
          defaultRepositoryId: 'edge',
          namedComponents: {'consentHistory': component('consent')},
        );

        expect(backup.data, {
          'namedComponents': {'consentHistory': component('consent')},
          'repositories': {
            'data': {'edge': component('profiles')},
            'defaultId': 'edge',
            'manifest': const [
              {'id': 'cloud', 'restorable': false},
              {'id': 'edge', 'restorable': true},
            ],
          },
          'vaultStore': component('wallet'),
        });
      });

      test('it sorts map keys deterministically', () {
        final backup = Backup.vault(
          vaultStore: component(),
          repositoryManifest: const [
            {'restorable': true, 'id': 'z'},
            {'restorable': true, 'id': 'a'},
          ],
          repositoryData: {'z': component('z'), 'a': component('a')},
          defaultRepositoryId: 'a',
          namedComponents: {'z': component('z'), 'a': component('a')},
        );

        expect(backup.data.keys, [
          'namedComponents',
          'repositories',
          'vaultStore',
        ]);
        expect((backup.data['namedComponents'] as Map<String, dynamic>).keys, [
          'a',
          'z',
        ]);
        final repositories =
            backup.data['repositories'] as Map<String, dynamic>;
        expect((repositories['data'] as Map<String, dynamic>).keys, ['a', 'z']);
      });

      test('it rejects duplicate repository IDs', () {
        expect(
          () => Backup.vault(
            vaultStore: component(),
            repositoryManifest: const [
              {'id': 'edge', 'restorable': true},
              {'id': 'edge', 'restorable': true},
            ],
            repositoryData: {'edge': component()},
            defaultRepositoryId: 'edge',
          ),
          throwsA(isA<TdkException>()),
        );
      });

      test('it rejects missing and unexpected repository payloads', () {
        expect(
          () => Backup.vault(
            vaultStore: component(),
            repositoryManifest: const [
              {'id': 'edge', 'restorable': true},
              {'id': 'cloud', 'restorable': false},
            ],
            repositoryData: {'cloud': component()},
            defaultRepositoryId: 'edge',
          ),
          throwsA(isA<TdkException>()),
        );
      });

      test('it rejects component payloads without a version', () {
        expect(
          () => Backup.vault(
            vaultStore: const {'seed': 'missing-version'},
            repositoryManifest: const [],
            repositoryData: const {},
            defaultRepositoryId: 'missing',
          ),
          throwsA(isA<TdkException>()),
        );
      });
    });
  });

  group('When working with backup data', () {
    group('and serializing then deserializing it', () {
      test('it preserves all fields', () {
        const backup = BackupData(
          encryptedBackup: 'deadbeef',
          salt: 'c2FsdA==',
          timestamp: '2024-01-02T03:04:05.000Z',
        );

        final restored = BackupData.fromJson(backup.toJson());

        expect(restored.encryptedBackup, equals('deadbeef'));
        expect(restored.salt, equals('c2FsdA=='));
        expect(restored.timestamp, equals('2024-01-02T03:04:05.000Z'));
      });
    });

    group('and deserializing it with a missing field', () {
      test('it throws an invalid backup format exception', () {
        expect(
          () => BackupData.fromJson({
            'encryptedBackup': 'deadbeef',
            'salt': 'c2FsdA==',
          }),
          throwsA(
            isA<TdkException>().having(
              (e) => e.code,
              'code',
              equals('invalid_backup_format'),
            ),
          ),
        );
      });
    });

    group('and deserializing it with a field of the wrong type', () {
      test('it throws a TdkException', () {
        expect(
          () => BackupData.fromJson({
            'encryptedBackup': 'deadbeef',
            'salt': 123,
            'timestamp': '2024-01-02T03:04:05.000Z',
          }),
          throwsA(isA<TdkException>()),
        );
      });
    });

    group('and converting it to a string', () {
      test('it redacts the encrypted payload', () {
        const backup = BackupData(
          encryptedBackup: 'deadbeef',
          salt: 'c2FsdA==',
          timestamp: '2024-01-02T03:04:05.000Z',
        );

        expect(backup.toString(), isNot(contains('deadbeef')));
        expect(backup.toString(), contains('[REDACTED]'));
      });
    });
  });
}
