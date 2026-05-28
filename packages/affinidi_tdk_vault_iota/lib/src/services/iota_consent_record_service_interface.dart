import 'package:ssi/ssi.dart' show VerifiableCredential;

import '../exceptions/tdk_exception_type.dart';
import '../models/auto_consent_result.dart';
import '../models/verifier_client_metadata.dart';

/// Defines the contract for persisting a consent record after a successful
/// Iota OID4VP share, and for checking prior consent before presenting the
/// interactive share screen.
abstract interface class IotaConsentRecordServiceInterface {
  /// Computes the stable request hash identifying a verifier+PD combination.
  ///
  /// Matches vault_universal_ui's `_generateRequestHash` algorithm:
  /// `SHA-1("$clientId|${jsonEncode(presentationDefinition)}")`.
  ///
  /// Parameters:
  /// * [clientId] - The verifier's `client_id` from the OID4VP request.
  /// * [presentationDefinition] - The raw PD map from the JWT payload.
  ///
  /// Returns a hex SHA-1 digest that is stable across repeat requests from
  /// the same verifier with the same PD.
  String computeRequestHash({
    required String clientId,
    required Map<String, dynamic> presentationDefinition,
  });

  /// Checks whether a prior consent record authorises the share to proceed
  /// automatically, without showing the interactive consent screen.
  ///
  /// Mirrors vault_universal_ui's `tryAutoshare` logic:
  /// 1. Look up the record for [requestHash] in the store.
  /// 2. Return [AutoConsentDeclined] if no record exists, auto-share is
  ///    disabled, consent management is active, or the stored record has no
  ///    shared VC IDs.
  /// 3. Verify that every VC ID in `record.sharedVcIds` is still present
  ///    in [availableVcs]. Return [AutoConsentDeclined] on any mismatch.
  /// 4. Recompute the share fingerprint and compare it to the stored hash.
  ///    Return [AutoConsentDeclined] if they differ (verifier branding or
  ///    VC content has changed since the last consent).
  /// 5. Return [AutoConsentApproved] with the previously shared VCs.
  ///
  /// Parameters:
  /// * [requestHash] - Pre-computed via [computeRequestHash].
  /// * [clientId] - The verifier's `client_id`.
  /// * [verifierMetadata] - Resolved branding used for hash recomputation.
  /// * [profileId] - ID of the profile being used for this share.
  /// * [vaultId] - Opaque wallet/DID identifier used for hash recomputation.
  /// * [availableVcs] - All VCs currently available to share.
  ///
  /// Returns an [AutoConsentResult] — either [AutoConsentApproved] (with the
  /// VCs to share) or [AutoConsentDeclined] (show the consent screen).
  /// Throws `TdkException` with code `failedToReadConsentRecord`
  /// if the underlying store lookup fails.
  Future<AutoConsentResult> tryAutomaticConsent({
    required String requestHash,
    required String clientId,
    required VerifierClientMetadata verifierMetadata,
    required String profileId,
    required String vaultId,
    required List<VerifiableCredential> availableVcs,
  });

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
}
