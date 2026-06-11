import 'package:ssi/ssi.dart';

/// A protocol-neutral view of one requested credential group within a
/// `MatchedCredentialsResult`.
///
/// Both PEX (`input_descriptors` combined with `submission_requirements`) and
/// DCQL (`credentials` with the `multiple` flag) collapse to the same shape: a
/// group identified by [id] that requires between [minimumVCsCountToShare] and
/// [maximumVCsCountToShare] credentials, the vault credentials that satisfy it,
/// and a recommended pre-selection. Consumers use this to enforce how many
/// credentials of a given type the user must pick, without depending on the
/// underlying query protocol.
class MatchedCredentialGroup {
  /// Creates a [MatchedCredentialGroup].
  const MatchedCredentialGroup({
    required this.id,
    required this.minimumVCsCountToShare,
    required this.maximumVCsCountToShare,
    required this.availableCredentials,
    required this.recommendedCredentials,
  });

  /// A stable identifier for this group.
  ///
  /// For PEX this is the `input_descriptor` id; for DCQL it is the Credential
  /// Query id.
  final String id;

  /// The minimum number of credentials the verifier requires from this group.
  final int minimumVCsCountToShare;

  /// The maximum number of credentials the verifier accepts from this group, or
  /// `null` when the verifier imposes no upper limit.
  final int? maximumVCsCountToShare;

  /// The vault credentials that are available to satisfy this group.
  final List<VerifiableCredential> availableCredentials;

  /// The recommended pre-selected credentials, capped at
  /// [maximumVCsCountToShare].
  final List<VerifiableCredential> recommendedCredentials;

  /// Whether the verifier accepts more than one credential for this group.
  ///
  /// `true` when [maximumVCsCountToShare] is `null` (unbounded) or greater than
  /// one. For DCQL this reflects the Credential Query `multiple` flag.
  bool get allowsMultiple =>
      maximumVCsCountToShare == null || maximumVCsCountToShare! > 1;
}
