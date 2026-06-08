import 'package:ssi/ssi.dart';

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
}
