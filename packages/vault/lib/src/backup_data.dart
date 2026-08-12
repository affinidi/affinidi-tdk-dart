import 'package:affinidi_tdk_common/affinidi_tdk_common.dart';

import 'exceptions/tdk_exception_type.dart';

/// Represents an encrypted vault backup ready for storage or transfer.
class BackupData {
  /// Creates a [BackupData].
  ///
  /// Parameters:
  /// * [encryptedBackup] - The authenticated-encrypted, hex-encoded backup
  ///   payload.
  /// * [salt] - The base64-encoded, per-backup PBKDF2 salt required to
  ///   re-derive the decryption key at restore time.
  /// * [timestamp] - ISO-8601 timestamp recording when the backup was created.
  const BackupData({
    required this.encryptedBackup,
    required this.salt,
    required this.timestamp,
  });

  /// Creates a [BackupData] from its JSON representation.
  ///
  /// Parameters:
  /// * [json] - The decoded backup file contents produced by [toJson].
  ///
  /// Returns a [BackupData] with the parsed fields.
  /// Throws a [TdkException] with code `invalid_backup_format` if any required
  /// field is missing or of the wrong type.
  factory BackupData.fromJson(Map<String, dynamic> json) {
    final encryptedBackup = json['encryptedBackup'];
    final salt = json['salt'];
    final timestamp = json['timestamp'];
    if (encryptedBackup is! String || salt is! String || timestamp is! String) {
      throw TdkException(
        message: 'Backup file is missing required fields or has invalid types.',
        code: TdkExceptionType.invalidBackupFormat.code,
      );
    }
    return BackupData(
      encryptedBackup: encryptedBackup,
      salt: salt,
      timestamp: timestamp,
    );
  }

  /// The authenticated-encrypted, hex-encoded backup payload.
  final String encryptedBackup;

  /// The base64-encoded, per-backup PBKDF2 salt used to derive the key.
  final String salt;

  /// ISO-8601 timestamp recording when the backup was created.
  final String timestamp;

  /// Serialises this backup to its JSON representation for persistence.
  ///
  /// Returns a JSON-serialisable [Map] that can be handed back to
  /// [BackupData.fromJson] to reconstruct this object.
  Map<String, dynamic> toJson() => {
    'encryptedBackup': encryptedBackup,
    'salt': salt,
    'timestamp': timestamp,
  };

  @override
  String toString() =>
      'BackupData(timestamp: $timestamp, encryptedBackup: [REDACTED])';
}
