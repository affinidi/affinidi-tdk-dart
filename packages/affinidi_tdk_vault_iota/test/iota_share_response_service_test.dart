import 'package:affinidi_tdk_common/affinidi_tdk_common.dart';
import 'package:affinidi_tdk_iota_client/affinidi_tdk_iota_client.dart';
import 'package:affinidi_tdk_vault_iota/affinidi_tdk_vault_iota.dart';
import 'package:dio/dio.dart';
import 'package:mocktail/mocktail.dart' hide VerificationResult;
import 'package:ssi/ssi.dart';
import 'package:test/test.dart';

// ── Mocks / Fakes ─────────────────────────────────────────────────────────────

class MockCallbackApi extends Mock implements CallbackApi {}

class _FakeVpBuilder implements VpBuilderInterface {
  final Map<String, dynamic> result;
  _FakeVpBuilder(this.result);

  @override
  Future<Map<String, dynamic>> build({
    required DidSigner signer,
    required List<ParsedVerifiableCredential<dynamic>> credentials,
    required String nonce,
    required String domain,
  }) async =>
      result;
}

class _FakeVC extends Fake implements ParsedVerifiableCredential<dynamic> {}

// ── Helpers ───────────────────────────────────────────────────────────────────

Future<DidSigner> _buildTestSigner() async {
  final keyStore = InMemoryKeyStore();
  final wallet = PersistentWallet(keyStore);
  final keyPair = await wallet.generateKey(keyType: KeyType.ed25519);
  final didManager = DidKeyManager(
    wallet: wallet,
    store: InMemoryDidStore(),
  );
  await didManager.addVerificationMethod(keyPair.id);
  return didManager.getSigner(
    didManager.assertionMethod.first,
    signatureScheme: SignatureScheme.ed25519,
  );
}

