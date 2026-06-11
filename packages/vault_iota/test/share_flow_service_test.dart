import 'package:affinidi_tdk_cryptography/affinidi_tdk_cryptography.dart';
import 'package:affinidi_tdk_vault_iota/affinidi_tdk_vault_iota.dart';
import 'package:affinidi_tdk_vault_iota/src/models/share_requirements.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import 'fixtures/jwt_fixtures.dart';
import 'mocks/mock_cryptography_service.dart';

VerifyJwtResult _validResult() => VerifyJwtResult(
  isValid: true,
  isExpired: false,
  errorMessage: null,
  jwtPayload: null,
);

Map<String, dynamic> _baseDecodedPayload({
  String nonce = 'test-nonce',
  String state = 'test-state',
  String clientId = 'did:key:z6Mk',
  String clientIdScheme = 'did',
  Map<String, dynamic>? clientMetadata = const {'client_name': 'Test Verifier'},
  String responseUri = 'https://example.com/response',
  String responseType = 'vp_token',
  String responseMode = 'direct_post',
  String? scope = 'openid',
  int exp = 9999999999,
  int iat = 1000000000,
  String? aud,
  Map<String, dynamic>? presentationDefinition,
}) => {
  'nonce': nonce,
  'state': state,
  'client_id': clientId,
  'client_id_scheme': clientIdScheme,
  if (clientMetadata != null) 'client_metadata': clientMetadata,
  'response_uri': responseUri,
  'response_type': responseType,
  'response_mode': responseMode,
  if (scope != null) 'scope': scope,
  'exp': exp,
  'iat': iat,
  if (aud != null) 'aud': aud,
  'presentation_definition':
      presentationDefinition ??
      {'id': 'pd-1', 'input_descriptors': <Map<String, dynamic>>[]},
};

