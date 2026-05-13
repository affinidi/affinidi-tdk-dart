import 'package:ssi/ssi.dart';

import '../../affinidi_tdk_vault_iota.dart';
import '../models/claimed_credentials_result.dart';
import '../models/vc_availability.dart';
import '../models/vc_unavailability_reason.dart';
import '../models/vcs_group_by_type.dart';

/// Matches a user's vault credentials against the share requirements
/// produced by [PDClassifier].
///
/// For each claimed and IDV descriptor in [PDRequirements], the matcher
/// evaluates the descriptor's field constraints against every VC in the
/// vault using a built-in PEX field evaluator, then classifies each result
/// as available or unavailable (with a typed reason). The overall result is
/// returned as a [ClaimedCredentialsResult].
///
/// ZPD-linked descriptors are not matched here — they follow a separate flow.
class ShareRequirementsMatcher {
  /// Creates a [ShareRequirementsMatcher].
  const ShareRequirementsMatcher();

  /// Matches [allVCs] against the claimed and IDV descriptors in [requirements].
  ///
  /// Returns a [ClaimedCredentialsResult] mapping each requested descriptor to
  /// its availability status. A failure within an individual descriptor match
  /// is caught and recorded as [VcUnavailabilityReason.unknown] rather than
  /// propagating.
  Future<ClaimedCredentialsResult> match(
    PDRequirements requirements,
    List<VerifiableCredential> allVCs,
  ) async {
    final allDescriptors = [
      ...requirements.claimedDescriptors,
      ...requirements.idvDescriptors,
    ];

    final vcsGroups = <PDDescriptor, VCsGroupByType>{};

    for (final descriptor in allDescriptors) {
      final submissionReq = _submissionRequirementsFor(
        descriptor,
        requirements,
      );

      try {
        final matchedVCs = _PexEvaluator.selectMatching(
          descriptor.toJson(),
          allVCs,
        );

        if (matchedVCs.isEmpty) {
          vcsGroups[descriptor] = const VCsGroupByType(
            matchedVCs: [VcUnavailable(reason: VcUnavailabilityReason.missing)],
          );
          continue;
        }

        final sorted = [...matchedVCs]
          ..sort(
            (a, b) => (b.validFrom ?? DateTime(0)).compareTo(
              a.validFrom ?? DateTime(0),
            ),
          );

        final available = sorted
            .where(
              (vc) =>
                  vc.validUntil == null ||
                  vc.validUntil!.isAfter(DateTime.now()),
            )
            .map((vc) => VcAvailable(vc: vc))
            .toList();

        final expired = sorted
            .where(
              (vc) =>
                  vc.validUntil != null &&
                  vc.validUntil!.isBefore(DateTime.now()),
            )
            .map(
              (vc) => VcUnavailable(
                reason: VcUnavailabilityReason.expired,
                bestMatchVc: vc,
              ),
            )
            .toList();

        vcsGroups[descriptor] = VCsGroupByType(
          matchedVCs: [...available, ...expired],
          minimumVCsCountToShare: submissionReq?.minimumVCsCountToShare ?? 1,
          maximumVCsCountToShare: submissionReq?.maximumVCsCountToShare ?? 1,
        );
      } catch (_) {
        vcsGroups[descriptor] = const VCsGroupByType(
          matchedVCs: [VcUnavailable(reason: VcUnavailabilityReason.unknown)],
        );
      }
    }

    return ClaimedCredentialsResult(vcsGroups: Map.unmodifiable(vcsGroups));
  }

  /// Extracts the [SubmissionRequirements] for [descriptor]'s group, if any.
  SubmissionRequirements? _submissionRequirementsFor(
    PDDescriptor descriptor,
    PDRequirements requirements,
  ) {
    final group = descriptor.groupName;
    if (group == null) return null;
    return requirements.submissionRequirementsByGroup[group];
  }
}

// ── Internal PEX field evaluator ─────────────────────────────────────────────

/// Evaluates Presentation Definition field constraints against a list of
/// Verifiable Credentials.
///
/// Supports the subset of PEX required for credential-type and issuer
/// matching:
/// - JSONPath: `$.type`, `$.issuer`, and any top-level field path
/// - Filter shapes: `{const}`, `{pattern}`, `{contains: {const}}`,
///   `{contains: {pattern}}`
abstract final class _PexEvaluator {
  /// Returns the VCs from [allVCs] that satisfy all `constraints.fields` in
  /// [inputDescriptor].
  ///
  /// If the descriptor has no `constraints` or no `fields`, all VCs are
  /// considered matching.
  static List<VerifiableCredential> selectMatching(
    Map<String, dynamic> inputDescriptor,
    List<VerifiableCredential> allVCs,
  ) {
    final constraints = inputDescriptor['constraints'] as Map<String, dynamic>?;
    final fields = constraints?['fields'] as List<dynamic>? ?? const [];

    if (fields.isEmpty) return List.of(allVCs);

    return allVCs.where((vc) => _matchesAllFields(vc, fields)).toList();
  }

  static bool _matchesAllFields(VerifiableCredential vc, List<dynamic> fields) {
    final vcJson = vc.toJson();
    return fields.every((field) {
      if (field is! Map<String, dynamic>) return true;
      return _evaluateField(field, vcJson);
    });
  }

  /// Returns `true` if [vcJson] satisfies the [field] constraint.
  ///
  /// A field is satisfied when at least one of its `path` entries resolves
  /// to a non-null value that passes the `filter`.
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

  /// Resolves a simple dot-notation JSONPath (e.g. `$.type`, `$.issuer`)
  /// against [vcJson].
  ///
  /// Returns `null` if the path cannot be traversed.
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
  /// Supported filter shapes:
  /// - `{contains: {const: "value"}}` — list/string contains the value
  /// - `{contains: {pattern: "regex"}}` — list/string matches the regex
  /// - `{const: "value"}` — list/string equals the value
  /// - `{pattern: "regex"}` — list/string matches the regex
  /// - `{type: "string"}` alone — passes without further checks
  static bool _matchesFilter(dynamic value, Map<String, dynamic> filter) {
    final contains = filter['contains'];
    if (contains is Map<String, dynamic>) {
      final constValue = contains['const']?.toString();
      final pattern = contains['pattern']?.toString();

      if (constValue != null) {
        return _listOrStringMatches(value, (s) => s == constValue);
      }
      if (pattern != null) {
        final regex = RegExp(pattern);
        return _listOrStringMatches(value, regex.hasMatch);
      }
    }

    final constValue = filter['const']?.toString();
    if (constValue != null) {
      return _listOrStringMatches(value, (s) => s == constValue);
    }

    final pattern = filter['pattern']?.toString();
    if (pattern != null) {
      final regex = RegExp(pattern);
      return _listOrStringMatches(value, regex.hasMatch);
    }

    // Filter has no condition we recognise (e.g. type-only filter) — pass.
    return true;
  }

  /// Applies [predicate] to each element of [value] when it is a [List], or
  /// directly to the extracted string when it is a scalar.
  ///
  /// Returns `true` if [predicate] holds for at least one element.
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

  /// Extracts a string from [value].
  ///
  /// - Strings are returned as-is.
  /// - Objects with an `id` field (e.g. issuer as object) return `id`.
  /// - Other types are `toString()`-ed.
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
