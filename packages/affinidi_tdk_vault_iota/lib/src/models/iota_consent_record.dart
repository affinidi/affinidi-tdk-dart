/// A record of a completed Iota OID4VP share event.
///
/// Mirrors the shape of the `LoginHistoryItem` stored by the Vault app so that
/// SDK consumers can maintain compatible consent history.  The `requestHash`
/// field uniquely identifies a verifier-request combination and is used to
/// detect whether an existing record should be updated rather than duplicated.
class IotaConsentRecord {
  /// Full fingerprint of the share event.
  ///
  /// Computed from: `profileId | did | clientId | clientMetadata | vcFingerprint`.
  /// Changes whenever the user, verifier branding, or selected credentials
  /// change — even for the same verifier.
  final String hash;

  /// Consumer-computed hash identifying the verifier+request combination.
  ///
  /// Stable across repeat requests from the same verifier with the same PD.
  /// Used as the deduplication key when persisting records.
  final String requestHash;

  /// URL of the verifier's logo image, if available.
  final String? logo;

  /// Origin (base URL) of the verifier's site, if available.
  final String? siteUrl;

  /// The holder's DID used to sign the Verifiable Presentation.
  ///
  /// Together with [requestHash] forms the composite primary key for storage,
  /// ensuring consent records are isolated per vault.
  final String holderDid;

  /// ISO 8601 timestamp of when the share was first completed.
  final String sharedAt;

  /// Display name of the profile used for this share.
  final String profileName;

  /// Identifier of the profile used for this share.
  final String profileId;

  /// The verifier's `client_id` from the OID4VP authorization request.
  final String clientId;

  /// Whether the user has enabled automatic sharing for this verifier.
  final bool isAutoShareEnabled;

  /// Identifiers of the Verifiable Credentials included in the VP.
  final List<String> sharedVcIds;

  /// Comma-separated list of VC types included in the VP.
  final String claimedVcTypesCsv;

  /// Labeled data points shared in the VP, keyed by display name.
  final Map<String, String> historySharedData;

  /// Whether the verifier has consent management enabled.
  ///
  /// When `true`, automatic sharing is suppressed regardless of [isAutoShareEnabled].
  final bool isConsentManagementEnabled;

  /// Creates an [IotaConsentRecord].
  const IotaConsentRecord({
    required this.hash,
    required this.requestHash,
    this.logo,
    this.siteUrl,
    required this.holderDid,
    required this.sharedAt,
    required this.profileName,
    required this.profileId,
    required this.clientId,
    required this.isAutoShareEnabled,
    required this.sharedVcIds,
    required this.claimedVcTypesCsv,
    this.historySharedData = const {},
    this.isConsentManagementEnabled = false,
  });

  /// Creates an [IotaConsentRecord] from a JSON map.
  factory IotaConsentRecord.fromJson(Map<String, dynamic> json) {
    return IotaConsentRecord(
      hash: json['hash'] as String,
      requestHash: json['requestHash'] as String? ?? '',
      logo: json['logo'] as String?,
      siteUrl: json['siteUrl'] as String?,
      holderDid: json['did'] as String,
      sharedAt: json['sharedAt'] as String,
      profileName: json['profileName'] as String? ?? '',
      profileId: json['profileId'] as String? ?? '',
      clientId: json['clientId'] as String? ?? '',
      isAutoShareEnabled: json['isAutoShareEnabled'] as bool,
      sharedVcIds: List<String>.from(json['sharedVcIds'] as List? ?? []),
      claimedVcTypesCsv: json['claimedVcTypesCsv'] as String? ?? '',
      historySharedData:
          (json['historySharedData'] as Map<String, dynamic>? ?? {}).map(
            (k, v) => MapEntry(k, v as String),
          ),
      isConsentManagementEnabled:
          json['isConsentManagementEnabled'] as bool? ?? false,
    );
  }

  /// Converts this [IotaConsentRecord] to a JSON map.
  Map<String, dynamic> toJson() => {
    'hash': hash,
    'requestHash': requestHash,
    if (logo != null) 'logo': logo,
    if (siteUrl != null) 'siteUrl': siteUrl,
    'did': holderDid,
    'sharedAt': sharedAt,
    'profileName': profileName,
    'profileId': profileId,
    'clientId': clientId,
    'isAutoShareEnabled': isAutoShareEnabled,
    'sharedVcIds': sharedVcIds,
    'claimedVcTypesCsv': claimedVcTypesCsv,
    'historySharedData': historySharedData,
    'isConsentManagementEnabled': isConsentManagementEnabled,
  };

  /// Returns a copy of this record with the specified fields replaced.
  IotaConsentRecord copyWith({
    String? hash,
    String? requestHash,
    String? logo,
    String? siteUrl,
    String? did,
    String? sharedAt,
    String? profileName,
    String? profileId,
    String? clientId,
    bool? isAutoShareEnabled,
    List<String>? sharedVcIds,
    String? claimedVcTypesCsv,
    Map<String, String>? historySharedData,
    bool? isConsentManagementEnabled,
  }) {
    return IotaConsentRecord(
      hash: hash ?? this.hash,
      requestHash: requestHash ?? this.requestHash,
      logo: logo ?? this.logo,
      siteUrl: siteUrl ?? this.siteUrl,
      holderDid: did ?? this.holderDid,
      sharedAt: sharedAt ?? this.sharedAt,
      profileName: profileName ?? this.profileName,
      profileId: profileId ?? this.profileId,
      clientId: clientId ?? this.clientId,
      isAutoShareEnabled: isAutoShareEnabled ?? this.isAutoShareEnabled,
      sharedVcIds: sharedVcIds ?? this.sharedVcIds,
      claimedVcTypesCsv: claimedVcTypesCsv ?? this.claimedVcTypesCsv,
      historySharedData: historySharedData ?? this.historySharedData,
      isConsentManagementEnabled:
          isConsentManagementEnabled ?? this.isConsentManagementEnabled,
    );
  }
}
