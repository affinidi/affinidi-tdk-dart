import 'package:affinidi_tdk_cryptography/affinidi_tdk_cryptography.dart';
import 'package:affinidi_tdk_vault_iota/affinidi_tdk_vault_iota.dart';
import 'package:ssi/ssi.dart';

/// This example demonstrates how a third-party wallet (non-Affinidi)
/// can integrate with the TDK to handle OID4VP share flows.
///
/// Key differences from Affinidi wallets:
/// - Use your own `DidSigner` implementation (Ed25519, secp256k1, P-256, etc.)
/// - The same services work regardless of wallet provider or key type
/// - The VP signature remains valid for any OID4VP verifier
///
/// This is useful for:
///   • Enterprise wallets with existing key infrastructure
///   • Wallets using hardware security modules
///   • Multi-signature wallets
///   • Wallets built on alternate DID methods (did:web, did:jwk, etc.)
Future<void> main() async {
  // ─────────────────────────────────────────────────────────────────────────
  // Step 1: Obtain a DidSigner for the holder's key
  // ─────────────────────────────────────────────────────────────────────────
  //
  // In a real application, this comes from your wallet's key management:
  //   • Load the holder's DID and signing key from secure storage
  //   • Initialize a signer using your crypto library (pointycastle, cryptography, etc.)
  //   • Ensure the key type matches the DID method (e.g., Ed25519 for did:key)
  //
  final holderSigner = await _createCustomSigner();

  // ─────────────────────────────────────────────────────────────────────────
  // Step 2: Parse the OID4VP request (same as any wallet)
  // ─────────────────────────────────────────────────────────────────────────
  //
  // This step is identical for all wallets. The request typically comes from:
  //   • A QR code scan (contains an authorization request URI)
  //   • A deep link (openid4vp://authorize?request=...)
  //   • An API response
  //
  // IMPORTANT: Replace <jwt-from-verifier> with an actual JWT from an OID4VP
  // verifier. You can obtain a real JWT by:
  //   1. Using the verifier test app: packages/app/
  //   2. Running an OID4VP verifier that generates share requests
  //   3. Decoding a JWT you've received from a real verifier
  //
  // Example JWT structure (header.payload.signature):
  //   - header: { "alg": "ES256", "typ": "JWT", "kid": "verifier-key-id" }
  //   - payload: {
  //       "iss": "https://verifier.example.com",
  //       "aud": "wallet-did",
  //       "presentation_definition": { ... },
  //       "response_type": "vp_token",
  //       "response_mode": "form_post",
  //       "client_id": "https://verifier.example.com",
  //       "redirect_uri": "https://verifier.example.com/callback",
  //       "nonce": "random-value",
  //       "iat": ...,
  //       "exp": ...
  //     }
  //
  const jwtFromVerifier = '<jwt-from-verifier>';
  final uri = Uri.parse('openid4vp://authorize?request=$jwtFromVerifier');
  const walletDid = 'did:key:z6MkExample...'; // The holder's DID

  try {
    final cryptography = CryptographyService();
    final flowService = ShareFlowService(cryptography: cryptography);
    
    final shareRequest = await flowService.validateOid4vpRequest(
      uri,
      walletDid: walletDid,
    );

    print('─ Request parsed successfully');
    print('Client ID (verifier): ${shareRequest.request.clientId}');
    print('Response mode: ${shareRequest.request.responseMode}');
    print('Callback URI: ${shareRequest.request.acceptResponseUri}');

    // ───────────────────────────────────────────────────────────────────────
    // Step 3: Match vault credentials against the request
    // ───────────────────────────────────────────────────────────────────────
    //
    // Load your wallet's credentials and check which ones satisfy the request.
    // This step is also wallet-agnostic.
    //
    final matcher = CredentialMatcherService();
    final vaultCredentials = <ParsedVerifiableCredential<dynamic>>[
      // In a real app, load from secure storage:
      // ...await _loadVaultCredentials()
    ];

    final matchResult = await matcher.match(shareRequest, vaultCredentials);

    if (!matchResult.hasEnoughVCsAvailableToShare) {
      print('✗ Not enough credentials available to satisfy this request.');
      return;
    }

    print('─ Credentials matched');
    print('Available: ${matchResult.availableCredentials.length}');
    print('Recommended: ${matchResult.recommendedMaximumVCs.length}');

    // ───────────────────────────────────────────────────────────────────────
    // Step 4: Present to user and get consent
    // ───────────────────────────────────────────────────────────────────────
    //
    // Show a consent screen listing which credentials will be shared.
    // For this example, we assume the user approves the recommended set.
    //
    final selectedCredentials = vaultCredentials
        .where(matchResult.recommendedMaximumVCs.contains)
        .toList();

    print('─ User approved sharing ${selectedCredentials.length} credential(s)');

    // ───────────────────────────────────────────────────────────────────────
    // Step 5: Build and submit the Verifiable Presentation
    // ───────────────────────────────────────────────────────────────────────
    //
    // This is the key integration point for third-party wallets:
    //   • Pass your custom `DidSigner` (holderSigner)
    //   • The service handles PEX vs DCQL internally
    //   • The VP is signed with your wallet's key, not Affinidi's
    //
    final responseService = IotaShareResponseService(signer: holderSigner);
    final redirectUri = await responseService.submitShareResponse(
      shareRequest: shareRequest,
      selectedCredentials: selectedCredentials,
      acceptResponseUri: shareRequest.request.acceptResponseUri,
    );

    print('─ VP submitted successfully');
    print('Redirect URI: ${redirectUri ?? '(none)'}');

    // ───────────────────────────────────────────────────────────────────────
    // Step 6: (Optional) Handle rejection
    // ───────────────────────────────────────────────────────────────────────
    //
    // If the user declines to share, send a rejection:
    //
    // await responseService.rejectShareResponse(
    //   shareRequest: shareRequest,
    //   rejectResponseUri: shareRequest.request.rejectResponseUri,
    // );
    // print('─ Share request rejected');
  } on TdkException catch (e) {
    print('✗ OID4VP error [${e.code}]: ${e.message}');
  }
}

