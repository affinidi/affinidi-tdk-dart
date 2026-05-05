import 'dart:convert';

import 'package:affinidi_tdk_cryptography/affinidi_tdk_cryptography.dart';
import 'package:test/test.dart';

// Fixtures generated with OpenSSL secp256k1 key + dart_jsonwebtoken ES256K
// signing. Test-only — do NOT use these keys in production.
const _testDid = 'did:key:zQ3shmBVsvSAHDWX3zhAk9h4ikFh8BFz9PhtSmyy5Sp5ZRejB';

// Valid JWT (exp: 9999999999 — year 2286)
const _validJwt =
    'eyJhbGciOiJFUzI1NksiLCJ0eXAiOiJKV1QifQ'
    '.eyJzdWIiOiJ0ZXN0IiwiaWF0IjoxNzc3OTcwNTg4LCJleHAiOjk5OTk5OTk5OTl9'
    '.CBvlgV06vsuIOPRaaDfx_KAYHpTsZj3PrGLlHfuU1pEYY'
    'P5xwK1KTIhvCaQxxQzVeeeZCslnKGUnJI2X2h8IrQ';

// Expired JWT (exp: 1000000001 — year 2001)
const _expiredJwt =
    'eyJhbGciOiJFUzI1NksiLCJ0eXAiOiJKV1QifQ'
    '.eyJzdWIiOiJ0ZXN0IiwiaWF0IjoxNzc3OTcwNTg4LCJleHAiOjEwMDAwMDAwMDF9'
    '.PsEegrkCB5eWVZiBiNBB2buy8jFG18cvhVIo1TH2lxO'
    'WqQjt40qQNxIyrN55NUGC9hWBZyJOeSG7eImKbsVjzQ';

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
        jwtToken: _validJwt,
        didKey: _testDid,
      );

      expect(result.isValid, isTrue);
      expect(result.isExpired, isFalse);
      expect(result.errorMessage, isEmpty);
      expect(result.jwtPayload, isNotNull);
    });

    test('should return isExpired=true for an expired JWT', () {
      final result = cryptographyService.verifyJwt(
        jwtToken: _expiredJwt,
        didKey: _testDid,
      );

      expect(result.isValid, isFalse);
      expect(result.isExpired, isTrue);
      expect(result.errorMessage, 'Jwt is expired');
    });

    test('should return isValid=false for a JWT with a tampered signature', () {
      final parts = _validJwt.split('.');
      final tampered =
          '${parts[0]}.${parts[1]}'
          '.TAMPERED_SIGNATURE';

      final result = cryptographyService.verifyJwt(
        jwtToken: tampered,
        didKey: _testDid,
      );

      expect(result.isValid, isFalse);
      expect(result.isExpired, isFalse);
      expect(result.errorMessage, isNotEmpty);
    });
  });

  group('decodeJwtToken', () {
    test('should decode the payload of a valid JWT', () {
      final payload = cryptographyService.decodeJwtToken(token: _validJwt);

      expect(payload['sub'], 'test');
      expect(payload['exp'], 9999999999);
    });
  });
}
