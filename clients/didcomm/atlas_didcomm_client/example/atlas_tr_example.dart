import 'dart:io';

import 'package:affinidi_tdk_atlas_didcomm_client/affinidi_tdk_atlas_didcomm_client.dart';
import 'package:affinidi_tdk_didcomm_mediator_client/affinidi_tdk_didcomm_mediator_client.dart';
import 'package:ssi/ssi.dart';

import '../../../../packages/integration_tests/test/test_config.dart';

Future<void> main() async {
  // Run commands below in your terminal to generate keys for Sender:
  // openssl ecparam -name prime256v1 -genkey -noout -out example/keys/alice_private_key.pem

  final config = await TestConfig.configureTestFiles(
    packageDirectoryName: 'atlas_didcomm_client',
    skipMediator: true,
    skipBob: true,
  );

  final senderKeyStore = InMemoryKeyStore();
  final senderWallet = PersistentWallet(senderKeyStore);

  final senderDidManager = DidPeerManager(
    wallet: senderWallet,
    store: InMemoryDidStore(),
  );

  const senderKeyId = 'sender-key-1';

  final senderPrivateKeyBytes = await extractPrivateKeyBytes(
    config.alicePrivateKeyPath,
  );

  await senderKeyStore.set(
    senderKeyId,
    StoredKey(keyType: KeyType.p256, privateKeyBytes: senderPrivateKeyBytes),
  );

  await senderDidManager.addVerificationMethod(senderKeyId);

  // Get the sender's DID for use as administrator and default mediator
  final senderDidDocument = await senderDidManager.getDidDocument();
  final senderDid = senderDidDocument.id;

  final atlasClient = await DidcommAtlasClient.init(
    didManager: senderDidManager,
  );

  await ConnectionPool.instance.startConnections();

  prettyPrint('Checking if there are deployed Trust Registry instances...');

  final existingInstances = await atlasClient.getTrInstancesList().catchError((
    Object error,
  ) {
    prettyPrint('Error while listing TR instances', object: error);

    exit(1);
  });

  if (existingInstances.instances.isNotEmpty) {
    prettyPrint('Cleaning previously deployed TR instances...');
    final cleaningStart = DateTime.now();

    for (final instance in existingInstances.instances) {
      final destroyResponse = await atlasClient.destroyTrInstance(
        serviceId: instance.id,
      );

      prettyPrint('Destroy response', object: destroyResponse);
    }

    // wait for deletion
    await _waitUntil(
      predicate: (trInstances) => trInstances.isNotEmpty,
      atlasClient: atlasClient,
      firstTimeout: const Duration(minutes: 10),
      logMessage: 'destroying...',
    );

    prettyPrint(
      'Cleaning previously deployed TR instances completed in ${DateTime.now().difference(cleaningStart).inMinutes} minutes.',
    );
  }

  prettyPrint('Deploying Trust Registry instance...');

  final deploymentStart = DateTime.now();

  final deploymentResponse = await atlasClient.deployTrInstance(
    options: DeployTrInstanceOptions(
      serviceSize: ServiceSize.tiny,
      name: 'Example Trust Registry',
      description: 'Example TR instance created by atlas_tr_example.dart',
      defaultMediatorDid:
          'did:web:example.com', // This can be any DID, using sender's DID is also fine
      administratorDids: senderDid,
      corsAllowedOrigins: '*',
    ),
  );

  final deployedTr =
      deploymentResponse.response as DeployTrustRegistryInstanceResponse;

  prettyPrint('Deployment response', object: deploymentResponse.response);

  // wait for completed deployment
  await _waitUntil(
    predicate: (trInstances) => trInstances.any(
      (tr) => tr.deploymentStatus != DeploymentStatus.createComplete,
    ),
    atlasClient: atlasClient,
    firstTimeout: const Duration(minutes: 5),
    logMessage: 'deploying...',
  );

  prettyPrint(
    'Deploying Trust Registry instance completed in ${DateTime.now().difference(deploymentStart).inMinutes} minutes.',
  );

  prettyPrint('Updating Trust Registry instance metadata...');

  final updateMetadataResponse = await atlasClient.updateTrInstanceDeployment(
    options: UpdateTrInstanceDeploymentOptions(
      serviceId: deployedTr.serviceId,
      name: 'Example Trust Registry (updated)',
      description:
          'Example TR instance metadata updated by atlas_tr_example.dart',
    ),
  );

  prettyPrint(
    'Update metadata response',
    object: updateMetadataResponse.response,
  );

  final finalTrMetadata = await atlasClient.getTrInstanceMetadata(
    serviceId: deployedTr.serviceId,
  );

  prettyPrint('Metadata after updates', object: finalTrMetadata);

  final deployedTrResponse = await atlasClient.getTrInstancesList();

  prettyPrint(
    'Get Trust Registry instances response',
    object: deployedTrResponse,
  );

  prettyPrint('Destroying deployed Trust Registry instance...');
  final destroyingStart = DateTime.now();

  final destroyResponse = await atlasClient.destroyTrInstance(
    serviceId: deployedTr.serviceId,
  );

  prettyPrint('Destroy response', object: destroyResponse);

  // wait for deletion
  await _waitUntil(
    predicate: (trInstances) => trInstances.isNotEmpty,
    atlasClient: atlasClient,
    firstTimeout: const Duration(minutes: 10),
    logMessage: 'destroying...',
  );

  prettyPrint(
    'Destroying Trust Registry instance completed in ${DateTime.now().difference(destroyingStart).inMinutes} minutes.',
  );

  await ConnectionPool.instance.stopConnections();
}

Future<void> _waitUntil({
  required bool Function(List<TrInstanceMetadata>) predicate,
  required DidcommAtlasClient atlasClient,
  required Duration firstTimeout,
  required String logMessage,
}) async {
  final timeout = const Duration(seconds: 10);
  var attemptsLeft = 100;
  late GetTrInstancesListResponseMessage list;

  prettyPrint(logMessage);
  await Future<void>.delayed(firstTimeout);

  do {
    prettyPrint(logMessage);
    await Future<void>.delayed(timeout);

    list = await atlasClient.getTrInstancesList();

    if (--attemptsLeft == 0) {
      throw Exception('Reached the max number of attempts');
    }
  } while (predicate(list.instances));
}
