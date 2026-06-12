import 'package:affinidi_tdk_cryptography/affinidi_tdk_cryptography.dart';
import 'package:affinidi_tdk_vault_iota/affinidi_tdk_vault_iota.dart';
import 'package:ssi/ssi.dart';

/// This example demonstrates how to match credentials against an OID4VP request
/// and submit (or reject) a Verifiable Presentation to the verifier.
///
/// It assumes you have already parsed the request using [ShareFlowService] and
/// loaded the credentials from your vault. See validate_oid4vp_request_example.dart
/// for the previous step.
Future<void> main() async {
  final cryptography = CryptographyService();

  final service = ShareFlowService(cryptography: cryptography);

  final uri = Uri.parse('openid4vp://authorize?request=<your-request-jwt>');
  final shareRequest = await service.validateOid4vpRequest(
    uri,
    walletDid: 'did:key:z6Mk...',
  );

  // --- Step 2: Match credentials ---

  // Load all credentials from your vault storage.
  // In a real application this comes from your own persistence layer.
  final allVaultCredentials = <VerifiableCredential>[];

  final matcher = CredentialMatcherService();
  final result = await matcher.match(shareRequest, allVaultCredentials);

  if (!result.hasEnoughVCsAvailableToShare) {
    print('Not enough credentials available to satisfy the request.');
    return;
  }

  // Use the recommended set as the default selection, or build a selection UI
  // using result.groups to enforce per-group min/max counts.
  final selectedVcs = result.recommendedMaximumVCs;

  print('Credentials selected: ${selectedVcs.length}');

  // --- Step 3: Submit (or reject) the VP ---

  // Create a DidSigner that controls the holder's signing key.
  // In a real application this comes from your wallet integration.
  final wallet = PersistentWallet(InMemoryKeyStore());
  final keyPair = await wallet.generateKey(keyType: KeyType.ed25519);
  final didManager = DidKeyManager(wallet: wallet, store: InMemoryDidStore());
  await didManager.addVerificationMethod(keyPair.id);
  final signer = await didManager.getSigner(
    didManager.assertionMethod.first,
    signatureScheme: SignatureScheme.ed25519,
  );

  final responseService = IotaShareResponseService(signer: signer);

  try {
    // On user approval — build and submit the VP.
    final redirectUri = await responseService.submitShareResponse(
      shareRequest: shareRequest,
      selectedCredentials: selectedVcs
          .cast<ParsedVerifiableCredential<dynamic>>(),
      acceptResponseUri: shareRequest.request.acceptResponseUri,
    );

    print('Share submitted successfully.');

    // When non-null, navigate the user to this URL to complete the flow on
    // the verifier's side (e.g. back to the verifier's web app).
    if (redirectUri != null) {
      print('Redirect to: $redirectUri');
    }
  } on TdkException catch (e) {
    print('VP submission failed [${e.code}]: ${e.message}');
  }

  // On user rejection — notify the verifier instead of submitting.
  // await responseService.rejectShareResponse(
  //   shareRequest: shareRequest,
  //   rejectResponseUri: shareRequest.request.rejectResponseUri,
  // );
}
