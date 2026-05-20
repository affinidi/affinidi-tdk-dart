# Affinidi TDK - Vault Iota

The Affinidi TDK Vault Iota package provides OID4VP share flow support for Iota. It handles parsing and validating Iota OID4VP request URIs so your application can present credentials in response to a verifier's request.

## Key Features

- Parse and validate Iota OID4VP request URIs.
- Verify JWT signatures and expiry using your `CryptographyService`.
- Validate `aud`, `client_id_scheme`, `client_id`, and `response_mode` claims.
- Extract the `Presentation Definition` and optional purpose metadata from the request.
- Storage-agnostic — the package has no opinion on where your credentials live.

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

// Inspect what the verifier is asking for
print(shareRequest.request.nonce);
print(shareRequest.presentationDefinition);
print(shareRequest.purpose?.dataCollectionPurpose);
```

### Step 2 — Find matching credentials (your responsibility)

Use your credential storage to find credentials that satisfy the
`presentationDefinition` returned in step 1. If you are using
`affinidi_tdk_vault`, the `CredentialStorage.query()` method is the
intended integration point.

### Step 3 — Submit the VP (coming soon)

A future release will add a `submitPresentation` method that accepts
the `shareRequest`, the matching credentials, and a signer, then builds
and POSTs the Verifiable Presentation to the verifier's `response_uri`.

The `jwtAssertion` field on `Oid4vpShareRequest` carries the raw JWT
assertion needed for VP submission and IDV redirect flows.

## Error handling

All errors are thrown as `TdkException` with one of the following codes:

| Code | Description |
|------|-------------|
| `parse_failure` | The `request` query parameter is absent, the JWT could not be decoded, or required payload fields are missing. |
| `invalid_or_expired_jwt` | The JWT signature is invalid, the token has expired, `client_id_scheme` is not `did`, or `aud` does not match `walletDid`. |
| `missing_client_id` | The `client_id` field is empty in the payload. |
| `invalid_response_mode` | `response_mode` is not `direct_post`. |

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
