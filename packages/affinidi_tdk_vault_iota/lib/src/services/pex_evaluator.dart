part of 'share_requirements_matcher_service.dart';

// ── PEX field evaluator ───────────────────────────────────────────────────────

/// Evaluates Presentation Definition field constraints against a list of
/// Verifiable Credentials.
///
/// Supports:
/// - JSONPath: `$.type`, `$.issuer`, and any dot-notation field path
/// - Filter: any valid JSON Schema (Draft 7) — `const`, `enum`, `pattern`,
///   `contains`, `minimum`, `maximum`, `format`, etc.
abstract final class PexEvaluator {
  /// Returns the VCs from [allVCs] that satisfy all `constraints.fields` in
  /// [inputDescriptor].
  ///
  /// - [inputDescriptor] (required) - a single input descriptor JSON object.
  /// - [allVCs] (required) - all [VerifiableCredential]s to filter.
  ///
  /// Returns all [allVCs] when the descriptor has no `constraints` or no
  /// `fields`. Otherwise returns only the VCs that satisfy every field
  /// constraint.
  static List<VerifiableCredential> selectMatching(
    Map<String, dynamic> inputDescriptor,
    List<VerifiableCredential> allVCs,
  ) {
    final constraints = inputDescriptor['constraints'] as Map<String, dynamic>?;
    final fields = constraints?['fields'] as List<dynamic>? ?? const [];

    if (fields.isEmpty) return List.of(allVCs);

    // Compile each field's JSON Schema filter once, before iterating over VCs.
    final compiledFields = _compileFields(fields);

    return allVCs.where((vc) {
      try {
        return _matchesAllFields(vc, compiledFields);
      } on Exception {
        return false;
      }
    }).toList();
  }

  /// Parses and compiles each entry in [fields] into a
  /// `(paths, schema)` record.
  ///
  /// Throws a [StateError] for any entry that is not a JSON object — this
  /// indicates a malformed PD that [PDClassifier] should have rejected.
  static List<({List<String> paths, JsonSchema? schema})> _compileFields(
    List<dynamic> fields,
  ) {
    return fields.map((field) {
      if (field is! Map<String, dynamic>) {
        throw StateError(
          'Malformed PD: constraints.fields[] entry is not a JSON object '
          '(got ${field.runtimeType}: $field). '
          'The descriptor should have been rejected by PDClassifier.',
        );
      }
      final paths =
          (field['path'] as List?)?.whereType<String>().toList() ??
          const <String>[];
      final rawFilter = field['filter'];
      if (rawFilter == null) {
        return (paths: paths, schema: null);
      }
      if (rawFilter is! Map<String, dynamic>) {
        throw StateError(
          'Malformed PD: constraints.fields[].filter is not a JSON object '
          '(got ${rawFilter.runtimeType}: $rawFilter). '
          'The descriptor should have been rejected by PDClassifier.',
        );
      }
      return (paths: paths, schema: JsonSchema.create(rawFilter));
    }).toList();
  }

  /// Returns `true` if [vc] satisfies every compiled field constraint.
  static bool _matchesAllFields(
    VerifiableCredential vc,
    List<({List<String> paths, JsonSchema? schema})> compiledFields,
  ) {
    final vcJson = vc.toJson();
    return compiledFields.every(
      (field) => _evaluateField(field.paths, field.schema, vcJson),
    );
  }

  /// Returns `true` if [vcJson] satisfies the compiled `field` constraint.
  ///
  /// A field is satisfied when at least one of its [paths] resolves to a
  /// non-null value that passes the optional [schema].
  static bool _evaluateField(
    List<String> paths,
    JsonSchema? schema,
    Map<String, dynamic> vcJson,
  ) {
    for (final path in paths) {
      final value = _resolveJsonPath(vcJson, path);
      if (value != null && (schema == null || schema.validate(value).isValid)) {
        return true;
      }
    }
    return false;
  }

  /// Resolves a simple dot-notation JSONPath against [vcJson].
  ///
  /// - [vcJson] (required) - the VC serialised to a JSON map.
  /// - [path] (required) - a JSONPath string such as `$.type` or `$.issuer`.
  ///   Only `$` and `$.field.subfield` notation is supported.
  ///
  /// Returns the resolved value, or `null` if the path cannot be traversed.
  static dynamic _resolveJsonPath(Map<String, dynamic> vcJson, String path) {
    if (path == r'$') return vcJson;
    if (!path.startsWith(r'$.')) {
      throw StateError(
        'Unsupported JSONPath syntax: "$path". '
        'Only dot-notation paths starting with \$. are supported '
        '(e.g. \$.type, \$.issuer). Bracket notation such as '
        r"$['@context'] or $[0] is not supported.",
      );
    }

    final segments = path.substring(2).split('.');
    dynamic current = vcJson;

    for (final segment in segments) {
      if (current is! Map<String, dynamic>) return null;
      current = current[segment];
    }
    return current;
  }
}
