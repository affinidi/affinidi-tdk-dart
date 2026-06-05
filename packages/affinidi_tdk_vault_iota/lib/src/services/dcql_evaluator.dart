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
  /// `jwt_vc_json` or `ldp_vc`. Returns all [allVCs] when no `meta` or
  /// `type_values` filter is defined. Otherwise applies OR-of-ANDs matching
  /// on the `type` array of each credential. VCs whose `type` accessor throws
  /// are silently skipped.
  static List<VerifiableCredential> selectMatching(
    DcqlCredentialQuery credentialQuery,
    List<VerifiableCredential> allVCs,
  ) {
    final format = credentialQuery.format;
    if (format != null && !_supportedFormats.contains(format)) {
      return [];
    }

    final typeValues = credentialQuery.meta?.typeValues;
    if (typeValues == null || typeValues.isEmpty) {
      return List.of(allVCs);
    }

    return allVCs.where((vc) {
      try {
        return _matchesTypeValues(vc, typeValues);
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
}
