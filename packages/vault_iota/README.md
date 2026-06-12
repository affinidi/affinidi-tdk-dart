# Affinidi TDK - Vault Iota

The Affinidi TDK - Vault Iota package provides the libraries to handle the OID4VP (OpenID for Verifiable Presentations) share flow with Affinidi Iota Framework. It takes a verifier's request from URL ingestion through to Verifiable Presentation submission, matching the requested credentials against the ones held in the user's Vault.

## Key Features

- Parse and validate Iota OID4VP request URIs.
- Classify what a verifier is requesting and extract the requested credentials and purpose metadata.
- Match the requested credentials against the credentials held in the user's Vault.
- Build and submit a signed Verifiable Presentation in response to the verifier's request.
- Manage consent records and support automatic consent for trusted verifiers.
- Storage-agnostic — the package has no opinion on where your credentials or consent records live.

## Requirements

- Dart SDK version ^3.8.0

## Installation

Run:

```bash
dart pub add affinidi_tdk_vault_iota
```

or manually add the package to your `pubspec.yaml` file:

```yaml
dependencies:
  affinidi_tdk_vault_iota: ^<version_number>
```

and then run the command below to install the package:

```bash
dart pub get
```

## Usage

After successfully installing the package, import it into your code.

```dart
import 'package:affinidi_tdk_vault_iota/affinidi_tdk_vault_iota.dart';
```

### Step 1 — Parse the OID4VP request URI

```dart
final service = ShareFlowService(cryptography: myCryptographyService);

final shareRequest = await service.validateOid4vpRequest(
  Uri.parse('openid4vp://authorize?request=<jwt>'),
  walletDid: 'did:key:z6Mk...', // optional — validates the `aud` claim
);

// shareRequest.request exposes the normalised parameters
// (clientId, nonce, acceptResponseUri, state, ...).
```

`validateOid4vpRequest` returns an `Oid4vpShareRequest`. Treat it as an
opaque handle — the package routes between PEX and DCQL internally, so you
pass the same `shareRequest` to the credential-matching and submission
services regardless of which query protocol the verifier used.

### Step 2 — Find matching credentials

Pass the `shareRequest` and the credentials held in the user's Vault to
`CredentialMatcherService.match()`. The service routes to PEX or DCQL
internally and returns a protocol-agnostic `MatchedCredentialsResult`.

```dart
final matcher = CredentialMatcherService();

final result = await matcher.match(shareRequest, allVaultCredentials);

if (!result.hasEnoughVCsAvailableToShare) {
  // The Vault does not hold enough credentials to satisfy the request.
  return;
}

// A sensible default selection to present to the user, or submit directly.
final selectedVcs = result.recommendedMaximumVCs;
```

`allVaultCredentials` is the `List<VerifiableCredential>` you load from your
own storage. Use `result.groups` to enforce per-group minimum and maximum
selection counts when building a selection UI.

### Step 3 — Submit (or reject) the Verifiable Presentation

Use `IotaShareResponseService` to build a signed VP from the selected
credentials and POST it to the verifier. It handles both PEX and DCQL
responses internally and uses the request `nonce` and `clientId` to bind the
presentation for replay protection.

`IotaShareResponseService` needs a `DidSigner` that controls the holder's
signing key. In a real application this comes from your wallet integration;
the snippet below builds one from an `ssi` wallet:

```dart
final wallet = PersistentWallet(InMemoryKeyStore());
final keyPair = await wallet.generateKey(keyType: KeyType.ed25519);

final didManager = DidKeyManager(wallet: wallet, store: InMemoryDidStore());
await didManager.addVerificationMethod(keyPair.id);

final signer = await didManager.getSigner(
  didManager.assertionMethod.first,
  signatureScheme: SignatureScheme.ed25519,
);
```

Then submit (or reject) the presentation:

```dart
final responseService = IotaShareResponseService(signer: signer);

// On user approval — build and submit the VP.
final redirectUri = await responseService.submitShareResponse(
  shareRequest: shareRequest,
  selectedCredentials: selectedVcs.cast<ParsedVerifiableCredential<dynamic>>(),
  acceptResponseUri: shareRequest.request.acceptResponseUri,
);

// On user rejection — notify the verifier.
await responseService.rejectShareResponse(
  shareRequest: shareRequest,
  rejectResponseUri: shareRequest.request.rejectResponseUri,
);
```

Both methods return the redirect `Uri` that the verifier optionally includes
in its response. When non-`null`, send the user to this URL to complete the
flow on the verifier's side (for example, back to the verifier's web app);
when `null`, the verifier expects no follow-up navigation. Both methods throw
a `TdkException` with code `submission_failed` if the call fails.

### Step 4 — Persist a consent record