void main() {
  late MockCallbackApi callbackApi;
  late DidSigner signer;

  final fakeVp = <String, dynamic>{'type': 'VerifiablePresentation', 'proof': <String, dynamic>{}};
  final fakeVC = _FakeVC();
  final descriptor = PDDescriptor.fromJson({'id': 'desc_1'});

  setUpAll(() async {
    signer = await _buildTestSigner();
    registerFallbackValue(CallbackInput((b) => b..state = ''));
  });

  setUp(() {
    callbackApi = MockCallbackApi();
  });

  IotaShareResponseService _buildService() => IotaShareResponseService(
    approveCallbackApi: callbackApi,
    signer: signer,
    vpBuilder: _FakeVpBuilder(fakeVp),
  );

  group('when submitShareResponse is called', () {
    group('and the callback API succeeds', () {
      setUp(() {
        when(
          () => callbackApi.iotOIDC4VPCallback(
            callbackInput: any(named: 'callbackInput'),
          ),
        ).thenAnswer((_) async => Response(
          data: CallbackResponseOK((b) => b
            ..message = 'OK'
            ..redirectUri = 'https://verifier.example.com/done'),
          requestOptions: RequestOptions(path: '/v1/callback'),
          statusCode: 200,
        ));
      });

      test('should complete without throwing', () async {
        final service = _buildService();

        await expectLater(
          service.submitShareResponse(
            state: 'test-state-uuid',
            nonce: 'test-nonce',
            clientId: 'did:key:test-verifier',
            definitionId: 'pd_1',
            selectedCredentials: [(descriptor: descriptor, credential: fakeVC)],
          ),
          completes,
        );
      });

      test('should call iotOIDC4VPCallback exactly once', () async {
        final service = _buildService();

        await service.submitShareResponse(
          state: 'test-state-uuid',
          nonce: 'test-nonce',
          clientId: 'did:key:test-verifier',
          definitionId: 'pd_1',
          selectedCredentials: [(descriptor: descriptor, credential: fakeVC)],
        );

        verify(
          () => callbackApi.iotOIDC4VPCallback(
            callbackInput: any(named: 'callbackInput'),
          ),
        ).called(1);
      });

      test('should pass state, presentationSubmission, and vpToken to the callback',
          () async {
        final service = _buildService();
        CallbackInput? captured;

        when(
          () => callbackApi.iotOIDC4VPCallback(
            callbackInput: any(named: 'callbackInput'),
          ),
        ).thenAnswer((inv) async {
          captured = inv.namedArguments[#callbackInput] as CallbackInput;
          return Response(
            requestOptions: RequestOptions(path: '/v1/callback'),
            statusCode: 200,
          );
        });

        await service.submitShareResponse(
          state: 'my-state',
          nonce: 'my-nonce',
          clientId: 'did:key:test-verifier',
          definitionId: 'pd_captured',
          selectedCredentials: [(descriptor: descriptor, credential: fakeVC)],
        );

        expect(captured, isNotNull);
        expect(captured!.state, equals('my-state'));
        expect(captured!.presentationSubmission, isNotNull);
        expect(captured!.vpToken, isNotNull);
      });

      test('should return the redirect URI from the response', () async {
        final service = _buildService();

        final result = await service.submitShareResponse(
          state: 'my-state',
          nonce: 'my-nonce',
          clientId: 'did:key:test-verifier',
          definitionId: 'pd_1',
          selectedCredentials: [(descriptor: descriptor, credential: fakeVC)],
        );

        expect(result, equals(Uri.parse('https://verifier.example.com/done')));
      });

      test('should return null when the response has no redirect URI', () async {
        when(
          () => callbackApi.iotOIDC4VPCallback(
            callbackInput: any(named: 'callbackInput'),
          ),
        ).thenAnswer((_) async => Response(
          requestOptions: RequestOptions(path: '/v1/callback'),
          statusCode: 200,
        ));
        final service = _buildService();

        final result = await service.submitShareResponse(
          state: 'my-state',
          nonce: 'my-nonce',
          clientId: 'did:key:test-verifier',
          definitionId: 'pd_1',
          selectedCredentials: [(descriptor: descriptor, credential: fakeVC)],
        );

        expect(result, isNull);
      });
    });

    group('and the callback API throws an exception', () {
      setUp(() {
        when(
          () => callbackApi.iotOIDC4VPCallback(
            callbackInput: any(named: 'callbackInput'),
          ),
        ).thenThrow(Exception('network error'));
      });

      test('should throw a TdkException with submissionFailed code', () async {
        final service = _buildService();

        await expectLater(
          service.submitShareResponse(
            state: 'state',
            nonce: 'nonce',
            clientId: 'did:key:test-verifier',
            definitionId: 'pd_1',
            selectedCredentials: [(descriptor: descriptor, credential: fakeVC)],
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

  group('when rejectShareResponse is called', () {
    group('and the callback API succeeds', () {
      setUp(() {
        when(
          () => callbackApi.iotOIDC4VPCallback(
            callbackInput: any(named: 'callbackInput'),
          ),
        ).thenAnswer((_) async => Response(
          requestOptions: RequestOptions(path: '/v1/callback'),
          statusCode: 200,
        ));
      });

      test('should send state and access_denied error to the callback', () async {
        final service = _buildService();
        CallbackInput? captured;

        when(
          () => callbackApi.iotOIDC4VPCallback(
            callbackInput: any(named: 'callbackInput'),
          ),
        ).thenAnswer((inv) async {
          captured = inv.namedArguments[#callbackInput] as CallbackInput;
          return Response(
            requestOptions: RequestOptions(path: '/v1/callback'),
            statusCode: 200,
          );
        });

        await service.rejectShareResponse(state: 'my-state');

        expect(captured, isNotNull);
        expect(captured!.state, equals('my-state'));
        expect(captured!.error, equals('access_denied'));
        expect(captured!.vpToken, isNull);
        expect(captured!.presentationSubmission, isNull);
      });

      test('should return the redirect URI from the response', () async {
        when(
          () => callbackApi.iotOIDC4VPCallback(
            callbackInput: any(named: 'callbackInput'),
          ),
        ).thenAnswer((_) async => Response(
          data: CallbackResponseOK((b) => b
            ..message = 'OK'
            ..redirectUri = 'https://verifier.example.com/done'),
          requestOptions: RequestOptions(path: '/v1/callback'),
          statusCode: 200,
        ));
        final service = _buildService();

        final result = await service.rejectShareResponse(state: 'my-state');

        expect(result, equals(Uri.parse('https://verifier.example.com/done')));
      });

      test('should use a separate rejectCallbackApi when provided', () async {
        final rejectCallbackApi = MockCallbackApi();
        when(
          () => rejectCallbackApi.iotOIDC4VPCallback(
            callbackInput: any(named: 'callbackInput'),
          ),
        ).thenAnswer((_) async => Response(
          requestOptions: RequestOptions(path: '/v1/callback'),
          statusCode: 200,
        ));

        final service = IotaShareResponseService(
          approveCallbackApi: callbackApi,
          rejectCallbackApi: rejectCallbackApi,
          signer: signer,
          vpBuilder: _FakeVpBuilder(fakeVp),
        );

        await service.rejectShareResponse(state: 'my-state');

        verifyNever(
          () => callbackApi.iotOIDC4VPCallback(
            callbackInput: any(named: 'callbackInput'),
          ),
        );
        verify(
          () => rejectCallbackApi.iotOIDC4VPCallback(
            callbackInput: any(named: 'callbackInput'),
          ),
        ).called(1);
      });
    });

    group('and the callback API throws an exception', () {
      setUp(() {
        when(
          () => callbackApi.iotOIDC4VPCallback(
            callbackInput: any(named: 'callbackInput'),
          ),
        ).thenThrow(Exception('network error'));
      });

      test('should throw a TdkException with submissionFailed code', () async {
        final service = _buildService();

        await expectLater(
          service.rejectShareResponse(state: 'state'),
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
