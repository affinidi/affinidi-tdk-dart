import 'package:ssi/ssi.dart';

import 'credential_set_options.dart';
import 'matched_credential_group.dart';
import 'matched_credentials_result.dart';
import 'pd_descriptor.dart';
import 'pd_requirements.dart' show PDRequirements;
import 'vcs_group_by_type.dart';

/// The result of matching a user's vault credentials against the claimed and
/// IDV descriptors in a [PDRequirements].
///
/// Each entry in [vcsGroups] maps one requested [PDDescriptor] to the
/// credentials found in the user's vault — available, expired, or missing.
class ClaimedCredentialsResult implements MatchedCredentialsResult {
  /// Creates a [ClaimedCredentialsResult].
  const ClaimedCredentialsResult({required this.vcsGroups});

  /// Maps each requested input descriptor to its matched credential group.
  final Map<PDDescriptor, VCsGroupByType> vcsGroups;

  /// Whether every requested descriptor has at least the minimum number of
  /// available credentials.
  @override
  bool get hasEnoughVCsAvailableToShare =>
      vcsGroups.values.every((group) => group.hasEnoughVCsToShare);

  /// The recommended set of credentials to share — up to the maximum allowed
  /// per group, across all descriptor groups.
  @override
  List<VerifiableCredential> get recommendedMaximumVCs => vcsGroups.values
      .expand((group) => group.recommendedMaximumVCs)
      .map((a) => a.vc)
      .toList();

  /// All credentials across all groups that are available to share.
  @override
  List<VerifiableCredential> get availableCredentials => vcsGroups.values
      .expand((group) => group.allAvailableVCs)
      .map((a) => a.vc)
      .toList();

  @override
  List<CredentialSetOptions>? get credentialSetOptions => null;

  @override
  List<MatchedCredentialGroup> get groups => vcsGroups.entries
      .map(
        (entry) => MatchedCredentialGroup(
          id: entry.key.id,
          minimumVCsCountToShare: entry.value.minimumVCsCountToShare,
          maximumVCsCountToShare: entry.value.maximumVCsCountToShare,
          availableCredentials: entry.value.allAvailableVCs
              .map((a) => a.vc)
              .toList(),
          recommendedCredentials: entry.value.recommendedMaximumVCs
              .map((a) => a.vc)
              .toList(),
        ),
      )
      .toList();
}