After a successful VP submission, call `IotaConsentRecordService.saveConsentRecord()`
to store a history entry for the share event. The service is storage-agnostic —
you supply the backend by implementing `ConsentStorage`.

#### Using the built-in Flutter Secure Storage backend

If your app already depends on `affinidi_tdk_vault_flutter_utils`, use the
provided `FlutterSecureConsentStorage`:

```dart
import 'package:affinidi_tdk_vault_flutter_utils/vault_flutter_utils.dart';
import 'package:affinidi_tdk_vault_iota/affinidi_tdk_vault_iota.dart';

final consentService = IotaConsentRecordService(
  store: FlutterSecureConsentStorage(),
  cryptography: myCryptographyService,
  shareResponseService: responseService,
);

// Call this after a successful submitShareResponse:
await consentService.saveConsentRecord(
  requestHash: requestHash, // stable per-verifier fingerprint you compute
  clientId: shareRequest.request.clientId,
  verifierMetadata: verifierMetadata,
  profileId: profileId,
  profileName: profileName,
  vaultId: holderVaultId,
  sharedVcs: selectedVcs,
  claimedVcTypesCsv: 'EmailV1VC,PhoneNumberV1VC',
  isAutoShareEnabled: false,
);
```

#### Bringing your own storage backend

Implement `ConsentStorage` with any persistence technology you prefer
(Drift, Hive, SQLite, a remote API, etc.):

```dart
class MyConsentStore implements ConsentStorage {
  @override
  Future<void> saveOrUpdate(IotaConsentRecord record) async {
    // upsert by record.hash in your database
  }

  @override
  Future<IotaConsentRecord?> findByRequestHash(String requestHash) async {
    // return the most recent matching record, or null
  }

  @override
  Future<List<IotaConsentRecord>> findAllByRequestHash(String requestHash) async {
    // return all matching records, or an empty list
  }
}

final consentService = IotaConsentRecordService(
  store: MyConsentStore(),
  cryptography: myCryptographyService,
  shareResponseService: responseService,
);
```

## Error handling

All errors are thrown as `TdkException` with one of the following codes:

| Code | Description |
|------|-------------|
| `parse_failure` | The `request` query parameter is absent, the JWT could not be decoded, or a required payload field is missing. |
| `invalid_or_expired_jwt` | The JWT signature is invalid or the token has expired. |
| `invalid_client_id_scheme` | The `client_id_scheme` in the request is not `did`. |
| `invalid_audience` | The JWT `aud` claim does not match the `walletDid` passed to `validateOid4vpRequest`. |
| `missing_client_id` | The `client_id` field is missing from the request. |
| `invalid_client_id` | An empty `clientId` was passed to the verifier metadata service. |
| `invalid_response_mode` | `response_mode` is not `direct_post`. |
| `invalid_response_type` | `response_type` is not `vp_token`. |
| `invalid_presentation_definition` | The Presentation Definition is structurally invalid. |
| `invalid_dcql_query` | The DCQL query is structurally invalid. |
| `unsupported_multiple_idv_types` | An IDV input descriptor requests more than two VC types. |
| `replay_detected` | The OID4VP request nonce has already been consumed — indicates a JWT replay attempt. |
| `empty_credentials` | `submitShareResponse` was called with an empty credentials list. |
| `incomplete_credential_selection` | The selected credentials do not cover every required DCQL credential query. |
| `submission_failed` | Submitting the VP to the verifier callback failed (network error, invalid state, or non-2xx response). |
| `failed_to_fetch_verifier_metadata` | The verifier's client metadata could not be fetched or parsed. |
| `failed_to_persist_consent_record` | Persisting a consent record to the `ConsentStorage` backend failed. |
| `failed_to_read_consent_record` | Reading a consent record from the `ConsentStorage` backend failed. |

## Support & feedback

If you face any issues or have suggestions, please don't hesitate to contact us using [this link](https://share.hsforms.com/1i-4HKZRXSsmENzXtPdIG4g8oa2v).

### Reporting technical issues

If you have a technical issue with the package's codebase, you can also create an issue directly in GitHub.

1. Ensure the bug was not already reported by searching on GitHub under
   [Issues](https://github.com/affinidi/affinidi-tdk/issues).

2. If you're unable to find an open issue addressing the problem,
   [open a new one](https://github.com/affinidi/affinidi-tdk/issues/new).
   Be sure to include a **title and clear description**, as much relevant information as possible,
   and a **code sample** or an **executable test case** demonstrating the expected behaviour that is not occurring.

## Contributing

Want to contribute?

Head over to our [CONTRIBUTING](https://github.com/affinidi/affinidi-tdk/blob/main/CONTRIBUTING.md) guidelines.
