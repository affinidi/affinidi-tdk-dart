import 'package:affinidi_tdk_test_utilities/affinidi_tdk_test_utilities.dart';
import 'package:affinidi_tdk_vault_iota/affinidi_tdk_vault_iota.dart';
import 'package:dio/dio.dart';
import 'package:test/test.dart';

const _baseUrl = 'https://apse1.api.affinidi.io';
const _clientId = 'did:key:z6Mk';

const _metadataUri = 'https://verifier.example.com/.well-known/metadata';

String get _defaultMetadataUrl => Uri.parse(_baseUrl)
    .replace(
      path:
          '/vpa/v1/login/configurations/metadata/${Uri.encodeComponent(_clientId)}',
    )
    .toString();

Map<String, dynamic> _validMetadataJson() => {
  'name': 'Test Verifier',
  'logo': 'https://example.com/logo.png',
  'origin': 'https://example.com',
  'domainVerified': true,
};

void main() {
  group('VerifierMetadataService', () {
    late Dio dio;
    late DioAdapter dioAdapter;

    setUp(() {
      dio = Dio();
      dioAdapter = DioAdapterFixtures.adapter(dio);
    });

    tearDown(() => dioAdapter.reset());

    VerifierMetadataService buildService() =>
        VerifierMetadataService(baseUrl: _baseUrl, dio: dio);

    group('when clientId is empty', () {
      test('should throw TdkException with invalid_client_id', () async {
        final service = buildService();
        addTearDown(service.dispose);

        await expectLater(
          () => service.fetchVerifierMetadata(clientId: ''),
          throwsA(
            isA<TdkException>().having(
              (e) => e.code,
              'code',
              TdkExceptionType.invalidClientId.code,
            ),
          ),
        );
      });
    });

    group('when clientMetadata is provided', () {
      test(
        'should parse it directly without making a network request',
        () async {
          // No mocked route — any network call would throw and fail the test.
          final service = buildService();
          addTearDown(service.dispose);

          final result = await service.fetchVerifierMetadata(
            clientId: _clientId,
            clientMetadata: _validMetadataJson(),
          );

          expect(result.name, 'Test Verifier');
          expect(result.logo, 'https://example.com/logo.png');
          expect(result.origin, 'https://example.com');
          expect(result.domainVerified, isTrue);
        },
      );

      test(
        'should return null fields when clientMetadata has no recognised keys',
        () async {
          final service = buildService();
          addTearDown(service.dispose);

          final result = await service.fetchVerifierMetadata(
            clientId: _clientId,
            clientMetadata: {'unexpected_field': 42},
          );

          expect(result.name, isNull);
          expect(result.logo, isNull);
          expect(result.origin, isNull);
          expect(result.domainVerified, isNull);
        },
      );
    });

    group('when clientMetadataUri is provided', () {
      test('should GET the exact clientMetadataUri', () async {
        Uri? capturedUri;
        dio.interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) {
              capturedUri = options.uri;
              handler.next(options);
            },
          ),
        );
        dioAdapter.mockRequestWithReply(
          url: _metadataUri,
          statusCode: 200,
          data: _validMetadataJson(),
          httpMethod: HttpMethod.get,
        );

        final service = buildService();
        addTearDown(service.dispose);

        await service.fetchVerifierMetadata(
          clientId: _clientId,
          clientMetadataUri: _metadataUri,
        );

        expect(capturedUri, Uri.parse(_metadataUri));
      });

      test('should return VerifierClientMetadata on a 200 response', () async {
        dioAdapter.mockRequestWithReply(
          url: _metadataUri,
          statusCode: 200,
          data: _validMetadataJson(),
          httpMethod: HttpMethod.get,
        );

        final service = buildService();
        addTearDown(service.dispose);

        final result = await service.fetchVerifierMetadata(
          clientId: _clientId,
          clientMetadataUri: _metadataUri,
        );

        expect(result.name, 'Test Verifier');
        expect(result.logo, 'https://example.com/logo.png');
        expect(result.origin, 'https://example.com');
        expect(result.domainVerified, isTrue);
      });

      test(
        'should throw TdkException with failed_to_fetch_verifier_metadata on non-200',
        () async {
          dioAdapter.mockRequestWithReply(
            url: _metadataUri,
            statusCode: 404,
            data: {'error': 'not found'},
            httpMethod: HttpMethod.get,
          );

          final service = buildService();
          addTearDown(service.dispose);

          await expectLater(
            () => service.fetchVerifierMetadata(
              clientId: _clientId,
              clientMetadataUri: _metadataUri,
            ),
            throwsA(
              isA<TdkException>()
                  .having(
                    (e) => e.code,
                    'code',
                    TdkExceptionType.failedToFetchVerifierMetadata.code,
                  )
                  .having((e) => e.message, 'message', contains('404')),
            ),
          );
        },
      );

      test('should be bypassed when clientMetadata is also provided', () async {
        // No mocked route — clientMetadata takes precedence, no network call.
        final service = buildService();
        addTearDown(service.dispose);

        final result = await service.fetchVerifierMetadata(
          clientId: _clientId,
          clientMetadataUri: _metadataUri,
          clientMetadata: _validMetadataJson(),
        );

        expect(result.name, 'Test Verifier');
      });
    });

    group('when clientMetadata is absent', () {
      test('should GET the correct default URL', () async {
        Uri? capturedUri;
        dio.interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) {
              capturedUri = options.uri;
              handler.next(options);
            },
          ),
        );
        dioAdapter.mockRequestWithReply(
          url: _defaultMetadataUrl,
          statusCode: 200,
          data: _validMetadataJson(),
          httpMethod: HttpMethod.get,
        );

        final service = buildService();
        addTearDown(service.dispose);

        await service.fetchVerifierMetadata(clientId: _clientId);

        expect(capturedUri, Uri.parse(_defaultMetadataUrl));
      });

      test('should return VerifierClientMetadata on a 200 response', () async {
        dioAdapter.mockRequestWithReply(
          url: _defaultMetadataUrl,
          statusCode: 200,
          data: _validMetadataJson(),
          httpMethod: HttpMethod.get,
        );

        final service = buildService();
        addTearDown(service.dispose);

        final result = await service.fetchVerifierMetadata(clientId: _clientId);

        expect(result.name, 'Test Verifier');
        expect(result.logo, 'https://example.com/logo.png');
        expect(result.origin, 'https://example.com');
        expect(result.domainVerified, isTrue);
      });

      test(
        'should return VerifierClientMetadata with null domainVerified when absent',
        () async {
          dioAdapter.mockRequestWithReply(
            url: _defaultMetadataUrl,
            statusCode: 200,
            data: {
              'name': 'Test Verifier',
              'logo': 'https://example.com/logo.png',
              'origin': 'https://example.com',
            },
            httpMethod: HttpMethod.get,
          );

          final service = buildService();
          addTearDown(service.dispose);

          final result = await service.fetchVerifierMetadata(
            clientId: _clientId,
          );

          expect(result.domainVerified, isNull);
        },
      );

      test(
        'should throw TdkException with failed_to_fetch_verifier_metadata on non-200',
        () async {
          dioAdapter.mockRequestWithReply(
            url: _defaultMetadataUrl,
            statusCode: 404,
            data: {'error': 'not found'},
            httpMethod: HttpMethod.get,
          );

          final service = buildService();
          addTearDown(service.dispose);

          await expectLater(
            () => service.fetchVerifierMetadata(clientId: _clientId),
            throwsA(
              isA<TdkException>()
                  .having(
                    (e) => e.code,
                    'code',
                    TdkExceptionType.failedToFetchVerifierMetadata.code,
                  )
                  .having((e) => e.message, 'message', contains('404')),
            ),
          );
        },
      );

      test(
        'should throw TdkException with failed_to_fetch_verifier_metadata on network error',
        () async {
          dioAdapter.mockRequestWithException(
            url: _defaultMetadataUrl,
            httpMethod: HttpMethod.get,
            exception: DioException(
              requestOptions: RequestOptions(path: _defaultMetadataUrl),
              type: DioExceptionType.connectionError,
              error: 'connection refused',
            ),
          );

          final service = buildService();
          addTearDown(service.dispose);

          await expectLater(
            () => service.fetchVerifierMetadata(clientId: _clientId),
            throwsA(
              isA<TdkException>()
                  .having(
                    (e) => e.code,
                    'code',
                    TdkExceptionType.failedToFetchVerifierMetadata.code,
                  )
                  .having(
                    (e) => e.originalMessage,
                    'originalMessage',
                    contains('connection refused'),
                  ),
            ),
          );
        },
      );

      test(
        'should throw TdkException when response body is a JSON array, not an object',
        () async {
          dioAdapter.mockRequestWithReply(
            url: _defaultMetadataUrl,
            statusCode: 200,
            data: [_validMetadataJson()],
            httpMethod: HttpMethod.get,
          );

          final service = buildService();
          addTearDown(service.dispose);

          await expectLater(
            () => service.fetchVerifierMetadata(clientId: _clientId),
            throwsA(
              isA<TdkException>().having(
                (e) => e.code,
                'code',
                TdkExceptionType.failedToFetchVerifierMetadata.code,
              ),
            ),
          );
        },
      );
    });
  });
}
