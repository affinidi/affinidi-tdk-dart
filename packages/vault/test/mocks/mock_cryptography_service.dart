import 'dart:convert';
import 'dart:typed_data';

import 'package:affinidi_tdk_cryptography/affinidi_tdk_cryptography.dart';
import 'package:mocktail/mocktail.dart';

/// A deterministic, round-trippable [CryptographyServiceInterface] fake.
///
/// Only the methods used by `VaultBackupService` are implemented. Encryption
/// embeds the derived key so [decryptFromHex] can reject a mismatched key,
/// allowing the wrong-passphrase path to be tested without real crypto.
class FakeCryptographyService extends Fake
    implements CryptographyServiceInterface {
  @override
  // ignore: non_constant_identifier_names
  Future<List<int>> Pbkdf2({
    required String password,
    required List<int> nonce,
  }) async => utf8.encode('key-$password');

  @override
  String encryptToHex(Uint8List key, Uint8List data) => base64Encode(
    utf8.encode(
      jsonEncode({'key': base64Encode(key), 'data': base64Encode(data)}),
    ),
  );

  @override
  Uint8List? decryptFromHex(Uint8List key, String hexStr) {
    final envelope =
        jsonDecode(utf8.decode(base64Decode(hexStr))) as Map<String, dynamic>;
    if (envelope['key'] != base64Encode(key)) {
      return null;
    }
    return Uint8List.fromList(base64Decode(envelope['data'] as String));
  }
}
