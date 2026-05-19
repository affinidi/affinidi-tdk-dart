import 'package:affinidi_tdk_vault_iota/affinidi_tdk_vault_iota.dart';

class ConsentRecordFixtures {
  static const requestHash = 'req_hash_abc';
  static const did = 'did:key:holder456';
  static const hash = 'full_hash_xyz';
  static const sharedAt = '2020-01-01T00:00:00.000Z';

  static IotaConsentRecord create({
    String requestHash = ConsentRecordFixtures.requestHash,
    String did = ConsentRecordFixtures.did,
    String hash = ConsentRecordFixtures.hash,
    String? logo = 'https://example.com/logo.png',
    String? siteUrl = 'https://example.com',
    String sharedAt = ConsentRecordFixtures.sharedAt,
    String profileName = 'My Profile',
    String profileId = 'profile-abc',
    String clientId = 'did:key:verifier123',
    bool isAutoShareEnabled = false,
    List<String> sharedVcIds = const ['vc-1', 'vc-2'],
    String sharedVcTypesCsv = 'SomeType,AnotherType',
  }) {
    return IotaConsentRecord(
      hash: hash,
      requestHash: requestHash,
      logo: logo,
      siteUrl: siteUrl,
      did: did,
      sharedAt: sharedAt,
      profileName: profileName,
      profileId: profileId,
      clientId: clientId,
      isAutoShareEnabled: isAutoShareEnabled,
      sharedVcIds: sharedVcIds,
      sharedVcTypesCsv: sharedVcTypesCsv,
    );
  }
}
