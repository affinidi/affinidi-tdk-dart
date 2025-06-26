# Affinidi Trust Development Kit (Affinidi TDK)

The Affinidi Trust Development Kit (Affinidi TDK) for Dart provides a suite of libraries and tools to implement decentralised identity solutions and to integrate with Affinidi Elements services to issue, share, and verify Verifiable Credentials (VCs) and Verifiable Presentations (VPs).

It provides a various packages to implement a secure vault to manage Decentralised Identifiers (DIDs), cryptogrpahic keys, and store Verifiable Credentials on your Flutter/Dart applications. The secure vault uses the [Affinidi SSI](https://github.com/affinidi/affinidi-tdk-dart), an open-source project for implementing Self-Sovereign Identity (SSI).

## Table of Contents

  - [Requirements](#requirements)
  - [Installation](#installation)
  - [Usage](#usage)
  - [Available Packages and Clients](#available-packages-and-clients)
  - [Support & feedback](#support--feedback)
  - [Contributing](#contributing)

## Requirements

- Dart SDK version ^3.6.0

## Installation

To install the Dart packages, run:

```
dart pub add <package_name>
```

or manually, add the package into your `pubspec.yaml` file:

```yaml
dependencies:
  <package_name>: ^<version_number>
```

and then run the command below to install the package:

```bash
dart pub get
```

Refer to the [available clients and packages](#available-clients-and-packages) for package names and relevant references.

## Usage

```Dart

import 'dart:typed_data';

import 'package:base_codecs/base_codecs.dart';
import 'package:iam_api_service/iam_api_service.dart';
import 'package:ssi/src/wallet/stores/in_memory_key_store.dart';
import 'package:ssi/ssi.dart';
import 'package:storages_interface/storages.dart';
import 'package:vault_interface/vault.dart';

void main() async {
  // KeyStorage
  final accountIndex = 23;
  final keyStorage = InMemoryVaultStore();
  await keyStorage.writeAccountIndex(accountIndex);

  // seed storage
  final seed = hexDecode(
    'a1772b144344781f2a55fc4d5e49f3767bb0967205ad08454a09c76d96fd2ccd',
  );

  // initialization
  const vfsRepositoryId = 'vfs';
  final profileRepositories = <String, ProfileRepository>{
    vfsRepositoryId: VfsProfileRepository(vfsRepositoryId),
  };

  // from wallet
  final keyStore = InMemoryKeyStore();
  final wallet = await Bip32Wallet.fromSeed(seed, keyStore);
  final vault = Vault(
    wallet: wallet,
    vaultStore: keyStorage,
    profileRepositories: profileRepositories,
    defaultProfileRepositoryId: vfsRepositoryId,
  );

  // Must initialize vault before being able to access any of the repositories
  await vault.ensureInitialized();
}

```

## Available Packages and Clients

See the list of available packages and clients of Affinidi TDK for Dart.

### Packages

Packages are commonly used utilities/helpers that are self-contained and composable.

| Name        | Reference        | Package name      | Status |
|---------------|---------------|-------------------|-----------|
| auth_provider    | [Source code](./packages/auth_provider/)  | [affinidi_tdk_auth_provider](https://pub.dev/packages/affinidi_tdk_auth_provider)   | ![◯](https://img.shields.io/badge/%E2%97%AF-52a447?style=flat) |
| consumer_auth_provider    | [Source code](./packages/consumer_auth_provider/) | [affinidi_tdk_consumer_auth_provider](https://pub.dev/packages/affinidi_tdk_consumer_auth_provider)   | ![◯](https://img.shields.io/badge/%E2%97%AF-52a447?style=flat) |
| claim_verifiable_credential   | [Source code](./packages/claim_verifiable_credential/)    | [affinidi_tdk_claim_verifiable_credential](https://pub.dev/packages/affinidi_tdk_claim_verifiable_credential) | ![◯](https://img.shields.io/badge/%E2%97%AF-52a447?style=flat) |
| common    | [Source code](./packages/common/) | [affinidi_tdk_common](https://pub.dev/packages/affinidi_tdk_common)   | ![◯](https://img.shields.io/badge/%E2%97%AF-52a447?style=flat) |
| cryptography  | [Source code](./packages/cryptography/) | [affinidi_tdk_cryptography](https://pub.dev/packages/affinidi_tdk_cryptography) | ![◯](https://img.shields.io/badge/%E2%97%AF-52a447?style=flat) |
| vault | [Source code](./packages/vault/)  | [affinidi_tdk_vault](https://pub.dev/packages/affinidi_tdk_vault) | ![◯](https://img.shields.io/badge/%E2%97%AF-52a447?style=flat) |
| vault_data_manager    | [Source code](./packages/vault_data_manager/) | [affinidi_tdk_vault_data_manager](https://pub.dev/packages/affinidi_tdk_vault_data_manager)   | ![◯](https://img.shields.io/badge/%E2%97%AF-52a447?style=flat) |
| vault_flutter_utls    | [Source code](./packages/vault_flutter_utils/)    | [affinidi_tdk_vault_flutter_utils](https://pub.dev/packages/affinidi_tdk_vault_flutter_utils) | ![◯](https://img.shields.io/badge/%E2%97%AF-52a447?style=flat) |
| test_utilities    | [Source code](./packages/test_utilities/) | [affinidi_tdk_test_utilities](https://pub.dev/packages/affinidi_tdk_test_utilities)   | ![◯](https://img.shields.io/badge/%E2%97%AF-52a447?style=flat) |
| iota_core | [Source code](./packages/iota_core/)  | Not published | - |

### Clients

Clients provide methods to access Affinidi Elements services such as Credential Issuance, Credential Verification, and Iota Framework.

| Name        | Reference        | Package name      | Status |
|---------------|---------------|-------------------|-----------|
| credential_issuance_client    | [Source code](./clients/credential_issuance_client/)  | [affinidi_tdk_credential_issuance_client](https://pub.dev/packages/affinidi_tdk_credential_issuance_client)   | ![◯](https://img.shields.io/badge/%E2%97%AF-52a447?style=flat) |
| credential_verification_client   | [Source code](./clients/credential_verification_client/)  | [affinidi_tdk_credential_verification_client](https://pub.dev/packages/affinidi_tdk_credential_verification_client)   | ![◯](https://img.shields.io/badge/%E2%97%AF-52a447?style=flat) |
| affinidi_tdk_iam_client   | [Source code](./clients/iam_client/)  | [affinidi_tdk_iam_client](https://pub.dev/packages/affinidi_tdk_iam_client)   | ![◯](https://img.shields.io/badge/%E2%97%AF-52a447?style=flat) |
| iota_client  | [Source code](./clients/iota_client/) | [affinidi_tdk_iota_client](https://pub.dev/packages/affinidi_tdk_iota_client)  | ![◯](https://img.shields.io/badge/%E2%97%AF-52a447?style=flat) |
| logic_configuration_client   | [Source code](./clients/login_configuration_client/)  | [affinidi_tdk_logic_configuration_client](https://pub.dev/packages/affinidi_tdk_login_configuration_client)   | ![◯](https://img.shields.io/badge/%E2%97%AF-52a447?style=flat) |
| vault_data_manager_client   | [Source code](./clients/vault_data_manager_client/)   | [affinidi_tdk_vault_data_manager](https://pub.dev/packages/affinidi_tdk_vault_data_manager_client)    | ![◯](https://img.shields.io/badge/%E2%97%AF-52a447?style=flat) |
| wallets_client   | [Source code](./clients/wallets_client/)  | [affinidi_tdk_wallets_client](https://pub.dev/packages/affinidi_tdk_wallets_client)   | ![◯](https://img.shields.io/badge/%E2%97%AF-52a447?style=flat) |


**Status definition:**

![◯](https://img.shields.io/badge/%E2%97%AF-Supported-2ecc71?labelColor=52a447&style=flat)
![◯](https://img.shields.io/badge/%E2%97%AF-Experimental-f9e79f?labelColor=FFEA00&style=flat)
![◯](https://img.shields.io/badge/%E2%97%AF-Unsupported-ec7063?labelColor=e74c3c&style=flat)

## Support & feedback

If you face any issues or have suggestions, please don't hesitate to contact us using [this link](https://share.hsforms.com/1i-4HKZRXSsmENzXtPdIG4g8oa2v).

### Reporting technical issues

If you have a technical issue with the Affinidi TDK for Dart's codebase, you can also create an issue directly in GitHub.

1. Ensure the bug was not already reported by searching on GitHub under
   [Issues](https://github.com/affinidi/affinidi-tdk-dart/issues).

2. If you're unable to find an open issue addressing the problem,
   [open a new one](https://github.com/affinidi/affinidi-tdk-dart/issues/new).
   Be sure to include a **title and clear description**, as much relevant information as possible,
   and a **code sample** or an **executable test case** demonstrating the expected behaviour that is not occurring.

## Contributing

Want to contribute?

Head over to our [CONTRIBUTING](https://github.com/affinidi/affinidi-tdk-dart/blob/main/CONTRIBUTING.md) guidelines.