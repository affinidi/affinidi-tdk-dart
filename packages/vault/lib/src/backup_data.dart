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

  /// The authenticated-encrypted, hex-encoded backup payload.
  final String encryptedBackup;

  /// The base64-encoded, per-backup PBKDF2 salt used to derive the key.
  final String salt;

  /// ISO-8601 timestamp recording when the backup was created.
  final String timestamp;

  @override
  String toString() =>
      'BackupData(timestamp: $timestamp, encryptedBackup: [REDACTED])';
}
