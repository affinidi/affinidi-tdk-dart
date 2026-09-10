# Affinidi TDK - Cryptography

`affinidi_tdk_cryptography` is a library that provides encryption and decryption utilities for the Affinidi TDK, allowing developers to perform secure cryptographic operations in Dart applications.

> **💡NOTE:** In most cases there is no need to use this package directly and instead use a higher level package or library, like [affinidi_tdk_consumer_auth_provider](../consumer_auth_provider/) or [affinidi_tdk_auth_provider](../auth_provider/).

## Table of Contents

- [Affinidi TDK - Cryptography](#affinidi-tdk---cryptography)
  - [Table of Contents](#table-of-contents)
  - [Requirements](#requirements)
  - [Getting Started](#getting-started)
  - [Usage](#usage)

## Requirements

- Dart SDK version ^3.6.0

## Getting Started

Add the following to your `pubspec.yaml` file:

```yaml
dependencies:
  affinidi_tdk_cryptography: ^<version_number>
```

Then run:

```bash
dart pub get
```

## Usage

Here is an example of how to use the cryptographic utilities:

```dart
import 'dart:convert';
import 'dart:typed_data';

import 'package:affinidi_tdk_cryptography/affinidi_tdk_cryptography.dart';

Future<void> main() async {
  const salt = 'fixed_salt';

  // Encryption
  final cryptographyService = CryptographyService();
  final Uint8List passwordBytes = readPasswordBytes();
  late final List<int> passwordEncryptionKey;
  try {
    passwordEncryptionKey = await cryptographyService.pbkdf2FromBytes(
      passwordBytes: passwordBytes,
      nonce: utf8.encode(salt),
    );
  } finally {
    passwordBytes.fillRange(0, passwordBytes.length, 0);
  }
  final encryptionKey = cryptographyService.getRandomBytes(32);
  final encryptedPassword = await cryptographyService.Aes256Encrypt(
    key: encryptionKey,
    data: passwordEncryptionKey,
  );

  ...

  // Decryption
  final decryptedPasswordBytes = await cryptographyService.Aes256Decrypt(
    encryptedData: encryptedPassword,
    key: encryptionKey,
  );
  if (decryptedPasswordBytes == null) {
    throw Exception('Failed to decrypt password');
  }
}
```
