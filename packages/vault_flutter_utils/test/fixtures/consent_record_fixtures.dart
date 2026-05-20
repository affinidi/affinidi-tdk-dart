import 'package:affinidi_tdk_vault_iota/affinidi_tdk_vault_iota.dart';

abstract final class ConsentRecordFixtures {
  static const requestHash = 'req-hash-abc';

  static IotaConsentRecord record() => const IotaConsentRecord(
    hash: 'full-hash-xyz',
    requestHash: requestHash,
    sharedAt: '2024-01-01T00:00:00.000Z',
    profileName: 'Personal',
    profileId: 'profile-1',
    clientId: 'did:key:z6MkVerifier',
    isAutoShareEnabled: false,
    sharedVcIds: ['vc-1'],
    claimedVcTypesCsv: 'EmailV1VC',
  );
}
