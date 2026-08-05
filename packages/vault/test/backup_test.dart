import 'package:affinidi_tdk_vault/affinidi_tdk_vault.dart';
import 'package:test/test.dart';

void main() {
  group('Backup', () {
    test('toJson and fromJson round-trip preserves version and data', () {
      final backup = Backup(version: '2.0.0', data: {'edge': 1});

      final restored = Backup.fromJson(backup.toJson());

      expect(restored.version, equals('2.0.0'));
      expect(restored.data, equals({'edge': 1}));
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
  });
}
