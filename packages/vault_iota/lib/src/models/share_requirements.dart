import 'package:dcql/dcql.dart';

import 'iota_payload.dart';
import 'iota_request.dart';
import 'request_purpose.dart';

/// The structured result of parsing and validating an OID4VP URI.
///
/// Returned by `ShareFlowService.validateOid4vpRequest` and passed to
/// credential-matching and submission services. Consumers should treat this
/// as an opaque handle — the TDK routes between PEX and DCQL internally.
///
/// The concrete subtype is either [PexShareRequest] (when the verifier used a
/// Presentation Definition) or [DcqlShareRequest] (when the verifier used a
/// DCQL query). These subtypes are internal implementation details and are not
/// part of the public package API.
sealed class Oid4vpShareRequest {
  /// The normalised authorization request parameters.
  final IotaRequest request;

  /// The raw JWT assertion string from the `request` query parameter.
  ///
  /// Must be forwarded when submitting the VP response or constructing
  /// an IDV redirect.
  final String jwtAssertion;

  /// Creates a new [Oid4vpShareRequest] instance.
  ///
  /// Parameters:
  /// * [request] - the normalised authorization request parameters.
  /// * [jwtAssertion] - the raw JWT string from the `request` query parameter.
  const Oid4vpShareRequest({required this.request, required this.jwtAssertion});

  /// Creates the appropriate [Oid4vpShareRequest] subtype from an [IotaPayload].
  ///
  /// Parameters:
  /// * [payload] - the decoded JWT payload.
  /// * [jwtAssertion] - raw JWT string from the `request` query parameter.
  ///
  /// Returns a [PexShareRequest] if [IotaPayload.presentationDefinition] is set,
  /// or a [DcqlShareRequest] if [IotaPayload.dcqlQuery] is set.
  factory Oid4vpShareRequest.fromPayload(
    IotaPayload payload, {
    required String jwtAssertion,
  }) {
    final pd = payload.presentationDefinition;
    if (pd != null) {
      return PexShareRequest(
        request: IotaRequest.fromPayload(payload),
        jwtAssertion: jwtAssertion,
        presentationDefinition: pd,
        purpose: payload.purpose,
      );
    }
    return DcqlShareRequest(
      request: IotaRequest.fromPayload(payload),
      jwtAssertion: jwtAssertion,
      dcqlQuery: payload.dcqlQuery!,
    );
  }
}

/// A PEX-based [Oid4vpShareRequest] — the verifier specified a
/// Presentation Definition.
final class PexShareRequest extends Oid4vpShareRequest {
  /// The Presentation Definition describing the required credentials.
  final Map<String, dynamic> presentationDefinition;

  /// The purpose metadata extracted from the presentation definition, if present.
  final RequestPurpose? purpose;

  /// Creates a new [PexShareRequest] instance.
  ///
  /// Parameters:
  /// * [request] - the normalised authorization request parameters.
  /// * [jwtAssertion] - the raw JWT string from the `request` query parameter.
  /// * [presentationDefinition] - the PEX Presentation Definition.
  /// * [purpose] - optional purpose metadata.
  const PexShareRequest({
    required super.request,
    required super.jwtAssertion,
    required this.presentationDefinition,
    this.purpose,
  });
}

/// A DCQL-based [Oid4vpShareRequest] — the verifier specified a DCQL query.
final class DcqlShareRequest extends Oid4vpShareRequest {
  /// The DCQL query describing the required credentials.
  final DcqlCredentialQuery dcqlQuery;

  /// Creates a new [DcqlShareRequest] instance.
  ///
  /// Parameters:
  /// * [request] - the normalised authorization request parameters.
  /// * [jwtAssertion] - the raw JWT string from the `request` query parameter.
  /// * [dcqlQuery] - the DCQL query.
  const DcqlShareRequest({
    required super.request,
    required super.jwtAssertion,
    required this.dcqlQuery,
  });
}
