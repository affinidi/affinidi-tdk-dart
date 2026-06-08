import 'package:affinidi_tdk_vault_iota/affinidi_tdk_vault_iota.dart';
import 'package:affinidi_tdk_vault_iota/src/models/dcql_query.dart';
import 'package:affinidi_tdk_vault_iota/src/models/share_requirements.dart';
import 'package:ssi/ssi.dart'
    show
        CredentialSubject,
        Issuer,
        JsonLdContext,
        ParsedVerifiableCredential,
        VcDataModelV1,
        VerifiableCredential;

/// A minimal [ParsedVerifiableCredential] backed by a [VcDataModelV1].
///
/// Used in tests that require the richer [ParsedVerifiableCredential] type
/// (e.g. [IotaConsentRecordService.tryAutomaticConsent]). Adds only the
/// [serialized] getter required by the interface; all other properties come
/// from [VcDataModelV1].
final class _TestParsedVc extends VcDataModelV1
    implements ParsedVerifiableCredential<Map<String, dynamic>> {
  _TestParsedVc({
    required super.context,
    required super.id,
    required super.type,
    required super.issuer,
    required super.credentialSubject,
    required super.issuanceDate,
  });

  @override
  Map<String, dynamic> get serialized => toJson();
}

class IotaConsentRecordFixtures {
  static const clientId = 'did:key:verifier123';
  static const profileId = 'profile-abc';
  static const profileName = 'My Profile';
  static const vaultId = 'vault-holder-456';
  static const sharedAt = '2020-01-01T00:00:00.000Z';
  static const requestHash = 'req_hash_abc';

  static const vcIssuerId = 'did:key:issuer1';
  static const vcId = 'vc-1';
  static final vcValidFrom = DateTime.utc(2023, 1, 1);
  static const vcCredentialSubject = <String, dynamic>{'name': 'Alice'};

  static final pdDescriptor = PDDescriptor.fromJson({'id': 'descriptor-1'});

  static final shareRequest = const PexShareRequest(
    request: IotaRequest(
      responseType: 'vp_token',
      responseMode: 'direct_post',
      acceptResponseUri: 'https://verifier.example.com/accept',
      rejectResponseUri: 'https://verifier.example.com/reject',
      state: 'test_state',
      nonce: 'test_nonce',
      clientId: clientId,
    ),
    presentationDefinition: {
      'id': 'def-1',
      'input_descriptors': [
        {'id': 'descriptor-1'},
      ],
    },
    jwtAssertion: 'test_jwt',
  );

  static final verifierMetadata = const VerifierClientMetadata(
    name: 'Test Verifier',
    logo: 'https://example.com/logo.png',
    origin: 'https://example.com',
  );

  static VerifiableCredential makeVc({
    String id = vcId,
    String issuerId = vcIssuerId,
    DateTime? validFrom,
    Map<String, dynamic> credentialSubject = vcCredentialSubject,
  }) {
    return VcDataModelV1(
      context: JsonLdContext.fromJson([
        'https://www.w3.org/2018/credentials/v1',
      ]),
      id: Uri.parse(id),
      type: {'VerifiableCredential'},
      issuer: Issuer(id: Uri.parse(issuerId)),
      credentialSubject: [CredentialSubject.fromJson(credentialSubject)],
      issuanceDate: validFrom ?? vcValidFrom,
    );
  }

  static ParsedVerifiableCredential<Map<String, dynamic>> makeParsedVc({
    String id = vcId,
    String issuerId = vcIssuerId,
    DateTime? validFrom,
    Map<String, dynamic> credentialSubject = vcCredentialSubject,
  }) {
    return _TestParsedVc(
      context: JsonLdContext.fromJson([
        'https://www.w3.org/2018/credentials/v1',
      ]),
      id: Uri.parse(id),
      type: {'VerifiableCredential'},
      issuer: Issuer(id: Uri.parse(issuerId)),
      credentialSubject: [CredentialSubject.fromJson(credentialSubject)],
      issuanceDate: validFrom ?? vcValidFrom,
    );
  }

  static IotaConsentRecord empty() => const IotaConsentRecord(
    hash: '',
    requestHash: '',
    sharedAt: '',
    profileName: '',
    profileId: '',
    clientId: '',
    isAutoShareEnabled: false,
    sharedVcIds: [],
    claimedVcTypesCsv: '',
  );

  static IotaConsentRecord existing() => const IotaConsentRecord(
    hash: 'old_hash',
    requestHash: 'request_hash',
    sharedAt: sharedAt,
    profileName: profileName,
    profileId: profileId,
    clientId: clientId,
    isAutoShareEnabled: false,
    sharedVcIds: ['vc-1'],
    claimedVcTypesCsv: 'SomeType',
  );

  static IotaConsentRecord autoShareEnabled() => const IotaConsentRecord(
    hash: 'old_hash',
    requestHash: requestHash,
    sharedAt: sharedAt,
    profileName: profileName,
    profileId: profileId,
    clientId: clientId,
    isAutoShareEnabled: true,
    isConsentManagementEnabled: false,
    sharedVcIds: ['vc-1'],
    claimedVcTypesCsv: 'SomeType',
  );

