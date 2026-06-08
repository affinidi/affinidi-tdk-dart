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

  /// A second record sharing the same [requestHash] but with a distinct [hash],
  /// used to verify that `findAllByRequestHash` returns all matching entries.
  static IotaConsentRecord secondRecord() => const IotaConsentRecord(
    hash: 'full-hash-pqr',
    requestHash: requestHash,
    sharedAt: '2024-06-01T00:00:00.000Z',
    profileName: 'Work',
    profileId: 'profile-2',
    clientId: 'did:key:z6MkVerifier',
    isAutoShareEnabled: true,
    sharedVcIds: ['vc-2'],
    claimedVcTypesCsv: 'NationalIdV1VC',
  );
}
