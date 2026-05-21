import 'package:ssi/ssi.dart' show VerifiableCredential;

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
  /// * [did] - The holder DID that signed the VP.
  /// * [sharedVcs] - The VCs included in the VP, in presentation order.
  /// * [claimedVcTypesCsv] - Comma-separated VC types included in the VP.
  /// * [isAutoShareEnabled] - Whether the user enabled automatic sharing for this verifier.
  /// * [historySharedData] - Labeled data points shared in the VP.
  /// * [datapoints] - ZPD datapoints shared in the VP (empty for non-ZPD flows).
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
    required String did,
    required List<VerifiableCredential> sharedVcs,
    required String claimedVcTypesCsv,
    required bool isAutoShareEnabled,
    Map<String, String> historySharedData = const {},
    Map<String, dynamic> datapoints = const {},
    bool isConsentManagementEnabled = false,
  });
}
