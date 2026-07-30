import 'package:ssi/ssi.dart';

import 'credential_set_options.dart';
import 'matched_credential_group.dart';

/// The common result interface for both PEX and DCQL credential matching.
///
/// Returned by `CredentialMatcherService.match` for both PEX and DCQL share
/// requests. Consumers only need this interface — they never need to branch
/// on the concrete type.
abstract interface class MatchedCredentialsResult {
  /// Whether every requested credential group has at least the minimum number
  /// of available credentials to satisfy the request.
  bool get hasEnoughVCsAvailableToShare;

  /// The recommended set of credentials to share across all groups.
  List<VerifiableCredential> get recommendedMaximumVCs;

  /// All credentials across all groups that are available to share.
  List<VerifiableCredential> get availableCredentials;

  /// The requested credential groups, each describing how many credentials of
  /// that group may be shared and which vault credentials satisfy it.
  ///
  /// Use this to enforce per-group minimum and maximum selection counts and to
  /// tell whether a group accepts multiple credentials
  /// ([MatchedCredentialGroup.allowsMultiple]).
  List<MatchedCredentialGroup> get groups;

  /// The credential-set alternatives, or `null` when the underlying query does
  /// not use credential sets (PEX, or DCQL without `credential_sets`).
  ///
  /// Each entry represents one `credential_set` from the DCQL query. Within
  /// each entry, the Wallet can choose any one
  /// [CredentialSetOptions.alternatives] to satisfy the set. Cross-reference
  /// with [groups] using the credential-query IDs in each alternative to
  /// retrieve the matching [MatchedCredentialGroup].
  ///
  /// When `null`, every entry in [groups] is independently required.
  List<CredentialSetOptions>? get credentialSetOptions;
}
