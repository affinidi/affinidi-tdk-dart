/// The rules a backup passphrase must satisfy.
///
/// This is the single source of truth for passphrase strength, shared by the
/// toolkit and its consumers. Each rule can be toggled independently, and extra
/// rules (a blocklist, an entropy check) can be added here later without
/// changing any caller.
class PassphrasePolicy {
  /// Creates a [PassphrasePolicy].
  const PassphrasePolicy({
    this.minLength = 12,
    this.requireUppercase = true,
    this.requireNumber = true,
    this.requireSpecialCharacter = true,
  });

  /// The default policy applied by the backup service.
  static const PassphrasePolicy standard = PassphrasePolicy();

  /// Minimum number of characters required.
  final int minLength;

  /// Whether at least one uppercase letter (A-Z) is required.
  final bool requireUppercase;

  /// Whether at least one number (0-9) is required.
  final bool requireNumber;

  /// Whether at least one non-alphanumeric character is required.
  final bool requireSpecialCharacter;

  /// Returns `null` when [passphrase] satisfies the policy, or a human-readable
  /// reason describing the first unmet rule.
  String? validate(String passphrase) {
    if (passphrase.length < minLength) {
      return 'Passphrase must be at least $minLength characters long.';
    }
    if (requireUppercase && !passphrase.contains(RegExp(r'[A-Z]'))) {
      return 'Passphrase must contain at least one uppercase letter.';
    }
    if (requireNumber && !passphrase.contains(RegExp(r'[0-9]'))) {
      return 'Passphrase must contain at least one number.';
    }
    if (requireSpecialCharacter &&
        !passphrase.contains(RegExp(r'[^A-Za-z0-9]'))) {
      return 'Passphrase must contain at least one special character.';
    }
    return null;
  }
}
