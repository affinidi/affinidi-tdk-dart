import 'package:affinidi_tdk_vault_iota/affinidi_tdk_vault_iota.dart';
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
}
