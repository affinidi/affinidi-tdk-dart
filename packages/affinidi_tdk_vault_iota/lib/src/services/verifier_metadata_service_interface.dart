import 'package:affinidi_tdk_common/affinidi_tdk_common.dart';

import '../models/verifier_client_metadata.dart';

/// Defines the contract for resolving the identity and branding of a verifier.
///
/// Implementations fetch the verifier's name, logo, and origin so that the
/// caller can display them on a consent screen before the user decides to share
/// credentials.
///
/// The service can be called independently of any other share flow step.
///
/// Example:
/// ```dart
/// final service = VerifierMetadataService(
///   baseUrl: 'https://apse1.api.affinidi.io',
/// );
/// final metadata = await service.fetchVerifierMetadata(
///   clientId: 'did:key:z6Mk...',
/// );
/// print(metadata.name);
/// ```
abstract interface class VerifierMetadataServiceInterface {
  /// Resolves the identity and branding of a verifier.
  ///
  /// Resolution priority:
  /// 1. If [clientMetadata] is provided, it is parsed directly — no
  ///    network request is made.
  /// 2. If [clientMetadataUri] is provided, a `GET` request is made to that
  ///    URI directly.
  /// 3. Otherwise a `GET` request is made to
  ///    `/vpa/v1/login/configurations/metadata/{clientId}`.
  ///
  /// Parameters:
  /// * [clientId] - the `client_id` from the OID4VP request (the verifier DID).
  /// * [clientMetadataUri] - optional URI from the `client_metadata_uri` JWT
  ///   claim (OID4VP 1.0 final §5.1). Used when the verifier provides metadata
  ///   by reference.
  /// * [clientMetadata] - optional inline metadata map from the `client_metadata`
  ///   JWT claim (OID4VP 1.0 final §5.1). When supplied, the network path is
  ///   skipped.
  ///
  /// Returns a [VerifierClientMetadata] with the verifier's name, logo, and
  /// origin.
  /// Throws [TdkException] with code `invalid_client_id` when [clientId] is
  /// empty.
  /// Throws [TdkException] with code `failed_to_fetch_verifier_metadata` when
  /// the verifier cannot be identified (network failure or unexpected response
  /// shape).
  Future<VerifierClientMetadata> fetchVerifierMetadata({
    required String clientId,
    String? clientMetadataUri,
    Map<String, dynamic>? clientMetadata,
  });

  /// Releases resources held by this service.
  ///
  /// Must be called when the service is no longer needed to avoid connection
  /// leaks. After calling [dispose], the service must not be used again.
  void dispose();
}
