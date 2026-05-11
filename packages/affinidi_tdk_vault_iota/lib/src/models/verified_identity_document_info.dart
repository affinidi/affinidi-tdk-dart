/// Metadata about the type of identity verification document required by a
/// share request.
///
/// Populated when the PD classifier identifies an input descriptor that
/// requests a `VerifiedIdentityDocument`-type VC from a trusted IDV issuer.
class VerifiedIdentityDocumentInfo {
  const VerifiedIdentityDocumentInfo({this.schemaContextUrl, this.type});

  /// The JSON-LD context URL of the IDV VC schema.
  final String? schemaContextUrl;

  /// The specific document type requested (e.g. `Passport`, `DriversLicense`).
  final String? type;

  factory VerifiedIdentityDocumentInfo.fromJson(Map<String, dynamic> json) {
    return VerifiedIdentityDocumentInfo(
      schemaContextUrl: json['schemaContextUrl'] as String?,
      type: json['type'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    if (schemaContextUrl != null) 'schemaContextUrl': schemaContextUrl,
    if (type != null) 'type': type,
  };

  VerifiedIdentityDocumentInfo copyWith({
    String? schemaContextUrl,
    String? type,
  }) {
    return VerifiedIdentityDocumentInfo(
      schemaContextUrl: schemaContextUrl ?? this.schemaContextUrl,
      type: type ?? this.type,
    );
  }
}
