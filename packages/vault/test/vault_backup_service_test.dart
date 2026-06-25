import 'package:affinidi_tdk_vault/affinidi_tdk_vault.dart';
import 'package:test/test.dart';

void main() {
  group('VaultBackupService', () {
    // TODO(Khoa): behavioural tests will be added with the logic in another PR.
    test('createBackup throws UnimplementedError', () {
      final service = VaultBackupService(restorables: const []);
      expect(service.createBackup(), throwsUnimplementedError);
    });

    test('restoreFromBackup throws UnimplementedError', () {
      final service = VaultBackupService(restorables: const []);
      expect(service.restoreFromBackup(const {}), throwsUnimplementedError);
    });
  });
}
