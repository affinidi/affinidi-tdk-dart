import 'package:affinidi_tdk_vault_iota/affinidi_tdk_vault_iota.dart';
import 'package:ssi/ssi.dart';
import 'package:test/test.dart';
import 'package:uuid/uuid.dart';

// ── Helpers ───────────────────────────────────────────────────────────────────

Future<DidSigner> _buildSigner({
  KeyType keyType = KeyType.ed25519,
  SignatureScheme signatureScheme = SignatureScheme.ed25519,
}) async {
  final keyStore = InMemoryKeyStore();
  final wallet = PersistentWallet(keyStore);
  final keyPair = await wallet.generateKey(keyType: keyType);
  final didManager = DidKeyManager(wallet: wallet, store: InMemoryDidStore());
  await didManager.addVerificationMethod(keyPair.id);
  return didManager.getSigner(
    didManager.assertionMethod.first,
    signatureScheme: signatureScheme,
  );
}

Future<LdVcDataModelV1> _issueV1Vc({
  required DidSigner issuerSigner,
  required String holderDid,
}) async {
  final unsigned = VcDataModelV1(
    context: JsonLdContext.fromJson([
      dmV1ContextUrl,
      'https://w3id.org/security/data-integrity/v2',
    ]),
    id: Uri.parse('urn:uuid:${const Uuid().v4()}'),
    issuer: Issuer.uri(issuerSigner.did),
    type: {'VerifiableCredential'},
    issuanceDate: DateTime.now().toUtc(),
    credentialSubject: [
      CredentialSubject.fromJson({'id': holderDid}),
    ],
  );

  return LdVcDm1Suite().issue(
    unsignedData: unsigned,
    proofGenerator: DataIntegrityEddsaJcsGenerator(
      signer: issuerSigner,
      proofPurpose: ProofPurpose.assertionMethod,
    ),
  );
}

Future<LdVcDataModelV2> _issueV2Vc({
  required DidSigner issuerSigner,
  required String holderDid,
}) async {
  final unsigned = VcDataModelV2(
    context: JsonLdContext.fromJson([dmV2ContextUrl]),
    id: Uri.parse('urn:uuid:${const Uuid().v4()}'),
    issuer: Issuer.uri(issuerSigner.did),
    type: {'VerifiableCredential'},
    credentialSubject: [
      CredentialSubject.fromJson({'id': holderDid}),
    ],
  );

  return LdVcDm2Suite().issue(
    unsignedData: unsigned,
    proofGenerator: DataIntegrityEddsaJcsGenerator(
      signer: issuerSigner,
      proofPurpose: ProofPurpose.assertionMethod,
    ),
  );
}

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  // secp256k1 → Secp256k1Signature2019Generator → compatible with DM v1 VP context.
  // ed25519   → DataIntegrityEddsaJcsGenerator  → requires DM v2 context (includes data integrity).
  late DidSigner secp256k1Signer;
  late DidSigner ed25519Signer;
  late LdVcDataModelV1 vcV1;
  late LdVcDataModelV2 vcV2;

  setUpAll(() async {
    secp256k1Signer = await _buildSigner(
      keyType: KeyType.secp256k1,
      signatureScheme: SignatureScheme.ecdsa_secp256k1_sha256,
    );
    ed25519Signer = await _buildSigner();
    vcV1 = await _issueV1Vc(
      issuerSigner: ed25519Signer,
      holderDid: ed25519Signer.did,
    );
    vcV2 = await _issueV2Vc(
      issuerSigner: ed25519Signer,
      holderDid: ed25519Signer.did,
    );
  });

  const builder = VpBuilder();
  const nonce = 'test-nonce-abc';
  const domain = 'did:key:test-verifier';

  group('VpBuilder', () {
    group('when build is called', () {
      group('and credentials is empty', () {
        test('should throw TdkException with emptyCredentials type', () async {
          await expectLater(
            builder.build(
              signer: ed25519Signer,
              credentials: [],
              nonce: nonce,
              domain: domain,
            ),
            throwsA(
              isA<TdkException>().having(
                (e) => e.code,
                'code',
                TdkExceptionType.emptyCredentials.code,
              ),
            ),
          );
        });
      });

      group('and credentials are DM v1', () {
        late Map<String, dynamic> result;

        setUpAll(() async {
          result = await builder.build(
            signer: secp256k1Signer,
            credentials: [vcV1],
            nonce: nonce,
            domain: domain,
          );
        });

        test('should include the DM v1 context URL', () {
          final context = result['@context'] as List<dynamic>;
          expect(context, contains(dmV1ContextUrl));
        });

        test('should include VerifiablePresentation in type', () {
          final type = result['type'] as List<dynamic>;
          expect(type, contains('VerifiablePresentation'));
        });

        test('should include a proof', () {
          expect(result, contains('proof'));
          expect(result['proof'], isNotNull);
        });

        test('should include the credential in verifiableCredential', () {
          final vcs = result['verifiableCredential'] as List<dynamic>;
          expect(vcs, hasLength(1));
        });

        test('should produce a unique id on each call', () async {
          final second = await builder.build(
            signer: secp256k1Signer,
            credentials: [vcV1],
            nonce: nonce,
            domain: domain,
          );
          expect(result['id'], isNot(equals(second['id'])));
        });
      });

      group('and credentials are DM v2', () {
        late Map<String, dynamic> result;

        setUpAll(() async {
          result = await builder.build(
            signer: ed25519Signer,
            credentials: [vcV2],
            nonce: nonce,
            domain: domain,
          );
        });

        test('should include the DM v2 context URL', () {
          final context = result['@context'] as List<dynamic>;
          expect(context, contains(dmV2ContextUrl));
        });

        test('should include VerifiablePresentation in type', () {
          final type = result['type'] as List<dynamic>;
          expect(type, contains('VerifiablePresentation'));
        });

        test('should include a proof', () {
          expect(result, contains('proof'));
          expect(result['proof'], isNotNull);
        });

        test('should include the credential in verifiableCredential', () {
          final vcs = result['verifiableCredential'] as List<dynamic>;
          expect(vcs, hasLength(1));
        });

        test('should produce a unique id on each call', () async {
          final second = await builder.build(
            signer: ed25519Signer,
            credentials: [vcV2],
            nonce: nonce,
            domain: domain,
          );
          expect(result['id'], isNot(equals(second['id'])));
        });
      });

      group('and credentials are both DM v2 and DM v1', () {
        test('should produce a signed DM v2 VP containing both', () async {
          final result = await builder.build(
            signer: ed25519Signer,
            credentials: [vcV1, vcV2],
            nonce: nonce,
            domain: domain,
          );

          final context = result['@context'] as List<dynamic>;
          expect(context, contains(dmV2ContextUrl));
          expect(context, isNot(contains(dmV1ContextUrl)));
          expect(result['verifiableCredential'], hasLength(2));
          expect(result['proof'], isNotNull);
        });
      });
    });
  });
}
