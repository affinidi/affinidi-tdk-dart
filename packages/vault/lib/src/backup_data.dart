import 'dart:typed_data';

/// Represents an encrypted vault backup ready for storage or transfer.
class BackupData {
  /// Creates a [BackupData].
  ///
  /// Parameters:
  /// * [encryptedBackup] - The AES-CBC encrypted, JSON-stringified backup payload.
  /// * [encryptionKey] - The raw AES key bytes used to encrypt [encryptedBackup].
  /// * [timestamp] - ISO-8601 timestamp recording when the backup was created.
  const BackupData({
    required this.encryptedBackup,
    required this.encryptionKey,
    required this.timestamp,
  });

  /// The AES-CBC encrypted, JSON-stringified backup payload.
  final String encryptedBackup;

  /// The raw AES key bytes used to encrypt [encryptedBackup].
  final Uint8List encryptionKey;

  /// ISO-8601 timestamp recording when the backup was created.
  final String timestamp;
}
