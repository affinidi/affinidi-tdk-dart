import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart' as crypto;
import 'package:meta/meta.dart';
import 'package:pointycastle/export.dart' as pc;
import 'package:ssi/ssi.dart';

/// A [KeyPair] implemented entirely with the third-party `cryptography` package
/// (https://pub.dev/packages/cryptography, published by dint.io).
///
/// This class contains **no Affinidi code** in its signing path. It stands in
/// for any non-Affinidi wallet SDK that can expose its key material through the
/// `ssi` [KeyPair] interface. Used to prove that `affinidi_tdk_vault_iota`
/// works with OID4VP wallets that were not built by Affinidi.
class ForeignEd25519KeyPair extends KeyPair {
  final crypto.SimpleKeyPairData _keyPairData;
  final Uint8List _publicKeyBytes;

  ForeignEd25519KeyPair._(this._keyPairData, this._publicKeyBytes);

  /// Generates a new Ed25519 key pair using the `cryptography` package.
  ///
  /// Returns a [ForeignEd25519KeyPair] whose private key never leaves the
  /// `cryptography` package implementation.
  static Future<ForeignEd25519KeyPair> generateEd25519() async {
    final algorithm = crypto.Ed25519();
    final kp = await algorithm.newKeyPair();
    final pub = await kp.extractPublicKey();
    final extracted = await kp.extract();
    return ForeignEd25519KeyPair._(extracted, Uint8List.fromList(pub.bytes));
  }

  @override
  String get id => 'third-party-ed25519-${_publicKeyBytes.take(4).join('-')}';

  @override
  SignatureScheme get defaultSignatureScheme => SignatureScheme.ed25519;

  @override
  PublicKey get publicKey => PublicKey(id, _publicKeyBytes, KeyType.ed25519);

  @override
  @protected
  Future<Uint8List> internalSign(
    Uint8List data,
    SignatureScheme signatureScheme,
  ) async {
    final algorithm = crypto.Ed25519();
    final sig = await algorithm.sign(data.toList(), keyPair: _keyPairData);
    return Uint8List.fromList(sig.bytes);
  }

  @override
  @protected
  Future<bool> internalVerify(
    Uint8List data,
    Uint8List signature,
    SignatureScheme signatureScheme,
  ) async {
    final algorithm = crypto.Ed25519();
    final pub = crypto.SimplePublicKey(
      _publicKeyBytes.toList(),
      type: crypto.KeyPairType.ed25519,
    );
    final sig = crypto.Signature(signature.toList(), publicKey: pub);
    return algorithm.verify(data.toList(), signature: sig);
  }

  @override
  Future<Uint8List> encrypt(Uint8List data, {Uint8List? publicKey}) =>
      throw UnsupportedError('Ed25519 does not support encryption');

  @override
  Future<Uint8List> decrypt(Uint8List data, {Uint8List? publicKey}) =>
      throw UnsupportedError('Ed25519 does not support decryption');

  @override
  Future<Uint8List> computeEcdhSecret(Uint8List publicKey) =>
      throw UnsupportedError('Ed25519 does not support ECDH');
}

/// Builds a [DidSigner] backed by a genuinely non-Affinidi [ForeignEd25519KeyPair].
///
/// Returns a [DidSigner] whose `did:key` DID is derived from the third-party
/// public key and whose signing is delegated to the `cryptography` package.
Future<DidSigner> buildThirdPartyEd25519Signer() async {
  final keyPair = await ForeignEd25519KeyPair.generateEd25519();
  final doc = DidKey.generateDocument(keyPair.publicKey);
  return DidSigner(
    did: doc.id,
    didKeyId: doc.verificationMethod.first.id,
    keyPair: keyPair,
    signatureScheme: SignatureScheme.ed25519,
  );
}

/// A [KeyPair] implemented entirely with the third-party `pointycastle` package
/// (https://pub.dev/packages/pointycastle).
///
/// Supports the two ECDSA curves the TDK uses — secp256k1 and P-256 — neither of
/// which the `cryptography` package can sign on the Dart VM. This class contains
/// **no Affinidi code** in its signing path. It stands in for any non-Affinidi
/// wallet SDK that signs with ECDSA and exposes its keys through the `ssi`
/// [KeyPair] interface.
///
/// Signatures are returned as 64-byte compact `r || s`, low-S normalized — the
/// exact format the `ssi` ECDSA verifiers expect. Public keys are returned as
/// 33-byte compressed points, matching `ssi`'s did:key derivation.
class ForeignEcdsaKeyPair extends KeyPair {
  final pc.ECPrivateKey _privateKey;
  final pc.ECPublicKey _publicKey;
  final pc.ECDomainParameters _domain;
  final KeyType _keyType;
  final SignatureScheme _scheme;
  final pc.SecureRandom _random;
  final String _id;

  ForeignEcdsaKeyPair._(
    this._privateKey,
    this._publicKey,
    this._domain,
    this._keyType,
    this._scheme,
    this._random,
    this._id,
  );

