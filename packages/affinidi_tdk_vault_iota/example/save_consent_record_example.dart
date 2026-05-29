import 'package:affinidi_tdk_cryptography/affinidi_tdk_cryptography.dart';
import 'package:affinidi_tdk_vault_iota/affinidi_tdk_vault_iota.dart';
import 'package:ssi/ssi.dart'
    show
        CredentialSubject,
        Issuer,
        JsonLdContext,
        ParsedVerifiableCredential,
        VcDataModelV1,
        VerifiableCredential;

/// A minimal in-memory [ConsentStorage] for demonstration purposes.
///
/// In a real application replace this with your own persistence backend.
class InMemoryConsentStorage implements ConsentStorage {
  final Map<String, IotaConsentRecord> _records = {};

  @override
  Future<void> saveOrUpdate(IotaConsentRecord record) async {
    _records[record.hash] = record;
  }

  @override
  Future<IotaConsentRecord?> findByRequestHash(String requestHash) async {
    for (final record in _records.values) {
      if (record.requestHash == requestHash) return record;
    }
    return null;
  }
}

/// A stub [IotaShareResponseServiceInterface] for demonstration purposes.
///
/// In a real application, construct [IotaShareResponseService] with a real
/// `CallbackApi` and `DidSigner` from your wallet integration.
class _StubShareResponseService implements IotaShareResponseServiceInterface {
  @override
  Future<Uri?> submitShareResponse({
    required String state,
    required String nonce,
    required String clientId,
    required String definitionId,
    required List<
      ({
        PDDescriptor descriptor,
        ParsedVerifiableCredential<dynamic> credential,
      })
    >
    selectedCredentials,
    required VpDataModel dataModel,
  }) => throw UnimplementedError(
    'Provide a real IotaShareResponseService for VP submission',
  );

  @override
  Future<Uri?> rejectShareResponse({required String state}) =>
      throw UnimplementedError(
        'Provide a real IotaShareResponseService for VP rejection',
      );
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

  final store = InMemoryConsentStorage();

  final service = IotaConsentRecordService(
    store: store,
    cryptography: cryptography,
    shareResponseService: _StubShareResponseService(),
  );

  // Values that would normally come from the validated OID4VP request and the
  // wallet / profile in use.
  const clientId = 'did:key:z6MkVerifier123';
  const holderVaultId = 'did:key:z6MkHolder456';
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

  final sharedVcs = <VerifiableCredential>[
    VcDataModelV1(
      context: JsonLdContext.fromJson([
        'https://www.w3.org/2018/credentials/v1',
      ]),
      id: Uri.parse('vc:uuid:vc-1'),
      type: {'VerifiableCredential', 'EmailV1VC'},
      issuer: Issuer(id: Uri.parse('did:key:z6MkIssuer')),
      credentialSubject: [
        CredentialSubject.fromJson({'email': 'user@example.com'}),
      ],
      issuanceDate: DateTime.utc(2024, 1, 1),
    ),
    VcDataModelV1(
      context: JsonLdContext.fromJson([
        'https://www.w3.org/2018/credentials/v1',
      ]),
      id: Uri.parse('vc:uuid:vc-2'),
      type: {'VerifiableCredential', 'PhoneNumberV1VC'},
      issuer: Issuer(id: Uri.parse('did:key:z6MkIssuer')),
      credentialSubject: [
        CredentialSubject.fromJson({'phoneNumber': '+1 555 000 0000'}),
      ],
      issuanceDate: DateTime.utc(2024, 1, 1),
    ),
  ];

  try {
    await service.saveConsentRecord(
      requestHash: requestHash,
      clientId: clientId,
      verifierMetadata: verifierMetadata,
      profileId: profileId,
      profileName: profileName,
      vaultId: holderVaultId,
      sharedVcs: sharedVcs,
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
    final saved = await store.findByRequestHash(requestHash);
    if (saved != null) {
      print('requestHash : ${saved.requestHash}');
      print('clientId    : ${saved.clientId}');
      print('profileName : ${saved.profileName}');
      print('sharedAt    : ${saved.sharedAt}');
      print('vcTypes     : ${saved.claimedVcTypesCsv}');
    }

    // Saving again with the same VCs produces the same hash and overwrites the
    // record; [sharedAt] is updated to reflect the most recent share time.
    await service.saveConsentRecord(
      requestHash: requestHash,
      clientId: clientId,
      verifierMetadata: verifierMetadata,
      profileId: profileId,
      profileName: profileName,
      vaultId: holderVaultId,
      sharedVcs: sharedVcs,
      claimedVcTypesCsv: 'EmailV1VC,PhoneNumberV1VC',
      isAutoShareEnabled: true,
    );

    final updated = await store.findByRequestHash(requestHash);
    if (updated != null) {
      print('\nAfter re-share:');
      print('sharedAt (updated)   : ${updated.sharedAt}');
      print('autoShare            : ${updated.isAutoShareEnabled}');
    }
  } on TdkException catch (e) {
    print('Failed to save consent record [${e.code}]: ${e.message}');
    if (e.originalMessage != null) {
      print('Original error: ${e.originalMessage}');
    }
  }
}
