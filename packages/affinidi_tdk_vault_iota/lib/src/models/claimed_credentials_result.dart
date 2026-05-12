import 'package:ssi/ssi.dart';

import '../../affinidi_tdk_vault_iota.dart';
import 'vc_availability.dart';
import 'vcs_group_by_type.dart';

/// The result of matching a user's vault credentials against the claimed and
/// IDV descriptors in a [PDRequirements].
///
/// Each entry in [vcsGroups] maps one requested [PDDescriptor] to the
/// credentials found in the user's vault — available, expired, or missing.
class ClaimedCredentialsResult {
  /// Creates a [ClaimedCredentialsResult].
  const ClaimedCredentialsResult({required this.vcsGroups});

  /// Maps each requested input descriptor to its matched credential group.
  final Map<PDDescriptor, VCsGroupByType> vcsGroups;

  /// Whether every requested descriptor has at least the minimum number of
  /// available credentials.
  bool get isEnoughVCsAvailableToShare =>
      vcsGroups.values.every((group) => group.hasEnoughVCsToShare);

  /// The recommended set of credentials to share — up to the maximum allowed
  /// per group, across all descriptor groups.
  List<VerifiableCredential> get maximumRecommendedVCs => vcsGroups.values
      .expand((group) => group.recommendedMaximumVCs)
      .whereType<VcAvailable>()
      .map((a) => a.vc)
      .toList();

  /// All credentials across all groups that are available to share.
  List<VerifiableCredential> get availableCredentials => vcsGroups.values
      .expand((group) => group.allAvailableVCs)
      .map((a) => a.vc)
      .toList();
}
