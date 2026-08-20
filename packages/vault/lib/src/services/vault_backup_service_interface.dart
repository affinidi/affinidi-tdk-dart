import 'dart:async';
import 'dart:typed_data';

import '../storage_interfaces/profile_repository.dart';
import '../storage_interfaces/restorable.dart';
import '../storage_interfaces/vault_store.dart';
import '../vault.dart';

/// Creates an empty VaultStore for restoration.
typedef VaultStoreFactory = FutureOr<VaultStore> Function();

/// Creates a profile repository for restoration.
typedef ProfileRepositoryFactory =
    FutureOr<ProfileRepository> Function(VaultStore vaultStore);

/// Creates a named restorable component for restoration.
typedef RestorableFactory = FutureOr<Restorable> Function();

/// Defines the contract for creating and restoring encrypted Vault backups.
abstract interface class VaultBackupServiceInterface {
  /// Creates an encrypted backup of [vault].
  ///
  /// Parameters:
  /// * [passphrase] - The user passphrase used to derive the backup encryption
  ///   key.
  ///
  /// Returns encrypted, file-ready bytes.
  /// Throws a `TdkException` if the backup cannot be created.
  Future<ByteData> createBackup({
    required Vault vault,
    required String passphrase,
  });

  /// Restores and opens a Vault from encrypted backup bytes.
  ///
  /// Parameters:
  /// * [backupData] - Bytes previously produced by [createBackup].
  /// * [passphrase] - The user passphrase used to derive the decryption key.
  /// * [vaultStoreFactory] - Creates the empty destination VaultStore.
  /// * [repositoryFactories] - Factories keyed by repository ID.
  /// * [namedRestorableFactories] - Factories keyed by named component ID.
  ///
  /// Concurrent restore calls made through the same service instance are
  /// serialized so the empty-destination checks and subsequent imports execute
  /// as one critical section. Callers should still avoid running concurrent
  /// restores through separate service instances against the same persistence
  /// targets.
  ///
  /// Throws a `TdkException` if the passphrase is incorrect or the backup is
  /// malformed.
  Future<Vault> restoreBackup({
    required ByteData backupData,
    required String passphrase,
    required VaultStoreFactory vaultStoreFactory,
    required Map<String, ProfileRepositoryFactory> repositoryFactories,
    Map<String, RestorableFactory> namedRestorableFactories = const {},
  });
}