  static IotaConsentRecord autoShareEnabledMatchingHash() =>
      const IotaConsentRecord(
        hash: 'mock_hash',
        requestHash: requestHash,
        sharedAt: sharedAt,
        profileName: profileName,
        profileId: profileId,
        clientId: clientId,
        isAutoShareEnabled: true,
        isConsentManagementEnabled: false,
        sharedVcIds: [vcId],
        claimedVcTypesCsv: 'SomeType',
      );

  static IotaConsentRecord autoShareDisabled() => const IotaConsentRecord(
    hash: 'mock_hash',
    requestHash: requestHash,
    sharedAt: sharedAt,
    profileName: profileName,
    profileId: profileId,
    clientId: clientId,
    isAutoShareEnabled: false,
    isConsentManagementEnabled: false,
    sharedVcIds: [vcId],
    claimedVcTypesCsv: 'SomeType',
  );

  static IotaConsentRecord consentManagementEnabled() =>
      const IotaConsentRecord(
        hash: 'mock_hash',
        requestHash: requestHash,
        sharedAt: sharedAt,
        profileName: profileName,
        profileId: profileId,
        clientId: clientId,
        isAutoShareEnabled: true,
        isConsentManagementEnabled: true,
        sharedVcIds: [vcId],
        claimedVcTypesCsv: 'SomeType',
      );

  /// Builds a [ClaimedCredentialsResult] containing the given [available] VCs.
  ///
  /// Each VC is placed in its own descriptor group. Pass an empty list (the
  /// default) to simulate a share flow where no credentials were matched.
  static ClaimedCredentialsResult claimedCredentials({
    List<ParsedVerifiableCredential<dynamic>> available = const [],
  }) {
    if (available.isEmpty) return const ClaimedCredentialsResult(vcsGroups: {});
    return ClaimedCredentialsResult(
      vcsGroups: {
        for (var i = 0; i < available.length; i++)
          PDDescriptor.fromJson({'id': 'descriptor-$i'}): VCsGroupByType(
            matchedVCs: [VcAvailable(vc: available[i])],
          ),
      },
    );
  }

  /// A [DcqlShareRequest] with a single credential query matching any
  /// [VerifiableCredential] (no type filter).
  static const dcqlShareRequest = DcqlShareRequest(
    request: IotaRequest(
      responseType: 'vp_token',
      responseMode: 'direct_post',
      acceptResponseUri: 'https://verifier.example.com/accept',
      rejectResponseUri: 'https://verifier.example.com/reject',
      state: 'test_state',
      nonce: 'test_nonce',
      clientId: clientId,
    ),
    dcqlQuery: DcqlQuery(credentials: [DcqlCredentialQuery(id: 'query-1')]),
    jwtAssertion: 'test_jwt',
  );

  /// A DCQL consent record with auto-share enabled and a hash matching the
  /// mock cryptography service return value (`mock_hash`).
  static IotaConsentRecord dcqlAutoShareEnabledMatchingHash() =>
      const IotaConsentRecord(
        hash: 'mock_hash',
        requestHash: requestHash,
        sharedAt: sharedAt,
        profileName: profileName,
        profileId: profileId,
        clientId: clientId,
        isAutoShareEnabled: true,
        isConsentManagementEnabled: false,
        sharedVcIds: [vcId],
        claimedVcTypesCsv: 'SomeType',
      );

  /// A [DcqlShareRequest] with two credential queries and a single required
  /// [DcqlCredentialSetQuery] whose options are `[['query-1'], ['query-2']]`
  /// (either query alone satisfies the set).
  static const dcqlShareRequestWithSets = DcqlShareRequest(
    request: IotaRequest(
      responseType: 'vp_token',
      responseMode: 'direct_post',
      acceptResponseUri: 'https://verifier.example.com/accept',
      rejectResponseUri: 'https://verifier.example.com/reject',
      state: 'test_state',
      nonce: 'test_nonce',
      clientId: clientId,
    ),
    dcqlQuery: DcqlQuery(
      credentials: [
        DcqlCredentialQuery(id: 'query-1'),
        DcqlCredentialQuery(id: 'query-2'),
      ],
      credentialSets: [
        DcqlCredentialSetQuery(
          options: [
            ['query-1'],
            ['query-2'],
          ],
        ),
      ],
    ),
    jwtAssertion: 'test_jwt',
  );

  /// A consent record storing only [vcId], intended for use with
  /// [dcqlShareRequestWithSets].
  static IotaConsentRecord dcqlWithSetsAutoShareMatchingHash() =>
      const IotaConsentRecord(
        hash: 'mock_hash',
        requestHash: requestHash,
        sharedAt: sharedAt,
        profileName: profileName,
        profileId: profileId,
        clientId: clientId,
        isAutoShareEnabled: true,
        isConsentManagementEnabled: false,
        sharedVcIds: [vcId],
        claimedVcTypesCsv: 'SomeType',
      );
}
