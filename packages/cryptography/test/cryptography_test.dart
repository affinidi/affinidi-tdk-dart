import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:affinidi_tdk_cryptography/affinidi_tdk_cryptography.dart';
import 'package:test/test.dart';

import 'fixtures/cryptography_fixtures.dart' as fixtures;

void main() {
  late CryptographyService cryptographyService;

  setUp(() {
    cryptographyService = CryptographyService();
  });

  group('createHash', () {
    test('returns a non-empty string for a given input', () {
      final result = cryptographyService.createHash(hashSource: 'client123|{}');

      expect(result, isNotEmpty);
    });
  });

  group('Aes256EncryptStringToHex and Aes256DecryptStringFromHex', () {
    test('decrypts back to the original plaintext', () async {
      const salt = 'fixed_salt';
      const dataToEncrypt = 'Hello, Affinidi!';
      final passwordBytes = Uint8List.fromList(utf8.encode('password'));

      late final List<int> encryptionKey;
      try {
        encryptionKey = await cryptographyService.pbkdf2FromBytes(
          passwordBytes: passwordBytes,
          nonce: utf8.encode(salt),
        );
      } finally {
        passwordBytes.fillRange(0, passwordBytes.length, 0);
      }

      final encryptedData = await cryptographyService.Aes256EncryptStringToHex(
        key: encryptionKey,
        data: dataToEncrypt,
      );

      final decryptedData =
          await cryptographyService.Aes256DecryptStringFromHex(
            key: encryptionKey,
            encryptedData: encryptedData,
          );

      expect(decryptedData, dataToEncrypt);
    });
  });

  group('When deriving a PBKDF2 key from mutable bytes', () {
    test('it derives a 32-byte key', () async {
      final nonce = utf8.encode('fixed_salt');
      final passwordBytes = Uint8List.fromList(
        List<int>.generate(16, (i) => i),
      );

      final key = await cryptographyService.pbkdf2FromBytes(
        passwordBytes: passwordBytes,
        nonce: nonce,
      );

      expect(key, hasLength(32));
    });

    test('it does not write operation timing to stdout', () async {
      final messages = <String>[];

      await runZoned(
        () => cryptographyService.pbkdf2FromBytes(
          passwordBytes: Uint8List(16),
          nonce: utf8.encode('fixed_salt'),
        ),
        zoneSpecification: ZoneSpecification(
          print: (_, _, _, message) => messages.add(message),
        ),
      );

      expect(messages, isEmpty);
    });
  });

  group('verifyJwt', () {
    test('should return isValid=true for a correctly signed JWT', () {
      final result = cryptographyService.verifyJwt(
        jwtToken: fixtures.validJwt,
        didKey: fixtures.testDid,
      );

      expect(result.isValid, isTrue);
      expect(result.isExpired, isFalse);
      expect(result.errorMessage, isEmpty);
      expect(result.jwtPayload, isNotNull);
    });

    test('should return isExpired=true for an expired JWT', () {
      final result = cryptographyService.verifyJwt(
        jwtToken: fixtures.expiredJwt,
        didKey: fixtures.testDid,
      );

      expect(result.isValid, isFalse);
      expect(result.isExpired, isTrue);
      expect(result.errorMessage, 'Jwt is expired');
    });

    test('should return isValid=false for a JWT with a tampered signature', () {
      final parts = fixtures.validJwt.split('.');
      final tampered =
          '${parts[0]}.${parts[1]}'
          '.TAMPERED_SIGNATURE';

      final result = cryptographyService.verifyJwt(
        jwtToken: tampered,
        didKey: fixtures.testDid,
      );

      expect(result.isValid, isFalse);
      expect(result.isExpired, isFalse);
      expect(result.errorMessage, isNotEmpty);
    });
  });

  group('decodeJwtToken', () {
    test('should decode the payload of a valid JWT', () {
      final payload = cryptographyService.decodeJwtToken(
        token: fixtures.validJwt,
      );

      expect(payload['sub'], 'test');
      expect(payload['exp'], 9999999999);
    });
  });
}
