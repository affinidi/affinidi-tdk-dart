/// @docImport 'pd_classifier_service.dart';
library;

import 'package:affinidi_tdk_common/affinidi_tdk_common.dart';
import 'package:ssi/ssi.dart';

import '../extensions/submission_requirements_extensions.dart';
import '../models/claimed_credentials_result.dart';
import '../models/pd_descriptor.dart';
import '../models/pd_requirements.dart';
import '../models/submission_requirements.dart';
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
  final Logger _logger;
  final RevocationList2020Verifier? _revocationVerifier;
  static const _componentName = 'ShareRequirementsMatcher';

  /// Creates a [ShareRequirementsMatcher].
  ///
  /// - [revocationVerifier] - optional [RevocationList2020Verifier] used to
  ///   check each matched credential's revocation status. When omitted,
  ///   revocation is not checked and credentials are assumed non-revoked.
  /// - [logger] - optional [Logger] instance; defaults to [Logger.instance].
  ShareRequirementsMatcher({
    RevocationList2020Verifier? revocationVerifier,
    Logger? logger,
  }) : _revocationVerifier = revocationVerifier,
       _logger = logger ?? Logger.instance;

  /// Matches [allVCs] against each claimed and IDV descriptor in
  /// [requirements] and returns an availability breakdown per descriptor.
  ///
  /// - [requirements] (required) - the classified PD requirements produced by
  ///   [PDClassifier]; only `claimedDescriptors` and `idvDescriptors` are
  ///   evaluated.
  /// - [allVCs] (required) - the full list of [VerifiableCredential]s from
  ///   the user's vault to match against.
  ///
  /// Individual descriptor failures are caught, logged, and recorded as
  /// [VcUnavailabilityReason.unknown] rather than propagating.
  ///
  /// The method is `async` to support future revocation-status checks, which
  /// require network I/O.
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
          vcsGroups[descriptor] = VCsGroupByType(
            minimumVCsCountToShare: submissionReq?.minimumVCsCountToShare ?? 1,
            maximumVCsCountToShare: submissionReq?.maximumVCsCountToShare ?? 1,
            matchedVCs: const [
              VcUnavailable(reason: VcUnavailabilityReason.missing),
            ],
          );
          continue;
        }

        vcsGroups[descriptor] = await _buildVCsGroup(matchedVCs, submissionReq);
      } catch (e, stack) {
        _logger.error(
          'Failed to evaluate descriptor "${descriptor.id}": $e',
          stackTrace: stack,
          component: _componentName,
        );
        vcsGroups[descriptor] = VCsGroupByType(
          minimumVCsCountToShare: submissionReq?.minimumVCsCountToShare ?? 1,
          maximumVCsCountToShare: submissionReq?.maximumVCsCountToShare ?? 1,
          matchedVCs: const [
            VcUnavailable(reason: VcUnavailabilityReason.unknown),
          ],
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
  /// and classifies each into available, revoked, or expired.
  ///
  /// - [matchedVCs] (required) - non-empty list of VCs that passed PEX
  ///   field evaluation for a single descriptor.
  /// - [submissionReq] - optional [SubmissionRequirements] controlling the
  ///   minimum and maximum VC counts to share; defaults to 1/1 when absent.
  ///
  /// Revocation is checked via [RevocationList2020Verifier] when one was
  /// provided at construction time. If the revocation check itself throws,
  /// the credential is treated as available and the error is logged.
  ///
  /// Returns a [VCsGroupByType] with available VCs first, then revoked, then
  /// expired.
  Future<VCsGroupByType> _buildVCsGroup(
    List<VerifiableCredential> matchedVCs,
    SubmissionRequirements? submissionReq,
  ) async {
    final sorted = [...matchedVCs]
      ..sort(
        (a, b) =>
            (b.validFrom ?? DateTime(0)).compareTo(a.validFrom ?? DateTime(0)),
      );

    final now = DateTime.now();
    final available = <VcAvailable>[];
    final revoked = <VcUnavailable>[];
    final expired = <VcUnavailable>[];

    for (final vc in sorted) {
      if (vc.validUntil != null && vc.validUntil!.isBefore(now)) {
        expired.add(
          VcUnavailable(
            reason: VcUnavailabilityReason.expired,
            bestMatchVc: vc,
          ),
        );
        continue;
      }

      if (_revocationVerifier != null && vc is ParsedVerifiableCredential) {
        try {
          final result = await _revocationVerifier.verify(vc);
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
          _logger.debug(stack.toString(), component: _componentName);
        }
      }

      available.add(VcAvailable(vc: vc));
    }

    return VCsGroupByType(
      matchedVCs: [...available, ...revoked, ...expired],
      minimumVCsCountToShare: submissionReq?.minimumVCsCountToShare ?? 1,
      maximumVCsCountToShare: submissionReq?.maximumVCsCountToShare ?? 1,
    );
  }
}
