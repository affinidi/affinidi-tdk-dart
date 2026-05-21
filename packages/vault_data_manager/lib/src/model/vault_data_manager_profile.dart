import 'account.dart';

/// Represents a user profile in the storage system.
class VaultDataManagerProfile {
  /// Unique identifier for the profile
  final String id;

  /// Account identifier
  final int accountIndex;

  /// Display name of the profile
  final String name;

  /// Optional description about the profile
  final String? description;

  /// URI pointing to the profile's picture
  final String? pictureURI;

  /// metadata associated with account, used to store dekek & path to the profile that has been shared
  final AccountMetadata? accountMetadata;

  /// Checks if this account has any shared storage data.
  bool get hasSharedStorageData =>
      accountMetadata?.sharedStorageData.isNotEmpty ?? false;

  /// Creates a new profile instance.
  ///
  /// The [id], [accountIndex], and [name] parameters are required.
  /// The [description], [pictureURI], and [accountMetadata] parameters are optional.
  VaultDataManagerProfile({
    required this.id,
    required this.accountIndex,
    required this.name,
    this.description,
    this.pictureURI,
    this.accountMetadata,
  });
}
