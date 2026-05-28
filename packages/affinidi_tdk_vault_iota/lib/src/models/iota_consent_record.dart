/// A record of a completed Iota OID4VP share event.
///
/// Mirrors the shape of the `LoginHistoryItem` stored by the Vault app so that
/// SDK consumers can maintain compatible consent history.  The `requestHash`
/// field uniquely identifies a verifier-request combination and is used to
/// detect whether an existing record should be updated rather than duplicated.
class IotaConsentRecord {
  /// Full fingerprint of the share event.
  ///
<<<<<<< HEAD
  /// Computed from: `profileId | vaultId | clientId | verifierName | logo | siteUrl | vcsFingerprint`.
=======
  /// Computed from: `profileId | did | clientId | clientMetadata | vcFingerprint`.
>>>>>>> dafdb15 (feat: add IotaConsentRecord model and ConsentRecordStore interface)
  /// Changes whenever the user, verifier branding, or selected credentials
  /// change — even for the same verifier.
  final String hash;

<<<<<<< HEAD
  /// Consumer-computed hash identifying the verifier+request combination.
=======
  /// Hash of the share request only: `sha1(clientId | presentationDefinition)`.
>>>>>>> dafdb15 (feat: add IotaConsentRecord model and ConsentRecordStore interface)
  ///
  /// Stable across repeat requests from the same verifier with the same PD.
  /// Used as the deduplication key when persisting records.
  final String requestHash;

  /// URL of the verifier's logo image, if available.
  final String? logo;

  /// Origin (base URL) of the verifier's site, if available.
  final String? siteUrl;

<<<<<<< HEAD
  /// ISO 8601 UTC timestamp of the most recent completed share.
=======
  /// The holder's DID used to sign the Verifiable Presentation.
  final String did;

  /// ISO 8601 timestamp of when the share was first completed.
>>>>>>> dafdb15 (feat: add IotaConsentRecord model and ConsentRecordStore interface)
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
<<<<<<< HEAD
  final String claimedVcTypesCsv;

  /// Labeled data points shared in the VP, keyed by display name.
  final Map<String, String> historySharedData;

  /// Whether the verifier has consent management enabled.
  ///
  /// When `true`, automatic sharing is suppressed regardless of [isAutoShareEnabled].
  final bool isConsentManagementEnabled;
=======
  final String sharedVcTypesCsv;
>>>>>>> dafdb15 (feat: add IotaConsentRecord model and ConsentRecordStore interface)

  /// Creates an [IotaConsentRecord].
  const IotaConsentRecord({
    required this.hash,
    required this.requestHash,
    this.logo,
    this.siteUrl,
<<<<<<< HEAD
=======
    required this.did,
>>>>>>> dafdb15 (feat: add IotaConsentRecord model and ConsentRecordStore interface)
    required this.sharedAt,
    required this.profileName,
    required this.profileId,
    required this.clientId,
    required this.isAutoShareEnabled,
    required this.sharedVcIds,
<<<<<<< HEAD
    required this.claimedVcTypesCsv,
    this.historySharedData = const {},
    this.isConsentManagementEnabled = false,
=======
    required this.sharedVcTypesCsv,
>>>>>>> dafdb15 (feat: add IotaConsentRecord model and ConsentRecordStore interface)
  });

