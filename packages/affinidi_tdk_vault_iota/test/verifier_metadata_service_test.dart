import 'dart:convert';

import 'package:affinidi_tdk_vault_iota/affinidi_tdk_vault_iota.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';

const _baseUrl = 'https://apse1.api.affinidi.io';
const _clientId = 'did:key:z6Mk';
const _metadataPath =
    '/vpa/v1/login/configurations/metadata/$_clientId';

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
    group('when embeddedClientMetadata is provided', () {
      test('should parse it directly without making a network request',
          () async {
        // A client that throws if called — ensures no network request is made.
        final httpClient = MockClient((_) async => throw StateError('no call'));

        final service = VerifierMetadataService(
          baseUrl: _baseUrl,
          httpClient: httpClient,
        );

        final result = await service.fetchVerifierMetadata(
          clientId: _clientId,
          embeddedClientMetadata: _validMetadataJson(),
        );

        expect(result.name, 'Test Verifier');
        expect(result.logo, 'https://example.com/logo.png');
        expect(result.origin, 'https://example.com');
        expect(result.domainVerified, isTrue);
      });

      test('should throw TdkException when embedded metadata is malformed',
          () async {
        final httpClient = MockClient((_) async => throw StateError('no call'));

        final service = VerifierMetadataService(
          baseUrl: _baseUrl,
          httpClient: httpClient,
        );

        await expectLater(
          () => service.fetchVerifierMetadata(
            clientId: _clientId,
            embeddedClientMetadata: {'unexpected_field': 42},
          ),
          throwsA(
            isA<TdkException>().having(
              (e) => e.code,
              'code',
              TdkExceptionType.verifierMetadataFetchFailed.code,
            ),
          ),
        );
      });
    });

    group('when embeddedClientMetadata is absent', () {
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

        await service.fetchVerifierMetadata(clientId: _clientId);

        expect(
          capturedUri.toString(),
          '$_baseUrl$_metadataPath',
        );
      });

      test('should return VerifierClientMetadata on a 200 response', () async {
        final service = VerifierMetadataService(
          baseUrl: _baseUrl,
          httpClient: _clientReturning(200, _validMetadataJson()),
        );

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
