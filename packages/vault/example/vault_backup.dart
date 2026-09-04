import 'dart:io' as io;
import 'dart:math';
import 'dart:typed_data';

import 'package:affinidi_tdk_vault/affinidi_tdk_vault.dart';
import 'package:affinidi_tdk_vault_data_manager/affinidi_tdk_vault_data_manager.dart';
import 'package:affinidi_tdk_vault_edge_drift_provider/affinidi_tdk_vault_edge_drift_provider.dart';
import 'package:affinidi_tdk_vault_edge_provider/affinidi_tdk_vault_edge_provider.dart';

const _edgeRepositoryId = 'edge';
const _vfsRepositoryId = 'vfs';
const _passphrasePolicy = PassphrasePolicy(minLength: 16);

Future<void> main(List<String> arguments) async {
  // Read the passphrase from a file so it is never a literal in source or a
  // shell history entry.
  final passphraseFile =
      io.Platform.environment['VAULT_BACKUP_PASSPHRASE_FILE'];
  if (passphraseFile == null) {
    io.stderr.writeln(
      'Set VAULT_BACKUP_PASSPHRASE_FILE to a file containing a passphrase '
      'that satisfies the configured passphrase policy.',
    );
    io.exitCode = 64;
    return;
  }

  final passphrase = await io.File(passphraseFile).readAsBytes();
  final backupPath = arguments.firstOrNull ?? 'vault.backup';
  final edgeDatabase = await DatabaseConfig.createInMemoryDatabase();
  try {
    final vault = await _openVault(edgeDatabase: edgeDatabase);
    await vault.profileRepositories[_edgeRepositoryId]!.createProfile(
      name: 'Local backup example',
    );
    final backup = await VaultBackupService(
      passphrasePolicy: _passphrasePolicy,
    ).createBackup(vault: vault, passphrase: passphrase);

    await io.File(backupPath).writeAsBytes(
      backup.buffer.asUint8List(backup.offsetInBytes, backup.lengthInBytes),
      flush: true,
    );
  } finally {
    passphrase.fillRange(0, passphrase.length, 0);
    await edgeDatabase.close();
  }
  print('Encrypted vault backup written to $backupPath');
}

Future<Vault> _openVault({required Database edgeDatabase}) async {
  // Use your application's persistent VaultStore here. In-memory storage keeps
  // this example self-contained.
  final vaultStore = InMemoryVaultStore();
  await vaultStore.setSeed(
    Uint8List.fromList(
      List<int>.generate(32, (_) => Random.secure().nextInt(256)),
    ),
  );
  await vaultStore.setAccountIndex(0);

  final vault = await Vault.fromVaultStore(
    vaultStore,
    profileRepositories: {
      _edgeRepositoryId: EdgeProfileRepository(
        _edgeRepositoryId,
        EdgeDriftRepositoryFactory(database: edgeDatabase),
        EdgeEncryptionService(vaultStore: vaultStore),
      ),
      _vfsRepositoryId: VfsProfileRepository(_vfsRepositoryId),
    },
    defaultProfileRepositoryId: _vfsRepositoryId,
  );
  await vault.ensureInitialized();
  return vault;
}
