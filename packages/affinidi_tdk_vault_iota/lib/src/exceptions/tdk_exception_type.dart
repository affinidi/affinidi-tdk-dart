/// Types of exceptions that can occur in the Vault Iota share flow.
enum TdkExceptionType {
  /// Exception thrown when the JWT in the request URI is invalid or has expired.
  invalidOrExpiredJwt('invalid_or_expired_jwt'),

  /// Exception thrown when the `response_mode` in the request is not `direct_post`.
  invalidResponseMode('invalid_response_mode'),

  /// Exception thrown when the `client_id` field is missing from the request.
  missingClientId('missing_client_id'),

  /// Exception thrown when the URI could not be parsed or a required field was missing.
  parseFailure('parse_failure'),

  /// Exception thrown when the verifier's client metadata could not be fetched
  /// or parsed.
  verifierMetadataFetchFailed('verifier_metadata_fetch_failed');

  /// Creates a new instance of [TdkExceptionType].
  ///
  /// [code] - The error code associated with this exception type.
  const TdkExceptionType(this.code);

  /// The error code associated with this exception type.
  final String code;
}
