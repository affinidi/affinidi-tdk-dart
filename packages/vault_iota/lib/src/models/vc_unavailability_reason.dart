/// The reason a verifiable credential is not available to share.
enum VcUnavailabilityReason {
  /// The credential has passed its `validUntil` date.
  expired,

  /// The credential has been revoked by the issuer.
  revoked,

  /// No matching credential exists in the user's vault.
  missing,

  /// Availability could not be determined (e.g. a matching error occurred).
  unknown,
}
