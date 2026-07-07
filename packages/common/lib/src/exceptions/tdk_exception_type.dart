/// Enumeration of specific error types for TdkException, each with a unique error code.
enum TdkExceptionType {
  /// The environment override is invalid.
  invalidEnvironmentOverride('invalid_environment_override'),

  /// The environment region override is invalid.
  invalidEnvironmentRegionOverride('invalid_environment_region_override');

  /// Creates a new [TdkExceptionType] with the given error code.
  const TdkExceptionType(this.code);

  /// A unique identifier for the type of error.
  final String code;
}
