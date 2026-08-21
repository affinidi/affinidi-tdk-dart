import 'package:affinidi_tdk_vault/affinidi_tdk_vault.dart';
import 'package:test/test.dart';

void main() {
  group('When validating PassphrasePolicy.standard', () {
    const policy = PassphrasePolicy.standard;

    group('and the passphrase meets every rule', () {
      test('it accepts the passphrase', () {
        expect(policy.validate('Correct-horse-staple1'), isNull);
      });
    });

    group('and the passphrase is shorter than the minimum length', () {
      test('it returns the minimum-length error', () {
        expect(
          policy.validate('Ab1!'),
          equals('Passphrase must be at least 12 characters long.'),
        );
      });
    });

    group('and the passphrase has no uppercase letter', () {
      test('it returns the uppercase error', () {
        expect(
          policy.validate('lowercase-only-1!'),
          equals('Passphrase must contain at least one uppercase letter.'),
        );
      });
    });

    group('and the passphrase has no number', () {
      test('it returns the number error', () {
        expect(
          policy.validate('NoNumbersHere!'),
          equals('Passphrase must contain at least one number.'),
        );
      });
    });

    group('and the passphrase has no special character', () {
      test('it returns the special-character error', () {
        expect(
          policy.validate('NoSpecials1234'),
          equals('Passphrase must contain at least one special character.'),
        );
      });
    });
  });

  group('When validating PassphrasePolicy with rules disabled', () {
    const policy = PassphrasePolicy(
      requireUppercase: false,
      requireNumber: false,
      requireSpecialCharacter: false,
    );

    group('and the passphrase meets the minimum length', () {
      test('it only enforces that minimum length', () {
        expect(policy.validate('all-lowercase-plain'), isNull);
      });
    });
  });
}
