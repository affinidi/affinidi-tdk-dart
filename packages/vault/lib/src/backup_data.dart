/// Represents an encrypted vault backup ready for storage or transfer.
class BackupData {
  /// Creates a [BackupData].
  ///
  /// Parameters:
  /// * [encryptedBackup] - The authenticated-encrypted, hex-encoded backup
  ///   payload.
  /// * [timestamp] - ISO-8601 timestamp recording when the backup was created.
  const BackupData({required this.encryptedBackup, required this.timestamp});

  /// The authenticated-encrypted, hex-encoded backup payload.
  final String encryptedBackup;

  /// ISO-8601 timestamp recording when the backup was created.
  final String timestamp;

  @override
  String toString() =>
      'BackupData(timestamp: $timestamp, encryptedBackup: [REDACTED])';
}
