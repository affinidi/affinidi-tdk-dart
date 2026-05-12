/// Types of exceptions that can occur in the Vault Iota share flow.
enum TdkExceptionType {
  /// Exception thrown when the verifier's client metadata could not be fetched
  /// or parsed.
  failedToFetchVerifierMetadata('failed_to_fetch_verifier_metadata'),

  /// Exception thrown when an empty [clientId] is passed to the verifier
  /// metadata service.
  invalidClientId('invalid_client_id');

  /// Creates a new instance of [TdkExceptionType].
  ///
  /// [code] - The error code associated with this exception type.
  const TdkExceptionType(this.code);

  /// The error code associated with this exception type.
  final String code;
}
