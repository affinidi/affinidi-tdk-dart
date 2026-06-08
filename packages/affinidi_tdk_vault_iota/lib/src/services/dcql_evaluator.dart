import 'package:ssi/ssi.dart';

import '../models/dcql_query.dart';

/// Evaluates a DCQL [DcqlCredentialQuery] against a list of
/// [VerifiableCredential]s and returns the matching subset.
///
/// All methods are pure static — no state, no side effects.
abstract final class DcqlEvaluator {
  static const _supportedFormats = {'jwt_vc_json', 'ldp_vc'};

  /// Returns the VCs from [allVCs] that match [credentialQuery].
  ///
  /// Parameters:
  /// * [credentialQuery] - the DCQL credential query entry to evaluate.
  /// * [allVCs] - all [VerifiableCredential]s to filter.
  ///
  /// Returns `[]` when `credentialQuery.format` is specified but is not
  /// `jwt_vc_json` or `ldp_vc`. A credential is kept when it satisfies both
  /// the `type_values` filter (OR-of-ANDs on its `type` array) and the
  /// `claims` filter. When `claim_sets` is absent every claim must match;
  /// otherwise at least one claim set must be fully satisfied. VCs whose
  /// evaluation throws are silently skipped.
  static List<VerifiableCredential> selectMatching(
    DcqlCredentialQuery credentialQuery,
    List<VerifiableCredential> allVCs,
  ) {
    final format = credentialQuery.format;
    if (format != null && !_supportedFormats.contains(format)) {
      return [];
    }

    final typeValues = credentialQuery.meta?.typeValues;
    final claims = credentialQuery.claims;
    final claimSets = credentialQuery.claimSets;

    return allVCs.where((vc) {
      try {
        if (typeValues != null &&
            typeValues.isNotEmpty &&
            !_matchesTypeValues(vc, typeValues)) {
          return false;
        }
        if (claims != null && claims.isNotEmpty) {
          return _evaluateClaims(vc, claims, claimSets);
        }
        return true;
      } on Object {
        return false;
      }
    }).toList();
  }

  /// Returns `true` if [vc]'s type list satisfies at least one group in
  /// [typeValues] (OR-of-ANDs evaluation).
  static bool _matchesTypeValues(
    VerifiableCredential vc,
    List<List<String>> typeValues,
  ) {
    final rawTypes = vc.toJson()['type'];
    if (rawTypes is! List) return false;
    final vcTypes = rawTypes.whereType<String>().toSet();

    // OR: at least one group must be fully satisfied
    return typeValues.any(
      // AND: every required type in the group must be present
      (group) => group.every(vcTypes.contains),
    );
  }

  /// Returns `true` if [vc] satisfies the [claims] requirement.
  ///
  /// When [claimSets] is `null`, every claim in [claims] must match. Otherwise
  /// at least one claim set must be fully satisfied, where a set is satisfied
  /// when all of its claim ids resolve to matching claims.
  static bool _evaluateClaims(
    VerifiableCredential vc,
    List<DcqlClaimDescriptor> claims,
    List<List<String>>? claimSets,
  ) {
    final vcJson = vc.toJson();

    if (claimSets == null) {
      return claims.every((claim) => _matchesClaim(vcJson, claim));
    }

    final satisfied = <String>{};
    for (var i = 0; i < claims.length; i++) {
      if (_matchesClaim(vcJson, claims[i])) {
        satisfied.add(claims[i].getEffectiveId(i));
      }
    }
    return claimSets.any((set) => set.every(satisfied.contains));
  }

  /// Returns `true` if [claim] matches a value within [vcJson].
  ///
  /// The claim path is resolved against [vcJson]; an absent path never matches.
  /// When no `values` are specified, presence of the path is sufficient. A
  /// resolved list matches when any of its elements is an accepted value;
  /// a scalar matches when it equals an accepted value.
  static bool _matchesClaim(
    Map<String, dynamic> vcJson,
    DcqlClaimDescriptor claim,
  ) {
    final actual = _resolvePath(vcJson, claim.path);
    if (actual == null) return false;

    final expected = claim.values;
    if (expected == null || expected.isEmpty) return true;

    if (actual is List) {
      return expected.any(actual.contains);
    }
    return expected.any((value) => value == actual);
  }

  /// Resolves [path] segments against [current], returning the located value.
  ///
  /// String segments index into maps, integer segments index into lists, and a
  /// `null` segment selects all elements of a list (collecting non-null
  /// resolutions into a list). Returns `null` when any segment cannot be
  /// resolved.
  static Object? _resolvePath(Object? current, List<Object?> path) {
    if (path.isEmpty) return current;
    if (current == null) return null;

    final head = path.first;
    final remaining = path.sublist(1);

    if (current is Map<String, dynamic>) {
      if (head is! String || !current.containsKey(head)) return null;
      return _resolvePath(current[head], remaining);
    }

    if (current is List) {
      if (head == null) {
        return current
            .map((item) => _resolvePath(item, remaining))
            .where((result) => result != null)
            .toList();
      }
      if (head is int && head >= 0 && head < current.length) {
        return _resolvePath(current[head], remaining);
      }
    }

    return null;
  }
}
