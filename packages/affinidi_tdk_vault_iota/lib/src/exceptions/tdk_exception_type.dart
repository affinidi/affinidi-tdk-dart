/// Types of exceptions that can occur in the Vault Iota share flow.
enum TdkExceptionType {
  /// Exception thrown when the verifier's client metadata could not be fetched
  /// or parsed.
  failedToFetchVerifierMetadata('failed_to_fetch_verifier_metadata'),

  /// Exception thrown when an empty `clientId` is passed to the verifier
  /// metadata service.
  invalidClientId('invalid_client_id'),

  /// The error code associated with this exception type.
  /// Thrown when a Presentation Definition is structurally invalid — e.g.
  /// missing `input_descriptors`, invalid filter shapes, or illegal
  /// submission requirement values.
  invalidPresentationDefinition('invalid_presentation_definition'),

  /// Thrown when a single IDV input descriptor requests more than two VC
  /// types (i.e. more than `VerifiedIdentityDocument` + one specific subtype).
  unsupportedMultipleIdvTypes('unsupported_multiple_idv_types');

  /// Creates a new instance of [TdkExceptionType].
  ///
  /// [code] - The error code associated with this exception type.
  const TdkExceptionType(this.code);

  /// The error code string associated with this exception type.
  final String code;
}
