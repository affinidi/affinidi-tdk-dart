/// A DCQL (Digital Credentials Query Language) query as defined in the
/// OID4VP spec.
///
/// A query describes which credentials a verifier is requesting and what
/// claims are required from each credential.
class DcqlQuery {
  /// The list of credential queries in this DCQL request.
  final List<DcqlCredentialQuery> credentials;

  /// Creates a new [DcqlQuery] instance.
  ///
  /// Parameters:
  /// * [credentials] - the list of credential queries to evaluate.
  const DcqlQuery({required this.credentials});

  /// Creates a [DcqlQuery] from a JSON map.
  ///
  /// Parameters:
  /// * [json] - JSON map with a `credentials` array of credential query objects.
  ///
  /// Throws [FormatException] if `credentials` is missing or not a list.
  factory DcqlQuery.fromJson(Map<String, dynamic> json) {
    final rawList = json['credentials'];
    if (rawList is! List) {
      throw FormatException(
        "DcqlQuery 'credentials' must be a list, got: ${rawList.runtimeType}",
      );
    }
    return DcqlQuery(
      credentials: rawList
          .map((e) => DcqlCredentialQuery.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  /// Converts this [DcqlQuery] to a JSON map.
  Map<String, dynamic> toJson() => {
    'credentials': credentials.map((c) => c.toJson()).toList(),
  };
}

/// A single credential query entry within a [DcqlQuery].
class DcqlCredentialQuery {
  /// The identifier for this credential query.
  final String id;

  /// The credential format (e.g. `jwt_vc_json`, `ldp_vc`).
  final String? format;

  /// Optional metadata constraining which credential types are accepted.
  final DcqlCredentialMeta? meta;

  /// Optional list of specific claims required from the credential.
  final List<DcqlClaimDescriptor>? claims;

  /// Creates a new [DcqlCredentialQuery] instance.
  ///
  /// Parameters:
  /// * [id] - identifier for this credential query.
  /// * [format] - optional credential format constraint.
  /// * [meta] - optional metadata with type constraints.
  /// * [claims] - optional list of specific claim requirements.
  const DcqlCredentialQuery({
    required this.id,
    this.format,
    this.meta,
    this.claims,
  });

  /// Creates a [DcqlCredentialQuery] from a JSON map.
  factory DcqlCredentialQuery.fromJson(Map<String, dynamic> json) {
    final rawClaims = json['claims'];
    return DcqlCredentialQuery(
      id: json['id'] as String,
      format: json['format'] as String?,
      meta: json['meta'] != null
          ? DcqlCredentialMeta.fromJson(json['meta'] as Map<String, dynamic>)
          : null,
      claims: rawClaims != null
          ? (rawClaims as List)
                .map(
                  (e) =>
                      DcqlClaimDescriptor.fromJson(e as Map<String, dynamic>),
                )
                .toList()
          : null,
    );
  }

  /// Converts this [DcqlCredentialQuery] to a JSON map.
  Map<String, dynamic> toJson() => {
    'id': id,
    if (format != null) 'format': format,
    if (meta != null) 'meta': meta!.toJson(),
    if (claims != null) 'claims': claims!.map((c) => c.toJson()).toList(),
  };
}

/// Metadata constraints for a [DcqlCredentialQuery].
///
/// Specifies which credential types are acceptable using an OR-of-ANDs
/// type filter via [typeValues].
class DcqlCredentialMeta {
  /// Type value sets used to filter credentials.
  ///
  /// Each inner list is an AND conjunction; the outer list is an OR disjunction.
  /// A credential matches if its `type` array satisfies at least one inner list.
  ///
  /// `null` means no type filter is applied.
  final List<List<String>>? typeValues;

  /// Creates a new [DcqlCredentialMeta] instance.
  ///
  /// Parameters:
  /// * [typeValues] - optional OR-of-ANDs type filter.
  const DcqlCredentialMeta({this.typeValues});

  /// Creates a [DcqlCredentialMeta] from a JSON map.
  factory DcqlCredentialMeta.fromJson(Map<String, dynamic> json) {
    final raw = json['type_values'];
    return DcqlCredentialMeta(
      typeValues: raw != null
          ? (raw as List)
                .map((group) => (group as List).cast<String>())
                .toList()
          : null,
    );
  }

  /// Converts this [DcqlCredentialMeta] to a JSON map.
  Map<String, dynamic> toJson() => {
    if (typeValues != null) 'type_values': typeValues,
  };
}

/// A descriptor specifying a required claim within a [DcqlCredentialQuery].
class DcqlClaimDescriptor {
  /// JSON Pointer path to the claim within the credential.
  final List<String> path;

  /// Optional set of acceptable values for this claim.
  final List<Object?>? values;

  /// Creates a new [DcqlClaimDescriptor] instance.
  ///
  /// Parameters:
  /// * [path] - JSON Pointer path segments to the claim.
  /// * [values] - optional list of acceptable values.
  const DcqlClaimDescriptor({required this.path, this.values});

  /// Creates a [DcqlClaimDescriptor] from a JSON map.
  factory DcqlClaimDescriptor.fromJson(Map<String, dynamic> json) {
    return DcqlClaimDescriptor(
      path: (json['path'] as List).cast<String>(),
      values: json['values'] != null
          ? (json['values'] as List).cast<Object?>()
          : null,
    );
  }

  /// Converts this [DcqlClaimDescriptor] to a JSON map.
  Map<String, dynamic> toJson() => {
    'path': path,
    if (values != null) 'values': values,
  };
}
