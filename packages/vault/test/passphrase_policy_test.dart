import 'package:affinidi_tdk_vault/affinidi_tdk_vault.dart';
import 'package:test/test.dart';

void main() {
  group('PassphrasePolicy.standard', () {
    const policy = PassphrasePolicy.standard;

    test('accepts a passphrase that meets every rule', () {
      expect(policy.validate('Correct-horse-staple1'), isNull);
    });

    test('rejects a passphrase shorter than the minimum length', () {
      expect(
        policy.validate('Ab1!'),
        equals('Passphrase must be at least 12 characters long.'),
      );
    });

    test('rejects a passphrase without an uppercase letter', () {
      expect(
        policy.validate('lowercase-only-1!'),
        equals('Passphrase must contain at least one uppercase letter.'),
      );
    });

    test('rejects a passphrase without a number', () {
      expect(
        policy.validate('NoNumbersHere!'),
        equals('Passphrase must contain at least one number.'),
      );
    });

    test('rejects a passphrase without a special character', () {
      expect(
        policy.validate('NoSpecials1234'),
        equals('Passphrase must contain at least one special character.'),
      );
    });
  });

  group('PassphrasePolicy with rules disabled', () {
    test('only enforces the minimum length', () {
      const policy = PassphrasePolicy(
        requireUppercase: false,
        requireNumber: false,
        requireSpecialCharacter: false,
      );

      expect(policy.validate('all-lowercase-plain'), isNull);
    });
  });
}
