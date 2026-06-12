import 'package:affinidi_tdk_cryptography/affinidi_tdk_cryptography.dart';
import 'package:affinidi_tdk_vault_iota/affinidi_tdk_vault_iota.dart';

/// This example demonstrates how to parse and validate an Iota OID4VP request URI.
Future<void> main() async {
  // Create a CryptographyService instance.
  // In a real application this would come from your dependency injection container.
  final cryptography = CryptographyService();

  final service = ShareFlowService(cryptography: cryptography);

  // The OID4VP request URI typically comes from:
  // - A QR code scan
  // - A deep link
  // - An API response
  final uri = Uri.parse('openid4vp://authorize?request=<your-request-jwt>');

  // Optionally supply the wallet DID to validate the `aud` claim in the JWT.
  const walletDid = 'did:key:z6Mk...';

  try {
    final shareRequest = await service.validateOid4vpRequest(
      uri,
      walletDid: walletDid,
    );

    // shareRequest.request exposes the normalised parameters.
    print('Verifier DID: ${shareRequest.request.clientId}');
    print('Accept response URI: ${shareRequest.request.acceptResponseUri}');

    // Whether the verifier used PEX or DCQL is an internal detail: pass the
    // same Oid4vpShareRequest to CredentialMatcherService and
    // IotaShareResponseService — they route to the correct protocol
    // transparently.
  } on TdkException catch (e) {
    print('OID4VP validation failed [${e.code}]: ${e.message}');
  }
}
