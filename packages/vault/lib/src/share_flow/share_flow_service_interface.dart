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
  ///
  /// Returns an [Oid4vpShareRequest] with the normalised request parameters,
  /// presentation definition, and optional purpose metadata.
  ///
  /// Throws:
  /// - [TdkException] if the URI cannot be parsed or a required field is missing.
  ///   - `parse_failure`: when the `request` query parameter is absent, malformed,
  ///     the JWT payload cannot be decoded, or the `client_id_scheme` is not `did`.
  ///   - `missing_client_id`: when the `client_id` field is absent from the payload.
  ///   - `invalid_or_expired_jwt`: when the JWT signature is invalid or the token has expired.
  ///   - `invalid_response_mode`: when `response_mode` is not `direct_post`.
  ///
  /// Example:
  /// ```dart
  /// final shareRequest = await service.validateOid4vpRequest(
  ///   Uri.parse('openid4vp://authorize?request=<jwt>'),
  /// );
  /// print(shareRequest.request.nonce);
  /// ```
  Future<Oid4vpShareRequest> validateOid4vpRequest(Uri uri);
}
