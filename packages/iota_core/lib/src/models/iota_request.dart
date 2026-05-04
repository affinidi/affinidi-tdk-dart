import 'iota_payload.dart';

/// Normalised OID4VP authorisation request built from an [IotaPayload].
///
/// Provides a structured view of the authorization request parameters
/// required to present or reject the sharing flow.
class IotaRequest {
  /// The type of the response (e.g. `vp_token`).
  final String responseType;

  /// The mode in which the response is delivered (e.g. `direct_post`).
  final String responseMode;

  /// The URI to which an accepted response should be sent.
  final String acceptResponseUri;

  /// The URI to which a rejected response should be sent.
  final String rejectResponseUri;

  /// The scope of the authorization request.
  final String scope;

  /// The state value used to correlate the authorization request and response.
  final String state;

  /// The nonce value to bind the presentation to the request.
  final String nonce;

  /// The client identifier of the verifier.
  final String? clientId;

  /// URI pointing to the client metadata document.
  final String? clientMetadataUri;

  /// Creates a new [IotaRequest] instance.
  ///
  /// Parameters:
  /// - [responseType] - type of the response.
  /// - [responseMode] - mode in which the response is delivered.
  /// - [acceptResponseUri] - URI to which an accepted response should be sent.
  /// - [rejectResponseUri] - URI to which a rejected response should be sent.
  /// - [scope] - scope of the authorization request.
  /// - [state] - state value used to correlate the request and response.
  /// - [nonce] - nonce value to bind the presentation to the request.
  /// - [clientId] - optional client identifier of the verifier.
  /// - [clientMetadataUri] - optional URI pointing to the client metadata document.
  const IotaRequest({
    required this.responseType,
    required this.responseMode,
    required this.acceptResponseUri,
    required this.rejectResponseUri,
    required this.scope,
    required this.state,
    required this.nonce,
    this.clientId,
    this.clientMetadataUri,
  });

  /// Creates an [IotaRequest] from an [IotaPayload].
  ///
  /// Parameters:
  /// - [payload] - the decoded JWT payload from the OID4VP request URI.
  factory IotaRequest.fromPayload(IotaPayload payload) {
    return IotaRequest(
      responseType: payload.responseType,
      responseMode: payload.responseMode,
      acceptResponseUri: payload.responseUri,
      rejectResponseUri: payload.responseUri,
      scope: payload.scope,
      state: payload.state,
      nonce: payload.nonce,
      clientId: payload.clientId,
      clientMetadataUri: payload.clientMetadataUri,
    );
  }
}
