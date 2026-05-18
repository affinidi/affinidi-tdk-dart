/// The resolved identity and branding of the verifier making a share request.
///
/// Returned by the verifier metadata service and consumed by the caller to
/// identify and display the requesting party on the consent screen.
///
/// Field optionality follows the OID4VP 1.0 final specification, §5.1 —
/// https://openid.net/specs/openid-4-verifiable-presentations-1_0.html#section-5.1
class VerifierClientMetadata {
  /// The human-readable name of the verifier.
  ///
  /// May be `null` when not provided by the verifier.
  final String? name;

  /// URL of the verifier's logo image.
  ///
  /// May be `null` when not provided by the verifier.
  final String? logo;

  /// The origin (base URL) of the verifier's site.
  ///
  /// May be `null` when not provided by the verifier.
  final String? origin;

  /// Whether the verifier's domain has been verified.
  ///
  /// `null` if the information is not available.
  final bool? domainVerified;

  /// Creates a new [VerifierClientMetadata] instance.
  const VerifierClientMetadata({
    this.name,
    this.logo,
    this.origin,
    this.domainVerified,
  });

  /// Creates a [VerifierClientMetadata] from a JSON map.
  factory VerifierClientMetadata.fromJson(Map<String, dynamic> json) {
    return VerifierClientMetadata(
      name: json['name'] as String?,
      logo: json['logo'] as String?,
      origin: json['origin'] as String?,
      domainVerified: json['domainVerified'] as bool?,
    );
  }

  /// Converts this [VerifierClientMetadata] to a JSON map.
  ///
  /// Null fields are omitted from the output.
  Map<String, dynamic> toJson() => {
    if (name != null) 'name': name,
    if (logo != null) 'logo': logo,
    if (origin != null) 'origin': origin,
    if (domainVerified != null) 'domainVerified': domainVerified,
  };
}
