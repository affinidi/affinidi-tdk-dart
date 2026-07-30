import 'package:affinidi_tdk_common/affinidi_tdk_common.dart';

import 'models/share_requirements.dart';

/// Defines the contract for the Iota OID4VP share flow service.
///
/// Implementations are responsible for parsing and validating an Iota
/// OID4VP request URI and returning a structured [Oid4vpShareRequest]
/// that the caller can use to drive the sharing UI.
///
/// Example:
/// ```dart
/// final service = ShareFlowService(
///   cryptography: MyCryptographyService(),
/// );
/// final shareRequest = await service.validateOid4vpRequest(
///   Uri.parse('openid4vp://authorize?request=<jwt>'),
/// );
/// ```
abstract interface class ShareFlowServiceInterface {
  /// Parses and validates an Iota OID4VP request URI.
  ///
  /// Decodes the JWT from the `request` query parameter, validates its
  /// contents, and returns a structured [Oid4vpShareRequest].
  ///
  /// [uri] - the OID4VP request URI containing a `request` JWT query parameter.
  /// [walletDid] - DID of the current wallet. When provided, the `aud`
  /// claim in the JWT payload is validated against it.
  ///
  /// Returns an [Oid4vpShareRequest] with the normalised request parameters,
  /// presentation definition, and optional purpose metadata.
  ///
  /// Throws:
  /// - [TdkException] if the URI cannot be parsed or validation fails.
  ///   - `parse_failure`: when the `request` query parameter is absent/malformed or the JWT payload cannot be decoded.
  ///   - `invalid_or_expired_jwt`: when signature verification fails, the token is expired, or the `iat` claim is in the future.
  ///   - `invalid_client_id_scheme`: when `client_id_scheme` is not `did`.
  ///   - `invalid_audience`: when the `aud` claim is present but does not match [walletDid] (or [walletDid] was omitted).
  ///   - `missing_client_id`, `invalid_response_mode`, `invalid_response_type`, `replay_detected`: when the corresponding request parameters fail validation.
  ///
  /// Example:
  /// ```dart
  /// final shareRequest = await service.validateOid4vpRequest(
  ///   Uri.parse('openid4vp://authorize?request=<jwt>'),
  ///   walletDid: 'did:key:z6Mk...',
  /// );
  /// print(shareRequest.request.nonce);
  /// ```
  Future<Oid4vpShareRequest> validateOid4vpRequest(
    Uri uri, {
    String? walletDid,
  });
}
