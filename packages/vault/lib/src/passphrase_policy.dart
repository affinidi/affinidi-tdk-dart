/// A rule that a passphrase failed to satisfy.
enum PassphraseViolation {
  /// The passphrase is shorter than the configured minimum length.
  tooShort('too_short'),

  /// The passphrase does not contain an uppercase letter.
  missingUppercase('missing_uppercase'),

  /// The passphrase does not contain a number.
  missingNumber('missing_number'),

  /// The passphrase does not contain a special character.
  missingSpecialCharacter('missing_special_character');

  /// Creates a [PassphraseViolation].
  const PassphraseViolation(this.code);

  /// Stable code that consumers can map to a localized message.
  final String code;
}

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

  /// Returns `null` when [passphrase] satisfies the policy, or the first rule
  /// it violates.
  PassphraseViolation? validate(String passphrase) {
    if (passphrase.length < minLength) {
      return PassphraseViolation.tooShort;
    }
    if (requireUppercase && !passphrase.contains(RegExp(r'[A-Z]'))) {
      return PassphraseViolation.missingUppercase;
    }
    if (requireNumber && !passphrase.contains(RegExp(r'[0-9]'))) {
      return PassphraseViolation.missingNumber;
    }
    if (requireSpecialCharacter &&
        !passphrase.contains(RegExp(r'[^A-Za-z0-9]'))) {
      return PassphraseViolation.missingSpecialCharacter;
    }
    return null;
  }
}
