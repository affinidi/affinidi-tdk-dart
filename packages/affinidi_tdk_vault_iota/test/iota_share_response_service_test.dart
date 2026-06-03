import 'package:affinidi_tdk_test_utilities/affinidi_tdk_test_utilities.dart';
import 'package:affinidi_tdk_vault_iota/affinidi_tdk_vault_iota.dart';
import 'package:dio/dio.dart';
import 'package:mocktail/mocktail.dart' hide VerificationResult;
import 'package:ssi/ssi.dart';
import 'package:test/test.dart';

// ── Fakes ─────────────────────────────────────────────────────────────────────

class _FakeVpBuilder implements VpBuilderInterface {
  final Map<String, dynamic> result;
  _FakeVpBuilder(this.result);

  @override
  Future<Map<String, dynamic>> build({
    required DidSigner signer,
    required List<ParsedVerifiableCredential<dynamic>> credentials,
    required String nonce,
    required String domain,
  }) async => result;
}

class _FakeVC extends Fake implements ParsedVerifiableCredential<dynamic> {}

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

const _acceptUri = 'https://verifier.example.com/callback';
const _rejectUri = 'https://verifier.example.com/reject';
const _redirectUri = 'https://verifier.example.com/done';

void main() {
  late Dio dio;
  late DioAdapter dioAdapter;
  late DidSigner signer;

  final fakeVp = <String, dynamic>{
    'type': 'VerifiablePresentation',
    'proof': <String, dynamic>{},
  };
  final fakeVC = _FakeVC();
  final descriptor = PDDescriptor.fromJson({'id': 'desc_1'});

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
    vpBuilder: _FakeVpBuilder(fakeVp),
  );

  group('when submitShareResponse is called', () {
    group('and the POST succeeds with a redirect_uri', () {
      setUp(() {
        dioAdapter.mockRequestWithReply(
          url: _acceptUri,
          statusCode: 200,
          data: {'redirect_uri': _redirectUri},
          httpMethod: HttpMethod.post,
        );
      });

      test('should complete without throwing', () async {
        await expectLater(
          buildService().submitShareResponse(
            state: 'test-state',
            nonce: 'test-nonce',
            clientId: 'did:key:test-verifier',
            definitionId: 'pd_1',
            selectedCredentials: [(descriptor: descriptor, credential: fakeVC)],
            acceptResponseUri: _acceptUri,
          ),
          completes,
        );
      });

      test('should return the redirect URI from the response', () async {
        final result = await buildService().submitShareResponse(
          state: 'my-state',
          nonce: 'my-nonce',
          clientId: 'did:key:test-verifier',
          definitionId: 'pd_1',
          selectedCredentials: [(descriptor: descriptor, credential: fakeVC)],
          acceptResponseUri: _acceptUri,
        );

        expect(result, equals(Uri.parse(_redirectUri)));
      });
    });

    group('and the POST succeeds with no redirect_uri', () {
      setUp(() {
        dioAdapter.mockRequestWithReply(
          url: _acceptUri,
          statusCode: 200,
          data: <String, dynamic>{},
          httpMethod: HttpMethod.post,
        );
      });

      test('should return null', () async {
        final result = await buildService().submitShareResponse(
          state: 'my-state',
          nonce: 'my-nonce',
          clientId: 'did:key:test-verifier',
          definitionId: 'pd_1',
          selectedCredentials: [(descriptor: descriptor, credential: fakeVC)],
          acceptResponseUri: _acceptUri,
        );

        expect(result, isNull);
      });
    });

    group('and the POST fails', () {
      setUp(() {
        dioAdapter.mockRequestWithException(
          url: _acceptUri,
          statusCode: 500,
          httpMethod: HttpMethod.post,
        );
      });

      test('should throw a TdkException with submissionFailed code', () async {
        await expectLater(
          buildService().submitShareResponse(
            state: 'state',
            nonce: 'nonce',
            clientId: 'did:key:test-verifier',
            definitionId: 'pd_1',
            selectedCredentials: [(descriptor: descriptor, credential: fakeVC)],
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

  group('when rejectShareResponse is called', () {
    group('and the POST succeeds with a redirect_uri', () {
      setUp(() {
        dioAdapter.mockRequestWithReply(
          url: _rejectUri,
          statusCode: 200,
          data: {'redirect_uri': _redirectUri},
          httpMethod: HttpMethod.post,
        );
      });

      test('should return the redirect URI from the response', () async {
        final result = await buildService().rejectShareResponse(
          state: 'my-state',
          rejectResponseUri: _rejectUri,
        );

        expect(result, equals(Uri.parse(_redirectUri)));
      });
    });

    group('and the POST succeeds with no redirect_uri', () {
      setUp(() {
        dioAdapter.mockRequestWithReply(
          url: _rejectUri,
          statusCode: 200,
          data: <String, dynamic>{},
          httpMethod: HttpMethod.post,
        );
      });

      test('should return null', () async {
        final result = await buildService().rejectShareResponse(
          state: 'my-state',
          rejectResponseUri: _rejectUri,
        );

        expect(result, isNull);
      });
    });

    group('and the POST fails', () {
      setUp(() {
        dioAdapter.mockRequestWithException(
          url: _rejectUri,
          statusCode: 500,
          httpMethod: HttpMethod.post,
        );
      });

      test('should throw a TdkException with submissionFailed code', () async {
        await expectLater(
          buildService().rejectShareResponse(
            state: 'state',
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
