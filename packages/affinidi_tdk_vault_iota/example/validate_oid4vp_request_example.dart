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

    // The verifier's client_id (the verifier DID)
    print('Client ID: ${shareRequest.request.clientId}');

    // The Presentation Definition lists the credentials the verifier needs
    print('Presentation Definition: ${shareRequest.presentationDefinition}');

    // Optional human-readable purpose metadata
    if (shareRequest.purpose?.isValid == true) {
      print('Purpose: ${shareRequest.purpose!.dataCollectionPurpose}');
    }

    // shareRequest.jwtAssertion carries the raw JWT for VP submission
    print('JWT assertion available: ${shareRequest.jwtAssertion.isNotEmpty}');

    // Next step: query your credential storage with the presentationDefinition,
    // then build and submit a Verifiable Presentation to the verifier.
  } on TdkException catch (e) {
    print('OID4VP validation failed [${e.code}]: ${e.message}');
  }
}
