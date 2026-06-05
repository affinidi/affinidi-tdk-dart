import 'package:affinidi_tdk_common/affinidi_tdk_common.dart';
import 'package:ssi/ssi.dart';

import '../models/dcql_query.dart';
import '../models/matched_credentials_result.dart';
import '../models/vc_availability.dart';
import '../models/vc_unavailability_reason.dart';
import '../models/vcs_group_by_type.dart';
import 'dcql_evaluator.dart';

/// The result of matching vault credentials against a [DcqlQuery].
///
/// Each entry in [vcsGroups] maps one [DcqlCredentialQuery] to the
/// credentials found in the vault — available, expired, or missing.
class DcqlMatchedCredentialsResult implements MatchedCredentialsResult {
  /// Creates a [DcqlMatchedCredentialsResult].
  const DcqlMatchedCredentialsResult({required this.vcsGroups});

  /// Maps each credential query entry to its matched credential group.
  final Map<DcqlCredentialQuery, VCsGroupByType> vcsGroups;

  @override
  bool get hasEnoughVCsAvailableToShare =>
      vcsGroups.values.every((group) => group.hasEnoughVCsToShare);

  @override
  List<VerifiableCredential> get recommendedMaximumVCs => vcsGroups.values
      .expand((group) => group.recommendedMaximumVCs)
      .map((a) => a.vc)
      .toList();

  @override
  List<VerifiableCredential> get availableCredentials => vcsGroups.values
      .expand((group) => group.allAvailableVCs)
      .map((a) => a.vc)
      .toList();
}

/// Matches a user's vault credentials against a [DcqlQuery].
///
/// For each [DcqlCredentialQuery] in the query, the matcher filters
/// credentials using [DcqlEvaluator.selectMatching], then classifies each
/// result as available, expired, or missing. The overall result is returned
/// as a [DcqlMatchedCredentialsResult].
class DcqlShareRequirementsMatcher {
  final Logger _logger;
  final RevocationList2020Verifier? _revocationVerifier;
  static const _componentName = 'DcqlShareRequirementsMatcher';

  /// Creates a [DcqlShareRequirementsMatcher].
  ///
  /// Parameters:
  /// * [revocationVerifier] - optional verifier used to check revocation status.
  ///   When omitted, revocation is not checked and credentials are assumed valid.
  /// * [logger] - optional [Logger] instance; defaults to [Logger.instance].
  DcqlShareRequirementsMatcher({
    RevocationList2020Verifier? revocationVerifier,
    Logger? logger,
  }) : _revocationVerifier = revocationVerifier,
       _logger = logger ?? Logger.instance;

  /// Matches [allVCs] against each credential query in [dcqlQuery].
  ///
  /// Parameters:
  /// * [dcqlQuery] - the DCQL query describing requested credentials.
  /// * [allVCs] - the full list of credentials from the vault.
  ///
  /// Returns a [DcqlMatchedCredentialsResult] mapping each query entry to its
  /// [VCsGroupByType]. Per-query evaluation errors are caught and recorded as
  /// [VcUnavailabilityReason.unknown]; other queries continue normally.
  Future<DcqlMatchedCredentialsResult> match(
    DcqlQuery dcqlQuery,
    List<VerifiableCredential> allVCs,
  ) async {
    final vcsGroups = <DcqlCredentialQuery, VCsGroupByType>{};

    for (final credentialQuery in dcqlQuery.credentials) {
      try {
        final matched = DcqlEvaluator.selectMatching(credentialQuery, allVCs);

        if (matched.isEmpty) {
          vcsGroups[credentialQuery] = const VCsGroupByType(
            matchedVCs: [VcUnavailable(reason: VcUnavailabilityReason.missing)],
          );
          continue;
        }

        final available = <VcAvailability>[];
        final expired = <VcAvailability>[];
        final revoked = <VcAvailability>[];
        final now = DateTime.now();

        for (final vc in matched) {
          if (vc.validUntil != null && vc.validUntil!.isBefore(now)) {
            expired.add(
              VcUnavailable(
                reason: VcUnavailabilityReason.expired,
                bestMatchVc: vc,
              ),
            );
            continue;
          }

          final verifier = _revocationVerifier;
          if (verifier != null) {
            if (vc is! ParsedVerifiableCredential) {
              _logger.warning(
                'Revocation check skipped: VC is ${vc.runtimeType}, '
                'not a ParsedVerifiableCredential. Treating as available.',
                component: _componentName,
              );
            } else {
              try {
                final result = await verifier.verify(vc);
                if (result.errors.isNotEmpty) {
                  revoked.add(
                    VcUnavailable(
                      reason: VcUnavailabilityReason.revoked,
                      bestMatchVc: vc,
                    ),
                  );
                  continue;
                }
              } catch (e, stack) {
                _logger.warning(
                  'Revocation check failed for VC — treating as available: $e',
                  component: _componentName,
                );
                _logger.warning(stack.toString(), component: _componentName);
              }
            }
          }

          available.add(VcAvailable(vc: vc));
        }

        vcsGroups[credentialQuery] = VCsGroupByType(
          matchedVCs: [...available, ...revoked, ...expired],
        );
      } catch (e, stackTrace) {
        _logger.error(
          '$_componentName: error evaluating credential query '
          '"${credentialQuery.id}": $e',
          component: _componentName,
        );
        _logger.warning(stackTrace.toString(), component: _componentName);
        vcsGroups[credentialQuery] = const VCsGroupByType(
          matchedVCs: [VcUnavailable(reason: VcUnavailabilityReason.unknown)],
        );
      }
    }

    return DcqlMatchedCredentialsResult(vcsGroups: vcsGroups);
  }
}
