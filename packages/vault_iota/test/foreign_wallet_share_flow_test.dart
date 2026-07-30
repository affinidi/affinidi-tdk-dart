/// Proves the package works with any OID4VP wallet, not just Affinidi's.
///
/// The holder wallet is built with non-Affinidi crypto libraries:
///   * Ed25519   -> `cryptography` package
///   * secp256k1 -> `pointycastle` package
///   * P-256     -> `pointycastle` package
///
/// For each wallet the test checks three things:
///   1. The full share flow completes and the VP is signed by the foreign key.
///   2. The signature is genuinely valid (verified independently, fails loudly).
///   3. The response follows the OID4VP standard so any verifier can read it.
library;

import 'dart:convert';

import 'package:affinidi_tdk_test_utilities/affinidi_tdk_test_utilities.dart';
import 'package:affinidi_tdk_vault_iota/affinidi_tdk_vault_iota.dart';
import 'package:affinidi_tdk_vault_iota/src/models/share_requirements.dart';
import 'package:dio/dio.dart';
import 'package:ssi/ssi.dart';
import 'package:test/test.dart';
import 'package:uuid/uuid.dart';

import 'fixtures/third_party_wallet_fixtures.dart';

// ── Constants ─────────────────────────────────────────────────────────────────

const _acceptUri = 'https://verifier.example.com/accept';
const _rejectUri = 'https://verifier.example.com/reject';
const _nonce = 'oid4vp-nonce-abc';
const _clientId = 'did:key:z6MkverifierXYZ';
const _state = 'share-state-123';
const _definitionId = 'pd-third-party-wallet-test';
const _descriptorId = 'desc-vc-1';

final _shareRequest = const PexShareRequest(
  request: IotaRequest(
    responseType: 'vp_token',
    responseMode: 'direct_post',
    acceptResponseUri: _acceptUri,
    rejectResponseUri: _rejectUri,
    state: _state,
    nonce: _nonce,
    clientId: _clientId,
  ),
  presentationDefinition: {
    'id': _definitionId,
    'input_descriptors': [
      {'id': _descriptorId},
    ],
  },
  jwtAssertion: 'test-jwt',
);

// ── VC issuer helper ──────────────────────────────────────────────────────────

