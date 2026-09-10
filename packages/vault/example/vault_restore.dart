import 'dart:io' as io;
import 'dart:typed_data';

import 'package:affinidi_tdk_vault/affinidi_tdk_vault.dart';
import 'package:affinidi_tdk_vault_data_manager/affinidi_tdk_vault_data_manager.dart';
import 'package:affinidi_tdk_vault_edge_drift_provider/affinidi_tdk_vault_edge_drift_provider.dart';
import 'package:affinidi_tdk_vault_edge_provider/affinidi_tdk_vault_edge_provider.dart';

const _edgeRepositoryId = 'edge';
const _vfsRepositoryId = 'vfs';

Future<void> main(List<String> arguments) async {
  // Read the passphrase from a file so it is never a literal in source or a
  // shell history entry.
  final passphraseFile =
      io.Platform.environment['VAULT_BACKUP_PASSPHRASE_FILE'];
  if (passphraseFile == null) {
    io.stderr.writeln(
      'Set VAULT_BACKUP_PASSPHRASE_FILE to the file containing the '
      'passphrase used for the backup.',
    );
    io.exitCode = 64;
    return;
  }

  final passphrase = await io.File(passphraseFile).readAsBytes();
  final backupPath = arguments.firstOrNull ?? 'vault.backup';
  final backupBytes = await io.File(backupPath).readAsBytes();
  final edgeDatabase = await DatabaseConfig.createInMemoryDatabase();
  try {
    final vault = await VaultBackupService().restoreBackup(
      backupData: ByteData.sublistView(backupBytes),
      passphrase: passphrase,
      // Every restore destination must be empty. Use a new persistent
      // VaultStore and edge database in an application instead of overwriting
      // existing storage.
      vaultStoreFactory: InMemoryVaultStore.new,
      repositoryFactories: {
        _edgeRepositoryId: ProfileRepositoryRegistration.withBackupData(
          id: _edgeRepositoryId,
          factory: (vaultStore) => EdgeProfileRepository(
            _edgeRepositoryId,
            EdgeDriftRepositoryFactory(database: edgeDatabase),
            EdgeEncryptionService(vaultStore: vaultStore),
          ),
          asRestorable: restorableIdentity,
        ),
        // VFS data remains in cloud storage, so only its stable ID and factory
        // are restored.
        _vfsRepositoryId: ProfileRepositoryRegistration.withoutBackupData(
          id: _vfsRepositoryId,
          factory: (_) => VfsProfileRepository(_vfsRepositoryId),
        ),
      },
    );

    final restoredProfiles = await vault.profileRepositories[_edgeRepositoryId]!
        .listProfiles();
    print(
      'Vault restored with repositories: '
      '${vault.profileRepositories.keys.join(', ')}',
    );
    print(
      'Restored local profiles: '
      '${restoredProfiles.map((profile) => profile.name).join(', ')}',
    );
  } finally {
    passphrase.fillRange(0, passphrase.length, 0);
    await edgeDatabase.close();
  }
}
