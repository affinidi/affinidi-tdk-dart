import 'dart:convert';
import 'dart:typed_data';

import 'package:affinidi_tdk_vault/affinidi_tdk_vault.dart';
import 'package:test/test.dart';

Uint8List passphraseBytes(String value) =>
    Uint8List.fromList(utf8.encode(value));

void main() {
  group('When validating PassphrasePolicy.standard', () {
    const policy = PassphrasePolicy.standard;

    group('and the passphrase meets every rule', () {
      test('it accepts the passphrase', () {
        expect(
          policy.validate(passphraseBytes('Correct-horse-staple1')),
          isNull,
        );
      });
    });

    group('and the passphrase is shorter than the minimum length', () {
      test('it returns the too-short violation', () {
        expect(
          policy.validate(passphraseBytes('Ab1!')),
          equals(PassphraseViolation.tooShort),
        );
      });
    });

    group('and the passphrase has no uppercase letter', () {
      test('it returns the missing-uppercase violation', () {
        expect(
          policy.validate(passphraseBytes('lowercase-only-1!')),
          equals(PassphraseViolation.missingUppercase),
        );
      });
    });

    group('and the passphrase has no number', () {
      test('it returns the missing-number violation', () {
        expect(
          policy.validate(passphraseBytes('NoNumbersHere!')),
          equals(PassphraseViolation.missingNumber),
        );
      });
    });

    group('and the passphrase has no special character', () {
      test('it returns the missing-special-character violation', () {
        expect(
          policy.validate(passphraseBytes('NoSpecials1234')),
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
        expect(policy.validate(passphraseBytes('all-lowercase-plain')), isNull);
      });
    });

    group('and multibyte characters do not meet the minimum length', () {
      test('it counts UTF-8 code points rather than bytes', () {
        expect(
          policy.validate(passphraseBytes('🔐🔐🔐')),
          equals(PassphraseViolation.tooShort),
        );
      });
    });
  });
}
