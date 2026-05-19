import 'package:affinidi_tdk_common/affinidi_tdk_common.dart';
import 'package:affinidi_tdk_vault_iota/affinidi_tdk_vault_iota.dart';

class IotaConsentRecordFixtures {
  static const clientId = 'did:key:verifier123';
  static const profileId = 'profile-abc';
  static const profileName = 'My Profile';
  static const did = 'did:key:holder456';
  static const sharedAt = '2020-01-01T00:00:00.000Z';

  static final verifierMetadata = VerifierClientMetadata(
    name: 'Test Verifier',
    logo: 'https://example.com/logo.png',
    origin: 'https://example.com',
  );

  static IotaConsentRecord empty() => IotaConsentRecord(
        hash: '',
        requestHash: '',
        did: '',
        sharedAt: '',
        profileName: '',
        profileId: '',
        clientId: '',
        isAutoShareEnabled: false,
        sharedVcIds: [],
        sharedVcTypesCsv: '',
      );

  static IotaConsentRecord existing() => IotaConsentRecord(
        hash: 'old_hash',
        requestHash: 'request_hash',
        did: did,
        sharedAt: sharedAt,
        profileName: profileName,
        profileId: profileId,
        clientId: clientId,
        isAutoShareEnabled: false,
        sharedVcIds: ['vc-1'],
        sharedVcTypesCsv: 'SomeType',
      );
}
