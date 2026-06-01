import 'package:affinidi_tdk_common/affinidi_tdk_common.dart';
import 'package:ssi/ssi.dart';
import 'package:uuid/uuid.dart';

import '../exceptions/tdk_exception_type.dart';
import '../extensions/did_signer_extensions.dart';
import '../models/vp_data_model.dart';

/// Defines the contract for building a signed Verifiable Presentation.
abstract class VpBuilderInterface {
  /// Builds a signed VP from the given [signer], [credentials], [nonce],
  /// and [domain]. The data model version is inferred from the credentials.
  ///
  /// Parameters:
  /// * [signer] - The DID signer that controls the holder's key.
  /// * [credentials] - The ordered list of credentials to include in the VP.
  /// * [nonce] - The nonce from the OID4VP request; used as the proof challenge.
  /// * [domain] - The `client_id` from the OID4VP request; binds the VP to the
  ///   verifier.
  ///
  /// Returns a [Future] containing the signed VP as a JSON map.
  /// Throws [TdkException] with [TdkExceptionType.emptyCredentials] if [credentials] is empty.
  /// Throws [UnsupportedError] if the signer uses an unsupported key scheme.
  Future<Map<String, dynamic>> build({
    required DidSigner signer,
    required List<ParsedVerifiableCredential<dynamic>> credentials,
    required String nonce,
    required String domain,
  });
}

/// Builds and signs a W3C Verifiable Presentation (Data Model V1 or V2).
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
      throw TdkException(
        message: 'credentials must not be empty',
        code: TdkExceptionType.emptyCredentials.code,
      );
    }

    final proofGenerator = signer.toProofGenerator(
      nonce: nonce,
      domain: domain,
    );

    return switch (_resolveDataModel(credentials)) {
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

  /// Detects the VP data model version from the credentials' JSON-LD context.
  ///
  /// Uses [dmV2ContextUrl] as the discriminator — if any credential's context
  /// contains it, the VP must be DM v2. Otherwise defaults to DM v1.
  VpDataModel _resolveDataModel(
    List<ParsedVerifiableCredential<dynamic>> credentials,
  ) {
    final contextRaw = credentials.first.context.toJson();
    final contextList = contextRaw is List ? contextRaw : [contextRaw];
    return contextList.contains(dmV2ContextUrl)
        ? VpDataModel.v2
        : VpDataModel.v1;
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
