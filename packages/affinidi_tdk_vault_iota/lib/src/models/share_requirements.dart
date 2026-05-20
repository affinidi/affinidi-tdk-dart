import 'iota_request.dart';
import 'request_purpose.dart';

/// The structured result of parsing and validating an OID4VP URI.
///
/// Returned by the share flow service and consumed by the caller to decide
/// what to show the user before any sharing happens.
class Oid4vpShareRequest {
  /// The normalised authorization request parameters.
  final IotaRequest request;

  /// The Presentation Definition describing the required credentials.
  final Map<String, dynamic> presentationDefinition;

  /// The purpose metadata extracted from the presentation definition, if present.
  final RequestPurpose? purpose;

  /// The raw JWT assertion string from the `request` query parameter.
  ///
  /// Must be forwarded when submitting the VP response or constructing
  /// an IDV redirect.
  final String jwtAssertion;

  /// Creates a new [Oid4vpShareRequest] instance.
  ///
  /// Parameters:
  /// - [request] - the normalised authorization request parameters.
  /// - [presentationDefinition] - the presentation definition describing the required credentials.
  /// - [jwtAssertion] - the raw JWT string from the `request` query parameter.
  /// - [purpose] - optional purpose metadata extracted from the presentation definition.
  const Oid4vpShareRequest({
    required this.request,
    required this.presentationDefinition,
    required this.jwtAssertion,
    this.purpose,
  });
}
