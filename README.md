# Affinidi Trust Development Kit for Dart

The Affinidi Trust Development Kit (Affinidi TDK) for Dart provides a suite of libraries and tools to implement decentralised identity solutions and to integrate with Affinidi Elements services to issue, share, and verify Verifiable Credentials (VCs) and Verifiable Presentations (VPs).

It provides various packages to implement a secure vault to manage Decentralised Identifiers (DIDs), cryptographic keys, and store Verifiable Credentials in your Flutter/Dart applications. The secure vault uses the [Affinidi SSI](https://github.com/affinidi/affinidi-tdk-dart), an open-source project for implementing Self-Sovereign Identity (SSI).

## Table of Contents

- [Requirements](#requirements)
- [Installation](#installation)
- [Usage](#usage)
  - [Implement Secure Vault](#implement-secure-vault)
  - [Issue Verifiable Credentials](#issue-verifiable-credentials)
- [Available Packages and Clients](#available-packages-and-clients)
  - [Packages](#packages)
  - [Clients](#clients)
  - [Status Legend](#status-legend)
- [Documentation](#documentation)
- [Support \& Feedback](#support--feedback)
  - [Reporting Technical Issues](#reporting-technical-issues)
- [Contributing](#contributing)

## Requirements

- Dart SDK version ^3.8.0 or higher.

## Installation

To install the Dart packages, run:

```bash
dart pub add <package_name>
```

Alternatively, manually add the package to your `pubspec.yaml` file:

```yaml
dependencies:
  <package_name>: ^<version_number>
```

Then run the following command to install the package:

```bash
dart pub get
```

Refer to the [available clients and packages](#available-packages-and-clients) for package names and relevant references.

## Usage

### Implement Secure Vault

Sample usage for implementing and initialising a secure vault using the `affinidi_tdk_vault` package:

```dart
import 'dart:typed_data';

import 'package:affinidi_tdk_vault/affinidi_tdk_vault.dart';
import 'package:affinidi_tdk_vault_data_manager/affinidi_tdk_vault_data_manager.dart';

void main() async {
  // Initialise InMemory storage
  final accountIndex = 32;
  final vaultStore = InMemoryVaultStore();
  await vaultStore.writeAccountIndex(accountIndex);

  // Generate seed from the storage layer
  final seed = vaultStore.getRandomSeed();
  await vaultStore.setSeed(seed);

  // Initialise profile interface
  const vfsRepositoryId = 'vfs';
  final profileRepositories = <String, ProfileRepository>{
    vfsRepositoryId: VfsProfileRepository(vfsRepositoryId),
  };

  // In this example, we are using Bip32 type wallet from SSI package
  final vault = await Vault.fromVaultStore(
    vaultStore,
    profileRepositories: profileRepositories,
    defaultProfileRepositoryId: vfsRepositoryId,
  );

  // Ensure vault is initialised before being able to access any of the repositories
  await vault.ensureInitialized();
}

```

### Issue Verifiable Credentials

Sample usage for issuing Verifiable Credentials (VCs) using the `affinidi_tdk_credential_issuance_client` client:

```dart
import 'package:built_collection/built_collection.dart';
import 'package:dio/dio.dart';
import 'package:affinidi_tdk_auth_provider/affinidi_tdk_auth_provider.dart';
import 'package:affinidi_tdk_credential_issuance_client/affinidi_tdk_credential_issuance_client.dart';
import 'package:built_value/json_object.dart';


try {

  // NOTE: Set your variables for PAT
  final privateKey = '<PAT_PRIVATE_KEY_STRING>';
  final passphrase = '<PAT_KEY_PAIR_PASSPHRASE>';
  final tokenId = '<PAT_ID>';
  final projectId = '<PROJECT_ID>';

  final authProvider = AuthProvider(
    privateKey: privateKey,
    passphrase: passphrase,
    tokenId: tokenId,
    projectId: projectId,
  );


  late IssuanceApi issuanceApi;

  final issuanceClient = AffinidiTdkCredentialIssuanceClient(
    dio: Dio(BaseOptions(
      baseUrl: AffinidiTdkCredentialIssuanceClient.basePath,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    )),
    authTokenHook: authProvider.fetchProjectScopedToken,
  );

  issuanceApi = issuanceClient.getIssuanceApi();

  final credentialTypeId = 'SchemaOne';

  final credentialData = {
    'first_name': 'FirstName',
    'last_name': 'LastName',
    'dob': '1970-01-01',
  };

  final credentialDataBuilder = MapBuilder<String, JsonObject>(
    credentialData.map((key, value) => MapEntry(key, JsonObject(value))),
  );


  final data = StartIssuanceInputDataInnerBuilder()
    ..credentialTypeId = credentialTypeId
    ..credentialData.replace(credentialDataBuilder.build());

  final startIssuanceInput = StartIssuanceInputBuilder()
    ..holderDid = 'did:key:holder-did-value'
    ..claimMode = StartIssuanceInputClaimModeEnum.FIXED_HOLDER
    ..data = ListBuilder<StartIssuanceInputDataInner>([data.build()]);

  final response = await issuanceApi.startIssuance(
    projectId: projectId,
    startIssuanceInput: startIssuanceInput.build(),
  );

  print(response);
} catch (e) {
  print('Error obtaining token: $e');
}

```

## Available Packages and Clients

Affinidi TDK for Dart provides two types of components:

- **Packages**: Self-contained, reusable utilities and helpers for implementing identity and credential management features.
- **Clients**: API clients for integrating with Affinidi Elements services.

### Packages

Packages provide core functionality for building decentralised identity solutions, vault and credential management.

| Description | Package Name | Source Code | Status |
|-------------|--------------|-------------|--------|
| Project-scoped authentication provider for integrating with Affinidi Elements services. | [affinidi_tdk_auth_provider](https://pub.dev/packages/affinidi_tdk_auth_provider) | [Source](./packages/auth_provider/) | ![◯](https://img.shields.io/badge/%E2%97%AF-52a447?style=flat) |
| Consumer-scoped authentication provider for Affinidi services. Used together with vault implementation. | [affinidi_tdk_consumer_auth_provider](https://pub.dev/packages/affinidi_tdk_consumer_auth_provider) | [Source](./packages/consumer_auth_provider/) | ![◯](https://img.shields.io/badge/%E2%97%AF-52a447?style=flat) |
| Utilities for claiming and handling Verifiable Credentials. | [affinidi_tdk_claim_verifiable_credential](https://pub.dev/packages/affinidi_tdk_claim_verifiable_credential) | [Source](./packages/claim_verifiable_credential/) | ![◯](https://img.shields.io/badge/%E2%97%AF-52a447?style=flat) |
| Common utilities and shared functionality across packages. | [affinidi_tdk_common](https://pub.dev/packages/affinidi_tdk_common) | [Source](./packages/common/) | ![◯](https://img.shields.io/badge/%E2%97%AF-52a447?style=flat) |
| Cryptographic operations and key management. | [affinidi_tdk_cryptography](https://pub.dev/packages/affinidi_tdk_cryptography) | [Source](./packages/cryptography/) | ![◯](https://img.shields.io/badge/%E2%97%AF-52a447?style=flat) |
| Secure vault for managing DIDs, keys, and credentials. | [affinidi_tdk_vault](https://pub.dev/packages/affinidi_tdk_vault) | [Source](./packages/vault/) | ![◯](https://img.shields.io/badge/%E2%97%AF-52a447?style=flat) |
| Data management utilities for the vault. | [affinidi_tdk_vault_data_manager](https://pub.dev/packages/affinidi_tdk_vault_data_manager) | [Source](./packages/vault_data_manager/) | ![◯](https://img.shields.io/badge/%E2%97%AF-52a447?style=flat) |
| Flutter-specific utilities for vault integration. | [affinidi_tdk_vault_flutter_utils](https://pub.dev/packages/affinidi_tdk_vault_flutter_utils) | [Source](./packages/vault_flutter_utils/) | ![◯](https://img.shields.io/badge/%E2%97%AF-52a447?style=flat) |
| Testing utilities and helpers for development. | [affinidi_tdk_test_utilities](https://pub.dev/packages/affinidi_tdk_test_utilities) | [Source](./packages/test_utilities/) | ![◯](https://img.shields.io/badge/%E2%97%AF-52a447?style=flat) |
| Create token and generate Iota Framework credentials. | affinidi_tdk_iota_core *[Not published]* | [Source](./packages/iota_core/) | ![◯](https://img.shields.io/badge/%E2%97%AF-52a447?style=flat) |

### Clients

Clients provide type-safe API wrappers for integrating with Affinidi Elements services, including credential issuance, verification, and sharing.

| Description | Package Name | Source Code | Status |
|-------------|--------------|-------------|--------|
| Issue Verifiable Credentials using Affinidi Credential Issuance service. | [affinidi_tdk_credential_issuance_client](https://pub.dev/packages/affinidi_tdk_credential_issuance_client) | [Source](./clients/credential_issuance_client/) | ![◯](https://img.shields.io/badge/%E2%97%AF-52a447?style=flat) |
| Verify Verifiable Credentials and Presentations. | [affinidi_tdk_credential_verification_client](https://pub.dev/packages/affinidi_tdk_credential_verification_client) | [Source](./clients/credential_verification_client/) | ![◯](https://img.shields.io/badge/%E2%97%AF-52a447?style=flat) |
| Identity and Access Management (IAM) operations. | [affinidi_tdk_iam_client](https://pub.dev/packages/affinidi_tdk_iam_client) | [Source](./clients/iam_client/) | ![◯](https://img.shields.io/badge/%E2%97%AF-52a447?style=flat) |
| Iota Framework for requesting and sharing credentials. | [affinidi_tdk_iota_client](https://pub.dev/packages/affinidi_tdk_iota_client) | [Source](./clients/iota_client/) | ![◯](https://img.shields.io/badge/%E2%97%AF-52a447?style=flat) |
| Configure and manage Affinidi Login settings. | [affinidi_tdk_login_configuration_client](https://pub.dev/packages/affinidi_tdk_login_configuration_client) | [Source](./clients/login_configuration_client/) | ![◯](https://img.shields.io/badge/%E2%97%AF-52a447?style=flat) |
| Manage vault data and operations via API. | [affinidi_tdk_vault_data_manager_client](https://pub.dev/packages/affinidi_tdk_vault_data_manager_client) | [Source](./clients/vault_data_manager_client/) | ![◯](https://img.shields.io/badge/%E2%97%AF-52a447?style=flat) |
| Wallet management and DID operations. | [affinidi_tdk_wallets_client](https://pub.dev/packages/affinidi_tdk_wallets_client) | [Source](./clients/wallets_client/) | ![◯](https://img.shields.io/badge/%E2%97%AF-52a447?style=flat) |

### Status Legend

Each package and client has a status indicator:

- ![◯](https://img.shields.io/badge/%E2%97%AF-Supported-2ecc71?labelColor=52a447&style=flat) **Supported** - Stable and production-ready.
- ![◯](https://img.shields.io/badge/%E2%97%AF-Experimental-f9e79f?labelColor=FFEA00&style=flat) **Experimental** - Under active development, API may change.
- ![◯](https://img.shields.io/badge/%E2%97%AF-Unsupported-ec7063?labelColor=e74c3c&style=flat) **Unsupported** - Deprecated or no longer maintained.

## Documentation

For comprehensive integration guides and API references, visit our [official documentation](https://docs.affinidi.com/docs/).

## Support & Feedback

If you face any issues or have suggestions, please don't hesitate to contact us using [this link](https://share.hsforms.com/1i-4HKZRXSsmENzXtPdIG4g8oa2v).

### Reporting Technical Issues

If you have a technical issue with the Affinidi TDK for Dart's codebase, you can create an issue directly in GitHub:

1. Ensure the bug was not already reported by searching on GitHub under [Issues](https://github.com/affinidi/affinidi-tdk-dart/issues).

2. If you're unable to find an open issue addressing the problem, [open a new one](https://github.com/affinidi/affinidi-tdk-dart/issues/new). Be sure to include a **title and clear description**, as much relevant information as possible, and a **code sample** or an **executable test case** demonstrating the expected behaviour that is not occurring.

## Contributing

We welcome contributions! Please read our [CONTRIBUTING](https://github.com/affinidi/affinidi-tdk-dart/blob/main/CONTRIBUTING.md) guidelines to get started.
