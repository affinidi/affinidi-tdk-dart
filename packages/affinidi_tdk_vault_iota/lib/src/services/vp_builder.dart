import 'package:ssi/ssi.dart';
import 'package:uuid/uuid.dart';

/// Defines the contract for building a signed Verifiable Presentation.
abstract class VpBuilderInterface {
  /// Builds a signed VP from the given [signer], [credentials], [nonce], and
  /// [domain].
  ///
  /// Parameters:
  /// * [signer] - The DID signer that controls the holder's key.
  /// * [credentials] - The ordered list of credentials to include in the VP.
  /// * [nonce] - The nonce from the OID4VP request; used as the proof challenge.
  /// * [domain] - The `client_id` from the OID4VP request; binds the VP to the
  ///   verifier.
  ///
  /// Returns a [Future] containing the signed VP as a JSON map.
  /// Throws [ArgumentError] if [credentials] is empty.
  /// Throws [UnimplementedError] if the signer uses an unsupported key scheme.
  Future<Map<String, dynamic>> build({
    required DidSigner signer,
    required List<ParsedVerifiableCredential<dynamic>> credentials,
    required String nonce,
    required String domain,
  });
}

/// Builds and signs a W3C Verifiable Presentation (Data Model V1).
class VpBuilder implements VpBuilderInterface {
  /// Creates a [VpBuilder].
  const VpBuilder();

  @override
  Future<Map<String, dynamic>> build({
    required DidSigner signer,
    required List<ParsedVerifiableCredential<dynamic>> credentials,
    required String nonce,
    required String domain,
  }) async {
    if (credentials.isEmpty) {
      throw ArgumentError.value(
        credentials,
        'credentials',
        'must not be empty',
      );
    }

    final proofGenerator = _buildProofGenerator(signer, nonce, domain);

    final unsigned = MutableVpDataModelV1(
      context: MutableJsonLdContext.fromJson([dmV1ContextUrl]),
      id: Uri.parse(const Uuid().v4()),
      type: {'VerifiablePresentation'},
      holder: MutableHolder.uri(signer.did),
      verifiableCredential: credentials,
    );

    final signed = await LdVpDm1Suite().issue(
      unsignedData: VpDataModelV1.fromMutable(unsigned),
      proofGenerator: proofGenerator,
    );

    return signed.toJson();
  }

  EmbeddedProofGenerator _buildProofGenerator(
    DidSigner signer,
    String nonce,
    String domain,
  ) =>
      switch (signer.signatureScheme) {
        SignatureScheme.ecdsa_secp256k1_sha256 =>
          Secp256k1Signature2019Generator(
            signer: signer,
            challenge: nonce,
            domain: [domain],
            proofPurpose: ProofPurpose.authentication,
          ),
        SignatureScheme.ecdsa_p256_sha256 ||
        SignatureScheme.ecdsa_p384_sha384 ||
        SignatureScheme.ecdsa_p521_sha512 =>
          DataIntegrityEcdsaJcsGenerator(
            signer: signer,
            challenge: nonce,
            domain: [domain],
            proofPurpose: ProofPurpose.authentication,
          ),
        SignatureScheme.ed25519 => DataIntegrityEddsaJcsGenerator(
            signer: signer,
            challenge: nonce,
            domain: [domain],
            proofPurpose: ProofPurpose.authentication,
          ),
        SignatureScheme.rsa_pkcs1_sha256 => throw UnimplementedError(
            'RSA is not supported for VP signing',
          ),
      };
}
