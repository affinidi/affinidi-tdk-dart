import 'package:affinidi_tdk_cryptography/affinidi_tdk_cryptography.dart';
import 'package:affinidi_tdk_vault_iota/affinidi_tdk_vault_iota.dart';
import 'package:affinidi_tdk_vault_iota/src/models/share_requirements.dart'
    show DcqlShareRequest, PexShareRequest;

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

    // Inspect PEX or DCQL fields depending on the query type
    switch (shareRequest) {
      case PexShareRequest pex:
        print('Presentation Definition: ${pex.presentationDefinition}');
        if (pex.purpose?.isValid == true) {
          print('Purpose: ${pex.purpose!.dataCollectionPurpose}');
        }
      case DcqlShareRequest dcql:
        print(
          'DCQL credentials requested: ${dcql.dcqlQuery.credentials.length}',
        );
    }

    // shareRequest.jwtAssertion carries the raw JWT for VP submission
    print('JWT assertion available: ${shareRequest.jwtAssertion.isNotEmpty}');

    // Next step: pass shareRequest to CredentialMatcherService.match() and
    // IotaShareResponseService.submitShareResponse() — both handle PEX and
    // DCQL transparently.
  } on TdkException catch (e) {
    print('OID4VP validation failed [${e.code}]: ${e.message}');
  }
}
