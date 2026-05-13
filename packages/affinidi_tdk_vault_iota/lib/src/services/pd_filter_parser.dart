part of 'pd_classifier_service.dart';

// ── PD filter value parser ────────────────────────────────────────────────────

/// Parses a single PD `filter` JSON object into a plain string value.
///
/// Supports the following filter shapes (in priority order):
/// - `{contains: {pattern: "regex"}}` — strips `^`/`$` anchors
/// - `{contains: {const: "value"}}`
/// - `{pattern: "regex"}` — strips anchors
/// - `{const: "value"}`
///
/// Throws a [TdkException] with
/// [TdkExceptionType.invalidPresentationDefinition] for structurally invalid
/// filter objects.
abstract final class PdFilterParser {
  /// Extracts a string value from a PD filter object.
  ///
  /// - [filter] (required) - a `constraints.fields[].filter` JSON object.
  ///
  /// Throws a [TdkException] with
  /// [TdkExceptionType.invalidPresentationDefinition] when the filter is
  /// structurally invalid (e.g. `contains` is not a map, or a value field is
  /// not a string).
  ///
  /// Returns the extracted string value. `^`/`$` regex anchors are stripped
  /// from `pattern` values.
  static String extractValue(Map<String, dynamic> filter) {
    final rawContains = filter[PdClassifierConstants.containsKey];

    if (rawContains != null) {
      if (rawContains is! Map<String, dynamic>) {
        _throw(
          'PD filter "contains" must be a JSON object.',
          TdkExceptionType.invalidPresentationDefinition.code,
        );
      }
      if (rawContains.containsKey(PdClassifierConstants.patternKey)) {
        final value = rawContains[PdClassifierConstants.patternKey];
        if (value is! String) {
          _throw(
            'PD filter "contains.pattern" must be a string.',
            TdkExceptionType.invalidPresentationDefinition.code,
          );
        }
        return _stripAnchors(value);
      }
      if (rawContains.containsKey(PdClassifierConstants.constKey)) {
        final value = rawContains[PdClassifierConstants.constKey];
        if (value is! String) {
          _throw(
            'PD filter "contains.const" must be a string.',
            TdkExceptionType.invalidPresentationDefinition.code,
          );
        }
        return value;
      }
    } else {
      if (filter.containsKey(PdClassifierConstants.patternKey)) {
        final value = filter[PdClassifierConstants.patternKey];
        if (value is! String) {
          _throw(
            'PD filter "pattern" must be a string.',
            TdkExceptionType.invalidPresentationDefinition.code,
          );
        }
        return _stripAnchors(value);
      }
      if (filter.containsKey(PdClassifierConstants.constKey)) {
        final value = filter[PdClassifierConstants.constKey];
        if (value is! String) {
          _throw(
            'PD filter "const" must be a string.',
            TdkExceptionType.invalidPresentationDefinition.code,
          );
        }
        return value;
      }
    }

    _throw(
      'Could not extract constraint value from PD filter.',
      TdkExceptionType.invalidPresentationDefinition.code,
    );
  }

  /// Removes leading `^` and trailing `$` regex anchors from [pattern].
  ///
  /// - [pattern] (required) - a raw regex pattern string from a PD filter.
  ///
  /// Returns the pattern with leading `^` and trailing `$` stripped.
  static String _stripAnchors(String pattern) {
    var result = pattern;
    if (result.startsWith('^')) result = result.substring(1);
    if (result.endsWith(r'$')) result = result.substring(0, result.length - 1);
    return result;
  }
}
