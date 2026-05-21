import 'package:ssi/ssi.dart';
import 'package:uuid/uuid.dart';

import '../extensions/did_signer_extensions.dart';
import '../models/vp_data_model.dart';

/// Defines the contract for building a signed Verifiable Presentation.
abstract class VpBuilderInterface {
  /// Builds a signed VP from the given [signer], [credentials], [nonce],
  /// [domain], and [dataModel].
  ///
  /// Parameters:
  /// * [signer] - The DID signer that controls the holder's key.
  /// * [credentials] - The ordered list of credentials to include in the VP.
  /// * [nonce] - The nonce from the OID4VP request; used as the proof challenge.
  /// * [domain] - The `client_id` from the OID4VP request; binds the VP to the
  ///   verifier.
  /// * [dataModel] - Whether to produce a DM v1 or DM v2 VP.
  ///
  /// Returns a [Future] containing the signed VP as a JSON map.
  /// Throws [ArgumentError] if [credentials] is empty.
  /// Throws [UnsupportedError] if the signer uses an unsupported key scheme.
  Future<Map<String, dynamic>> build({
    required DidSigner signer,
    required List<ParsedVerifiableCredential<dynamic>> credentials,
    required String nonce,
    required String domain,
    required VpDataModel dataModel,
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
    required VpDataModel dataModel,
  }) async {
    if (credentials.isEmpty) {
      throw ArgumentError.value(
        credentials,
        'credentials',
        'must not be empty',
      );
    }

    final proofGenerator = signer.toProofGenerator(
      nonce: nonce,
      domain: domain,
    );

    return switch (dataModel) {
      VpDataModel.v1 => _buildV1(
        signer: signer,
        credentials: credentials,
        proofGenerator: proofGenerator,
      ),
      VpDataModel.v2 => _buildV2(
        signer: signer,
        credentials: credentials,
        proofGenerator: proofGenerator,
      ),
    };
  }

  Future<Map<String, dynamic>> _buildV1({
    required DidSigner signer,
    required List<ParsedVerifiableCredential<dynamic>> credentials,
    required EmbeddedProofGenerator proofGenerator,
  }) async {
    final unsigned = MutableVpDataModelV1(
      context: MutableJsonLdContext.fromJson([dmV1ContextUrl]),
      id: Uri.parse('urn:uuid:${const Uuid().v4()}'),
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

  Future<Map<String, dynamic>> _buildV2({
    required DidSigner signer,
    required List<ParsedVerifiableCredential<dynamic>> credentials,
    required EmbeddedProofGenerator proofGenerator,
  }) async {
    final unsigned = MutableVpDataModelV2(
      context: MutableJsonLdContext.fromJson([dmV2ContextUrl]),
      id: Uri.parse('urn:uuid:${const Uuid().v4()}'),
      type: {'VerifiablePresentation'},
      holder: MutableHolder.uri(signer.did),
      verifiableCredential: credentials,
    );

    final signed = await LdVpDm2Suite().issue(
      unsignedData: VpDataModelV2.fromMutable(unsigned),
      proofGenerator: proofGenerator,
    );

    return signed.toJson();
  }
}
