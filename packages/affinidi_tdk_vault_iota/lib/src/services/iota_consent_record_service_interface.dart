import 'package:ssi/ssi.dart' show VerifiableCredential;

import '../models/auto_consent_result.dart';
import '../models/verifier_client_metadata.dart';

/// Defines the contract for persisting a consent record after a successful
/// Iota OID4VP share.
abstract interface class IotaConsentRecordServiceInterface {
  /// Persists or updates the consent record for a completed share event.
  ///
  /// Parameters:
  /// * [requestHash] - Pre-computed hash identifying the verifier+request combination.
  ///   Used as the deduplication key. The consumer controls the algorithm.
  /// * [verifierMetadata] - Resolved branding of the verifier (logo, siteUrl).
  /// * [profileId] - ID of the profile used for the share.
  /// * [profileName] - Display name of the profile used for the share.
  /// * [clientId] - The verifier's `client_id` from the OID4VP request.
  /// * [vaultId] - Opaque identifier of the Vault or wallet that signed the VP (e.g. a DID or account ID).
  /// * [sharedVcs] - The VCs included in the VP, in presentation order.
  /// * [claimedVcTypesCsv] - Comma-separated VC types included in the VP.
  /// * [isAutoShareEnabled] - Whether the user enabled automatic sharing for this verifier.
  /// * [historySharedData] - Labeled data points shared in the VP.
  /// * [isConsentManagementEnabled] - Whether the verifier has consent management enabled.
  ///
  /// Throws `TdkException` with code `failed_to_persist_consent_record` if the
  /// underlying store operation fails.
  Future<void> saveConsentRecord({
    required String requestHash,
    required String clientId,
    required VerifierClientMetadata verifierMetadata,
    required String profileId,
    required String profileName,
    required String vaultId,
    required List<VerifiableCredential> sharedVcs,
    required String claimedVcTypesCsv,
    required bool isAutoShareEnabled,
    Map<String, String> historySharedData = const {},
    bool isConsentManagementEnabled = false,
  });

  /// Checks whether a previous consent record authorises this share request
  /// to proceed without user interaction.
  ///
  /// Parameters:
  /// * [requestHash] - The same hash that was passed to [saveConsentRecord]
  ///   when the record was persisted. Used to look up the matching history entry.
  /// * [availableVcs] - All VCs currently in the user's vault.
  /// * [verifierMetadata] - Current verifier branding, compared against the
  ///   stored fingerprint to detect changes.
  /// * [profileId] - ID of the profile attempting the share.
  /// * [vaultId] - Opaque wallet identifier used in the fingerprint check.
  /// * [isConsentManagementEnabled] - When `true`, automatic sharing is
  ///   suppressed and [AutoConsentDeclined] is returned immediately.
  ///
  /// Returns [AutoConsentApproved] with the VCs to share when auto-consent
  /// is valid, or [AutoConsentDeclined] when the interactive flow is required.
  /// Throws `TdkException` with code `failed_to_read_consent_record` if the
  /// underlying storage read fails.
  Future<AutoConsentResult> tryAutomaticConsent({
    required String requestHash,
    required List<VerifiableCredential> availableVcs,
    required VerifierClientMetadata verifierMetadata,
    required String profileId,
    required String vaultId,
    bool isConsentManagementEnabled = false,
  });
}
