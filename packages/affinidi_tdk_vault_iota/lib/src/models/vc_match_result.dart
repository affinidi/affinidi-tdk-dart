import 'package:ssi/ssi.dart';

/// The result of matching credentials against a single input descriptor.
///
/// Returned by a [VcMatcher] function and consumed by
/// [ShareRequirementsMatcher] to determine credential availability.
class VcMatchResult {
  /// Creates a [VcMatchResult].
  const VcMatchResult({
    required this.matchedVCs,
    required this.requiredCredentialsPresent,
  });

  /// The credentials that matched the input descriptor.
  final List<VerifiableCredential> matchedVCs;

  /// Whether the wallet considers the required credentials present.
  final bool requiredCredentialsPresent;
}

/// A function that matches credentials against a single-descriptor
/// Presentation Definition.
///
/// The consumer provides this — typically wrapping their wallet's PEX engine.
///
/// [presentationDefinition] is a single-descriptor PD map built by
/// [ShareRequirementsMatcher]. [allVerifiableCredentials] is the full list of
/// credentials from the user's vault.
typedef VcMatcher = Future<VcMatchResult> Function({
  required Map<String, dynamic> presentationDefinition,
  required List<VerifiableCredential> allVerifiableCredentials,
});
