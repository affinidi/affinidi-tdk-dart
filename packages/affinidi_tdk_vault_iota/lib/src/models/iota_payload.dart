import 'dcql_query.dart';
import 'request_purpose.dart';

/// The decoded JWT body from an Iota OID4VP `?request=` URI parameter.
class IotaPayload {
  /// The nonce value to bind the presentation to the request.
  final String nonce;

  /// The state value used to correlate the authorization request and response.
  final String state;

  /// The client identifier of the verifier.
  final String clientId;

  /// The scheme used to identify the client (e.g. `did`).
  final String clientIdScheme;

  /// The URI to retrieve client metadata from, as defined in OID4VP 1.0 final §5.1.
  ///
  /// Optional — present when the verifier provides metadata by reference instead
  /// of inline via [clientMetadata].
  final String? clientMetadataUri;

  /// The client metadata object as defined in OID4VP 1.0 final §5.1.
  ///
  /// Optional — verifiers may omit this field.
  final Map<String, dynamic>? clientMetadata;

  /// The URI to which the response should be sent.
  final String responseUri;

  /// The type of the response (e.g. `vp_token`).
  final String responseType;

  /// The mode in which the response is delivered (e.g. `direct_post`).
  final String responseMode;

  /// The scope of the authorization request.
  ///
  /// Optional per OID4VP 1.0 final §5.2 — either `scope` or `dcql_query`
  /// must be present, but not both.
  final String? scope;

  /// Optional audience claim of the JWT.
  final String? aud;

  /// Expiration time of the JWT as a Unix timestamp (seconds).
  final int exp;

  /// Issued-at time of the JWT as a Unix timestamp (seconds).
  final int iat;

  /// The Presentation Definition describing the required credentials.
  ///
  /// Exactly one of [presentationDefinition] or [dcqlQuery] must be non-null.
  final Map<String, dynamic>? presentationDefinition;

  /// The DCQL query describing the required credentials.
  ///
  /// Exactly one of [presentationDefinition] or [dcqlQuery] must be non-null.
  final DcqlQuery? dcqlQuery;

  /// Creates a new [IotaPayload] instance.
  ///
  /// Parameters:
  /// - [nonce] - nonce value to bind the presentation to the request.
  /// - [state] - state value used to correlate the authorization request and response.
  /// - [clientId] - client identifier of the verifier.
  /// - [clientIdScheme] - scheme used to identify the client.
  /// - [clientMetadataUri] - optional URI to retrieve client metadata from.
  /// - [clientMetadata] - optional inline client metadata object.
  /// - [responseUri] - URI to which the response should be sent.
  /// - [responseType] - type of the response.
  /// - [responseMode] - mode in which the response is delivered.
  /// - [scope] - optional scope of the authorization request.
  /// - [aud] - optional audience claim of the JWT.
  /// - [exp] - expiration time of the JWT as a Unix timestamp (seconds).
  /// - [iat] - issued-at time of the JWT as a Unix timestamp (seconds).
  /// - [presentationDefinition] - PEX Presentation Definition.
  /// - [dcqlQuery] - DCQL query (mutually exclusive with [presentationDefinition]).
  const IotaPayload({
    required this.nonce,
    required this.state,
    required this.clientId,
    required this.clientIdScheme,
    this.clientMetadataUri,
    this.clientMetadata,
    required this.responseUri,
    required this.responseType,
    required this.responseMode,
    this.scope,
    this.aud,
    required this.exp,
    required this.iat,
    this.presentationDefinition,
    this.dcqlQuery,
  }) : assert(
         (presentationDefinition != null) != (dcqlQuery != null),
         'Exactly one of presentationDefinition or dcqlQuery must be provided.',
       );

  /// Creates an [IotaPayload] from a JSON map.
  ///
  /// Parameters:
  /// - [json] - JSON map representing the JWT payload, with snake_case keys.
  ///
  /// Throws [FormatException] if neither `presentation_definition` nor `dcql_query` is present.
  factory IotaPayload.fromJson(Map<String, dynamic> json) {
    final rawPd = json['presentation_definition'];
    final rawDcql = json['dcql_query'];
    if (rawPd == null && rawDcql == null) {
      throw const FormatException(
        "JWT payload must contain either 'presentation_definition' or 'dcql_query'.",
      );
    }
    return IotaPayload(
      nonce: json['nonce'] as String,
      state: json['state'] as String,
      clientId: (json['client_id'] as String?) ?? '',
      clientIdScheme: json['client_id_scheme'] as String,
      clientMetadataUri: json['client_metadata_uri'] as String?,
      clientMetadata: json['client_metadata'] as Map<String, dynamic>?,
      responseUri: json['response_uri'] as String,
      responseType: json['response_type'] as String,
      responseMode: json['response_mode'] as String,
      scope: json['scope'] as String?,
      aud: json['aud'] as String?,
      exp: (json['exp'] as num).toInt(),
      iat: (json['iat'] as num).toInt(),
      presentationDefinition: rawPd as Map<String, dynamic>?,
      dcqlQuery: rawDcql != null
          ? DcqlQuery.fromJson(rawDcql as Map<String, dynamic>)
          : null,
    );
  }

  /// Converts this [IotaPayload] to a JSON map.
  ///
  /// Null fields are omitted from the output.
  Map<String, dynamic> toJson() => {
    'nonce': nonce,
    'state': state,
    'client_id': clientId,
    'client_id_scheme': clientIdScheme,
    if (clientMetadataUri != null) 'client_metadata_uri': clientMetadataUri,
    if (clientMetadata != null) 'client_metadata': clientMetadata,
    'response_uri': responseUri,
    'response_type': responseType,
    'response_mode': responseMode,
    if (scope != null) 'scope': scope,
    if (aud != null) 'aud': aud,
    'exp': exp,
    'iat': iat,
    if (presentationDefinition != null)
      'presentation_definition': presentationDefinition,
    if (dcqlQuery != null) 'dcql_query': dcqlQuery!.toJson(),
  };

  /// Extracts and validates the [RequestPurpose] from the presentation
  /// definition's `purpose` field.
  ///
  /// Returns `null` if the `purpose` field is absent or does not contain a
  /// valid [RequestPurpose].
  RequestPurpose? get purpose {
    final rawPurpose = presentationDefinition?['purpose'];
    if (rawPurpose == null) return null;
    final parsed = RequestPurpose.fromJson(rawPurpose);
    return parsed.isValid ? parsed : null;
  }
}
