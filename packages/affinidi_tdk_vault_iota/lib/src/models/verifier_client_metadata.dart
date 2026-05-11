/// The resolved identity and branding of the verifier making a share request.
///
/// Returned by the verifier metadata service and consumed by the caller to
/// identify and display the requesting party on the consent screen.
class VerifierClientMetadata {
  /// The human-readable name of the verifier.
  ///
  /// Optional per OID4VP 1.0 final §5.1 — may be `null` when not provided.
  final String? name;

  /// URL of the verifier's logo image.
  ///
  /// Optional per OID4VP 1.0 final §5.1 — may be `null` when not provided.
  final String? logo;

  /// The origin (base URL) of the verifier's site.
  ///
  /// Optional per OID4VP 1.0 final §5.1 — may be `null` when not provided.
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
