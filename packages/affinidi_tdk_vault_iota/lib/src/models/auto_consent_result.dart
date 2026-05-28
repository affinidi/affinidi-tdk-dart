import 'package:ssi/ssi.dart' show VerifiableCredential;

/// Result of an automatic consent check.
///
/// Indicates whether a previous consent record authorises the share flow to proceed
/// without user interaction.
///
/// Use a switch expression or pattern-matching to handle both cases:
/// ```dart
/// switch (result) {
///   case AutoConsentApproved(:final vcsToShare):
///     // submit the VP using vcsToShare
///   case AutoConsentDeclined():
///     // show the interactive consent screen
/// }
/// ```
sealed class AutoConsentResult {
  const AutoConsentResult();
}

/// The automatic consent check passed and the share flow may proceed without
/// user interaction.
///
/// [vcsToShare] contains the VCs that were shared in the previous session,
/// already verified to still be available and matching the stored fingerprint.
final class AutoConsentApproved extends AutoConsentResult {
  /// The Verifiable Credentials to include in the VP — same set as the
  /// previous share, preserved in presentation order.
  final List<VerifiableCredential> vcsToShare;

  /// Creates an [AutoConsentApproved] result.
  ///
  /// Parameters:
  /// * [vcsToShare] - VCs that were previously shared and are still available.
  const AutoConsentApproved({required this.vcsToShare});
}

/// The automatic consent check did not pass.
///
/// The caller must show the interactive consent screen. This happens when:
/// - No prior consent record exists for this verifier+PD combination.
/// - The user did not enable automatic sharing last time.
/// - The verifier has consent management enabled (suppresses auto-share).
/// - One or more previously shared VCs are no longer available.
/// - The share fingerprint has changed (verifier branding or VC content changed).
final class AutoConsentDeclined extends AutoConsentResult {
  /// Creates an [AutoConsentDeclined] result.
  const AutoConsentDeclined();
}
