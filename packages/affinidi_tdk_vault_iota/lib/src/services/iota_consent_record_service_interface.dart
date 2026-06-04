import 'package:ssi/ssi.dart' show VerifiableCredential;

import '../models/auto_consent_result.dart';
import '../models/claimed_credentials_result.dart';
import '../models/share_requirements.dart';
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

  /// Checks whether a previous consent record authorises this share request,
  /// and if so, submits the VP automatically.
  ///
  /// Reconstructs the previously-approved set by matching stored VC IDs
  /// against [claimedCredentials], verifies the share fingerprint, then
  /// builds and submits the VP.
  ///
  /// Parameters:
  /// * [shareRequest] - The parsed OID4VP share request. Provides the
  ///   presentation definition, `state`, `nonce`, and `clientId`.
  /// * [claimedCredentials] - The already-matched credentials from the share
  ///   flow. Previously-shared VCs are looked up by ID within this result.
  /// * [verifierMetadata] - Current verifier branding, compared against the
  ///   stored fingerprint to detect changes.
  /// * [requestHash] - The same hash that was passed to [saveConsentRecord]
  ///   when the record was persisted. Used to look up the matching history
  ///   entry. **Security note:** the TDK does not compute or verify this
  ///   value — it is supplied by the consumer. A buggy or malicious consumer
  ///   could pass a hash that maps to an unrelated stored record. The
  ///   auto-consent path therefore re-validates every security-sensitive field
  ///   against the live [shareRequest]: the verifier `clientId`, the
  ///   descriptor count, that each previously-shared VC still satisfies the
  ///   current descriptor constraints (via PEX), and the full share
  ///   fingerprint.
  /// * [vaultId] - Opaque identifier of the vault or wallet that will sign the
  ///   VP (e.g. a DID). Included in the fingerprint to detect wallet switches.
  ///   The caller must ensure this corresponds to the wallet/profile that will
  ///   actually sign the VP.
  ///
  /// Returns [AutoConsentApproved] with the verifier's redirect URI on success,
  /// or [AutoConsentDeclined] when the interactive flow is required.
  /// Throws `TdkException` with code `failed_to_read_consent_record` if the
  /// underlying storage read fails, or with submission-related codes if the VP
  /// post fails.
  Future<AutoConsentResult> tryAutomaticConsent({
    required Oid4vpShareRequest shareRequest,
    required ClaimedCredentialsResult claimedCredentials,
    required VerifierClientMetadata verifierMetadata,
    required String requestHash,
    required String vaultId,
  });
}
