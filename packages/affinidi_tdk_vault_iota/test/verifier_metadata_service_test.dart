import 'dart:convert';

import 'package:affinidi_tdk_vault_iota/affinidi_tdk_vault_iota.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';

const _baseUrl = 'https://apse1.api.affinidi.io';
const _clientId = 'did:key:z6Mk';

Map<String, dynamic> _validMetadataJson() => {
  'name': 'Test Verifier',
  'logo': 'https://example.com/logo.png',
  'origin': 'https://example.com',
  'domainVerified': true,
};

http.Client _clientReturning(int statusCode, Object body) =>
    MockClient((_) async => http.Response(jsonEncode(body), statusCode));

void main() {
  group('VerifierMetadataService', () {
    group('when clientId is empty', () {
      test('should throw TdkException with invalid_client_id', () async {
        final service = VerifierMetadataService(baseUrl: _baseUrl);
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
          // A client that throws if called — ensures no network request is made.
          final httpClient = MockClient(
            (_) async => throw StateError('no call'),
          );

          final service = VerifierMetadataService(
            baseUrl: _baseUrl,
            httpClient: httpClient,
          );
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
          final httpClient = MockClient(
            (_) async => throw StateError('no call'),
          );

          final service = VerifierMetadataService(
            baseUrl: _baseUrl,
            httpClient: httpClient,
          );
          addTearDown(service.dispose);

          final result = await service.fetchVerifierMetadata(
            clientId: _clientId,
            clientMetadata: {'unexpected_field': 42},
          );

          // All spec fields are optional — unrecognised keys produce null values.
          expect(result.name, isNull);
          expect(result.logo, isNull);
          expect(result.origin, isNull);
          expect(result.domainVerified, isNull);
        },
      );
    });

    group('when clientMetadataUri is provided', () {
      const metadataUri = 'https://verifier.example.com/.well-known/metadata';

      test('should GET the exact clientMetadataUri', () async {
        Uri? capturedUri;
        final httpClient = MockClient((request) async {
          capturedUri = request.url;
          return http.Response(jsonEncode(_validMetadataJson()), 200);
        });

        final service = VerifierMetadataService(
          baseUrl: _baseUrl,
          httpClient: httpClient,
        );
        addTearDown(service.dispose);

        await service.fetchVerifierMetadata(
          clientId: _clientId,
          clientMetadataUri: metadataUri,
        );

        expect(capturedUri, Uri.parse(metadataUri));
      });

      test('should return VerifierClientMetadata on a 200 response', () async {
        final service = VerifierMetadataService(
          baseUrl: _baseUrl,
          httpClient: _clientReturning(200, _validMetadataJson()),
        );
        addTearDown(service.dispose);

        final result = await service.fetchVerifierMetadata(
          clientId: _clientId,
          clientMetadataUri: metadataUri,
        );

        expect(result.name, 'Test Verifier');
        expect(result.logo, 'https://example.com/logo.png');
        expect(result.origin, 'https://example.com');
        expect(result.domainVerified, isTrue);
      });

      test(
        'should throw TdkException with failed_to_fetch_verifier_metadata on non-200',
        () async {
          final service = VerifierMetadataService(
            baseUrl: _baseUrl,
            httpClient: _clientReturning(404, {'error': 'not found'}),
          );
          addTearDown(service.dispose);

          await expectLater(
            () => service.fetchVerifierMetadata(
              clientId: _clientId,
              clientMetadataUri: metadataUri,
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

      test(
        'should take priority over Affinidi API when clientMetadata is absent',
        () async {
          final requestedUris = <Uri>[];
          final httpClient = MockClient((request) async {
            requestedUris.add(request.url);
            return http.Response(jsonEncode(_validMetadataJson()), 200);
          });

          final service = VerifierMetadataService(
            baseUrl: _baseUrl,
            httpClient: httpClient,
          );
          addTearDown(service.dispose);

          await service.fetchVerifierMetadata(
            clientId: _clientId,
            clientMetadataUri: metadataUri,
          );

          expect(requestedUris, hasLength(1));
          expect(requestedUris.single, Uri.parse(metadataUri));
        },
      );

      test(
        'should be bypassed when clientMetadata is also provided',
        () async {
          final httpClient = MockClient(
            (_) async => throw StateError('no call'),
          );

          final service = VerifierMetadataService(
            baseUrl: _baseUrl,
            httpClient: httpClient,
          );
          addTearDown(service.dispose);

          // clientMetadata takes precedence — no network request expected.
          final result = await service.fetchVerifierMetadata(
            clientId: _clientId,
            clientMetadataUri: metadataUri,
            clientMetadata: _validMetadataJson(),
          );

          expect(result.name, 'Test Verifier');
        },
      );
    });

    group('when clientMetadata is absent', () {
      test('should GET the correct URL', () async {
        Uri? capturedUri;
        final httpClient = MockClient((request) async {
          capturedUri = request.url;
          return http.Response(jsonEncode(_validMetadataJson()), 200);
        });

        final service = VerifierMetadataService(
          baseUrl: _baseUrl,
          httpClient: httpClient,
        );
        addTearDown(service.dispose);

        await service.fetchVerifierMetadata(clientId: _clientId);

        expect(
          capturedUri,
          Uri.parse(_baseUrl).replace(
            path:
                '/vpa/v1/login/configurations/metadata/${Uri.encodeComponent(_clientId)}',
          ),
        );
      });

      test('should return VerifierClientMetadata on a 200 response', () async {
        final service = VerifierMetadataService(
          baseUrl: _baseUrl,
          httpClient: _clientReturning(200, _validMetadataJson()),
        );
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
          final body = {
            'name': 'Test Verifier',
            'logo': 'https://example.com/logo.png',
            'origin': 'https://example.com',
          };

          final service = VerifierMetadataService(
            baseUrl: _baseUrl,
            httpClient: _clientReturning(200, body),
          );
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
          final service = VerifierMetadataService(
            baseUrl: _baseUrl,
            httpClient: _clientReturning(404, {'error': 'not found'}),
          );
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
          final httpClient = MockClient(
            (_) async => throw Exception('connection refused'),
          );

          final service = VerifierMetadataService(
            baseUrl: _baseUrl,
            httpClient: httpClient,
          );
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
        'should throw TdkException when response body is not valid JSON',
        () async {
          final httpClient = MockClient(
            (_) async => http.Response('not-json', 200),
          );

          final service = VerifierMetadataService(
            baseUrl: _baseUrl,
            httpClient: httpClient,
          );
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

      test(
        'should throw TdkException when response body is a JSON array, not an object',
        () async {
          final httpClient = MockClient(
            (_) async => http.Response(jsonEncode([_validMetadataJson()]), 200),
          );

          final service = VerifierMetadataService(
            baseUrl: _baseUrl,
            httpClient: httpClient,
          );
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
