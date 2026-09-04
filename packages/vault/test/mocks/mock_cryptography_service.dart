import 'dart:convert';
import 'dart:typed_data';

import 'package:affinidi_tdk_cryptography/affinidi_tdk_cryptography.dart';
import 'package:mocktail/mocktail.dart';

/// A deterministic, round-trippable [CryptographyServiceInterface] fake.
///
/// Only the methods used by `VaultBackupService` are implemented. Encryption
/// embeds the derived key so decryption can reject a mismatched key, allowing
/// the wrong-passphrase path to be tested without real crypto.
class FakeCryptographyService extends Fake
    implements CryptographyServiceInterface {
  FakeCryptographyService({
    List<int> Function(Uint8List passwordBytes)? keyFactory,
    this.events,
  }) : _keyFactory = keyFactory;

  final List<int> Function(Uint8List passwordBytes)? _keyFactory;
  final List<String>? events;
  List<int>? lastDerivedKey;

  @override
  List<int> getRandomBytes(int length) => List<int>.filled(length, 7);

  @override
  Future<List<int>> pbkdf2FromBytes({
    required Uint8List passwordBytes,
    required List<int> nonce,
  }) async {
    events?.add('deriveKey');
    final key =
        _keyFactory?.call(passwordBytes) ??
        List<int>.from([...utf8.encode('key-'), ...passwordBytes]);
    lastDerivedKey = key;
    return key;
  }

  @override
  // ignore: non_constant_identifier_names
  Future<String> Aes256EncryptStringToHex({
    required List<int> key,
    required String data,
  }) async {
    events?.add('encrypt');
    return base64Encode(
      utf8.encode(jsonEncode({'key': base64Encode(key), 'data': data})),
    );
  }

  @override
  // ignore: non_constant_identifier_names
  Future<String?> Aes256DecryptStringFromHex({
    required List<int> key,
    required String encryptedData,
  }) async {
    final envelope =
        jsonDecode(utf8.decode(base64Decode(encryptedData)))
            as Map<String, dynamic>;
    if (envelope['key'] != base64Encode(key)) {
      return null;
    }
    return envelope['data'] as String;
  }
}
