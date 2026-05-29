import 'package:ssi/ssi.dart'
    show ParsedVerifiableCredential, VerifiableCredential;

import '../models/auto_consent_result.dart';
import '../models/pd_descriptor.dart';
import '../models/verifier_client_metadata.dart';
import '../models/vp_data_model.dart';

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
  /// When all consent checks pass, the method builds and submits the VP using
  /// the previously approved credential set, then returns
  /// [AutoConsentApproved] carrying the verifier's redirect URI.
  /// If any check fails the interactive flow is required and
  /// [AutoConsentDeclined] is returned.
  ///
  /// Parameters:
  /// * [requestHash] - The same hash that was passed to [saveConsentRecord]
  ///   when the record was persisted. Used to look up the matching history entry.
  /// * [matchedCredentials] - Descriptor–credential pairs from the share
  ///   requirements matcher. All credentials must satisfy
  ///   [ParsedVerifiableCredential] so they can be signed into the VP.
  /// * [verifierMetadata] - Current verifier branding, compared against the
  ///   stored fingerprint to detect changes.
  /// * [profileId] - ID of the profile attempting the share.
  /// * [vaultId] - Opaque wallet identifier used in the fingerprint check.
  /// * [state] - The OID4VP `state` parameter from the authorisation request.
  /// * [nonce] - The OID4VP `nonce` used as the VP challenge.
  /// * [definitionId] - The Presentation Definition ID.
  /// * [dataModel] - Signing parameters (signer, data model version).
  /// * [isConsentManagementEnabled] - When `true`, automatic sharing is
  ///   suppressed and [AutoConsentDeclined] is returned immediately.
  ///
  /// Returns [AutoConsentApproved] with the verifier's redirect URI on success,
  /// or [AutoConsentDeclined] when the interactive flow is required.
  /// Throws `TdkException` with code `failed_to_read_consent_record` if the
  /// underlying storage read fails, or with submission-related codes if the VP
  /// post fails.
  Future<AutoConsentResult> tryAutomaticConsent({
    required String requestHash,
    required List<
      ({
        PDDescriptor descriptor,
        ParsedVerifiableCredential<dynamic> credential,
      })
    >
    matchedCredentials,
    required VerifierClientMetadata verifierMetadata,
    required String profileId,
    required String vaultId,
    required String state,
    required String nonce,
    required String definitionId,
    required VpDataModel dataModel,
    bool isConsentManagementEnabled = false,
  });
}
