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

  final atlasClient = await DidcommAtlasClient.init(
    didManager: senderDidManager,
  );

  await ConnectionPool.instance.startConnections();

  prettyPrint('Checking if there are deployed MPX instances...');

  final existingInstances = await atlasClient.getMpxInstancesList().catchError((
    Object error,
  ) {
    prettyPrint('Error while listing MPX instances', object: error);

    exit(1);
  });

  if (existingInstances.instances.isNotEmpty) {
    prettyPrint('Cleaning previously deployed MPX instances...');
    final cleaningStart = DateTime.now();

    for (final instance in existingInstances.instances) {
      final destroyResponse = await atlasClient.destroyMpxInstance(
        serviceId: instance.id,
      );

      prettyPrint('Destroy response', object: destroyResponse);
    }

    // wait for deletion
    await _waitUntil(
      predicate: (mpxInstances) => mpxInstances.isNotEmpty,
      atlasClient: atlasClient,
      firstTimeout: const Duration(minutes: 10),
      logMessage: 'destroying...',
    );

    prettyPrint(
      'Cleaning previously deployed MPX instances completed in ${DateTime.now().difference(cleaningStart).inMinutes} minutes.',
    );
  }

  prettyPrint('Deploying MPX instance...');

  final deploymentStart = DateTime.now();

  final deploymentResponse = await atlasClient.deployMpxInstance(
    options: const DeployMpxInstanceOptions(
      serviceSize: ServiceSize.tiny,
      name: 'Example MPX',
      description: 'Example MPX instance created by atlas_mpx_example.dart',
    ),
  );

  final deployedMpx = deploymentResponse.response as DeployMpxInstanceResponse;

  prettyPrint('Deployment response', object: deploymentResponse.response);

  // wait for completed deployment
  await _waitUntil(
    predicate: (mpxInstances) => mpxInstances.any(
      (mpx) => mpx.deploymentStatus != DeploymentStatus.createComplete,
    ),
    atlasClient: atlasClient,
    firstTimeout: const Duration(minutes: 5),
    logMessage: 'deploying...',
  );

  prettyPrint(
    'Deploying MPX instance completed in ${DateTime.now().difference(deploymentStart).inMinutes} minutes.',
  );

  prettyPrint('Updating MPX instance metadata...');

  final updateMetadataResponse = await atlasClient.updateMpxInstanceDeployment(
    options: UpdateMpxInstanceDeploymentOptions(
      serviceId: deployedMpx.serviceId,
      name: 'Example MPX (updated)',
      description:
          'Example MPX instance metadata updated by atlas_mpx_example.dart',
    ),
  );

  prettyPrint(
    'Update metadata response',
    object: updateMetadataResponse.response,
  );

  final finalMpxMetadata = await atlasClient.getMpxInstanceMetadata(
    serviceId: deployedMpx.serviceId,
  );

  prettyPrint('Metadata after updates', object: finalMpxMetadata);

  final deployedMpxResponse = await atlasClient.getMpxInstancesList();

  prettyPrint('Get MPX instances response', object: deployedMpxResponse);

  prettyPrint('Destroying deployed MPX instance...');
  final destroyingStart = DateTime.now();

  final destroyResponse = await atlasClient.destroyMpxInstance(
    serviceId: deployedMpx.serviceId,
  );

  prettyPrint('Destroy response', object: destroyResponse);

  // wait for deletion
  await _waitUntil(
    predicate: (mpxInstances) => mpxInstances.isNotEmpty,
    atlasClient: atlasClient,
    firstTimeout: const Duration(minutes: 10),
    logMessage: 'destroying...',
  );

  prettyPrint(
    'Destroying MPX instance completed in ${DateTime.now().difference(destroyingStart).inMinutes} minutes.',
  );

  await ConnectionPool.instance.stopConnections();
}

Future<void> _waitUntil({
  required bool Function(List<MpxInstanceMetadata>) predicate,
  required DidcommAtlasClient atlasClient,
  required Duration firstTimeout,
  required String logMessage,
}) async {
  final timeout = const Duration(seconds: 10);
  var attemptsLeft = 100;
  late GetMpxInstancesListResponseMessage list;

  prettyPrint(logMessage);
  await Future<void>.delayed(firstTimeout);

  do {
    prettyPrint(logMessage);
    await Future<void>.delayed(timeout);

    list = await atlasClient.getMpxInstancesList();

    if (--attemptsLeft == 0) {
      throw Exception('Reached the max number of attempts');
    }
  } while (predicate(list.instances));
}
