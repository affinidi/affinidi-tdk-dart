import 'package:affinidi_tdk_cryptography/affinidi_tdk_cryptography.dart';
import 'package:affinidi_tdk_vault_iota/affinidi_tdk_vault_iota.dart';

/// A minimal in-memory [ConsentRecordStore] for demonstration purposes.
///
/// In a real application replace this with `DriftConsentRecordStore` from
/// `package:vault_edge_drift_provider`, or your own persistence backend.
class InMemoryConsentRecordStore implements ConsentRecordStore {
  final Map<String, IotaConsentRecord> _records = {};

  String _key(String requestHash, String did) => '$requestHash|$did';

  @override
  Future<void> saveOrUpdate(IotaConsentRecord record) async {
    _records[_key(record.requestHash, record.profileDid)] = record;
  }

  @override
  Future<IotaConsentRecord?> findByRequestHashAndDid(
    String requestHash,
    String did,
  ) async => _records[_key(requestHash, did)];
}

/// This example demonstrates how to persist a consent record after a
/// successful Iota OID4VP share.
///
/// The consumer is responsible for computing `requestHash` — the deduplication
/// key that identifies a unique verifier + Presentation Definition combination.
/// Use any stable algorithm you prefer; the example below uses SHA-1 via the
/// bundled [CryptographyService].
Future<void> main() async {
  final cryptography = CryptographyService();

  final store = InMemoryConsentRecordStore();

  final service = IotaConsentRecordService(
    store: store,
    cryptography: cryptography,
  );

  // Values that would normally come from the validated OID4VP request and the
  // wallet / profile in use.
  const clientId = 'did:key:z6MkVerifier123';
  const holderDid = 'did:key:z6MkHolder456';
  const profileId = 'profile-abc';
  const profileName = 'Personal';

  // Compute the request fingerprint.  The consumer chooses the algorithm.
  // Here we produce sha1("$clientId") — a simple per-verifier deduplication.
  // You may include the serialised Presentation Definition JSON for stricter
  // per-request deduplication.
  final requestHash = cryptography.createHash(hashSource: clientId);

  final verifierMetadata = const VerifierClientMetadata(
    name: 'Example Verifier',
    logo: 'https://example.com/logo.png',
    origin: 'https://example.com',
    domainVerified: true,
  );

  try {
    await service.saveConsentRecord(
      requestHash: requestHash,
      clientId: clientId,
      verifierMetadata: verifierMetadata,
      profileId: profileId,
      profileName: profileName,
      did: holderDid,
      sharedVcIds: ['vc:uuid:vc-1', 'vc:uuid:vc-2'],
      claimedVcTypesCsv: 'EmailV1VC,PhoneNumberV1VC',
      isAutoShareEnabled: false,
      historySharedData: {
        'Email address': 'user@example.com',
        'Phone number': '+1 555 000 0000',
      },
      isConsentManagementEnabled: false,
    );

    print('Consent record saved successfully.');

    // Retrieve the record to confirm persistence.
    final saved = await store.findByRequestHashAndDid(requestHash, holderDid);
    if (saved != null) {
      print('requestHash : ${saved.requestHash}');
      print('clientId    : ${saved.clientId}');
      print('did         : ${saved.profileDid}');
      print('profileName : ${saved.profileName}');
      print('sharedAt    : ${saved.sharedAt}');
      print('vcTypes     : ${saved.claimedVcTypesCsv}');
    }

    // Saving again preserves the original [sharedAt] timestamp (upsert).
    await service.saveConsentRecord(
      requestHash: requestHash,
      clientId: clientId,
      verifierMetadata: verifierMetadata,
      profileId: profileId,
      profileName: profileName,
      did: holderDid,
      sharedVcIds: ['vc:uuid:vc-3'],
      claimedVcTypesCsv: 'EmailV1VC',
      isAutoShareEnabled: true,
    );

    final updated = await store.findByRequestHashAndDid(requestHash, holderDid);
    if (updated != null) {
      print('\nAfter re-share:');
      print('sharedAt (unchanged) : ${updated.sharedAt}');
      print('autoShare            : ${updated.isAutoShareEnabled}');
    }
  } on TdkException catch (e) {
    print('Failed to save consent record [${e.code}]: ${e.message}');
    if (e.originalMessage != null) {
      print('Original error: ${e.originalMessage}');
    }
  }
}
