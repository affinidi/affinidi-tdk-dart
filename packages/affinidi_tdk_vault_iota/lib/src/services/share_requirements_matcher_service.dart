import 'package:ssi/ssi.dart';

import '../../affinidi_tdk_vault_iota.dart';
import '../models/claimed_credentials_result.dart';
import '../models/vc_availability.dart';
import '../models/vc_match_result.dart';
import '../models/vc_unavailability_reason.dart';
import '../models/vcs_group_by_type.dart';
import 'pd_classifier_constants.dart';

/// Matches a user's vault credentials against the share requirements
/// produced by [PDClassifier].
///
/// For each claimed and IDV descriptor in [PDRequirements], the matcher
/// calls the injected [VcMatcher] function, then classifies each result as
/// available or unavailable (with a typed reason). The overall result is
/// returned as a [ClaimedCredentialsResult].
///
/// The consumer is responsible for providing a [VcMatcher] that wraps their
/// wallet's credential-matching engine (e.g. a PEX implementation).
class ShareRequirementsMatcher {
  /// Creates a [ShareRequirementsMatcher].
  ///
  /// [matcher] — a function that matches credentials against a single-descriptor PD.
  const ShareRequirementsMatcher({required VcMatcher matcher})
      : _matcher = matcher;

  final VcMatcher _matcher;

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
      final pd = {
        'id': descriptor.id,
        'input_descriptors': [descriptor.toJson()],
      };

      final submissionReq = _submissionRequirementsFor(
        descriptor,
        requirements,
      );

      try {
        final matchResult = await _matcher(
          presentationDefinition: pd,
          allVerifiableCredentials: allVCs,
        );

        if (matchResult.matchedVCs.isEmpty ||
            !matchResult.requiredCredentialsPresent) {
          vcsGroups[descriptor] = const VCsGroupByType(
            matchedVCs: [VcUnavailable(reason: VcUnavailabilityReason.missing)],
          );
          continue;
        }

        final sorted = [...matchResult.matchedVCs]..sort(
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
          minimumVCsCountToShare:
              submissionReq?.minimumVCsCountToShare ?? 1,
          maximumVCsCountToShare:
              submissionReq?.maximumVCsCountToShare ?? 1,
        );
      } catch (_) {
        vcsGroups[descriptor] = const VCsGroupByType(
          matchedVCs: [
            VcUnavailable(reason: VcUnavailabilityReason.unknown),
          ],
        );
      }
    }

    return ClaimedCredentialsResult(
      vcsGroups: Map.unmodifiable(vcsGroups),
    );
  }

  /// Extracts the [SubmissionRequirements] for [descriptor]'s group, if any.
  SubmissionRequirements? _submissionRequirementsFor(
    PDDescriptor descriptor,
    PDRequirements requirements,
  ) {
    final rawGroup =
        descriptor.toJson()[PdClassifierConstants.groupNameKey];
    final String? group;
    if (rawGroup is List && rawGroup.isNotEmpty) {
      group = rawGroup.first.toString();
    } else if (rawGroup is String && rawGroup.isNotEmpty) {
      group = rawGroup;
    } else {
      group = null;
    }
    if (group == null) return null;
    return requirements.submissionRequirementsByGroup[group];
  }
}
