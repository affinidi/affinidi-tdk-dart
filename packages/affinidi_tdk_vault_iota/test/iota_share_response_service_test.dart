import 'dart:convert';

import 'package:affinidi_tdk_test_utilities/affinidi_tdk_test_utilities.dart';
import 'package:affinidi_tdk_vault_iota/affinidi_tdk_vault_iota.dart';
import 'package:affinidi_tdk_vault_iota/src/models/share_requirements.dart';
import 'package:dcql/dcql.dart';
import 'package:dio/dio.dart';
import 'package:ssi/ssi.dart';
import 'package:test/test.dart';

import 'fixtures/iota_consent_record_fixtures.dart';

// ── Fakes ─────────────────────────────────────────────────────────────────────

class _FakeVpBuilder implements VpBuilderInterface {
  final Map<String, dynamic> result;

  const _FakeVpBuilder(this.result);

  @override
  Future<Map<String, dynamic>> build({
    required DidSigner signer,
    required List<ParsedVerifiableCredential<dynamic>> credentials,
    required String nonce,
    required String domain,
  }) async => result;
}

// ── Test data ─────────────────────────────────────────────────────────────────

const _redirectUri = 'https://verifier.example.com/done';
const _acceptUri = 'https://verifier.example.com/accept';
const _rejectUri = 'https://verifier.example.com/reject';
const _dcqlAcceptUri = 'https://dcql-verifier.example.com/accept';
const _dcqlRejectUri = 'https://dcql-verifier.example.com/reject';

final _fakeVp = <String, dynamic>{
  'type': 'VerifiablePresentation',
  'proof': <String, dynamic>{},
};

final _fakeVC = IotaConsentRecordFixtures.makeParsedVc();

// Reuses the fixture so URIs, state, and nonce are consistent.
final _pexShareRequest = IotaConsentRecordFixtures.shareRequest;

final _dcqlShareRequest = DcqlShareRequest(
  request: const IotaRequest(
    responseType: 'vp_token',
    responseMode: 'direct_post',
    acceptResponseUri: _dcqlAcceptUri,
    rejectResponseUri: _dcqlRejectUri,
    state: 'dcql-state',
    nonce: 'dcql-nonce',
    clientId: 'did:key:dcql-verifier',
  ),
  dcqlQuery: DcqlCredentialQuery(
    credentials: [DcqlCredential(id: 'q1', format: CredentialFormat.ldpVc)],
  ),
  jwtAssertion: 'dcql-jwt',
);

// ── Helpers ───────────────────────────────────────────────────────────────────

Future<DidSigner> _buildTestSigner() async {
  final keyStore = InMemoryKeyStore();
  final wallet = PersistentWallet(keyStore);
  final keyPair = await wallet.generateKey(keyType: KeyType.ed25519);
  final didManager = DidKeyManager(wallet: wallet, store: InMemoryDidStore());
  await didManager.addVerificationMethod(keyPair.id);
  return didManager.getSigner(
    didManager.assertionMethod.first,
    signatureScheme: SignatureScheme.ed25519,
  );
}

