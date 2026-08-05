import 'package:ssi/ssi.dart' show VerifiableCredential;

import '../models/auto_consent_result.dart';
import '../models/matched_credentials_result.dart';
import '../models/share_requirements.dart';
import '../models/verifier_client_metadata.dart';

/// Defines the contract for persisting a consent record after a successful
/// Iota OID4VP share.
abstract interface class IotaConsentRecordServiceInterface {
  /// Persists or updates the consent record for a completed share event.
  ///
  /// Parameters:
  /// * [shareRequest] - The validated OID4VP share request. The SDK derives the
  ///   internal request fingerprint (used to look up prior consent) and the
  ///   verifier `client_id` from it, so the save and lookup paths always agree.
  /// * [verifierMetadata] - Resolved branding of the verifier (logo, siteUrl).
  /// * [profileId] - ID of the profile used for the share.
  /// * [profileName] - Display name of the profile used for the share.
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
    required Oid4vpShareRequest shareRequest,
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

  /// Deletes the consent record identified by [hash].
  ///
  /// Parameters:
  /// * [hash] - The `IotaConsentRecord.hash` of the record to delete.
  ///
  /// Throws `TdkException` with code `consent_record_not_found` if no record
  /// matches [hash], or with code `failed_to_delete_consent_record` if the
  /// underlying store operation fails.
  Future<void> deleteConsentRecord({required String hash});

  /// Checks whether a previous consent record authorises this share request,
  /// and if so, submits the VP automatically.
  ///
  /// Reconstructs the previously-approved set by matching stored VC IDs
  /// against [matchedCredentials], verifies the share fingerprint, then
  /// builds and submits the VP.
  ///
  /// Parameters:
  /// * [shareRequest] - The parsed OID4VP share request. Provides the
  ///   presentation definition, `state`, `nonce`, and `clientId`.
  /// * [matchedCredentials] - The already-matched credentials from the share
  ///   flow (PEX or DCQL). Previously-shared VCs are looked up by ID within
  ///   this result.
  /// * [verifierMetadata] - Current verifier branding, compared against the
  ///   stored fingerprint to detect changes.
  /// * [vaultId] - Opaque identifier of the vault or wallet that will sign the
  ///   VP (e.g. a DID). Included in the fingerprint to detect wallet switches.
  ///   The caller must ensure this corresponds to the wallet/profile that will
  ///   actually sign the VP.
  ///
  /// The SDK computes the internal request fingerprint from [shareRequest] and
  /// [vaultId] — the same derivation used by [saveConsentRecord] — so the lookup
  /// can never miss because of a mismatched caller-supplied hash. The
  /// auto-consent path still re-validates every security-sensitive field against
  /// the live [shareRequest]: the verifier `clientId`, the credential count,
  /// that each previously-shared VC still satisfies the current request
  /// constraints (via PEX or DCQL evaluator), and the full share fingerprint.
  ///
  /// All stored records matching the request fingerprint with auto-share enabled
  /// are evaluated in order. Each record is skipped if any guard fails (consent
  /// management enabled, previously shared VCs unavailable, credential count
  /// changed, VC-to-requirement matching failed, clientId mismatch, or
  /// fingerprint mismatch). The first record that passes all guards triggers
  /// VP submission.
  ///
  /// Returns [AutoConsentApproved] with the verifier's redirect URI on success,
  /// or [AutoConsentDeclined] when no stored record passes all checks.
  /// Throws `TdkException` with code `failed_to_read_consent_record` if the
  /// underlying storage read fails, or with submission-related codes if the VP
  /// post fails.
  Future<AutoConsentResult> tryAutomaticConsent({
    required Oid4vpShareRequest shareRequest,
    required MatchedCredentialsResult matchedCredentials,
    required VerifierClientMetadata verifierMetadata,
    required String vaultId,
  });
}
