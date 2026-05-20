import 'iota_consent_record.dart';

/// The result of an auto-share eligibility check.
///
/// Returned by [IotaConsentRecordServiceInterface.checkAutoShare] to indicate
/// whether the share can proceed without user interaction.
sealed class AutoShareResult {
  const AutoShareResult();
}

/// The user has previously consented and opted in to automatic sharing.
///
/// The consumer should proceed with the share without showing the consent
/// screen. [previousConsent] contains the stored consent data — including
/// [IotaConsentRecord.sharedVcIds] — which the consumer uses to re-build and
/// submit the Verifiable Presentation.
final class AutoShareEligible extends AutoShareResult {
  /// The stored consent record from the previous share with this verifier.
  final IotaConsentRecord previousConsent;

  /// Creates an [AutoShareEligible] result.
  const AutoShareEligible({required this.previousConsent});
}

/// The share cannot proceed automatically; the user must go through the full
/// share flow.
final class FullShareRequired extends AutoShareResult {
  /// The reason why automatic sharing is not possible.
  final FullShareRequiredReason reason;

  /// Creates a [FullShareRequired] result.
  const FullShareRequired({required this.reason});
}

/// Describes why automatic sharing cannot proceed.
enum FullShareRequiredReason {
  /// No previous consent record found for this verifier+request combination.
  noExistingConsent,

  /// The user has not opted in to automatic sharing for this verifier.
  autoShareNotEnabled,

  /// The verifier requires the user to review and approve every share,
  /// regardless of prior consent.
  consentManagementEnabled,
}