void main() {
  late Dio dio;
  late DioAdapter dioAdapter;
  late DidSigner signer;

  setUpAll(() async {
    signer = await _buildTestSigner();
  });

  setUp(() {
    dio = Dio();
    dioAdapter = DioAdapterFixtures.adapter(dio);
  });

  tearDown(() => dioAdapter.reset());

  IotaShareResponseService buildService() => IotaShareResponseService(
    signer: signer,
    dio: dio,
    vpBuilder: _FakeVpBuilder(_fakeVp),
  );

  // ── PEX submit ──────────────────────────────────────────────────────────────

  group('submitShareResponse (PEX)', () {
    group('when the POST succeeds', () {
      test('POSTs to acceptResponseUri with state, vp_token, and '
          'presentation_submission', () async {
        RequestOptions? captured;
        dio.interceptors.add(
          InterceptorsWrapper(
            onRequest: (opts, handler) {
              captured = opts;
              handler.next(opts);
            },
          ),
        );
        dioAdapter.mockRequestWithReply(
          url: _acceptUri,
          statusCode: 200,
          data: <String, dynamic>{},
          httpMethod: HttpMethod.post,
        );

        await buildService().submitShareResponse(
          shareRequest: _pexShareRequest,
          selectedCredentials: [_fakeVC],
          acceptResponseUri: _acceptUri,
        );

        expect(captured, isNotNull);
        expect(captured!.path, equals(_acceptUri));
        final data = captured!.data as Map<String, dynamic>;
        expect(data['state'], equals(_pexShareRequest.request.state));
        expect(data['vp_token'], isNotNull);
        expect(data['presentation_submission'], isNotNull);
      });

      test('returns the redirect URI from the response', () async {
        dioAdapter.mockRequestWithReply(
          url: _acceptUri,
          statusCode: 200,
          data: {'redirect_uri': _redirectUri},
          httpMethod: HttpMethod.post,
        );

        final result = await buildService().submitShareResponse(
          shareRequest: _pexShareRequest,
          selectedCredentials: [_fakeVC],
          acceptResponseUri: _acceptUri,
        );

        expect(result, equals(Uri.parse(_redirectUri)));
      });

      test('returns null when the response has no redirect_uri', () async {
        dioAdapter.mockRequestWithReply(
          url: _acceptUri,
          statusCode: 200,
          data: <String, dynamic>{},
          httpMethod: HttpMethod.post,
        );

        final result = await buildService().submitShareResponse(
          shareRequest: _pexShareRequest,
          selectedCredentials: [_fakeVC],
          acceptResponseUri: _acceptUri,
        );

        expect(result, isNull);
      });

      test('presentation_submission contains definitionId from PD', () async {
        RequestOptions? captured;
        dio.interceptors.add(
          InterceptorsWrapper(
            onRequest: (opts, handler) {
              captured = opts;
              handler.next(opts);
            },
          ),
        );
        dioAdapter.mockRequestWithReply(
          url: _acceptUri,
          statusCode: 200,
          data: <String, dynamic>{},
          httpMethod: HttpMethod.post,
        );

        await buildService().submitShareResponse(
          shareRequest: _pexShareRequest,
          selectedCredentials: [_fakeVC],
          acceptResponseUri: _acceptUri,
        );

        final data = captured!.data as Map<String, dynamic>;
        final submission =
            jsonDecode(data['presentation_submission'] as String)
                as Map<String, dynamic>;
        expect(submission['definition_id'], equals('def-1'));
      });
    });

    group('when the POST throws an exception', () {
      test('throws TdkException with submissionFailed code', () async {
        dioAdapter.mockRequestWithException(
          url: _acceptUri,
          statusCode: 500,
          httpMethod: HttpMethod.post,
        );

        await expectLater(
          buildService().submitShareResponse(
            shareRequest: _pexShareRequest,
            selectedCredentials: [_fakeVC],
            acceptResponseUri: _acceptUri,
          ),
          throwsA(
            isA<TdkException>().having(
              (e) => e.code,
              'code',
              equals(TdkExceptionType.submissionFailed.code),
            ),
          ),
        );
      });
    });
  });

  // ── DCQL submit ─────────────────────────────────────────────────────────────

  group('submitShareResponse (DCQL)', () {
    group('when the POST succeeds', () {
      test('POSTs to acceptResponseUri with state and vp_token only', () async {
        RequestOptions? captured;
        dio.interceptors.add(
          InterceptorsWrapper(
            onRequest: (opts, handler) {
              captured = opts;
              handler.next(opts);
            },
          ),
        );
        dioAdapter.mockRequestWithReply(
          url: _dcqlAcceptUri,
          statusCode: 200,
          data: <String, dynamic>{},
          httpMethod: HttpMethod.post,
        );

        await buildService().submitShareResponse(
          shareRequest: _dcqlShareRequest,
          selectedCredentials: [_fakeVC],
          acceptResponseUri: _dcqlAcceptUri,
        );

        expect(captured, isNotNull);
        final data = captured!.data as Map<String, dynamic>;
        expect(data['state'], equals(_dcqlShareRequest.request.state));
        expect(data['vp_token'], isNotNull);
        expect(data.containsKey('presentation_submission'), isFalse);

        final vpToken = jsonDecode(data['vp_token'] as String) as Map;
        expect(vpToken.keys, equals({'q1'}));
        // multiple omitted/false → array with exactly one Presentation.
        expect(vpToken['q1'], isA<List>());
        expect((vpToken['q1'] as List).length, equals(1));
        expect((vpToken['q1'] as List).first, isA<Map<String, dynamic>>());
      });

      test('returns one Presentation per matching Credential when '
          'multiple is true', () async {
        final multipleRequest = DcqlShareRequest(
          request: const IotaRequest(
            responseType: 'vp_token',
            responseMode: 'direct_post',
            acceptResponseUri: _dcqlAcceptUri,
            rejectResponseUri: _dcqlRejectUri,
            state: 'dcql-state',
            nonce: 'dcql-nonce',
            clientId: 'did:key:dcql-verifier',
          ),
          dcqlQuery: DcqlCredentialQuery(
            credentials: [
              DcqlCredential(
                id: 'q1',
                format: CredentialFormat.ldpVc,
                multiple: true,
              ),
            ],
          ),
          jwtAssertion: 'dcql-jwt',
        );

        RequestOptions? captured;
        dio.interceptors.add(
          InterceptorsWrapper(
            onRequest: (opts, handler) {
              captured = opts;
              handler.next(opts);
            },
          ),
        );
        dioAdapter.mockRequestWithReply(
          url: _dcqlAcceptUri,
          statusCode: 200,
          data: <String, dynamic>{},
          httpMethod: HttpMethod.post,
        );

        await buildService().submitShareResponse(
          shareRequest: multipleRequest,
          selectedCredentials: [_fakeVC, _fakeVC],
          acceptResponseUri: _dcqlAcceptUri,
        );

        final data = captured!.data as Map<String, dynamic>;
        final vpToken = jsonDecode(data['vp_token'] as String) as Map;
        expect(vpToken.keys, equals({'q1'}));
        expect((vpToken['q1'] as List).length, equals(2));
      });

      test('returns the redirect URI from the response', () async {
        dioAdapter.mockRequestWithReply(
          url: _dcqlAcceptUri,
          statusCode: 200,
          data: {'redirect_uri': _redirectUri},
          httpMethod: HttpMethod.post,
        );

        final result = await buildService().submitShareResponse(
          shareRequest: _dcqlShareRequest,
          selectedCredentials: [_fakeVC],
          acceptResponseUri: _dcqlAcceptUri,
        );

        expect(result, equals(Uri.parse(_redirectUri)));
      });
    });

    group('when the POST throws an exception', () {
      test('throws TdkException with submissionFailed code', () async {
        dioAdapter.mockRequestWithException(
          url: _dcqlAcceptUri,
          statusCode: 500,
          httpMethod: HttpMethod.post,
        );

        await expectLater(
          buildService().submitShareResponse(
            shareRequest: _dcqlShareRequest,
            selectedCredentials: [_fakeVC],
            acceptResponseUri: _dcqlAcceptUri,
          ),
          throwsA(
            isA<TdkException>().having(
              (e) => e.code,
              'code',
              equals(TdkExceptionType.submissionFailed.code),
            ),
          ),
        );
      });
    });

    group('when require_cryptographic_holder_binding is false', () {
      final noBindingRequest = DcqlShareRequest(
        request: const IotaRequest(
          responseType: 'vp_token',
          responseMode: 'direct_post',
          acceptResponseUri: _dcqlAcceptUri,
          rejectResponseUri: _dcqlRejectUri,
          state: 'dcql-state',
          nonce: 'dcql-nonce',
          clientId: 'did:key:dcql-verifier',
        ),
        dcqlQuery: DcqlCredentialQuery(
          credentials: [
            DcqlCredential(
              id: 'q1',
              format: CredentialFormat.ldpVc,
              requireCryptographicHolderBinding: false,
            ),
          ],
        ),
        jwtAssertion: 'dcql-jwt',
      );

      test('returns raw VC JSON entry inside a single-item array', () async {
        RequestOptions? captured;
        dio.interceptors.add(
          InterceptorsWrapper(
            onRequest: (opts, handler) {
              captured = opts;
              handler.next(opts);
            },
          ),
        );
        dioAdapter.mockRequestWithReply(
          url: _dcqlAcceptUri,
          statusCode: 200,
          data: <String, dynamic>{},
          httpMethod: HttpMethod.post,
        );

        await buildService().submitShareResponse(
          shareRequest: noBindingRequest,
          selectedCredentials: [_fakeVC],
          acceptResponseUri: _dcqlAcceptUri,
        );

        final data = captured!.data as Map<String, dynamic>;
        final vpToken = jsonDecode(data['vp_token'] as String) as Map;
        // requireCryptographicHolderBinding: false, multiple: false → array of one raw VC.
        final entries = vpToken['q1'] as List;
        expect(entries.length, equals(1));
        final entry = entries.first as Map;
        // The VP builder must not have been called — entry is the raw VC JSON.
        expect(entry, isNot(equals(_fakeVp)));
        expect(entry['id'], equals('vc-1'));
      });

      test('returns a signed VP when requireCryptographicHolderBinding '
          'is true', () async {
        final bindingRequest = DcqlShareRequest(
          request: const IotaRequest(
            responseType: 'vp_token',
            responseMode: 'direct_post',
            acceptResponseUri: _dcqlAcceptUri,
            rejectResponseUri: _dcqlRejectUri,
            state: 'dcql-state',
            nonce: 'dcql-nonce',
            clientId: 'did:key:dcql-verifier',
          ),
          dcqlQuery: DcqlCredentialQuery(
            credentials: [
              DcqlCredential(
                id: 'q1',
                format: CredentialFormat.ldpVc,
                requireCryptographicHolderBinding: true,
              ),
            ],
          ),
          jwtAssertion: 'dcql-jwt',
        );

        RequestOptions? captured;
        dio.interceptors.add(
          InterceptorsWrapper(
            onRequest: (opts, handler) {
              captured = opts;
              handler.next(opts);
            },
          ),
        );
        dioAdapter.mockRequestWithReply(
          url: _dcqlAcceptUri,
          statusCode: 200,
          data: <String, dynamic>{},
          httpMethod: HttpMethod.post,
        );

        await buildService().submitShareResponse(
          shareRequest: bindingRequest,
          selectedCredentials: [_fakeVC],
          acceptResponseUri: _dcqlAcceptUri,
        );

        final data = captured!.data as Map<String, dynamic>;
        final vpToken = jsonDecode(data['vp_token'] as String) as Map;
        // requireCryptographicHolderBinding: true, multiple: false → array of one signed VP.
        final entries = vpToken['q1'] as List;
        expect(entries.length, equals(1));
        final entry = entries.first as Map;
        // VP builder was invoked — entry must equal the fake VP.
        expect(entry, equals(_fakeVp));
      });

      test(
        'omits an unmatched optional credential query from vp_token',
        () async {
          final optionalRequest = DcqlShareRequest(
            request: const IotaRequest(
              responseType: 'vp_token',
              responseMode: 'direct_post',
              acceptResponseUri: _dcqlAcceptUri,
              rejectResponseUri: _dcqlRejectUri,
              state: 'dcql-state',
              nonce: 'dcql-nonce',
              clientId: 'did:key:dcql-verifier',
            ),
            dcqlQuery: DcqlCredentialQuery(
              credentials: [
                DcqlCredential(id: 'q-match', format: CredentialFormat.ldpVc),
                // Uses a different format, so _fakeVC (ldpVc) won't match.
                DcqlCredential(
                  id: 'q-optional-no-match',
                  format: CredentialFormat.msoMdoc,
                ),
              ],
              // q-optional-no-match is in a non-required set so the guard
              // must not throw when it has no match.
              credentialSets: [
                DcqlCredentialSet(
                  required: true,
                  options: [
                    ['q-match'],
                  ],
                ),
                DcqlCredentialSet(
                  required: false,
                  options: [
                    ['q-optional-no-match'],
                  ],
                ),
              ],
            ),
            jwtAssertion: 'dcql-jwt',
          );

          RequestOptions? captured;
          dio.interceptors.add(
            InterceptorsWrapper(
              onRequest: (opts, handler) {
                captured = opts;
                handler.next(opts);
              },
            ),
          );
          dioAdapter.mockRequestWithReply(
            url: _dcqlAcceptUri,
            statusCode: 200,
            data: <String, dynamic>{},
            httpMethod: HttpMethod.post,
          );

          await buildService().submitShareResponse(
            shareRequest: optionalRequest,
            selectedCredentials: [_fakeVC],
            acceptResponseUri: _dcqlAcceptUri,
          );

          final data = captured!.data as Map<String, dynamic>;
          final vpToken = jsonDecode(data['vp_token'] as String) as Map;
          expect(vpToken.containsKey('q-match'), isTrue);
          expect(vpToken.containsKey('q-optional-no-match'), isFalse);
        },
      );
    });

    group('VC-to-query assignment (each VC populates exactly one slot)', () {
      // Two generic ldpVc queries — any ldpVc VC matches both.
      DcqlShareRequest twoQueryRequest() => DcqlShareRequest(
        request: const IotaRequest(
          responseType: 'vp_token',
          responseMode: 'direct_post',
          acceptResponseUri: _dcqlAcceptUri,
          rejectResponseUri: _dcqlRejectUri,
          state: 'dcql-state',
          nonce: 'dcql-nonce',
          clientId: 'did:key:dcql-verifier',
        ),
        dcqlQuery: DcqlCredentialQuery(
          credentials: [
            DcqlCredential(
              id: 'q1',
              format: CredentialFormat.ldpVc,
              requireCryptographicHolderBinding: false,
            ),
            DcqlCredential(
              id: 'q2',
              format: CredentialFormat.ldpVc,
              requireCryptographicHolderBinding: false,
            ),
          ],
          // q2 is optional so that submitting with only one VC (covering q1)
          // does not trigger the required-query guard.
          credentialSets: [
            DcqlCredentialSet(
              required: true,
              options: [
                ['q1'],
              ],
            ),
            DcqlCredentialSet(
              required: false,
              options: [
                ['q2'],
              ],
            ),
          ],
        ),
        jwtAssertion: 'dcql-jwt',
      );

      Future<Map> capturedVpToken({
        required DcqlShareRequest shareRequest,
        required List<ParsedVerifiableCredential<dynamic>> selectedCredentials,
      }) async {
        RequestOptions? captured;
        dio.interceptors.add(
          InterceptorsWrapper(
            onRequest: (opts, handler) {
              captured = opts;
              handler.next(opts);
            },
          ),
        );
        dioAdapter.mockRequestWithReply(
          url: _dcqlAcceptUri,
          statusCode: 200,
          data: <String, dynamic>{},
          httpMethod: HttpMethod.post,
        );

        await buildService().submitShareResponse(
          shareRequest: shareRequest,
          selectedCredentials: selectedCredentials,
          acceptResponseUri: _dcqlAcceptUri,
        );

        final data = captured!.data as Map<String, dynamic>;
        return jsonDecode(data['vp_token'] as String) as Map;
      }

      test(
        'a VC that matches two queries is only assigned to the first query',
        () async {
          // selectedCredentials contains a single VC that matches both q1 and q2.
          // It must only appear in q1; q2 must be omitted (no VC remains for it).
          final vpToken = await capturedVpToken(
            shareRequest: twoQueryRequest(),
            selectedCredentials: [_fakeVC],
          );

          expect(
            vpToken.keys,
            equals({'q1'}),
            reason: 'q2 should be omitted — the only VC was consumed by q1',
          );
        },
      );

      test(
        'two VCs are each assigned to their own query slot, not shared',
        () async {
          final vcA = IotaConsentRecordFixtures.makeParsedVc(id: 'vc-a');
          final vcB = IotaConsentRecordFixtures.makeParsedVc(id: 'vc-b');

          // Both VCs match both queries. With correct assignment:
          //   q1 → vcA (first in list, requireCryptographicHolderBinding: false
          //              so raw JSON is returned — id is 'vc-a')
          //   q2 → vcB (remainder — id is 'vc-b')
          final vpToken = await capturedVpToken(
            shareRequest: twoQueryRequest(),
            selectedCredentials: [vcA, vcB],
          );

          expect(vpToken.keys, containsAll(['q1', 'q2']));
          expect(((vpToken['q1'] as List).first as Map)['id'], equals('vc-a'));
          expect(((vpToken['q2'] as List).first as Map)['id'], equals('vc-b'));
        },
      );
    });

    group('when selected credentials do not cover required queries '
        '(incomplete_credential_selection)', () {
      test(
        'throws when no credential_sets and a required query has no match',
        () async {
          // Single required query (no credential_sets), but empty selection.
          await expectLater(
            buildService().submitShareResponse(
              shareRequest: _dcqlShareRequest, // has required q1
              selectedCredentials: const [],
              acceptResponseUri: _dcqlAcceptUri,
            ),
            throwsA(
              isA<TdkException>().having(
                (e) => e.code,
                'code',
                TdkExceptionType.incompleteCredentialSelection.code,
              ),
            ),
          );
        },
      );

      test(
        'throws when a required credential_set option cannot be satisfied',
        () async {
          final setsRequest = DcqlShareRequest(
            request: const IotaRequest(
              responseType: 'vp_token',
              responseMode: 'direct_post',
              acceptResponseUri: _dcqlAcceptUri,
              rejectResponseUri: _dcqlRejectUri,
              state: 'dcql-state',
              nonce: 'dcql-nonce',
              clientId: 'did:key:dcql-verifier',
            ),
            dcqlQuery: DcqlCredentialQuery(
              credentials: [
                // Uses msoMdoc — _fakeVC is ldpVc so it will not match.
                DcqlCredential(id: 'q-mdoc', format: CredentialFormat.msoMdoc),
              ],
              credentialSets: [
                DcqlCredentialSet(
                  required: true,
                  options: [
                    ['q-mdoc'],
                  ],
                ),
              ],
            ),
            jwtAssertion: 'dcql-jwt',
          );

          await expectLater(
            buildService().submitShareResponse(
              shareRequest: setsRequest,
              selectedCredentials: [_fakeVC], // ldpVc, does not satisfy q-mdoc
              acceptResponseUri: _dcqlAcceptUri,
            ),
            throwsA(
              isA<TdkException>().having(
                (e) => e.code,
                'code',
                TdkExceptionType.incompleteCredentialSelection.code,
              ),
            ),
          );
        },
      );
    });
  });

  // ── Reject ──────────────────────────────────────────────────────────────────

  group('rejectShareResponse', () {
    group('when the POST succeeds', () {
      test('POSTs state and access_denied to rejectResponseUri', () async {
        RequestOptions? captured;
        dio.interceptors.add(
          InterceptorsWrapper(
            onRequest: (opts, handler) {
              captured = opts;
              handler.next(opts);
            },
          ),
        );
        dioAdapter.mockRequestWithReply(
          url: _rejectUri,
          statusCode: 200,
          data: <String, dynamic>{},
          httpMethod: HttpMethod.post,
        );

        await buildService().rejectShareResponse(
          shareRequest: _pexShareRequest,
          rejectResponseUri: _rejectUri,
        );

        expect(captured, isNotNull);
        final data = captured!.data as Map<String, dynamic>;
        expect(data['state'], equals(_pexShareRequest.request.state));
        expect(data['error'], equals('access_denied'));
        expect(data.containsKey('vp_token'), isFalse);
        expect(data.containsKey('presentation_submission'), isFalse);
      });

      test('returns the redirect URI from the response', () async {
        dioAdapter.mockRequestWithReply(
          url: _rejectUri,
          statusCode: 200,
          data: {'redirect_uri': _redirectUri},
          httpMethod: HttpMethod.post,
        );

        final result = await buildService().rejectShareResponse(
          shareRequest: _pexShareRequest,
          rejectResponseUri: _rejectUri,
        );

        expect(result, equals(Uri.parse(_redirectUri)));
      });

      test('returns null when response has no redirect_uri', () async {
        dioAdapter.mockRequestWithReply(
          url: _rejectUri,
          statusCode: 200,
          data: <String, dynamic>{},
          httpMethod: HttpMethod.post,
        );

        final result = await buildService().rejectShareResponse(
          shareRequest: _pexShareRequest,
          rejectResponseUri: _rejectUri,
        );

        expect(result, isNull);
      });
    });

    group('when the POST throws an exception', () {
      test('throws TdkException with submissionFailed code', () async {
        dioAdapter.mockRequestWithException(
          url: _rejectUri,
          statusCode: 500,
          httpMethod: HttpMethod.post,
        );

        await expectLater(
          buildService().rejectShareResponse(
            shareRequest: _pexShareRequest,
            rejectResponseUri: _rejectUri,
          ),
          throwsA(
            isA<TdkException>().having(
              (e) => e.code,
              'code',
              equals(TdkExceptionType.submissionFailed.code),
            ),
          ),
        );
      });
    });
  });
}
