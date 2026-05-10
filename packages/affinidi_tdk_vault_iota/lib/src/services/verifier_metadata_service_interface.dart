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
  /// If [embeddedClientMetadata] is provided it is parsed directly and no
  /// network request is made.  Otherwise a `GET` request is made to
  /// `/vpa/v1/login/configurations/metadata/{clientId}` to retrieve the
  /// metadata.
  ///
  /// [clientId] - the `client_id` from the OID4VP request (the verifier DID).
  /// [embeddedClientMetadata] - optional metadata map already present in the
  /// request payload (the `client_metadata` JWT claim).  When supplied, the
  /// network call is skipped.
  ///
  /// Returns a [VerifierClientMetadata] with the verifier's name, logo, and
  /// origin.
  ///
  /// Throws:
  /// - [TdkException] with code `verifier_metadata_fetch_failed` when the
  ///   verifier cannot be identified (network failure, unexpected response
  ///   shape, or missing required fields).
  Future<VerifierClientMetadata> fetchVerifierMetadata({
    required String clientId,
    Map<String, dynamic>? embeddedClientMetadata,
  });
}
