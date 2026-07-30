import 'dart:convert';

import 'package:affinidi_tdk_test_utilities/affinidi_tdk_test_utilities.dart';
import 'package:affinidi_tdk_vault_iota/affinidi_tdk_vault_iota.dart';
import 'package:affinidi_tdk_vault_iota/src/models/share_requirements.dart';
import 'package:dcql/dcql.dart';
import 'package:dio/dio.dart';
import 'package:ssi/ssi.dart';
import 'package:test/test.dart';

import 'fixtures/iota_consent_record_fixtures.dart';
import 'fixtures/pd_descriptor_fixtures.dart';
import 'fixtures/verifiable_credential_fixtures.dart';

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

  IotaShareResponseService buildService({
    List<String> trustedHosts = const [
      'verifier.example.com',
      'dcql-verifier.example.com',
    ],
  }) => IotaShareResponseService(
    signer: signer,
    dio: dio,
    vpBuilder: _FakeVpBuilder(_fakeVp),
    trustedVerifiersList: trustedHosts,
  );

  // ── response_uri parse-failure paths ─────────────────────────────────────────

  group('response_uri validation (parse failure)', () {
    test(
      'throws invalidResponseUri for a non-HTTPS acceptResponseUri',
      () async {
        final service = buildService();
        await expectLater(
          () => service.submitShareResponse(
            shareRequest: _pexShareRequest,
            selectedCredentials: [_fakeVC],
            acceptResponseUri: 'http://verifier.example.com/accept',
          ),
          throwsA(
            isA<TdkException>().having(
              (e) => e.code,
              'code',
              TdkExceptionType.invalidResponseUri.code,
            ),
          ),
        );
      },
    );

    test('throws invalidResponseUri for an IP-address host', () async {
      final service = buildService();
      await expectLater(
        () => service.submitShareResponse(
          shareRequest: _pexShareRequest,
          selectedCredentials: [_fakeVC],
          acceptResponseUri: 'https://127.0.0.1/accept',
        ),
        throwsA(
          isA<TdkException>().having(
            (e) => e.code,
            'code',
            TdkExceptionType.invalidResponseUri.code,
          ),
        ),
      );
    });

    test(
      'throws invalidResponseUri for a URI with userinfo or fragment',
      () async {
        final service = buildService();
        await expectLater(
          () => service.submitShareResponse(
            shareRequest: _pexShareRequest,
            selectedCredentials: [_fakeVC],
            acceptResponseUri: 'https://user@verifier.example.com/accept#frag',
          ),
          throwsA(
            isA<TdkException>().having(
              (e) => e.code,
              'code',
              TdkExceptionType.invalidResponseUri.code,
            ),
          ),
        );
      },
    );
  });

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

    group('when credentials are supplied out of descriptor order', () {
      test('descriptor_map paths reference the matching credential, not the '
          'positional index', () async {
        // The presentation definition lists the degree descriptor first,
        // but the caller supplies the credentials in the reverse order.
        // Each descriptor_map entry must point at the credential that
        // actually satisfies it inside the VP.
        final reorderedRequest = PexShareRequest(
          request: _pexShareRequest.request,
          jwtAssertion: 'test_jwt',
          presentationDefinition: {
            'id': 'def-reordered',
            'input_descriptors': [
              buildDescriptor(id: 'desc_degree', type: 'UniversityDegree'),
              buildDescriptor(
                id: 'desc_employment',
                type: 'EmploymentCredential',
              ),
            ],
          },
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
          url: _acceptUri,
          statusCode: 200,
          data: <String, dynamic>{},
          httpMethod: HttpMethod.post,
        );

        await buildService().submitShareResponse(
          shareRequest: reorderedRequest,
          selectedCredentials: [
            buildTestVc(type: 'EmploymentCredential'), // index 0
            buildTestVc(type: 'UniversityDegree'), // index 1
          ],
          acceptResponseUri: _acceptUri,
        );

        final data = captured!.data as Map<String, dynamic>;
        final submission =
            jsonDecode(data['presentation_submission'] as String)
                as Map<String, dynamic>;
        final map = (submission['descriptor_map'] as List)
            .cast<Map<String, dynamic>>();

        final degree = map.firstWhere((e) => e['id'] == 'desc_degree');
        final employment = map.firstWhere((e) => e['id'] == 'desc_employment');

        expect(degree['path'], equals(r'$.verifiableCredential[1]'));
        expect(employment['path'], equals(r'$.verifiableCredential[0]'));
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

    group('response_uri validation (invalid_response_uri)', () {
      for (final uri in [
        'http://verifier.example.com/accept',
        'file:///tmp/accept',
        'javascript:alert(1)',
        'intent://verifier.example.com/accept',
      ]) {
        test('rejects unsafe scheme: $uri', () async {
          await expectLater(
            buildService().submitShareResponse(
              shareRequest: _pexShareRequest,
              selectedCredentials: [_fakeVC],
              acceptResponseUri: uri,
            ),
            throwsA(
              isA<TdkException>().having(
                (e) => e.code,
                'code',
                TdkExceptionType.invalidResponseUri.code,
              ),
            ),
          );
        });
      }

      test('rejects response_uri with userinfo', () async {
        await expectLater(
          buildService().submitShareResponse(
            shareRequest: _pexShareRequest,
            selectedCredentials: [_fakeVC],
            acceptResponseUri: 'https://user@verifier.example.com/accept',
          ),
          throwsA(
            isA<TdkException>().having(
              (e) => e.code,
              'code',
              TdkExceptionType.invalidResponseUri.code,
            ),
          ),
        );
      });

      test('rejects response_uri with fragment', () async {
        await expectLater(
          buildService().submitShareResponse(
            shareRequest: _pexShareRequest,
            selectedCredentials: [_fakeVC],
            acceptResponseUri: 'https://verifier.example.com/accept#fragment',
          ),
          throwsA(
            isA<TdkException>().having(
              (e) => e.code,
              'code',
              TdkExceptionType.invalidResponseUri.code,
            ),
          ),
        );
      });

      test('rejects response_uri with IPv4 address', () async {
        await expectLater(
          buildService().submitShareResponse(
            shareRequest: _pexShareRequest,
            selectedCredentials: [_fakeVC],
            acceptResponseUri: 'https://1.2.3.4/accept',
          ),
          throwsA(
            isA<TdkException>().having(
              (e) => e.code,
              'code',
              TdkExceptionType.invalidResponseUri.code,
            ),
          ),
        );
      });

      test('rejects response_uri with IPv6 loopback', () async {
        await expectLater(
          buildService().submitShareResponse(
            shareRequest: _pexShareRequest,
            selectedCredentials: [_fakeVC],
            acceptResponseUri: 'https://[::1]/accept',
          ),
          throwsA(
            isA<TdkException>().having(
              (e) => e.code,
              'code',
              TdkExceptionType.invalidResponseUri.code,
            ),
          ),
        );
      });

      test('rejects response_uri with IPv4-mapped IPv6 address', () async {
        await expectLater(
          buildService().submitShareResponse(
            shareRequest: _pexShareRequest,
            selectedCredentials: [_fakeVC],
            acceptResponseUri: 'https://[::ffff:1.2.3.4]/accept',
          ),
          throwsA(
            isA<TdkException>().having(
              (e) => e.code,
              'code',
              TdkExceptionType.invalidResponseUri.code,
            ),
          ),
        );
      });

      test('rejects response_uri host not declared by client_id DID', () async {
        await expectLater(
          buildService(
            trustedHosts: ['verifier.example.com'],
          ).submitShareResponse(
            shareRequest: _pexShareRequest,
            selectedCredentials: [_fakeVC],
            acceptResponseUri: 'https://attacker.example.com/steal',
          ),
          throwsA(
            isA<TdkException>().having(
              (e) => e.code,
              'code',
              TdkExceptionType.untrustedResponseUri.code,
            ),
          ),
        );
      });

      test(
        'returns null for redirect_uri host not declared by client_id DID',
        () async {
          dioAdapter.mockRequestWithReply(
            url: _acceptUri,
            statusCode: 200,
            data: {'redirect_uri': 'https://attacker.example.com/phishing'},
            httpMethod: HttpMethod.post,
          );

          final result =
              await buildService(
                trustedHosts: ['verifier.example.com'],
              ).submitShareResponse(
                shareRequest: _pexShareRequest,
                selectedCredentials: [_fakeVC],
                acceptResponseUri: _acceptUri,
              );

          expect(result, isNull);
        },
      );

      test('rejects response_uri when host is not in trusted list', () async {
        final service = IotaShareResponseService(
          signer: signer,
          dio: dio,
          vpBuilder: _FakeVpBuilder(_fakeVp),
          trustedVerifiersList: const ['other.example.com'],
        );

        await expectLater(
          service.submitShareResponse(
            shareRequest: _pexShareRequest,
            selectedCredentials: [_fakeVC],
            acceptResponseUri: _acceptUri,
          ),
          throwsA(
            isA<TdkException>().having(
              (e) => e.code,
              'code',
              TdkExceptionType.untrustedResponseUri.code,
            ),
          ),
        );
      });

      test('accepts response_uri when host is in trusted list', () async {
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

        final service = IotaShareResponseService(
          signer: signer,
          dio: dio,
          vpBuilder: _FakeVpBuilder(_fakeVp),
          trustedVerifiersList: const ['verifier.example.com'],
        );

        await service.submitShareResponse(
          shareRequest: _pexShareRequest,
          selectedCredentials: [_fakeVC],
          acceptResponseUri: _acceptUri,
        );

        expect(captured, isNotNull);
        expect(captured!.path, equals(_acceptUri));
      });
    });

    // ── trustedVerifiersList — success and attack cases ──────────────────────

    group('trustedVerifiersList', () {
      const trustedHosts = ['verifier.example.com'];

      IotaShareResponseService serviceWithTrustedHosts() =>
          IotaShareResponseService(
            signer: signer,
            dio: dio,
            vpBuilder: _FakeVpBuilder(_fakeVp),
            trustedVerifiersList: trustedHosts,
          );

      test(
        'throws emptyTrustedVerifiersList when constructed with an empty list',
        () {
          expect(
            () => IotaShareResponseService(
              signer: signer,
              dio: dio,
              vpBuilder: _FakeVpBuilder(_fakeVp),
              trustedVerifiersList: const [],
            ),
            throwsA(
              isA<TdkException>().having(
                (e) => e.code,
                'code',
                TdkExceptionType.emptyTrustedVerifiersList.code,
              ),
            ),
          );
        },
      );

      test(
        'throws invalidResponseUri when entry contains a scheme or path',
        () {
          for (final badEntry in [
            'https://verifier.example.com',
            'http://verifier.example.com',
            'verifier.example.com/path',
            'verifier.example.com:8443',
          ]) {
            expect(
              () => IotaShareResponseService(
                signer: signer,
                vpBuilder: _FakeVpBuilder(_fakeVp),
                trustedVerifiersList: [badEntry],
              ),
              throwsA(
                isA<TdkException>().having(
                  (e) => e.code,
                  'code',
                  TdkExceptionType.invalidResponseUri.code,
                ),
              ),
              reason: 'bad entry: $badEntry',
            );
          }
        },
      );

      test('matches trusted host case-insensitively', () async {
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

        final service = IotaShareResponseService(
          signer: signer,
          dio: dio,
          vpBuilder: _FakeVpBuilder(_fakeVp),
          // Mixed-case host must still match the lower-case acceptResponseUri.
          trustedVerifiersList: const ['Verifier.Example.COM'],
        );

        await service.submitShareResponse(
          shareRequest: _pexShareRequest,
          selectedCredentials: [_fakeVC],
          acceptResponseUri: _acceptUri,
        );

        expect(captured, isNotNull);
        expect(captured!.path, equals(_acceptUri));
      });

      test(
        'success: legitimate verifier host in list can post VP to trusted host',
        () async {
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

          // _pexShareRequest has acceptResponseUri on 'verifier.example.com' — in the list.
          await serviceWithTrustedHosts().submitShareResponse(
            shareRequest: _pexShareRequest,
            selectedCredentials: [_fakeVC],
            acceptResponseUri: _acceptUri,
          );

          expect(captured, isNotNull);
          expect(captured!.path, equals(_acceptUri));
          final data = captured!.data as Map<String, dynamic>;
          expect(data['vp_token'], isNotNull);
        },
      );

      test(
        'attack: attacker did:key with untrusted response_uri is rejected',
        () async {
          const attackerCallbackUri =
              'https://attacker-controlled-host.example/steal';

          final attackerShareRequest = PexShareRequest(
            request: const IotaRequest(
              responseType: 'vp_token',
              responseMode: 'direct_post',
              acceptResponseUri: attackerCallbackUri,
              rejectResponseUri: attackerCallbackUri,
              state: 'attacker-state',
              nonce: 'attacker-nonce',
              clientId: 'did:key:z6MkAttackerGeneratedKey',
            ),
            presentationDefinition: _pexShareRequest.presentationDefinition,
            jwtAssertion: 'attacker-jwt',
          );

          await expectLater(
            serviceWithTrustedHosts().submitShareResponse(
              shareRequest: attackerShareRequest,
              selectedCredentials: [_fakeVC],
              // Attacker-controlled callback URL — must never receive the VP.
              acceptResponseUri: attackerCallbackUri,
            ),
            throwsA(
              isA<TdkException>().having(
                (e) => e.code,
                'code',
                TdkExceptionType.untrustedResponseUri.code,
              ),
            ),
          );
        },
      );

      test('attack: callback host not in trusted list is rejected', () async {
        const attackerCallbackUri =
            'https://attacker-controlled-host.example/steal';

        final attackerShareRequest = PexShareRequest(
          request: const IotaRequest(
            responseType: 'vp_token',
            responseMode: 'direct_post',
            acceptResponseUri: attackerCallbackUri,
            rejectResponseUri: attackerCallbackUri,
            state: 'attacker-state',
            nonce: 'attacker-nonce',
            // Uses a legitimate clientId — but they cannot produce a valid
            // JWT signature for it without controlling the private key.
            clientId: 'did:key:verifier123',
          ),
          presentationDefinition: _pexShareRequest.presentationDefinition,
          jwtAssertion: 'forged-jwt',
        );

        await expectLater(
          serviceWithTrustedHosts().submitShareResponse(
            shareRequest: attackerShareRequest,
            selectedCredentials: [_fakeVC],
            acceptResponseUri: attackerCallbackUri,
          ),
          throwsA(
            isA<TdkException>().having(
              (e) => e.code,
              'code',
              TdkExceptionType.untrustedResponseUri.code,
            ),
          ),
        );
      });

      test(
        'attack: host not in trusted list means did:key is always blocked',
        () async {
          final serviceOtherHost = IotaShareResponseService(
            signer: signer,
            dio: dio,
            vpBuilder: _FakeVpBuilder(_fakeVp),
            // host not in trustedVerifiersList — TDK rejects.
            trustedVerifiersList: ['other.example.com'],
          );

          await expectLater(
            serviceOtherHost.submitShareResponse(
              shareRequest: _pexShareRequest,
              selectedCredentials: [_fakeVC],
              acceptResponseUri: _acceptUri,
            ),
            throwsA(
              isA<TdkException>().having(
                (e) => e.code,
                'code',
                TdkExceptionType.untrustedResponseUri.code,
              ),
            ),
          );
        },
      );
    });
  });

  // ── DCQL submit ─────────────────────────────────────────────────────────────

  group('submitShareResponse (DCQL)', () {
    group('when the POST succeeds', () {
      test('POSTs to acceptResponseUri with state and DCQL-shaped vp_token '
          '(no presentation_submission)', () async {
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

        // OID4VP 1.0 §8.1: vp_token is a JSON object keyed by credential-query
        // id whose values are arrays of the satisfying presentations.
        final vpToken =
            jsonDecode(data['vp_token'] as String) as Map<String, dynamic>;
        expect(vpToken.keys, equals({'q1'}));
        expect(vpToken['q1'], equals([_fakeVp]));
      });

      test(
        'builds a per-query presentation and omits unsatisfied queries',
        () async {
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

          // q1 accepts ldp_vc (satisfied by the shared W3C VC); q2 requires a
          // different format, so it has no matching credential and must be
          // omitted from the vp_token.
          final multiQueryRequest = DcqlShareRequest(
            request: _dcqlShareRequest.request,
            dcqlQuery: DcqlCredentialQuery(
              credentials: [
                DcqlCredential(id: 'q1', format: CredentialFormat.ldpVc),
                DcqlCredential(id: 'q2', format: CredentialFormat.jwtVcJson),
              ],
            ),
            jwtAssertion: _dcqlShareRequest.jwtAssertion,
          );

          await buildService().submitShareResponse(
            shareRequest: multiQueryRequest,
            selectedCredentials: [_fakeVC],
            acceptResponseUri: _dcqlAcceptUri,
          );

          final data = captured!.data as Map<String, dynamic>;
          final vpToken =
              jsonDecode(data['vp_token'] as String) as Map<String, dynamic>;
          expect(vpToken.keys, equals({'q1'}));
          expect(vpToken['q1'], equals([_fakeVp]));
        },
      );

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
