import 'package:affinidi_tdk_cryptography/affinidi_tdk_cryptography.dart';
import 'package:affinidi_tdk_vault_iota/affinidi_tdk_vault_iota.dart';
import 'package:ssi/ssi.dart';

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

    // shareRequest.jwtAssertion carries the raw JWT for VP submission
    print('JWT assertion available: ${shareRequest.jwtAssertion.isNotEmpty}');

    // Whether the verifier used PEX or DCQL is an internal detail: the same
    // Oid4vpShareRequest flows through the services below, which route to the
    // correct protocol transparently.

    // Match the request against the credentials in the user's vault.
    // In a real application, `vaultCredentials` comes from the user's vault.
    final matcher = CredentialMatcherService();
    final vaultCredentials = <ParsedVerifiableCredential<dynamic>>[];
    final matchResult = await matcher.match(shareRequest, vaultCredentials);

    if (!matchResult.hasEnoughVCsAvailableToShare) {
      print(
        'The vault does not hold enough credentials to satisfy this request.',
      );
      return;
    }

    print(
      'Credentials available to share: '
      '${matchResult.availableCredentials.length}',
    );
    print(
      'Recommended credentials to share: '
      '${matchResult.recommendedMaximumVCs.length}',
    );

    // Pick the vault credentials the matcher recommended sharing.
    final selectedCredentials = vaultCredentials
        .where(matchResult.recommendedMaximumVCs.contains)
        .toList();

    // Build and submit the Verifiable Presentation to the verifier. The signer
    // controls the holder's key; in a real application it comes from your
    // wallet integration. The response service handles PEX and DCQL
    // transparently and POSTs the VP to the request's acceptResponseUri.
    final responseService = IotaShareResponseService(signer: await _signer());
    final redirectUri = await responseService.submitShareResponse(
      shareRequest: shareRequest,
      selectedCredentials: selectedCredentials,
      acceptResponseUri: shareRequest.request.acceptResponseUri,
    );

    print('Share submitted. Redirect URI: ${redirectUri ?? '(none)'}');
  } on TdkException catch (e) {
    print('OID4VP validation failed [${e.code}]: ${e.message}');
  }
}

/// Builds a demo [DidSigner] backed by an in-memory wallet.
///
/// In a real application the signer comes from your wallet integration and
/// controls the holder's signing key.
Future<DidSigner> _signer() async {
  final wallet = PersistentWallet(InMemoryKeyStore());
  final keyPair = await wallet.generateKey(keyType: KeyType.ed25519);
  final didManager = DidKeyManager(wallet: wallet, store: InMemoryDidStore());
  await didManager.addVerificationMethod(keyPair.id);
  return didManager.getSigner(
    didManager.assertionMethod.first,
    signatureScheme: SignatureScheme.ed25519,
  );
}
