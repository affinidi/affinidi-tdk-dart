/// Represents the current storage usage of a vault.
class VaultStorageUsage {
  /// Storage used, in bytes.
  final int usedBytes;

  /// Creates a [VaultStorageUsage] with the given [usedBytes].
  const VaultStorageUsage({required this.usedBytes});

  /// Creates a [VaultStorageUsage] from a raw byte count.
  factory VaultStorageUsage.fromBytes(int bytes) {
    return VaultStorageUsage(usedBytes: bytes);
  }

  @override
  String toString() =>
      'VaultStorageUsage(usedBytes: $usedBytes)';
}
