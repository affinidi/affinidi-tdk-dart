import 'dart:convert' show jsonEncode;

import 'package:affinidi_tdk_cryptography/affinidi_tdk_cryptography.dart';
import 'package:affinidi_tdk_vault_iota/affinidi_tdk_vault_iota.dart';
import 'package:ssi/ssi.dart'
    show
        CredentialSubject,
        DidSigner,
        Issuer,
        JsonLdContext,
        ParsedVerifiableCredential,
        VcDataModelV1,
        VerifiableCredential;

/// A database-backed [ConsentStorage] implementation.
///
/// Replace the in-memory map with your real database calls (e.g. sqflite,
/// Drift, Isar, or a remote API).
class DatabaseConsentStorage implements ConsentStorage {
  // Simulates a database table keyed by IotaConsentRecord.hash.
  final Map<String, IotaConsentRecord> _db = {};

  @override
  Future<void> saveOrUpdate(IotaConsentRecord record) async {
    // INSERT OR REPLACE INTO consent_records WHERE hash = record.hash
    _db[record.hash] = record;
  }

  @override
  Future<IotaConsentRecord?> findByRequestHash(String requestHash) async {
    // SELECT * FROM consent_records WHERE request_hash = ? ORDER BY shared_at DESC LIMIT 1
    final matches =
        _db.values.where((r) => r.requestHash == requestHash).toList()
          ..sort((a, b) => b.sharedAt.compareTo(a.sharedAt));
    return matches.firstOrNull;
  }

  @override
  Future<List<IotaConsentRecord>> findAllByRequestHash(
    String requestHash,
  ) async {
    // SELECT * FROM consent_records WHERE request_hash = ?
    return _db.values.where((r) => r.requestHash == requestHash).toList();
  }
}

/// A stub [IotaShareResponseServiceInterface] for demonstration purposes.
///
/// In a real application, construct [IotaShareResponseService] with a real
/// [DidSigner] from your wallet integration.
class _StubShareResponseService implements IotaShareResponseServiceInterface {
  @override
  Future<Uri?> submitShareResponse({
    required Oid4vpShareRequest shareRequest,
    required List<ParsedVerifiableCredential<dynamic>> selectedCredentials,
    required String acceptResponseUri,
  }) async {
    print('VP submitted to $acceptResponseUri');
    return null;
  }

  @override
  Future<Uri?> rejectShareResponse({
    required Oid4vpShareRequest shareRequest,
    required String rejectResponseUri,
  }) async {
    print('VP rejected.');
    return null;
  }
}

/// This example demonstrates how to:
/// 1. Persist a consent record after a successful Iota OID4VP share.
/// 2. Use [IotaConsentRecordService.tryAutomaticConsent] to automatically
///    re-submit a VP for a previously approved verifier.
Future<void> main() async {
  final cryptography = CryptographyService();
  final store = DatabaseConsentStorage();
  final shareResponseService = _StubShareResponseService();

  final service = IotaConsentRecordService(
    store: store,
    cryptography: cryptography,
    shareResponseService: shareResponseService,
  );

  // Values that would normally come from the validated OID4VP request and the
  // wallet / profile in use.
  const clientId = 'did:key:z6MkVerifier123';
  const holderVaultId = 'did:key:z6MkHolder456';
  const profileId = 'profile-abc';
  const profileName = 'Personal';

  // The Presentation Definition from the validated share request.
  const presentationDefinition = <String, dynamic>{
    'id': 'pd-email-phone',
    'input_descriptors': [
      {'id': 'email_vc'},
      {'id': 'phone_vc'},
    ],
  };

  // Compute the request fingerprint: sha1("$clientId|<PD JSON>").
  // Including the serialised query ensures two different PDs from the same
  // verifier produce different hashes, preventing auto-share from firing on a
  // request shape that was never approved.
  final requestHash = cryptography.createHash(
    hashSource: '$clientId|${jsonEncode(presentationDefinition)}',
  );

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
    // --- Save a consent record after the user approves a share ---

    await service.saveConsentRecord(
      requestHash: requestHash,
      clientId: clientId,
      verifierMetadata: verifierMetadata,
      profileId: profileId,
      profileName: profileName,
      vaultId: holderVaultId,
      sharedVcs: sharedVcs,
      claimedVcTypesCsv: 'EmailV1VC,PhoneNumberV1VC',
      isAutoShareEnabled: true, // user opted in to auto-share for this verifier
      historySharedData: {
        'Email address': 'user@example.com',
        'Phone number': '+1 555 000 0000',
      },
    );

    print('Consent record saved.');
    final saved = await store.findByRequestHash(requestHash);
    if (saved != null) {
      print('clientId    : ${saved.clientId}');
      print('profileName : ${saved.profileName}');
      print('autoShare   : ${saved.isAutoShareEnabled}');
    }

    // --- Try automatic consent on the next request from the same verifier ---
    //
    // On a subsequent share request from the same verifier with the same
    // Presentation Definition, call tryAutomaticConsent before showing any UI.
    // If the user previously enabled auto-share for this verifier+PD
    // combination, the VP is submitted automatically without prompting.

    // Simulate loading vault credentials for the matcher.
    final cryptography2 = CryptographyService();
    final service2 = ShareFlowService(cryptography: cryptography2);
    final nextShareRequest = await service2.validateOid4vpRequest(
      Uri.parse('openid4vp://authorize?request=<your-request-jwt>'),
      walletDid: holderVaultId,
    );

    final matcher = CredentialMatcherService();
    final matchResult = await matcher.match(nextShareRequest, sharedVcs);

    final autoResult = await service.tryAutomaticConsent(
      shareRequest: nextShareRequest,
      matchedCredentials: matchResult,
      verifierMetadata: verifierMetadata,
      requestHash: requestHash,
      vaultId: holderVaultId,
    );

    switch (autoResult) {
      case AutoConsentApproved(:final redirectUri):
        print('Auto-consent approved. Redirect: ${redirectUri ?? '(none)'}');
      case AutoConsentDeclined():
        print('Auto-consent declined — show the share approval UI.');
    }
  } on TdkException catch (e) {
    print('Error [${e.code}]: ${e.message}');
  }
}
