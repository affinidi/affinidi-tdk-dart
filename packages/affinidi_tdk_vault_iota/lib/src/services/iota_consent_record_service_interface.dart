import '../models/verifier_client_metadata.dart';

/// Defines the contract for persisting a consent record after a successful
/// Iota OID4VP share.
abstract interface class IotaConsentRecordServiceInterface {
  /// Persists or updates the consent record for a completed share event.
  ///
  /// Parameters:
  /// * [clientId] - The verifier's `client_id` from the OID4VP request.
  /// * [presentationDefinition] - The raw PD JSON map; used to compute the request fingerprint.
  /// * [verifierMetadata] - Resolved branding of the verifier (logo, siteUrl).
  /// * [profileId] - ID of the profile used for the share.
  /// * [profileName] - Display name of the profile used for the share.
  /// * [did] - The holder DID that signed the VP.
  /// * [sharedVcIds] - IDs of the VCs included in the VP.
  /// * [claimedVcTypesCsv] - Comma-separated VC types included in the VP.
  /// * [isAutoShareEnabled] - Whether the user enabled automatic sharing for this verifier.
  /// * [historySharedData] - Labeled data points shared in the VP.
  /// * [isConsentManagementEnabled] - Whether the verifier has consent management enabled.
  ///
  /// Throws `TdkException` with code `failed_to_persist_consent_record` if the
  /// underlying store operation fails.
  Future<void> saveConsentRecord({
    required String clientId,
    required Map<String, dynamic> presentationDefinition,
    required VerifierClientMetadata verifierMetadata,
    required String profileId,
    required String profileName,
    required String did,
    required List<String> sharedVcIds,
    required String claimedVcTypesCsv,
    required bool isAutoShareEnabled,
    Map<String, String> historySharedData = const {},
    bool isConsentManagementEnabled = false,
  });

  /// Computes the stable request fingerprint for a verifier + PD combination.
  ///
  /// Parameters:
  /// * [clientId] - The verifier's `client_id` from the OID4VP request.
  /// * [presentationDefinition] - The raw PD JSON map.
  ///
  /// Returns a hex SHA-1 digest to check for an existing consent record
  String computeRequestHash({
    required String clientId,
    required Map<String, dynamic> presentationDefinition,
  });
}
