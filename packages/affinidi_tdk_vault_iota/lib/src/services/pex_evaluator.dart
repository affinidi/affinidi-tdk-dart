part of 'share_requirements_matcher_service.dart';

// ── PEX field evaluator ───────────────────────────────────────────────────────

/// Evaluates Presentation Definition field constraints against a list of
/// Verifiable Credentials.
///
/// Supports the subset of PEX required for credential-type and issuer
/// matching:
/// - JSONPath: `$.type`, `$.issuer`, and any top-level field path
/// - Filter shapes: `{const}`, `{pattern}`, `{contains: {const}}`,
///   `{contains: {pattern}}`
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

  /// Returns `true` if [vcJson] satisfies every constraint in [fields].
  ///
  /// - [vc] (required) - the [VerifiableCredential] being tested.
  /// - [fields] (required) - list of `constraints.fields` objects from the
  ///   input descriptor.
  ///
  /// Returns `true` when all fields are satisfied.
  ///
  /// Throws a [StateError] if a `fields[]` entry is not a JSON object —
  /// matching the fail-closed behaviour of the `@sphereon/pex` JS library,
  /// which also rejects a VC when a field entry has no `path` property.
  /// This case indicates a malformed PD that [PDClassifier] should have
  /// rejected before evaluation reaches this point.
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
  ///   `constraints.fields[]` entry.
  ///
  /// Supported filter shapes:
  /// - `{contains: {const: "value"}}` — list/string contains the value
  /// - `{contains: {pattern: "regex"}}` — list/string matches the regex
  /// - `{const: "value"}` — list/string equals the value
  /// - `{pattern: "regex"}` — list/string matches the regex
  /// - `{type: "string"}` alone — passes without further checks
  ///
  /// Returns `true` when [value] matches a supported [filter]. Unsupported
  /// filter shapes return `false`, except `{type: ...}` by itself, which is
  /// treated as a no-op and returns `true`.
  static bool _matchesFilter(dynamic value, Map<String, dynamic> filter) {
    final contains = filter['contains'];
    if (contains is Map<String, dynamic>) {
      final constValue = contains['const']?.toString();
      final pattern = contains['pattern']?.toString();

      if (constValue != null) {
        return _listOrStringMatches(value, (s) => s == constValue);
      }
      if (pattern != null) {
        return _matchesPattern(value, pattern);
      }
    }

    final constValue = filter['const']?.toString();
    if (constValue != null) {
      return _listOrStringMatches(value, (s) => s == constValue);
    }

    final pattern = filter['pattern']?.toString();
    if (pattern != null) {
      return _matchesPattern(value, pattern);
    }

    final meaningfulKeys = filter.keys.where((k) => k != 'type').toSet();
    return meaningfulKeys.isEmpty;
  }

  /// Compiles [pattern] into a [RegExp] and tests [value] against it.
  ///
  /// - [value] (required) - the resolved VC JSON value to test (may be a
  ///   `List`, `String`, or other scalar).
  /// - [pattern] (required) - the regex string from the filter object.
  ///
  /// Returns `false` when [pattern] is not a valid regular expression, rather
  /// than propagating a [FormatException] that would be swallowed as
  /// [VcUnavailabilityReason.unknown] by the outer error handler.
  static bool _matchesPattern(dynamic value, String pattern) {
    final RegExp regex;
    try {
      regex = RegExp(pattern);
    } on FormatException {
      return false;
    }
    return _listOrStringMatches(value, regex.hasMatch);
  }

  /// Applies [predicate] to each element of [value] when it is a [List], or
  /// to the extracted string representation when [value] is a scalar.
  ///
  /// - [value] (required) - the resolved VC JSON value to test.
  /// - [predicate] (required) - the string-level test to apply.
  ///
  /// Returns `true` if [predicate] holds for at least one element (or the
  /// scalar itself).
  static bool _listOrStringMatches(
    dynamic value,
    bool Function(String) predicate,
  ) {
    if (value is List) {
      return value.any((e) {
        final s = _toStringValue(e);
        return s != null && predicate(s);
      });
    }
    final s = _toStringValue(value);
    return s != null && predicate(s);
  }

  /// Coerces [value] to a string for filter comparison.
  ///
  /// - [value] - the raw JSON value; may be `null`, a `String`, a
  ///   `Map<String, dynamic>`, or any other scalar.
  ///
  /// Returns the string as-is, the `id` field for issuer-as-object shapes,
  /// `value.toString()` for other scalars, or `null` when [value] is `null`.
  static String? _toStringValue(dynamic value) {
    if (value == null) return null;
    if (value is String) return value;
    if (value is Map<String, dynamic>) {
      final id = value['id'];
      if (id != null) return _toStringValue(id);
    }
    return value.toString();
  }
}
