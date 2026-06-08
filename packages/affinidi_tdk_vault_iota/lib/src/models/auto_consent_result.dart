/// Result of an automatic consent check and share submission.
///
/// Indicates whether the share was completed automatically or whether user
/// interaction is still required.
///
/// Use a switch expression or pattern-matching to handle both cases:
/// ```dart
/// switch (result) {
///   case AutoConsentApproved(:final redirectUri):
///     // VP already submitted; navigate to redirectUri if present
///   case AutoConsentDeclined():
///     // show the interactive consent screen
/// }
/// ```
sealed class AutoConsentResult {
  const AutoConsentResult();
}

/// The automatic consent check passed and the VP was submitted successfully.
///
/// [redirectUri] is the redirect URI returned by the verifier callback, or
/// `null` if the verifier did not provide one.
final class AutoConsentApproved extends AutoConsentResult {
  /// The redirect [Uri] returned by the verifier after VP submission,
  /// or `null` when the verifier did not provide a redirect.
  final Uri? redirectUri;

  /// Creates an [AutoConsentApproved] result.
  ///
  /// Parameters:
  /// * [redirectUri] - The verifier's redirect URI, or `null`.
  const AutoConsentApproved({required this.redirectUri});
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
