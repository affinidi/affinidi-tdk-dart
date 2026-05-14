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

    return allVCs.where((vc) => _matchesAllFields(vc, fields)).toList();
  }

  /// Returns `true` if `vcJson` satisfies every constraint in [fields].
  ///
  /// - [vc] (required) - the [VerifiableCredential] being tested.
  /// - [fields] (required) - list of `constraints.fields` objects from the
  ///   input descriptor.
  ///
  /// Returns `true` when all fields are satisfied.
  ///
  /// Throws a [StateError] if a `fields[]` entry is not a JSON object.
  /// This indicates a malformed PD that [PDClassifier] should have rejected
  /// before evaluation reaches this point.
  static bool _matchesAllFields(VerifiableCredential vc, List<dynamic> fields) {
    final vcJson = vc.toJson();
    return fields.every((field) {
      if (field is! Map<String, dynamic>) {
        throw StateError(
          'Malformed PD: constraints.fields[] entry is not a JSON object '
          '(got ${field.runtimeType}: $field). '
          'The descriptor should have been rejected by PDClassifier.',
        );
      }
      return _evaluateField(field, vcJson);
    });
  }

  /// Returns `true` if [vcJson] satisfies the [field] constraint.
  ///
  /// - [field] (required) - a single `constraints.fields[]` entry.
  /// - [vcJson] (required) - the VC serialised to a JSON map.
  ///
  /// A field is satisfied when at least one of its `path` entries resolves
  /// to a non-null value that passes the optional `filter`.
  static bool _evaluateField(
    Map<String, dynamic> field,
    Map<String, dynamic> vcJson,
  ) {
    final paths = (field['path'] as List?)?.cast<String>() ?? const [];
    final filter = field['filter'] as Map<String, dynamic>?;

    for (final path in paths) {
      final value = _resolveJsonPath(vcJson, path);
      if (value != null && (filter == null || _matchesFilter(value, filter))) {
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
    if (!path.startsWith(r'$.')) return null;

    final segments = path.substring(2).split('.');
    dynamic current = vcJson;

    for (final segment in segments) {
      if (current is! Map<String, dynamic>) return null;
      current = current[segment];
    }
    return current;
  }

  /// Returns `true` if [value] satisfies [filter].
  ///
  /// - [value] (required) - the resolved value from the VC JSON (may be a
  ///   `List`, `String`, `Map`, or other scalar).
  /// - [filter] (required) - the `filter` object from a
  ///   `constraints.fields[]` entry, which is a JSON Schema (Draft 7).
  ///
  /// Validates using a full JSON Schema (Draft 7) evaluator for spec-correct
  /// results across all supported keywords.
  static bool _matchesFilter(dynamic value, Map<String, dynamic> filter) {
    final schema = JsonSchema.create(filter);
    return schema.validate(value).isValid;
  }
}