void main() {
  late MockCryptographyService mockCryptography;
  late ShareFlowService service;

  setUp(() {
    mockCryptography = MockCryptographyService();
    service = ShareFlowService(cryptography: mockCryptography);
  });

  group('when validating an OID4VP request URI', () {
    group('and the URI contains an embedded exception', () {
      test('should throw a TdkException with code parse_failure', () async {
        final uri = Uri.parse(
          'openid4vp://authorize?exception=Something+went+wrong',
        );

        await expectLater(
          () => service.validateOid4vpRequest(
            uri,
            walletDid: 'did:key:myWalletDid',
          ),
          throwsA(
            isA<TdkException>()
                .having(
                  (e) => e.code,
                  'code',
                  TdkExceptionType.parseFailure.code,
                )
                .having((e) => e.message, 'message', 'Request failed.')
                .having(
                  (e) => e.originalMessage,
                  'originalMessage',
                  'Something went wrong',
                ),
          ),
        );
      });
    });

    group('and the `request` query parameter is absent', () {
      test('should throw a TdkException with code parse_failure', () async {
        final uri = Uri.parse('openid4vp://authorize?state=abc');

        await expectLater(
          () => service.validateOid4vpRequest(
            uri,
            walletDid: 'did:key:myWalletDid',
          ),
          throwsA(
            isA<TdkException>().having(
              (e) => e.code,
              'code',
              TdkExceptionType.parseFailure.code,
            ),
          ),
        );
      });
    });

    group('and the JWT cannot be decoded', () {
      test(
        'should throw a TdkException with code parse_failure and set originalMessage',
        () async {
          when(
            () => mockCryptography.decodeJwtToken(token: any(named: 'token')),
          ).thenThrow(Exception('bad jwt'));

          final uri = Uri.parse('openid4vp://authorize?request=$validJwt');

          await expectLater(
            () => service.validateOid4vpRequest(
              uri,
              walletDid: 'did:key:myWalletDid',
            ),
            throwsA(
              isA<TdkException>()
                  .having(
                    (e) => e.code,
                    'code',
                    TdkExceptionType.parseFailure.code,
                  )
                  .having(
                    (e) => e.originalMessage,
                    'originalMessage',
                    contains('bad jwt'),
                  ),
            ),
          );
        },
      );
    });

    group('and the JWT payload is missing required fields', () {
      test('should throw a TdkException with code parse_failure', () async {
        when(
          () => mockCryptography.decodeJwtToken(token: any(named: 'token')),
        ).thenReturn({'nonce': 'only-nonce'}); // missing required fields

        final uri = Uri.parse('openid4vp://authorize?request=$validJwt');

        await expectLater(
          () => service.validateOid4vpRequest(
            uri,
            walletDid: 'did:key:myWalletDid',
          ),
          throwsA(
            isA<TdkException>()
                .having(
                  (e) => e.code,
                  'code',
                  TdkExceptionType.parseFailure.code,
                )
                .having(
                  (e) => e.message,
                  'message',
                  'JWT payload is missing required fields.',
                ),
          ),
        );
      });
    });

    group(
      'and the JWT payload contains both presentation_definition and dcql_query',
      () {
        test('should throw a TdkException with code parse_failure', () async {
          when(
            () => mockCryptography.decodeJwtToken(token: any(named: 'token')),
          ).thenReturn({
            ..._baseDecodedPayload(),
            'dcql_query': {
              'credentials': [<String, dynamic>{}],
            },
          });

          final uri = Uri.parse('openid4vp://authorize?request=$validJwt');

          await expectLater(
            () => service.validateOid4vpRequest(
              uri,
              walletDid: 'did:key:myWalletDid',
            ),
            throwsA(
              isA<TdkException>().having(
                (e) => e.code,
                'code',
                TdkExceptionType.parseFailure.code,
              ),
            ),
          );
        });
      },
    );

    group('and the JWT signature is invalid', () {
      test(
        'should throw a TdkException with code invalid_or_expired_jwt and set originalMessage',
        () async {
          when(
            () => mockCryptography.decodeJwtToken(token: any(named: 'token')),
          ).thenReturn(_baseDecodedPayload());
          when(
            () => mockCryptography.verifyJwt(
              jwtToken: any(named: 'jwtToken'),
              didKey: any(named: 'didKey'),
            ),
          ).thenReturn(
            VerifyJwtResult(
              isValid: false,
              isExpired: false,
              errorMessage: 'bad signature',
              jwtPayload: null,
            ),
          );

          final uri = Uri.parse('openid4vp://authorize?request=$validJwt');

          await expectLater(
            () => service.validateOid4vpRequest(
              uri,
              walletDid: 'did:key:myWalletDid',
            ),
            throwsA(
              isA<TdkException>()
                  .having(
                    (e) => e.code,
                    'code',
                    TdkExceptionType.invalidOrExpiredJwt.code,
                  )
                  .having(
                    (e) => e.originalMessage,
                    'originalMessage',
                    'bad signature',
                  ),
            ),
          );
        },
      );
    });

    group('and the JWT is expired', () {
      test(
        'should throw a TdkException with code invalid_or_expired_jwt',
        () async {
          when(
            () => mockCryptography.decodeJwtToken(token: any(named: 'token')),
          ).thenReturn(_baseDecodedPayload());
          when(
            () => mockCryptography.verifyJwt(
              jwtToken: any(named: 'jwtToken'),
              didKey: any(named: 'didKey'),
            ),
          ).thenReturn(
            VerifyJwtResult(
              isValid: true,
              isExpired: true,
              errorMessage: null,
              jwtPayload: null,
            ),
          );

          final uri = Uri.parse('openid4vp://authorize?request=$validJwt');

          await expectLater(
            () => service.validateOid4vpRequest(
              uri,
              walletDid: 'did:key:myWalletDid',
            ),
            throwsA(
              isA<TdkException>().having(
                (e) => e.code,
                'code',
                TdkExceptionType.invalidOrExpiredJwt.code,
              ),
            ),
          );
        },
      );
    });

    group('and the client_id_scheme is not `did`', () {
      test(
        'should throw a TdkException with code invalid_client_id_scheme',
        () async {
          when(
            () => mockCryptography.decodeJwtToken(token: any(named: 'token')),
          ).thenReturn(_baseDecodedPayload(clientIdScheme: 'x509_san_dns'));
          when(
            () => mockCryptography.verifyJwt(
              jwtToken: any(named: 'jwtToken'),
              didKey: any(named: 'didKey'),
            ),
          ).thenReturn(_validResult());

          final uri = Uri.parse(
            'openid4vp://authorize?request=$jwtWithWrongClientIdScheme',
          );

          await expectLater(
            () => service.validateOid4vpRequest(
              uri,
              walletDid: 'did:key:myWalletDid',
            ),
            throwsA(
              isA<TdkException>()
                  .having(
                    (e) => e.code,
                    'code',
                    TdkExceptionType.invalidClientIdScheme.code,
                  )
                  .having(
                    (e) => e.message,
                    'message',
                    contains('x509_san_dns'),
                  ),
            ),
          );
        },
      );
    });

    group('and the `aud` claim does not match the walletDid', () {
      test('should throw a TdkException with code invalid_audience', () async {
        when(
          () => mockCryptography.decodeJwtToken(token: any(named: 'token')),
        ).thenReturn(_baseDecodedPayload(aud: 'did:key:someOtherDid'));
        when(
          () => mockCryptography.verifyJwt(
            jwtToken: any(named: 'jwtToken'),
            didKey: any(named: 'didKey'),
          ),
        ).thenReturn(_validResult());

        final uri = Uri.parse('openid4vp://authorize?request=$validJwt');

        await expectLater(
          () => service.validateOid4vpRequest(
            uri,
            walletDid: 'did:key:myWalletDid',
          ),
          throwsA(
            isA<TdkException>()
                .having(
                  (e) => e.code,
                  'code',
                  TdkExceptionType.invalidAudience.code,
                )
                .having(
                  (e) => e.message,
                  'message',
                  'JWT aud does not match the wallet DID.',
                ),
          ),
        );
      });

      test(
        'should throw when aud is present but walletDid is null (replay protection)',
        () async {
          when(
            () => mockCryptography.decodeJwtToken(token: any(named: 'token')),
          ).thenReturn(_baseDecodedPayload(aud: 'did:key:someOtherDid'));
          when(
            () => mockCryptography.verifyJwt(
              jwtToken: any(named: 'jwtToken'),
              didKey: any(named: 'didKey'),
            ),
          ).thenReturn(_validResult());

          final uri = Uri.parse('openid4vp://authorize?request=$validJwt');

          await expectLater(
            () => service.validateOid4vpRequest(
              uri,
              walletDid: 'did:key:myWalletDid',
            ),
            throwsA(
              isA<TdkException>()
                  .having(
                    (e) => e.code,
                    'code',
                    TdkExceptionType.invalidAudience.code,
                  )
                  .having((e) => e.message, 'message', contains('walletDid')),
            ),
          );
        },
      );

      test('should not throw when aud is absent (aud check skipped)', () async {
        when(
          () => mockCryptography.decodeJwtToken(token: any(named: 'token')),
        ).thenReturn(_baseDecodedPayload());
        when(
          () => mockCryptography.verifyJwt(
            jwtToken: any(named: 'jwtToken'),
            didKey: any(named: 'didKey'),
          ),
        ).thenReturn(_validResult());

        final uri = Uri.parse('openid4vp://authorize?request=$validJwt');

        await expectLater(
          service.validateOid4vpRequest(uri, walletDid: 'did:key:myWalletDid'),
          completes,
        );
      });

      test(
        'should not throw when aud is absent and walletDid is null',
        () async {
          when(
            () => mockCryptography.decodeJwtToken(token: any(named: 'token')),
          ).thenReturn(_baseDecodedPayload());
          when(
            () => mockCryptography.verifyJwt(
              jwtToken: any(named: 'jwtToken'),
              didKey: any(named: 'didKey'),
            ),
          ).thenReturn(_validResult());

          final uri = Uri.parse('openid4vp://authorize?request=$validJwt');

          await expectLater(service.validateOid4vpRequest(uri), completes);
        },
      );

      test('should not throw when aud matches walletDid exactly', () async {
        when(
          () => mockCryptography.decodeJwtToken(token: any(named: 'token')),
        ).thenReturn(_baseDecodedPayload(aud: 'did:key:myWalletDid'));
        when(
          () => mockCryptography.verifyJwt(
            jwtToken: any(named: 'jwtToken'),
            didKey: any(named: 'didKey'),
          ),
        ).thenReturn(_validResult());

        final uri = Uri.parse('openid4vp://authorize?request=$validJwt');

        await expectLater(
          service.validateOid4vpRequest(uri, walletDid: 'did:key:myWalletDid'),
          completes,
        );
      });
    });

    group('and the client_id is empty', () {
      test('should throw a TdkException with code missing_client_id', () async {
        when(
          () => mockCryptography.decodeJwtToken(token: any(named: 'token')),
        ).thenReturn(_baseDecodedPayload(clientId: ''));
        when(
          () => mockCryptography.verifyJwt(
            jwtToken: any(named: 'jwtToken'),
            didKey: any(named: 'didKey'),
          ),
        ).thenReturn(_validResult());

        final uri = Uri.parse(
          'openid4vp://authorize?request=$jwtWithEmptyClientId',
        );

        await expectLater(
          () => service.validateOid4vpRequest(
            uri,
            walletDid: 'did:key:myWalletDid',
          ),
          throwsA(
            isA<TdkException>().having(
              (e) => e.code,
              'code',
              TdkExceptionType.missingClientId.code,
            ),
          ),
        );
      });
    });

    group('and the response_mode is not `direct_post`', () {
      test(
        'should throw a TdkException with code invalid_response_mode',
        () async {
          when(
            () => mockCryptography.decodeJwtToken(token: any(named: 'token')),
          ).thenReturn(_baseDecodedPayload(responseMode: 'query'));
          when(
            () => mockCryptography.verifyJwt(
              jwtToken: any(named: 'jwtToken'),
              didKey: any(named: 'didKey'),
            ),
          ).thenReturn(_validResult());

          final uri = Uri.parse(
            'openid4vp://authorize?request=$jwtWithWrongResponseMode',
          );

          await expectLater(
            () => service.validateOid4vpRequest(
              uri,
              walletDid: 'did:key:myWalletDid',
            ),
            throwsA(
              isA<TdkException>().having(
                (e) => e.code,
                'code',
                TdkExceptionType.invalidResponseMode.code,
              ),
            ),
          );
        },
      );
    });

    group('and the response_type is not `vp_token`', () {
      test(
        'should throw a TdkException with code invalid_response_type',
        () async {
          when(
            () => mockCryptography.decodeJwtToken(token: any(named: 'token')),
          ).thenReturn(_baseDecodedPayload(responseType: 'code'));
          when(
            () => mockCryptography.verifyJwt(
              jwtToken: any(named: 'jwtToken'),
              didKey: any(named: 'didKey'),
            ),
          ).thenReturn(_validResult());

          final uri = Uri.parse('openid4vp://authorize?request=$validJwt');

          await expectLater(
            () => service.validateOid4vpRequest(
              uri,
              walletDid: 'did:key:myWalletDid',
            ),
            throwsA(
              isA<TdkException>().having(
                (e) => e.code,
                'code',
                TdkExceptionType.invalidResponseType.code,
              ),
            ),
          );
        },
      );
    });

    group('and the purpose field is malformed JSON', () {
      test('should return an Oid4vpShareRequest with null purpose', () async {
        when(
          () => mockCryptography.decodeJwtToken(token: any(named: 'token')),
        ).thenReturn(
          _baseDecodedPayload(
            presentationDefinition: {
              'id': 'pd-1',
              'input_descriptors': <Map<String, dynamic>>[],
              'purpose': '{not-valid-json',
            },
          ),
        );
        when(
          () => mockCryptography.verifyJwt(
            jwtToken: any(named: 'jwtToken'),
            didKey: any(named: 'didKey'),
          ),
        ).thenReturn(_validResult());

        final result =
            await service.validateOid4vpRequest(
                  Uri.parse('openid4vp://authorize?request=$validJwt'),
                )
                as PexShareRequest;

        expect(result.purpose, isNull);
      });
    });

    group('and the URI is valid', () {
      test('should call verifyJwt with the clientId as didKey', () async {
        when(
          () => mockCryptography.decodeJwtToken(token: any(named: 'token')),
        ).thenReturn(_baseDecodedPayload(clientId: 'did:key:z6Mk'));
        when(
          () => mockCryptography.verifyJwt(
            jwtToken: any(named: 'jwtToken'),
            didKey: 'did:key:z6Mk',
          ),
        ).thenReturn(_validResult());

        await service.validateOid4vpRequest(
          Uri.parse('openid4vp://authorize?request=$validJwt'),
        );

        verify(
          () => mockCryptography.verifyJwt(
            jwtToken: any(named: 'jwtToken'),
            didKey: 'did:key:z6Mk',
          ),
        ).called(1);
      });

      test('should return an Oid4vpShareRequest with no purpose', () async {
        when(
          () => mockCryptography.decodeJwtToken(token: any(named: 'token')),
        ).thenReturn(_baseDecodedPayload());
        when(
          () => mockCryptography.verifyJwt(
            jwtToken: any(named: 'jwtToken'),
            didKey: any(named: 'didKey'),
          ),
        ).thenReturn(_validResult());

        final result =
            await service.validateOid4vpRequest(
                  Uri.parse('openid4vp://authorize?request=$validJwt'),
                )
                as PexShareRequest;

        expect(result.request.nonce, 'test-nonce');
        expect(result.request.state, 'test-state');
        expect(result.request.clientId, 'did:key:z6Mk');
        expect(result.request.clientMetadata, {'client_name': 'Test Verifier'});
        expect(
          result.request.acceptResponseUri,
          'https://example.com/response',
        );
        expect(
          result.request.rejectResponseUri,
          'https://example.com/response',
        );
        expect(result.request.responseMode, 'direct_post');
        expect(result.request.scope, 'openid');
        expect(result.presentationDefinition['id'], 'pd-1');
        expect(result.purpose, isNull);
        expect(result.jwtAssertion, validJwt);
      });

      test(
        'should return an Oid4vpShareRequest with purpose when present',
        () async {
          when(
            () => mockCryptography.decodeJwtToken(token: any(named: 'token')),
          ).thenReturn(
            _baseDecodedPayload(
              presentationDefinition: {
                'id': 'pd-1',
                'input_descriptors': <Map<String, dynamic>>[],
                'purpose':
                    '{"data_collection_purpose":"KYC verification","request_description":"Verify identity"}',
              },
            ),
          );
          when(
            () => mockCryptography.verifyJwt(
              jwtToken: any(named: 'jwtToken'),
              didKey: any(named: 'didKey'),
            ),
          ).thenReturn(_validResult());

          final result =
              await service.validateOid4vpRequest(
                    Uri.parse(
                      'openid4vp://authorize?request=$validJwtWithPurpose',
                    ),
                  )
                  as PexShareRequest;

          expect(result.purpose, isNotNull);
          expect(result.purpose!.dataCollectionPurpose, 'KYC verification');
          expect(result.purpose!.requestDescription, 'Verify identity');
          expect(result.purpose!.isValid, isTrue);
        },
      );

      test(
        'should return an Oid4vpShareRequest with null purpose when purpose isValid is false',
        () async {
          when(
            () => mockCryptography.decodeJwtToken(token: any(named: 'token')),
          ).thenReturn(
            _baseDecodedPayload(
              presentationDefinition: {
                'id': 'pd-1',
                'input_descriptors': <Map<String, dynamic>>[],
                // data_collection_purpose is null → isValid == false
                'purpose': '{"data_collection_purpose":null}',
              },
            ),
          );
          when(
            () => mockCryptography.verifyJwt(
              jwtToken: any(named: 'jwtToken'),
              didKey: any(named: 'didKey'),
            ),
          ).thenReturn(_validResult());

          final result =
              await service.validateOid4vpRequest(
                    Uri.parse('openid4vp://authorize?request=$validJwt'),
                  )
                  as PexShareRequest;

          expect(result.purpose, isNull);
        },
      );
    });
  });
}