  /// Generates a new ECDSA key pair for the given [keyType] using `pointycastle`.
  ///
  /// [keyType] must be [KeyType.secp256k1] or [KeyType.p256].
  ///
  /// Returns a [ForeignEcdsaKeyPair] whose private key never leaves the
  /// `pointycastle` implementation.
  static ForeignEcdsaKeyPair generate({required KeyType keyType}) {
    final (domainName, scheme) = switch (keyType) {
      KeyType.secp256k1 => (
        'secp256k1',
        SignatureScheme.ecdsa_secp256k1_sha256,
      ),
      KeyType.p256 => ('prime256v1', SignatureScheme.ecdsa_p256_sha256),
      _ => throw ArgumentError('Unsupported key type: $keyType'),
    };

    final domain = pc.ECDomainParameters(domainName);
    final random = _secureRandom();
    final generator = pc.ECKeyGenerator()
      ..init(
        pc.ParametersWithRandom(pc.ECKeyGeneratorParameters(domain), random),
      );
    final pair = generator.generateKeyPair();

    return ForeignEcdsaKeyPair._(
      pair.privateKey,
      pair.publicKey,
      domain,
      keyType,
      scheme,
      random,
      'third-party-$domainName-${DateTime.now().microsecondsSinceEpoch}',
    );
  }

  @override
  String get id => _id;

  @override
  SignatureScheme get defaultSignatureScheme => _scheme;

  @override
  PublicKey get publicKey {
    final encoded = _publicKey.Q!.getEncoded(true);
    return PublicKey(_id, Uint8List.fromList(encoded), _keyType);
  }

  @override
  @protected
  Future<Uint8List> internalSign(
    Uint8List data,
    SignatureScheme signatureScheme,
  ) async {
    // ECDSASigner with a SHA-256 digest hashes [data] then signs — mirroring
    // ssi, which signs SHA-256(signingInput).
    final signer = pc.ECDSASigner(pc.SHA256Digest())
      ..init(
        true,
        pc.ParametersWithRandom(
          pc.PrivateKeyParameter<pc.ECPrivateKey>(_privateKey),
          _random,
        ),
      );
    final sig = signer.generateSignature(data) as pc.ECSignature;

    // Low-S normalization: ssi's canonical signatures use the lower of s and
    // n - s. A high-S signature is still valid ECDSA but some verifiers reject
    // it, so normalize to be safe.
    final n = _domain.n;
    final s = sig.s.compareTo(n >> 1) > 0 ? n - sig.s : sig.s;

    return Uint8List.fromList([
      ..._bigIntTo32Bytes(sig.r),
      ..._bigIntTo32Bytes(s),
    ]);
  }

  @override
  @protected
  Future<bool> internalVerify(
    Uint8List data,
    Uint8List signature,
    SignatureScheme signatureScheme,
  ) async {
    const fieldSize = 32;
    assert(
      signature.length == fieldSize * 2,
      'Expected ${fieldSize * 2}-byte compact r||s, got ${signature.length}',
    );
    final r = _bytesToBigInt(signature.sublist(0, fieldSize));
    final s = _bytesToBigInt(signature.sublist(fieldSize, fieldSize * 2));
    final verifier = pc.ECDSASigner(pc.SHA256Digest())
      ..init(false, pc.PublicKeyParameter<pc.ECPublicKey>(_publicKey));
    return verifier.verifySignature(data, pc.ECSignature(r, s));
  }

  @override
  Future<Uint8List> encrypt(Uint8List data, {Uint8List? publicKey}) =>
      throw UnsupportedError('Encryption is not used by the share flow');

  @override
  Future<Uint8List> decrypt(Uint8List data, {Uint8List? publicKey}) =>
      throw UnsupportedError('Decryption is not used by the share flow');

  @override
  Future<Uint8List> computeEcdhSecret(Uint8List publicKey) =>
      throw UnsupportedError('ECDH is not used by the share flow');

  static pc.SecureRandom _secureRandom() {
    final secureRandom = pc.FortunaRandom();
    final seedSource = Random.secure();
    final seed = Uint8List.fromList(
      List<int>.generate(32, (_) => seedSource.nextInt(256)),
    );
    secureRandom.seed(pc.KeyParameter(seed));
    return secureRandom;
  }

  static Uint8List _bigIntTo32Bytes(BigInt value) {
    final result = Uint8List(32);
    var remaining = value;
    for (var i = 31; i >= 0; i--) {
      result[i] = (remaining & BigInt.from(0xff)).toInt();
      remaining >>= 8;
    }
    return result;
  }

  static BigInt _bytesToBigInt(Uint8List bytes) {
    var result = BigInt.zero;
    for (final byte in bytes) {
      result = (result << 8) | BigInt.from(byte);
    }
    return result;
  }
}

/// Builds a [DidSigner] backed by a genuinely non-Affinidi [ForeignEcdsaKeyPair].
///
/// [keyType] must be [KeyType.secp256k1] or [KeyType.p256].
///
/// Returns a [DidSigner] whose `did:key` DID is derived from the third-party
/// public key and whose signing is delegated to the `pointycastle` package.
DidSigner buildThirdPartyEcdsaSigner({required KeyType keyType}) {
  final keyPair = ForeignEcdsaKeyPair.generate(keyType: keyType);
  final doc = DidKey.generateDocument(keyPair.publicKey);
  return DidSigner(
    did: doc.id,
    didKeyId: doc.verificationMethod.first.id,
    keyPair: keyPair,
    signatureScheme: keyPair.defaultSignatureScheme,
  );
}
