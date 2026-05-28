/// Normalised OID4VP authorisation request built from a payload.
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
  ///
  /// Optional per OID4VP 1.0 final §5.2 — either `scope` or `dcql_query`
  /// must be present, but not both.
  final String? scope;

  /// The state value used to correlate the authorization request and response.
  final String state;

  /// The nonce value to bind the presentation to the request.
  final String nonce;

  /// The client identifier of the verifier.
  final String clientId;

  /// The URI to retrieve client metadata from, as defined in OID4VP 1.0 final §5.1.
  ///
  /// Optional — present when the verifier provides metadata by reference instead
  /// of inline via [clientMetadata].
  final String? clientMetadataUri;

  /// The client metadata object as defined in OID4VP 1.0 final §5.1.
  ///
  /// Optional — verifiers may omit this field.
  final Map<String, dynamic>? clientMetadata;

  /// Creates a new [IotaRequest] instance.
  ///
  /// Parameters:
  /// - [responseType] - type of the response.
  /// - [responseMode] - mode in which the response is delivered.
  /// - [acceptResponseUri] - URI to which an accepted response should be sent.
  /// - [rejectResponseUri] - URI to which a rejected response should be sent.
  /// - [scope] - optional scope of the authorization request.
  /// - [state] - state value used to correlate the request and response.
  /// - [nonce] - nonce value to bind the presentation to the request.
  /// - [clientId] - client identifier of the verifier.
  /// - [clientMetadataUri] - optional URI to retrieve client metadata from.
  /// - [clientMetadata] - optional inline client metadata object.
  const IotaRequest({
    required this.responseType,
    required this.responseMode,
    required this.acceptResponseUri,
    required this.rejectResponseUri,
    this.scope,
    required this.state,
    required this.nonce,
    required this.clientId,
    this.clientMetadataUri,
    this.clientMetadata,
  });
}
