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

  /// Creates a new [Oid4vpShareRequest] instance.
  ///
  /// Parameters:
  /// - [request] - the normalised authorization request parameters.
  /// - [presentationDefinition] - the presentation definition describing the required credentials.
  /// - [purpose] - optional purpose metadata extracted from the presentation definition.
  const Oid4vpShareRequest({
    required this.request,
    required this.presentationDefinition,
    this.purpose,
  });
}
