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

/// Creates a profile repository of a specific subtype for restoration.
typedef TypedProfileRepositoryFactory<T extends ProfileRepository> =
    FutureOr<T> Function(VaultStore vaultStore);

/// Returns the same repository as a [Restorable] view when it implements the
/// interface directly.
Restorable restorableIdentity<T extends Restorable>(T repository) => repository;

/// Declares the expected topology for a repository restored from backup.
abstract class ProfileRepositoryRegistration {
  /// Creates a repository registration.
  const ProfileRepositoryRegistration._({
    required this.id,
    required this.expectsBackupData,
  });

  /// Creates a registration for a repository that is expected to carry backup
  /// data in the manifest.
  static ProfileRepositoryRegistration
  withBackupData<T extends ProfileRepository>({
    required String id,
    required TypedProfileRepositoryFactory<T> factory,
    required Restorable Function(T repository) asRestorable,
  }) => _RestorableProfileRepositoryRegistration<T>(
    id: id,
    factory: factory,
    asRestorable: asRestorable,
  );

  /// Creates a registration for a repository that is present in the Vault but
  /// does not carry repository backup data.
  static ProfileRepositoryRegistration withoutBackupData({
    required String id,
    required ProfileRepositoryFactory factory,
  }) => _NonBackupDataProfileRepositoryRegistration(id: id, factory: factory);

  /// The repository identifier expected in the backup manifest.
  final String id;

  /// Whether the created repository is expected to expose repository backup
  /// data through a [Restorable] view.
  final bool expectsBackupData;

  /// Creates the repository instance once validation has completed.
  Future<ProfileRepository> create(VaultStore vaultStore);

  /// Returns a [Restorable] view when this registration expects one.
  Restorable? restorableView(ProfileRepository repository);
}

final class _RestorableProfileRepositoryRegistration<
  T extends ProfileRepository
>
    extends ProfileRepositoryRegistration {
  const _RestorableProfileRepositoryRegistration({
    required super.id,
    required TypedProfileRepositoryFactory<T> factory,
    required Restorable Function(T repository) asRestorable,
  }) : _factory = factory,
       _asRestorable = asRestorable,
       super._(expectsBackupData: true);

  final TypedProfileRepositoryFactory<T> _factory;
  final Restorable Function(T repository) _asRestorable;

  @override
  Future<ProfileRepository> create(VaultStore vaultStore) async =>
      await _factory(vaultStore);

  @override
  Restorable restorableView(ProfileRepository repository) =>
      _asRestorable(repository as T);
}

final class _NonBackupDataProfileRepositoryRegistration
    extends ProfileRepositoryRegistration {
  const _NonBackupDataProfileRepositoryRegistration({
    required super.id,
    required ProfileRepositoryFactory factory,
  }) : _factory = factory,
       super._(expectsBackupData: false);

  final ProfileRepositoryFactory _factory;

  @override
  Future<ProfileRepository> create(VaultStore vaultStore) async =>
      await _factory(vaultStore);

  @override
  Restorable? restorableView(ProfileRepository repository) => null;
}

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
  /// * [repositoryFactories] - Repository restore registrations keyed by
  ///   repository ID.
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
    required Map<String, ProfileRepositoryRegistration> repositoryFactories,
    Map<String, RestorableFactory> namedRestorableFactories = const {},
  });
}
