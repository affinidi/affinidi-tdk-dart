import 'package:affinidi_tdk_common/affinidi_tdk_common.dart';

import '../exceptions/tdk_exception_type.dart';

/// A DCQL (Digital Credentials Query Language) query as defined in the
/// OID4VP spec.
///
/// A query describes which credentials a verifier is requesting and what
/// claims are required from each credential.
class DcqlQuery {
  /// The list of credential queries in this DCQL request.
  final List<DcqlCredentialQuery> credentials;

  /// Optional credential set queries describing which combinations of
  /// [credentials] satisfy the request.
  ///
  /// When `null` or empty, every entry in [credentials] is required.
  final List<DcqlCredentialSetQuery>? credentialSets;

  /// Creates a new [DcqlQuery] instance.
  ///
  /// Parameters:
  /// * [credentials] - the list of credential queries to evaluate.
  /// * [credentialSets] - optional credential set combinations.
  const DcqlQuery({required this.credentials, this.credentialSets});

  /// Creates a [DcqlQuery] from a JSON map.
  ///
  /// Parameters:
  /// * [json] - JSON map with a `credentials` array of credential query objects.
  ///
  /// Throws [TdkException] with [TdkExceptionType.invalidDcqlQuery] if
  /// `credentials` is missing or not a list.
  factory DcqlQuery.fromJson(Map<String, dynamic> json) {
    final rawList = json['credentials'];
    if (rawList is! List) {
      throw TdkException(
        message:
            "DCQL query 'credentials' must be a list, got: "
            '${rawList.runtimeType}.',
        code: TdkExceptionType.invalidDcqlQuery.code,
      );
    }
    final rawSets = json['credential_sets'];
    return DcqlQuery(
      credentials: rawList
          .map((e) => DcqlCredentialQuery.fromJson(e as Map<String, dynamic>))
          .toList(),
      credentialSets: rawSets != null
          ? (rawSets as List)
                .map(
                  (e) => DcqlCredentialSetQuery.fromJson(
                    e as Map<String, dynamic>,
                  ),
                )
                .toList()
          : null,
    );
  }

  /// Converts this [DcqlQuery] to a JSON map.
  Map<String, dynamic> toJson() => {
    'credentials': credentials.map((c) => c.toJson()).toList(),
    if (credentialSets != null)
      'credential_sets': credentialSets!.map((s) => s.toJson()).toList(),
  };
}

/// A credential set query within a [DcqlQuery].
///
/// Expresses acceptable combinations of credential query ids as an
/// OR-of-ANDs over [options].
class DcqlCredentialSetQuery {
  /// The acceptable combinations of credential query ids.
  ///
  /// Each inner list is an AND set of credential query ids (referencing the
  /// `id` of a [DcqlCredentialQuery]); the outer list is an OR disjunction.
  /// The set is satisfied when at least one inner list is fully satisfied.
  final List<List<String>> options;

  /// Whether this credential set must be satisfied.
  ///
  /// Defaults to `true` when omitted from the query.
  final bool required;

  /// Optional verifier-supplied purpose describing why the data is requested.
  final Object? purpose;

  /// Creates a new [DcqlCredentialSetQuery] instance.
  ///
  /// Parameters:
  /// * [options] - OR-of-ANDs combinations of credential query ids.
  /// * [required] - whether the set must be satisfied; defaults to `true`.
  /// * [purpose] - optional purpose metadata.
  const DcqlCredentialSetQuery({
    required this.options,
    this.required = true,
    this.purpose,
  });

  /// Creates a [DcqlCredentialSetQuery] from a JSON map.
  ///
  /// Parameters:
  /// * [json] - JSON map with an `options` array and optional `required` and
  ///   `purpose` fields.
  ///
  /// Throws [TdkException] with [TdkExceptionType.invalidDcqlQuery] if
  /// `options` is missing or not a list.
  factory DcqlCredentialSetQuery.fromJson(Map<String, dynamic> json) {
    final rawOptions = json['options'];
    if (rawOptions is! List) {
      throw TdkException(
        message:
            "DCQL credential set 'options' must be a list, got: "
            '${rawOptions.runtimeType}.',
        code: TdkExceptionType.invalidDcqlQuery.code,
      );
    }
    return DcqlCredentialSetQuery(
      options: rawOptions
          .map((group) => (group as List).cast<String>())
          .toList(),
      required: json['required'] as bool? ?? true,
      purpose: json['purpose'],
    );
  }

