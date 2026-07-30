/// Types of exceptions that can occur in the Vault Flutter Utils package.
enum TdkExceptionType {
  /// Thrown when deserializing a consent record from secure storage fails —
  /// e.g. corrupt JSON or a schema mismatch after a model change.
  failedToReadConsentRecord('failed_to_read_consent_record');

  /// Creates a new instance of [TdkExceptionType].
  const TdkExceptionType(this.code);

  /// The error code associated with this exception type.
  final String code;
}
