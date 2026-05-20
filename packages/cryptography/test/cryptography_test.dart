import 'dart:convert';

import 'package:affinidi_tdk_cryptography/affinidi_tdk_cryptography.dart';
import 'package:test/test.dart';

import 'fixtures/cryptography_fixtures.dart' as fixtures;

void main() {
  late CryptographyService cryptographyService;

  setUp(() {
    cryptographyService = CryptographyService();
  });

  group('AES-256 encrypt and decrypt', () {
    test('should round-trip a string through AES-256 hex encoding', () async {
      const password = 'password';
      const salt = 'fixed_salt';
      const dataToEncrypt = 'Hello, Affinidi!';

      final encryptionKey = await cryptographyService.Pbkdf2(
        password: password,
        nonce: utf8.encode(salt),
      );

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