  /// Converts this [DcqlCredentialSetQuery] to a JSON map.
  Map<String, dynamic> toJson() => {
    'options': options,
    'required': required,
    if (purpose != null) 'purpose': purpose,
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

  /// Optional groups of claim ids, where satisfying any one group is enough.
  ///
  /// Each inner list is an AND set of claim ids (referencing the `id` of a
  /// [DcqlClaimDescriptor]); the outer list is an OR disjunction. When `null`,
  /// every entry in [claims] must match.
  final List<List<String>>? claimSets;

  /// Whether the verifier accepts more than one matching Credential for this
  /// query.
  ///
  /// Defaults to `false` when omitted, in which case exactly one Presentation
  /// is returned for this query id. When `true`, all matching Credentials may
  /// be returned. See the OpenID4VP 1.0 specification, section 6.1.
  final bool multiple;

  /// Creates a new [DcqlCredentialQuery] instance.
  ///
  /// Parameters:
  /// * [id] - identifier for this credential query.
  /// * [format] - optional credential format constraint.
  /// * [meta] - optional metadata with type constraints.
  /// * [claims] - optional list of specific claim requirements.
  /// * [claimSets] - optional OR-of-ANDs groups of claim ids.
  /// * [multiple] - whether multiple matching Credentials are accepted;
  ///   defaults to `false`.
  const DcqlCredentialQuery({
    required this.id,
    this.format,
    this.meta,
    this.claims,
    this.claimSets,
    this.multiple = false,
  });

  /// Creates a [DcqlCredentialQuery] from a JSON map.
  factory DcqlCredentialQuery.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    if (id is! String) {
      throw TdkException(
        message: 'DCQL credential query is missing a string "id".',
        code: TdkExceptionType.invalidDcqlQuery.code,
      );
    }
    final rawClaims = json['claims'];
    final rawClaimSets = json['claim_sets'];
    return DcqlCredentialQuery(
      id: id,
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
      claimSets: rawClaimSets != null
          ? (rawClaimSets as List)
                .map((group) => (group as List).cast<String>())
                .toList()
          : null,
      multiple: json['multiple'] as bool? ?? false,
    );
  }

  /// Converts this [DcqlCredentialQuery] to a JSON map.
  Map<String, dynamic> toJson() => {
    'id': id,
    if (format != null) 'format': format,
    if (meta != null) 'meta': meta!.toJson(),
    if (claims != null) 'claims': claims!.map((c) => c.toJson()).toList(),
    if (claimSets != null) 'claim_sets': claimSets,
    'multiple': multiple,
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
  /// Default prefix used to derive a claim id when [id] is absent.
  static const String defaultIdPrefix = 'CLAIM_';

  /// Optional identifier for this claim, referenced by `claim_sets`.
  final String? id;

  /// Path segments locating the claim within the credential.
  ///
  /// Each element is a `String` (object key), an `int` (array index), or
  /// `null` (wildcard selecting all elements of an array).
  final List<Object?> path;

  /// Optional set of acceptable values for this claim.
  final List<Object?>? values;

  /// Creates a new [DcqlClaimDescriptor] instance.
  ///
  /// Parameters:
  /// * [path] - path segments to the claim.
  /// * [id] - optional claim identifier referenced by `claim_sets`.
  /// * [values] - optional list of acceptable values.
  const DcqlClaimDescriptor({required this.path, this.id, this.values});

  /// Creates a [DcqlClaimDescriptor] from a JSON map.
  factory DcqlClaimDescriptor.fromJson(Map<String, dynamic> json) {
    final rawPath = json['path'];
    if (rawPath is! List) {
      throw TdkException(
        message: 'DCQL claim descriptor is missing a "path" array.',
        code: TdkExceptionType.invalidDcqlQuery.code,
      );
    }
    return DcqlClaimDescriptor(
      id: json['id'] as String?,
      path: rawPath.cast<Object?>(),
      values: json['values'] != null
          ? (json['values'] as List).cast<Object?>()
          : null,
    );
  }

  /// Returns [id] when set, otherwise a deterministic id derived from [index].
  ///
  /// Parameters:
  /// * [index] - the position of this claim within its credential query.
  ///
  /// Returns the effective claim id used for `claim_sets` resolution.
  String getEffectiveId(int index) => id ?? '$defaultIdPrefix$index';

  /// Converts this [DcqlClaimDescriptor] to a JSON map.
  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    'path': path,
    if (values != null) 'values': values,
  };
}
