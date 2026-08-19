import 'package:affinidi_tdk_vault/affinidi_tdk_vault.dart';
import 'package:test/test.dart';

void main() {
  group('Backup', () {
    test('toJson and fromJson round-trip preserves version and data', () {
      final backup = Backup(version: Backup.currentVersion, data: {'edge': 1});

      final restored = Backup.fromJson(backup.toJson());

      expect(restored.version, equals(Backup.currentVersion));
      expect(restored.data, equals({'edge': 1}));
    });

    test('fromJson throws TdkException when version is unsupported', () {
      expect(
        () =>
            Backup.fromJson({'version': '99.0.0', 'data': <String, dynamic>{}}),
        throwsA(
          isA<TdkException>().having(
            (e) => e.code,
            'code',
            equals('invalid_backup_format'),
          ),
        ),
      );
    });

    test('defaults version to currentVersion', () {
      final backup = Backup(data: const {});

      expect(backup.version, equals(Backup.currentVersion));
    });

    test('exposes data as an unmodifiable map', () {
      final backup = Backup(data: {'a': 1});

      expect(() => backup.data['b'] = 2, throwsUnsupportedError);
    });

    test('fromJson throws TdkException when version is missing', () {
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

    test('fromJson throws TdkException when version is not a String', () {
      expect(
        () => Backup.fromJson({'version': 1, 'data': <String, dynamic>{}}),
        throwsA(isA<TdkException>()),
      );
    });

    test('fromJson throws TdkException when data is missing', () {
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

    test('fromJson throws TdkException when data is not a Map', () {
      expect(
        () => Backup.fromJson({'version': '1.0.0', 'data': 'nope'}),
        throwsA(isA<TdkException>()),
      );
    });

    group('vault schema', () {
      Map<String, dynamic> component([String value = 'value']) => {
        'version': '1.0.0',
        'value': value,
      };

      test('creates a repository-scoped backup', () {
        final backup = Backup.vault(
          vaultStore: component('wallet'),
          repositoryManifest: const [
            {'id': 'cloud', 'restorable': false},
            {'id': 'edge', 'restorable': true},
          ],
          repositoryData: {'edge': component('profiles')},
          namedComponents: {'consentHistory': component('consent')},
        );

        expect(backup.data, {
          'namedComponents': {'consentHistory': component('consent')},
          'repositories': {
            'data': {'edge': component('profiles')},
            'manifest': const [
              {'id': 'cloud', 'restorable': false},
              {'id': 'edge', 'restorable': true},
            ],
          },
          'vaultStore': component('wallet'),
        });
      });

      test('sorts map keys deterministically', () {
        final backup = Backup.vault(
          vaultStore: component(),
          repositoryManifest: const [
            {'restorable': true, 'id': 'z'},
            {'restorable': true, 'id': 'a'},
          ],
          repositoryData: {'z': component('z'), 'a': component('a')},
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

      test('rejects duplicate repository ids', () {
        expect(
          () => Backup.vault(
            vaultStore: component(),
            repositoryManifest: const [
              {'id': 'edge', 'restorable': true},
              {'id': 'edge', 'restorable': true},
            ],
            repositoryData: {'edge': component()},
          ),
          throwsA(isA<TdkException>()),
        );
      });

      test('rejects missing and unexpected repository payloads', () {
        expect(
          () => Backup.vault(
            vaultStore: component(),
            repositoryManifest: const [
              {'id': 'edge', 'restorable': true},
              {'id': 'cloud', 'restorable': false},
            ],
            repositoryData: {'cloud': component()},
          ),
          throwsA(isA<TdkException>()),
        );
      });

      test('rejects component payloads without a version', () {
        expect(
          () => Backup.vault(
            vaultStore: const {'seed': 'missing-version'},
            repositoryManifest: const [],
            repositoryData: const {},
          ),
          throwsA(isA<TdkException>()),
        );
      });
    });
  });

  group('BackupData', () {
    test('toJson and fromJson round-trip preserves all fields', () {
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

    test('fromJson throws TdkException when a field is missing', () {
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

    test('fromJson throws TdkException when a field has the wrong type', () {
      expect(
        () => BackupData.fromJson({
          'encryptedBackup': 'deadbeef',
          'salt': 123,
          'timestamp': '2024-01-02T03:04:05.000Z',
        }),
        throwsA(isA<TdkException>()),
      );
    });

    test('toString redacts the encrypted payload', () {
      const backup = BackupData(
        encryptedBackup: 'deadbeef',
        salt: 'c2FsdA==',
        timestamp: '2024-01-02T03:04:05.000Z',
      );

      expect(backup.toString(), isNot(contains('deadbeef')));
      expect(backup.toString(), contains('[REDACTED]'));
    });
  });
}
