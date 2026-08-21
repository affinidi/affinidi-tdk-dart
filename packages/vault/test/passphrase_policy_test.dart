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
      test('it returns the too-short violation', () {
        expect(policy.validate('Ab1!'), equals(PassphraseViolation.tooShort));
      });
    });

    group('and the passphrase has no uppercase letter', () {
      test('it returns the missing-uppercase violation', () {
        expect(
          policy.validate('lowercase-only-1!'),
          equals(PassphraseViolation.missingUppercase),
        );
      });
    });

    group('and the passphrase has no number', () {
      test('it returns the missing-number violation', () {
        expect(
          policy.validate('NoNumbersHere!'),
          equals(PassphraseViolation.missingNumber),
        );
      });
    });

    group('and the passphrase has no special character', () {
      test('it returns the missing-special-character violation', () {
        expect(
          policy.validate('NoSpecials1234'),
          equals(PassphraseViolation.missingSpecialCharacter),
        );
      });
    });

    group('and a violation is mapped to a localized message', () {
      test('it exposes a stable code', () {
        expect(PassphraseViolation.tooShort.code, equals('too_short'));
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
