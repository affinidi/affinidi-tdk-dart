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

http.Client _clientReturning(int statusCode, Object body) => MockClient(
      (_) async => http.Response(jsonEncode(body), statusCode),
    );

void main() {
  group('VerifierMetadataService', () {
    group('when clientMetadata is provided', () {
      test('should parse it directly without making a network request',
          () async {
        // A client that throws if called — ensures no network request is made.
        final httpClient = MockClient((_) async => throw StateError('no call'));

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
      });

      test('should return null fields when clientMetadata has no recognised keys',
          () async {
        final httpClient = MockClient((_) async => throw StateError('no call'));

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
      });
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
          Uri.parse('$_baseUrl/vpa/v1/login/configurations/metadata/$_clientId'),
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

      test('should return VerifierClientMetadata with null domainVerified when absent',
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

        final result = await service.fetchVerifierMetadata(clientId: _clientId);

        expect(result.domainVerified, isNull);
      });

      test(
        'should throw TdkException with verifier_metadata_fetch_failed on non-200',
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
                    TdkExceptionType.verifierMetadataFetchFailed.code,
                  )
                  .having(
                    (e) => e.message,
                    'message',
                    contains('404'),
                  ),
            ),
          );
        },
      );

      test(
        'should throw TdkException with verifier_metadata_fetch_failed on network error',
        () async {
          final httpClient =
              MockClient((_) async => throw Exception('connection refused'));

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
                    TdkExceptionType.verifierMetadataFetchFailed.code,
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
                TdkExceptionType.verifierMetadataFetchFailed.code,
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
                TdkExceptionType.verifierMetadataFetchFailed.code,
              ),
            ),
          );
        },
      );
    });
  });
}