/// Issues a signed VC for [holderDid].
///
/// The issuer doesn't matter to the claim, only the holder wallet must be
/// foreign. [useV2] picks the data model: secp256k1 needs DM v1, Ed25519 and
/// P-256 need DM v2.
Future<ParsedVerifiableCredential<dynamic>> _issueVc({
  required String holderDid,
  required bool useV2,
}) async {
  final ks = InMemoryKeyStore();
  final wallet = PersistentWallet(ks);

  if (useV2) {
    final issuerKp = await wallet.generateKey(keyType: KeyType.ed25519);
    final issuerDoc = DidKey.generateDocument(issuerKp.publicKey);
    final issuerSigner = DidSigner(
      did: issuerDoc.id,
      didKeyId: issuerDoc.verificationMethod.first.id,
      keyPair: issuerKp,
      signatureScheme: SignatureScheme.ed25519,
    );
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

  // DM v1 needs a secp256k1 issuer and the Secp256k1Signature2019 suite.
  final issuerKp = await wallet.generateKey(keyType: KeyType.secp256k1);
  final issuerDoc = DidKey.generateDocument(issuerKp.publicKey);
  final issuerSigner = DidSigner(
    did: issuerDoc.id,
    didKeyId: issuerDoc.verificationMethod.first.id,
    keyPair: issuerKp,
    signatureScheme: SignatureScheme.ecdsa_secp256k1_sha256,
  );
  final unsigned = VcDataModelV1(
    context: JsonLdContext.fromJson([dmV1ContextUrl]),
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
    proofGenerator: Secp256k1Signature2019Generator(
      signer: issuerSigner,
      proofPurpose: ProofPurpose.assertionMethod,
    ),
  );
}

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  group('Iota share flow with a non-Affinidi OID4VP wallet', () {
    for (final testCase in [
      (
        label: 'Ed25519 (cryptography package)',
        useV2: true,
        buildSigner: () async => buildThirdPartyEd25519Signer(),
      ),
      (
        label: 'secp256k1 (pointycastle package)',
        useV2: false,
        buildSigner: () async =>
            buildThirdPartyEcdsaSigner(keyType: KeyType.secp256k1),
      ),
      (
        label: 'P-256 (pointycastle package)',
        useV2: true,
        buildSigner: () async =>
            buildThirdPartyEcdsaSigner(keyType: KeyType.p256),
      ),
    ]) {
      group('when the wallet signs with ${testCase.label}', () {
        late RequestOptions capturedRequest;
        late String holderDid;

        setUpAll(() async {
          // Build the holder wallet with a third-party library, not Affinidi.
          final foreignSigner = await testCase.buildSigner();
          holderDid = foreignSigner.did;

          final vc = await _issueVc(
            holderDid: holderDid,
            useV2: testCase.useV2,
          );

          final dio = Dio();
          final adapter = DioAdapterFixtures.adapter(dio);
          adapter.mockRequestWithReply(
            url: _acceptUri,
            statusCode: 200,
            data: {'redirect_uri': 'https://verifier.example.com/done'},
            httpMethod: HttpMethod.post,
          );
          dio.interceptors.add(
            InterceptorsWrapper(
              onRequest: (opts, handler) {
                capturedRequest = opts;
                handler.next(opts);
              },
            ),
          );

          // Run the real share flow, signing with the foreign wallet.
          final service = IotaShareResponseService(
            signer: foreignSigner,
            dio: dio,
          );
          await service.submitShareResponse(
            shareRequest: _shareRequest,
            selectedCredentials: [vc],
            acceptResponseUri: _acceptUri,
          );
        });

        // ── Check 1: the foreign wallet did the work ──────────────────────

        test('a non-Affinidi wallet completes the share flow (POST sent)', () {
          expect(capturedRequest.path, equals(_acceptUri));
          expect(capturedRequest.method, equals('POST'));
        });

        test('the VP holder is the foreign wallet DID', () {
          final data = capturedRequest.data as Map<String, dynamic>;
          final vp =
              jsonDecode(data['vp_token'] as String) as Map<String, dynamic>;
          final holder = vp['holder'];
          final holderId = holder is Map ? holder['id'] : holder;
          expect(holderId, equals(holderDid));
        });

        // ── Check 2: the signature is genuinely valid ─────────────────────

        test(
          'the VP signature verifies independently of the signing path',
          () async {
            final data = capturedRequest.data as Map<String, dynamic>;
            final vpToken = data['vp_token'] as String;

            // Re-check the signature with ssi's verifier: it fetches the wallet's
            // public key and verifies the bytes itself. A bad signature fails here.
            final parsedVp = UniversalPresentationParser.parse(vpToken);
            final result = await UniversalPresentationVerifier(
              customVerifiers: [
                VpDomainChallengeVerifier(
                  domain: const [_clientId],
                  challenge: _nonce,
                ),
              ],
            ).verify(parsedVp);

            expect(
              result.isValid,
              isTrue,
              reason: 'VP failed verification: ${result.errors}',
            );
          },
        );

        test(
          'a tampered VP signature is rejected (verifier is not a no-op)',
          () async {
            final data = capturedRequest.data as Map<String, dynamic>;
            final vp =
                jsonDecode(data['vp_token'] as String) as Map<String, dynamic>;

            // Flip the last byte of proofValue/jws to corrupt the signature.
            final proof = Map<String, dynamic>.from(vp['proof'] as Map);
            final proofValueKey = proof.containsKey('proofValue')
                ? 'proofValue'
                : 'jws';
            final original = proof[proofValueKey] as String;
            proof[proofValueKey] =
                '${original.substring(0, original.length - 1)}X';

            final tamperedVp = jsonEncode({...vp, 'proof': proof});
            final parsedTampered = UniversalPresentationParser.parse(
              tamperedVp,
            );
            final result = await UniversalPresentationVerifier().verify(
              parsedTampered,
            );

            expect(
              result.isValid,
              isFalse,
              reason: 'Verifier accepted a tampered signature — it is a no-op',
            );
          },
        );

        // ── Check 3: the response follows the OID4VP standard ──────────────

        test(
          'response carries the verifier-supplied state (replay binding)',
          () {
            final data = capturedRequest.data as Map<String, dynamic>;
            expect(data['state'], equals(_state));
          },
        );

        test('VP proof challenge equals the OID4VP nonce', () {
          final data = capturedRequest.data as Map<String, dynamic>;
          final vp =
              jsonDecode(data['vp_token'] as String) as Map<String, dynamic>;
          final proof = vp['proof'] as Map<String, dynamic>;
          expect(proof['challenge'], equals(_nonce));
        });

        test('VP proof domain contains the verifier clientId', () {
          final data = capturedRequest.data as Map<String, dynamic>;
          final vp =
              jsonDecode(data['vp_token'] as String) as Map<String, dynamic>;
          final proof = vp['proof'] as Map<String, dynamic>;
          final domain = proof['domain'];
          final domainValues = domain is List ? domain : [domain];
          expect(domainValues, contains(_clientId));
        });

        test('presentation_submission echoes the verifier definition_id', () {
          final data = capturedRequest.data as Map<String, dynamic>;
          final submission =
              jsonDecode(data['presentation_submission'] as String)
                  as Map<String, dynamic>;
          expect(submission['definition_id'], equals(_definitionId));
        });

        test('presentation_submission descriptor_map is OID4VP-shaped', () {
          final data = capturedRequest.data as Map<String, dynamic>;
          final submission =
              jsonDecode(data['presentation_submission'] as String)
                  as Map<String, dynamic>;
          final descriptorMap = submission['descriptor_map'] as List;

          expect(descriptorMap, isNotEmpty);
          final entry = descriptorMap.first as Map<String, dynamic>;
          expect(entry['id'], equals(_descriptorId));
          expect(entry['path'], isA<String>());
          expect(entry['path'], startsWith(r'$'));
          expect(entry['format'], isA<String>());
        });
      });
    }
  });
}
