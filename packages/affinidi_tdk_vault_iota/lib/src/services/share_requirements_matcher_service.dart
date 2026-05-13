import 'package:ssi/ssi.dart';

import '../../affinidi_tdk_vault_iota.dart';
import '../models/claimed_credentials_result.dart';
import '../models/vc_availability.dart';
import '../models/vc_unavailability_reason.dart';
import '../models/vcs_group_by_type.dart';

part 'pex_evaluator.dart';

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

  /// Matches [allVCs] against each claimed and IDV descriptor in
  /// [requirements] and returns an availability breakdown per descriptor.
  ///
  /// - [requirements] (required) - the classified PD requirements produced by
  ///   [PDClassifier]; only `claimedDescriptors` and `idvDescriptors` are
  ///   evaluated.
  /// - [allVCs] (required) - the full list of [VerifiableCredential]s from
  ///   the user's vault to match against.
  ///
  /// Individual descriptor failures are caught and recorded as
  /// [VcUnavailabilityReason.unknown] rather than propagating.
  ///
  /// Returns a [ClaimedCredentialsResult] mapping each descriptor to its
  /// [VCsGroupByType] (available, expired, or missing).
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
        final matchedVCs = PexEvaluator.selectMatching(
          descriptor.toJson(),
          allVCs,
        );

        if (matchedVCs.isEmpty) {
          vcsGroups[descriptor] = const VCsGroupByType(
            matchedVCs: [VcUnavailable(reason: VcUnavailabilityReason.missing)],
          );
          continue;
        }

        vcsGroups[descriptor] = _buildVCsGroup(matchedVCs, submissionReq);
      } catch (_) {
        vcsGroups[descriptor] = const VCsGroupByType(
          matchedVCs: [VcUnavailable(reason: VcUnavailabilityReason.unknown)],
        );
      }
    }

    return ClaimedCredentialsResult(vcsGroups: Map.unmodifiable(vcsGroups));
  }

  /// Extracts the [SubmissionRequirements] for [descriptor]'s group, if any.
  ///
  /// - [descriptor] (required) - the [PDDescriptor] whose `groupName` is
  ///   used to look up the requirements.
  /// - [requirements] (required) - the [PDRequirements] containing the
  ///   `submissionRequirementsByGroup` map.
  ///
  /// Returns the matching [SubmissionRequirements], or `null` when the
  /// descriptor has no group or the group has no associated requirements.
  SubmissionRequirements? _submissionRequirementsFor(
    PDDescriptor descriptor,
    PDRequirements requirements,
  ) {
    final group = descriptor.groupName;
    if (group == null) return null;
    return requirements.submissionRequirementsByGroup[group];
  }

  /// Sorts [matchedVCs] by [VerifiableCredential.validFrom] (newest first)
  /// and partitions them into available and expired availability entries.
  ///
  /// - [matchedVCs] (required) - non-empty list of VCs that passed PEX
  ///   field evaluation for a single descriptor.
  /// - [submissionReq] - optional [SubmissionRequirements] controlling the
  ///   minimum and maximum VC counts to share; defaults to 1/1 when absent.
  ///
  /// Returns a [VCsGroupByType] with available VCs listed before expired ones.
  VCsGroupByType _buildVCsGroup(
    List<VerifiableCredential> matchedVCs,
    SubmissionRequirements? submissionReq,
  ) {
    final sorted = [...matchedVCs]
      ..sort(
        (a, b) =>
            (b.validFrom ?? DateTime(0)).compareTo(a.validFrom ?? DateTime(0)),
      );

    final available = sorted
        .where(
          (vc) =>
              vc.validUntil == null || vc.validUntil!.isAfter(DateTime.now()),
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

    return VCsGroupByType(
      matchedVCs: [...available, ...expired],
      minimumVCsCountToShare: submissionReq?.minimumVCsCountToShare ?? 1,
      maximumVCsCountToShare: submissionReq?.maximumVCsCountToShare ?? 1,
    );
  }
}

