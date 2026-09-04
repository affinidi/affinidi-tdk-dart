import 'dart:convert';
import 'dart:typed_data';

import 'package:affinidi_tdk_cryptography/affinidi_tdk_cryptography.dart';

Future<void> main() async {
  final cryptographyService = CryptographyService();

  const password = 'password';
  const salt = 'fixed_salt';
  const dataToEncrypt = 'Hello, Affinidi!';
  final passwordBytes = Uint8List.fromList(utf8.encode(password));

  late final List<int> encryptionKey;
  try {
    encryptionKey = await cryptographyService.pbkdf2FromBytes(
      passwordBytes: passwordBytes,
      nonce: utf8.encode(salt),
    );
  } finally {
    passwordBytes.fillRange(0, passwordBytes.length, 0);
  }

  // Encrypt the data
  final encryptedData = await cryptographyService.Aes256EncryptStringToHex(
    key: encryptionKey,
    data: dataToEncrypt,
  );

  print('Encrypted Data: $encryptedData');

  // Decrypt the data
  final decryptedData = await cryptographyService.Aes256DecryptStringFromHex(
    key: encryptionKey,
    encryptedData: encryptedData,
  );

  print('Decrypted Data: $decryptedData');
}