  /// Creates an [IotaConsentRecord] from a JSON map.
  factory IotaConsentRecord.fromJson(Map<String, dynamic> json) {
<<<<<<< HEAD
    final hash = json['hash'] as String?;
    if (hash == null || hash.isEmpty) {
      throw const FormatException(
        'IotaConsentRecord.fromJson: missing or empty required field "hash".',
      );
    }

    final requestHash = json['requestHash'] as String?;
    if (requestHash == null || requestHash.isEmpty) {
      throw const FormatException(
        'IotaConsentRecord.fromJson: missing or empty required field "requestHash".',
      );
    }

    final sharedAt = json['sharedAt'] as String?;
    if (sharedAt == null || sharedAt.isEmpty) {
      throw const FormatException(
        'IotaConsentRecord.fromJson: missing or empty required field "sharedAt".',
      );
    }

    final isAutoShareEnabled = json['isAutoShareEnabled'] as bool?;
    if (isAutoShareEnabled == null) {
      throw const FormatException(
        'IotaConsentRecord.fromJson: missing required field "isAutoShareEnabled".',
      );
    }

    return IotaConsentRecord(
      hash: hash,
      requestHash: requestHash,
      logo: json['logo'] as String?,
      siteUrl: json['siteUrl'] as String?,
      sharedAt: sharedAt,
      profileName: json['profileName'] as String? ?? '',
      profileId: json['profileId'] as String? ?? '',
      clientId: json['clientId'] as String? ?? '',
      isAutoShareEnabled: isAutoShareEnabled,
      sharedVcIds: List<String>.from(json['sharedVcIds'] as List? ?? []),
      claimedVcTypesCsv: json['claimedVcTypesCsv'] as String? ?? '',
      historySharedData:
          (json['historySharedData'] as Map<String, dynamic>? ?? {}).map(
            (k, v) => MapEntry(k, v as String),
          ),
      isConsentManagementEnabled:
          json['isConsentManagementEnabled'] as bool? ?? false,
=======
    return IotaConsentRecord(
      hash: json['hash'] as String,
      requestHash: json['requestHash'] as String? ?? '',
      logo: json['logo'] as String?,
      siteUrl: json['siteUrl'] as String?,
      did: json['did'] as String,
      sharedAt: json['sharedAt'] as String,
      profileName: json['profileName'] as String? ?? '',
      profileId: json['profileId'] as String? ?? '',
      clientId: json['clientId'] as String? ?? '',
      isAutoShareEnabled: json['isAutoShareEnabled'] as bool,
      sharedVcIds: List<String>.from(json['sharedVcIds'] as List? ?? []),
      sharedVcTypesCsv: json['sharedVcTypesCsv'] as String? ?? '',
>>>>>>> dafdb15 (feat: add IotaConsentRecord model and ConsentRecordStore interface)
    );
  }

  /// Converts this [IotaConsentRecord] to a JSON map.
  Map<String, dynamic> toJson() => {
    'hash': hash,
    'requestHash': requestHash,
    if (logo != null) 'logo': logo,
    if (siteUrl != null) 'siteUrl': siteUrl,
<<<<<<< HEAD
=======
    'did': did,
>>>>>>> dafdb15 (feat: add IotaConsentRecord model and ConsentRecordStore interface)
    'sharedAt': sharedAt,
    'profileName': profileName,
    'profileId': profileId,
    'clientId': clientId,
    'isAutoShareEnabled': isAutoShareEnabled,
    'sharedVcIds': sharedVcIds,
<<<<<<< HEAD
    'claimedVcTypesCsv': claimedVcTypesCsv,
    'historySharedData': historySharedData,
    'isConsentManagementEnabled': isConsentManagementEnabled,
=======
    'sharedVcTypesCsv': sharedVcTypesCsv,
>>>>>>> dafdb15 (feat: add IotaConsentRecord model and ConsentRecordStore interface)
  };

  /// Returns a copy of this record with the specified fields replaced.
  IotaConsentRecord copyWith({
    String? hash,
    String? requestHash,
    String? logo,
    String? siteUrl,
<<<<<<< HEAD
=======
    String? did,
>>>>>>> dafdb15 (feat: add IotaConsentRecord model and ConsentRecordStore interface)
    String? sharedAt,
    String? profileName,
    String? profileId,
    String? clientId,
    bool? isAutoShareEnabled,
    List<String>? sharedVcIds,
<<<<<<< HEAD
    String? claimedVcTypesCsv,
    Map<String, String>? historySharedData,
    bool? isConsentManagementEnabled,
=======
    String? sharedVcTypesCsv,
>>>>>>> dafdb15 (feat: add IotaConsentRecord model and ConsentRecordStore interface)
  }) {
    return IotaConsentRecord(
      hash: hash ?? this.hash,
      requestHash: requestHash ?? this.requestHash,
      logo: logo ?? this.logo,
      siteUrl: siteUrl ?? this.siteUrl,
<<<<<<< HEAD
=======
      did: did ?? this.did,
>>>>>>> dafdb15 (feat: add IotaConsentRecord model and ConsentRecordStore interface)
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
