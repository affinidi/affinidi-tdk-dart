import 'package:affinidi_tdk_vault_iota/affinidi_tdk_vault_iota.dart';

class IotaConsentRecordFixtures {
  static const clientId = 'did:key:verifier123';
  static const profileId = 'profile-abc';
  static const profileName = 'My Profile';
  static const did = 'did:key:holder456';
  static const sharedAt = '2020-01-01T00:00:00.000Z';
  static const requestHash = 'req_hash_abc';

  static final verifierMetadata = const VerifierClientMetadata(
    name: 'Test Verifier',
    logo: 'https://example.com/logo.png',
    origin: 'https://example.com',
  );

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
}
