import 'package:affinidi_tdk_vault_iota/affinidi_tdk_vault_iota.dart';
import 'package:affinidi_tdk_vault_iota/src/models/iota_payload.dart';
import 'package:dcql/dcql.dart';
import 'package:test/test.dart';

void main() {
  // Minimal valid field values reused across tests.
  const base = (
    nonce: 'nonce',
    state: 'state',
    clientId: 'did:key:verifier',
    clientIdScheme: 'did',
    responseUri: 'https://verifier.example.com/cb',
    responseType: 'vp_token',
    responseMode: 'direct_post',
    exp: 9999999999,
    iat: 1000000000,
  );

  const pd = <String, dynamic>{'id': 'def-1', 'input_descriptors': <dynamic>[]};

  final dcql = DcqlCredentialQuery(
    credentials: [DcqlCredential(id: 'q-1', format: CredentialFormat.ldpVc)],
  );

  IotaPayload buildPayload({
    Map<String, dynamic>? presentationDefinition,
    DcqlCredentialQuery? dcqlQuery,
  }) => IotaPayload(
    nonce: base.nonce,
    state: base.state,
    clientId: base.clientId,
    clientIdScheme: base.clientIdScheme,
    responseUri: base.responseUri,
    responseType: base.responseType,
    responseMode: base.responseMode,
    exp: base.exp,
    iat: base.iat,
    presentationDefinition: presentationDefinition,
    dcqlQuery: dcqlQuery,
  );

  group('IotaPayload constructor', () {
    test('accepts a payload with only presentationDefinition', () {
      expect(() => buildPayload(presentationDefinition: pd), returnsNormally);
    });

    test('accepts a payload with only dcqlQuery', () {
      expect(() => buildPayload(dcqlQuery: dcql), returnsNormally);
    });

    test('throws TdkException when both fields are provided', () {
      expect(
        () => buildPayload(presentationDefinition: pd, dcqlQuery: dcql),
        throwsA(
          isA<TdkException>().having(
            (e) => e.code,
            'code',
            TdkExceptionType.parseFailure.code,
          ),
        ),
      );
    });

    test('throws TdkException when neither field is provided', () {
      expect(
        buildPayload,
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
}
