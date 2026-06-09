/// Types of exceptions that can occur in the Vault Iota share flow.
enum TdkExceptionType {
  /// Exception thrown when the verifier's client metadata could not be fetched
  /// or parsed.
  failedToFetchVerifierMetadata('failed_to_fetch_verifier_metadata'),

  /// Exception thrown when an empty `clientId` is passed to the verifier
  /// metadata service.
  invalidClientId('invalid_client_id'),

  /// Exception thrown when the JWT in the request URI is invalid or has expired.
  invalidOrExpiredJwt('invalid_or_expired_jwt'),

  /// Exception thrown when the `response_mode` in the request is not `direct_post`.
  invalidResponseMode('invalid_response_mode'),

  /// Exception thrown when the `client_id` field is missing from the request.
  missingClientId('missing_client_id'),

  /// Exception thrown when the `client_id_scheme` in the request is not `did`.
  invalidClientIdScheme('invalid_client_id_scheme'),

  /// Exception thrown when the JWT `aud` claim does not match the wallet DID.
  invalidAudience('invalid_audience'),

  /// Exception thrown when the URI could not be parsed or a required field was missing.
  parseFailure('parse_failure'),

  /// Thrown when a Presentation Definition is structurally invalid.
  invalidPresentationDefinition('invalid_presentation_definition'),

  /// Thrown when a DCQL query is structurally invalid — e.g. a required
  /// field is missing or has the wrong type.
  invalidDcqlQuery('invalid_dcql_query'),

  /// Thrown when a single IDV input descriptor requests more than two VC
  /// types (i.e. more than `VerifiedIdsentityDocument` + one specific subtype).
  unsupportedMultipleIdvTypes('unsupported_multiple_idv_types'),

  /// Thrown when submitting the VP to the verifier callback fails — e.g.
  /// network error, invalid state token, or a non-2xx response.
  submissionFailed('submission_failed'),

  /// Thrown when `VpBuilder.build` is called with an empty credentials list.
  emptyCredentials('empty_credentials'),

  /// Thrown when persisting a consent record to the consumer-provided
  /// `ConsentStorage` fails.
  failedToPersistConsentRecord('failed_to_persist_consent_record'),

  /// Thrown when reading a consent record from the consumer-provided
  /// `ConsentStorage` fails.
  failedToReadConsentRecord('failed_to_read_consent_record');

  /// Creates a new instance of [TdkExceptionType].
  const TdkExceptionType(this.code);

  /// The error code associated with this exception type.
  final String code;
}
