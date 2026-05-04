/// Enum representing different types of exceptions that can occur in this package.
///
/// - [invalidOrExpiredJwt] - the JWT in the request URI is invalid or has expired.
/// - [invalidResponseMode] - the `response_mode` in the request is not `direct_post`.
/// - [missingClientId] - the `client_id` field is missing from the request.
/// - [parseFailure] - the URI could not be parsed or a required field was missing.
///
/// Each exception type has the following properties:
/// - [code] - string code that uniquely identifies the exception type.
enum TdkExceptionType {
  /// The JWT in the request URI is invalid or has expired.
  invalidOrExpiredJwt(code: 'invalid_or_expired_jwt'),

  /// The `response_mode` in the request is not `direct_post`.
  invalidResponseMode(code: 'invalid_response_mode'),

  /// The `client_id` field is missing from the request.
  missingClientId(code: 'missing_client_id'),

  /// The URI could not be parsed or a required field was missing.
  parseFailure(code: 'parse_failure');

  const TdkExceptionType({required this.code});

  /// The machine-readable error code.
  final String code;
}
