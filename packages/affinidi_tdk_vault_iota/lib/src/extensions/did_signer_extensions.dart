import 'package:ssi/ssi.dart';

/// Extension on [DidSigner] that builds the appropriate [EmbeddedProofGenerator]
/// for Verifiable Presentation signing.
extension DidSignerProofGenerator on DidSigner {
  /// Returns an [EmbeddedProofGenerator] matching this signer's
  /// [SignatureScheme], configured with [nonce] as the challenge and
  /// [domain] as the proof domain.
  ///
  /// Parameters:
  /// * [nonce] - The OID4VP request nonce; used as the VP proof challenge.
  /// * [domain] - The `client_id` from the OID4VP request; binds the proof
  ///   to the verifier.
  ///
  /// Throws [UnsupportedError] if the signer uses [SignatureScheme.rsa_pkcs1_sha256].
  EmbeddedProofGenerator toProofGenerator({
    required String nonce,
    required String domain,
  }) => switch (signatureScheme) {
    SignatureScheme.ecdsa_secp256k1_sha256 => Secp256k1Signature2019Generator(
      signer: this,
      challenge: nonce,
      domain: [domain],
      proofPurpose: ProofPurpose.authentication,
    ),
    SignatureScheme.ecdsa_p256_sha256 ||
    SignatureScheme.ecdsa_p384_sha384 ||
    SignatureScheme.ecdsa_p521_sha512 => DataIntegrityEcdsaJcsGenerator(
      signer: this,
      challenge: nonce,
      domain: [domain],
      proofPurpose: ProofPurpose.authentication,
    ),
    SignatureScheme.ed25519 => DataIntegrityEddsaJcsGenerator(
      signer: this,
      challenge: nonce,
      domain: [domain],
      proofPurpose: ProofPurpose.authentication,
    ),
    SignatureScheme.rsa_pkcs1_sha256 => throw UnsupportedError(
      'RSA is not supported for VP signing',
    ),
  };
}