/// Creates a custom DidSigner for demonstration.
///
/// In a real third-party wallet:
///   • Load the holder's existing key material from secure storage
///   • Initialize a signer with your crypto library
///   • Support multiple key types (Ed25519, secp256k1, P-256, RSA, etc.)
///   • Use hardware security modules if available
Future<DidSigner> _createCustomSigner() async {
  // Example: Using the `ssi` package with in-memory keys
  // (In production, use secure key storage)
  final wallet = PersistentWallet(InMemoryKeyStore());
  final keyPair = await wallet.generateKey(keyType: KeyType.ed25519);

  final didManager = DidKeyManager(wallet: wallet, store: InMemoryDidStore());
  await didManager.addVerificationMethod(keyPair.id);

  return didManager.getSigner(
    didManager.assertionMethod.first,
    signatureScheme: SignatureScheme.ed25519,
  );
}

/// ──────────────────────────────────────────────────────────────────────────
/// Integration Checklist for Third-Party Wallets
/// ──────────────────────────────────────────────────────────────────────────
///
/// Before using the TDK in your wallet:
///
/// ☐ Implement a `DidSigner` that uses your wallet's key infrastructure
///   (or use the `ssi` package if compatible)
///
/// ☐ Load the holder's DID and credentials from secure storage
///
/// ☐ Implement a UI flow:
///   1. Scan/receive the OID4VP request URI
///   2. Call `ShareFlowService.validateOid4vpRequest()`
///   3. Match credentials using `CredentialMatcherService`
///   4. Show the user which credentials will be shared
///   5. Get consent
///   6. Call `IotaShareResponseService.submitShareResponse()`
///
/// ☐ Handle errors gracefully (TdkException with typed error codes)
///
/// ☐ Test with real verifiers (use a test/dev verifier first)
///
/// ☐ Optionally save consent records via `IotaConsentRecordService`
///
/// ──────────────────────────────────────────────────────────────────────────
