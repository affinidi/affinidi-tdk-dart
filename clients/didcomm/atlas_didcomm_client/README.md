# Affinidi Atlas DIDComm Client for Dart

> IMPORTANT: This package is in closed beta. Please run any file in the [example](https://github.com/affinidi/affinidi-tdk/tree/main/clients/dart/didcomm/atlas_didcomm_client/example) folder and follow the instructions.

A Dart client for interacting with Affinidi Atlas over DIDComm v2.1. It enables secure, end-to-end encrypted management of Atlas services using DID-based identities and message flows.

This client provides high-level APIs to:

- Manage service ACLs
- Deploy and destroy Atlas service instances
- Retrieve instance metadata and lists
- Query service requests and update deployments/configurations

## Table of Contents

- [Core Concepts](#core-concepts)
- [Key Features](#key-features)
- [Requirements](#requirements)
- [Installation](#installation)
- [Usage](#usage)
	- [Initialise client](#initialise-client)
	- [List instances](#list-instances)
	- [Deploy and destroy instances](#deploy-and-destroy-instances)
	- [Get metadata and requests](#get-metadata-and-requests)
	- [Update deployment/configuration](#update-deploymentconfiguration)
- [Security Features](#security-features)
- [Support & Feedback](#support--feedback)
- [Contributing](#contributing)

## Core Concepts

- **DIDComm v2.1**: Open standard for secure, interoperable, end-to-end encrypted communication using DIDs.
- **Affinidi Atlas**: An orchestrator that manages Mediator instances via DIDComm, providing coordinated lifecycle, configuration, and secure messaging.
- **Mediator ACL**: Access control list that configures which users/DIDs can access a specific Atlas‑deployed instance.

## Key Features

- High-level Dart APIs over DIDComm for Atlas
- Instance lifecycle: deploy, destroy, list, and metadata
- Gets a list of requests from a deployed instance
- Deployment and configuration updates

## Requirements

- Dart SDK `^3.6.0`

## Installation

Run:

```bash
dart pub add affinidi_tdk_atlas_didcomm_client
```

or add to `pubspec.yaml`:

```yaml
dependencies:
	affinidi_tdk_atlas_didcomm_client: ^1.0.0
```

then install:

```bash
dart pub get
```

## Usage

Below are common flows when working with the Atlas DIDComm client.

### Initialise client

```dart
import 'package:affinidi_tdk_atlas_didcomm_client/affinidi_tdk_atlas_didcomm_client.dart';
import 'package:affinidi_tdk_didcomm_mediator_client/affinidi_tdk_didcomm_mediator_client.dart';
import 'package:ssi/ssi.dart';

Future<void> main() async {
	// Prepare a DID manager with a wallet and key
	final keyStore = InMemoryKeyStore();
	final wallet = PersistentWallet(keyStore);
	final didManager = DidPeerManager(
		wallet: wallet,
		store: InMemoryDidStore(),
	);

	const keyId = 'atlas-key-1';
	await wallet.generateKey(keyId: keyId, keyType: KeyType.p256);
	await didManager.addVerificationMethod(keyId);

	// Initialise the Atlas client
	final client = await DidcommAtlasClient.init(
		didManager: didManager,
	);

	// Start connections before making requests
	await ConnectionPool.instance.startConnections();

	// ... use client ...

	// Stop connections when done
	await ConnectionPool.instance.stopConnections();
}
```

### List instances

```dart
// Mediator instances
final mediators = await client.getMediatorInstancesList();
print(mediators.instances);
```

### Deploy and destroy instances

```dart
// Deploy Mediator
final deployResponse = await client.deployMediatorInstance(
	options: const DeployMediatorInstanceOptions(
		serviceSize: ServiceSize.small,
		mediatorAclMode: MediatorAclMode.explicitAllow,
	),
);
final deployedMediator = deployResponse.response as DeployMediatorInstanceResponse;
print(deployedMediator.serviceId);

// Destroy Mediator
final destroyResponse = await client.destroyMediatorInstance(
	serviceId: deployedMediator.serviceId,
);
print(destroyResponse);
```

### Get metadata and requests

```dart
// Metadata
final metadata = await client.getMediatorInstanceMetadata(
	serviceId: 'mediator-123',
);
print(metadata);

// Requests
final requests = await client.getMediatorRequests();
print(requests);
```

### Update deployment/configuration

```dart
// Update deployment for Mediator
await client.updateMediatorInstanceDeployment(
	options: UpdateMediatorInstanceDeploymentOptions(
		serviceId: 'mediator-123',
	),
);

// Update configuration for Mediator
await client.updateMediatorInstanceConfiguration(
	options: UpdateMediatorInstanceConfigurationOptions(
		serviceId: 'mediator-123',
	),
);
```

## Security Features

- **Message wrapping verification**: Accepts only signed and encrypted envelopes (`authcryptSignPlaintext`, `anoncryptSignPlaintext`).
- **Sender validation**: Responses must originate from Atlas service DID.
- **ACL configuration**: The client sets mediator ACL to authorise Atlas to reach your DID.
- **Problem reports**: Errors are surfaced as standard DIDComm problem reports and linked to request threads.

## Support & Feedback

If you face any issues or have suggestions, please contact us using:
https://share.hsforms.com/1i-4HKZRXSsmENzXtPdIG4g8oa2v

### Reporting Technical Issues

- Search existing issues: https://github.com/affinidi/affinidi-tdk/issues
- Open a new issue with details and a minimal repro: https://github.com/affinidi/affinidi-tdk/issues/new

## Contributing

See our CONTRIBUTING guidelines:
https://github.com/affinidi/affinidi-tdk/blob/main/CONTRIBUTING.md

