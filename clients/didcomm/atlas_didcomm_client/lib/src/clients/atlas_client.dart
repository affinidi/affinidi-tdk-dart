import 'dart:async';

import 'package:affinidi_tdk_didcomm_mediator_client/affinidi_tdk_didcomm_mediator_client.dart';
import 'package:ssi/ssi.dart';
import 'package:uuid/uuid.dart';

import '../messages/atlas/deploy_instance/deploy_instance_request_message.dart';
import '../messages/atlas/deploy_instance/deploy_instance_response_message.dart';
import '../messages/atlas/destroy_instance/destroy_instance_request_message.dart';
import '../messages/atlas/destroy_instance/destroy_instance_response_message.dart';
import '../messages/atlas/get_instance_metadata/get_instance_metadata_request_message.dart';
import '../messages/atlas/get_instance_metadata/get_instance_metadata_response_message.dart';
import '../messages/atlas/get_instances_list/get_instances_list_request_message.dart';
import '../messages/atlas/get_instances_list/get_instances_list_response_message.dart';
import '../messages/atlas/get_requests/get_requests_request_message.dart';
import '../messages/atlas/get_requests/get_requests_response_message.dart';
import '../messages/atlas/update_instance_configuration/update_instance_configuration_request_message.dart';
import '../messages/atlas/update_instance_configuration/update_instance_configuration_response_message.dart';
import '../messages/atlas/update_instance_deployment/update_instance_deployment_request_message.dart';
import '../messages/atlas/update_instance_deployment/update_instance_deployment_response_message.dart';
import '../models/request_bodies/deploy_mediator_instance_options.dart';
import '../models/request_bodies/deploy_mpx_instance_options.dart';
import '../models/request_bodies/deploy_tr_instance_options.dart';
import '../models/request_bodies/destroy_mediator_instance_options.dart';
import '../models/request_bodies/destroy_mpx_instance_options.dart';
import '../models/request_bodies/destroy_tr_instance_options.dart';
import '../models/request_bodies/get_mediator_instance_metadata_options.dart';
import '../models/request_bodies/get_mediator_instance_requests_request_options.dart';
import '../models/request_bodies/get_mediator_instances_list_request_options.dart';
import '../models/request_bodies/get_mpx_instance_metadata_options.dart';
import '../models/request_bodies/get_mpx_instance_requests_request_options.dart';
import '../models/request_bodies/get_mpx_instances_list_request_options.dart';
import '../models/request_bodies/get_tr_instance_metadata_options.dart';
import '../models/request_bodies/get_tr_instance_requests_request_options.dart';
import '../models/request_bodies/get_tr_instances_list_request_options.dart';
import '../models/request_bodies/update_mediator_instance_configuration_options.dart';
import '../models/request_bodies/update_mediator_instance_deployment_options.dart';
import '../models/request_bodies/update_mpx_instance_deployment_options.dart';
import '../models/request_bodies/update_tr_instance_deployment_options.dart';
import 'service_client.dart';

/// DIDComm client for interacting with the Affinidi Atlas service.
class DidcommAtlasClient extends DidcommServiceClient {
  /// The DID for the Atlas service.
  ///
  /// Override at compile time by defining `AFFINIDI_ATLAS_DID`:
  /// - Dart: `dart run -D AFFINIDI_ATLAS_DID=<did>`
  /// - Flutter: `flutter run --dart-define=AFFINIDI_ATLAS_DID=<did>`
  /// If not set, defaults to `did:web:did.affinidi.io:ama`.
  static final atlasDid = const String.fromEnvironment(
    'AFFINIDI_ATLAS_DID',
    defaultValue: 'did:web:did.affinidi.io:ama',
  );

  /// Creates a [DidcommAtlasClient] instance.
  DidcommAtlasClient({
    required super.didManager,
    required super.serviceDidDocument,
    super.clientOptions = const AffinidiClientOptions(),
    required super.mediatorDidDocument,
    required super.authorizationProvider,
    required super.keyPair,
    required super.didKeyId,
    required super.signer,
  });

  /// Initializes a [DidcommAtlasClient] instance.
  ///
  /// [didManager] required for managing DIDs and keys.
  /// [authorizationProvider] is optional; if not provided an [AffinidiAuthorizationProvider] will be created.
  /// [clientOptions] configures client behavior
  static Future<DidcommAtlasClient> init({
    required DidManager didManager,
    AuthorizationProvider? authorizationProvider,
    AffinidiClientOptions clientOptions = const AffinidiClientOptions(),
  }) async {
    final atlasDidDocument = await UniversalDIDResolver.defaultResolver
        .resolveDid(atlasDid);

    // TODO: add enum instead of hardcoding service type
    final mediatorService = atlasDidDocument.service.firstWhere(
      (service) => service.type.toString() == 'DIDCommMessaging',
    );

    final mediatorDid = mediatorService.id.split('#').first;

    final mediatorDidDocument = await UniversalDIDResolver.defaultResolver
        .resolveDid(mediatorDid);

    final mediatorClient = await DidcommMediatorClient.init(
      didManager: didManager,
      mediatorDidDocument: mediatorDidDocument,
      clientOptions: clientOptions,
      authorizationProvider:
          authorizationProvider ??
          await AffinidiAuthorizationProvider.init(
            didManager: didManager,
            mediatorDidDocument: mediatorDidDocument,
          ),
    );

    final client = DidcommAtlasClient(
      didManager: mediatorClient.didManager,
      clientOptions: mediatorClient.clientOptions,
      mediatorDidDocument: mediatorClient.mediatorDidDocument,
      authorizationProvider: mediatorClient.authorizationProvider,
      keyPair: mediatorClient.keyPair,
      didKeyId: mediatorClient.didKeyId,
      signer: mediatorClient.signer,
      serviceDidDocument: atlasDidDocument,
    );

    await client.configureAcl();
    return client;
  }

  /// Gets the list of mediator instances.
  Future<GetMediatorInstancesListResponseMessage> getMediatorInstancesList({
    int? limit,
    String? exclusiveStartKey,
  }) async {
    final requestMessage = GetInstancesListMessage.mediator(
      id: const Uuid().v4(),
      to: [serviceDidDocument.id],
      options: GetMediatorInstancesListRequestOptions(
        limit: limit,
        exclusiveStartKey: exclusiveStartKey,
      ),
    );

    final responseMessage = await sendServiceMessage(requestMessage).catchError((
      Object error,
    ) {
      if (error is ProblemReportMessage && error.body != null) {
        final body = ProblemReportBody.fromJson(error.body!);

        if (const ProblemCodeConverter().toJson(body.code) ==
            'e.msg.forbidden') {
          // ignore: only_throw_errors
          throw 'This feature is currently in closed beta and not enabled for your account. Submit a closed beta registration form with your DID (${error.to!.first}) at https://share.hsforms.com/1ayUlp606Qt27QDiiipff0g8oa2v to request access.';
        }
      }

      // ignore: only_throw_errors
      throw error;
    });

    return GetMediatorInstancesListResponseMessage(
      id: responseMessage.id,
      from: responseMessage.from,
      to: responseMessage.to,
      createdTime: responseMessage.createdTime,
      expiresTime: responseMessage.expiresTime,
      body: responseMessage.body,
    );
  }

  /// Deploys a new mediator instance.
  Future<DeployInstanceResponseMessage> deployMediatorInstance({
    required DeployMediatorInstanceOptions options,
  }) async {
    final requestMessage = DeployInstanceRequestMessage.mediator(
      id: const Uuid().v4(),
      to: [serviceDidDocument.id],
      options: options,
    );

    final responseMessage = await sendServiceMessage(requestMessage);

    return DeployInstanceResponseMessage.mediator(
      id: responseMessage.id,
      from: responseMessage.from!,
      to: responseMessage.to!,
      createdTime: responseMessage.createdTime,
      expiresTime: responseMessage.expiresTime,
      body: responseMessage.body!,
    );
  }

  /// Deploys a new MPX (Meeting Place) instance.
  Future<DeployInstanceResponseMessage> deployMpxInstance({
    required DeployMpxInstanceOptions options,
  }) async {
    final requestMessage = DeployInstanceRequestMessage.meetingPlace(
      id: const Uuid().v4(),
      to: [serviceDidDocument.id],
      options: options,
    );

    final responseMessage = await sendServiceMessage(requestMessage);

    return DeployInstanceResponseMessage.meetingPlace(
      id: responseMessage.id,
      from: responseMessage.from!,
      to: responseMessage.to!,
      createdTime: responseMessage.createdTime,
      expiresTime: responseMessage.expiresTime,
      body: responseMessage.body!,
    );
  }

  /// Deploys a new Trust Registry instance.
  Future<DeployInstanceResponseMessage> deployTrInstance({
    required DeployTrInstanceOptions options,
  }) async {
    final requestMessage = DeployInstanceRequestMessage.trustRegistry(
      id: const Uuid().v4(),
      to: [serviceDidDocument.id],
      options: options,
    );

    final responseMessage = await sendServiceMessage(requestMessage);

    return DeployInstanceResponseMessage.trustRegistry(
      id: responseMessage.id,
      from: responseMessage.from!,
      to: responseMessage.to!,
      createdTime: responseMessage.createdTime,
      expiresTime: responseMessage.expiresTime,
      body: responseMessage.body!,
    );
  }

  /// Gets the metadata for a specific mediator instance.
  Future<GetMediatorInstanceMetadataResponseMessage>
  getMediatorInstanceMetadata({required String serviceId}) async {
    final requestMessage = GetInstanceMetadataRequestMessage.mediator(
      id: const Uuid().v4(),
      to: [serviceDidDocument.id],
      options: GetMediatorInstanceMetadataOptions(serviceId: serviceId),
    );

    final responseMessage = await sendServiceMessage(requestMessage);

    return GetMediatorInstanceMetadataResponseMessage(
      id: responseMessage.id,
      from: responseMessage.from,
      to: responseMessage.to,
      createdTime: responseMessage.createdTime,
      expiresTime: responseMessage.expiresTime,
      body: responseMessage.body,
    );
  }

  /// Gets the metadata for a specific MPX instance.
  Future<GetMpxInstanceMetadataResponseMessage> getMpxInstanceMetadata({
    required String serviceId,
  }) async {
    final requestMessage = GetInstanceMetadataRequestMessage.meetingPlace(
      id: const Uuid().v4(),
      to: [serviceDidDocument.id],
      options: GetMpxInstanceMetadataOptions(serviceId: serviceId),
    );

    final responseMessage = await sendServiceMessage(requestMessage);

    return GetMpxInstanceMetadataResponseMessage(
      id: responseMessage.id,
      from: responseMessage.from,
      to: responseMessage.to,
      createdTime: responseMessage.createdTime,
      expiresTime: responseMessage.expiresTime,
      body: responseMessage.body,
    );
  }

  /// Gets the metadata for a specific Trust Registry instance.
  Future<GetTrInstanceMetadataResponseMessage> getTrInstanceMetadata({
    required String serviceId,
  }) async {
    final requestMessage = GetInstanceMetadataRequestMessage.trustRegistry(
      id: const Uuid().v4(),
      to: [serviceDidDocument.id],
      options: GetTrInstanceMetadataOptions(serviceId: serviceId),
    );

    final responseMessage = await sendServiceMessage(requestMessage);

    return GetTrInstanceMetadataResponseMessage(
      id: responseMessage.id,
      from: responseMessage.from,
      to: responseMessage.to,
      createdTime: responseMessage.createdTime,
      expiresTime: responseMessage.expiresTime,
      body: responseMessage.body,
    );
  }

  /// Destroys a mediator instance.
  Future<DestroyInstanceResponseMessage> destroyMediatorInstance({
    required String serviceId,
  }) async {
    final requestMessage = DestroyInstanceRequestMessage.mediator(
      id: const Uuid().v4(),
      to: [serviceDidDocument.id],
      options: DestroyMediatorInstanceOptions(serviceId: serviceId),
    );

    final responseMessage = await sendServiceMessage(requestMessage);

    return DestroyInstanceResponseMessage.mediator(
      id: responseMessage.id,
      from: responseMessage.from!,
      to: responseMessage.to!,
      createdTime: responseMessage.createdTime,
      expiresTime: responseMessage.expiresTime,
      body: responseMessage.body!,
    );
  }

  /// Destroys an MPX instance.
  Future<DestroyInstanceResponseMessage> destroyMpxInstance({
    required String serviceId,
  }) async {
    final requestMessage = DestroyInstanceRequestMessage.meetingPlace(
      id: const Uuid().v4(),
      to: [serviceDidDocument.id],
      options: DestroyMpxInstanceOptions(serviceId: serviceId),
    );

    final responseMessage = await sendServiceMessage(requestMessage);

    return DestroyInstanceResponseMessage.meetingPlace(
      id: responseMessage.id,
      from: responseMessage.from!,
      to: responseMessage.to!,
      createdTime: responseMessage.createdTime,
      expiresTime: responseMessage.expiresTime,
      body: responseMessage.body!,
    );
  }

  /// Destroys a Trust Registry instance.
  Future<DestroyInstanceResponseMessage> destroyTrInstance({
    required String serviceId,
  }) async {
    final requestMessage = DestroyInstanceRequestMessage.trustRegistry(
      id: const Uuid().v4(),
      to: [serviceDidDocument.id],
      options: DestroyTrInstanceOptions(serviceId: serviceId),
    );

    final responseMessage = await sendServiceMessage(requestMessage);

    return DestroyInstanceResponseMessage.trustRegistry(
      id: responseMessage.id,
      from: responseMessage.from!,
      to: responseMessage.to!,
      createdTime: responseMessage.createdTime,
      expiresTime: responseMessage.expiresTime,
      body: responseMessage.body!,
    );
  }

  /// Updates the deployment configuration of a mediator instance.
  Future<UpdateMediatorInstanceDeploymentResponseMessage>
  updateMediatorInstanceDeployment({
    required UpdateMediatorInstanceDeploymentOptions options,
  }) async {
    final requestMessage = UpdateInstanceDeploymentRequestMessage.mediator(
      id: const Uuid().v4(),
      to: [serviceDidDocument.id],
      options: options,
    );

    final responseMessage = await sendServiceMessage(requestMessage);

    return UpdateMediatorInstanceDeploymentResponseMessage(
      id: responseMessage.id,
      from: responseMessage.from,
      to: responseMessage.to,
      createdTime: responseMessage.createdTime,
      expiresTime: responseMessage.expiresTime,
      body: responseMessage.body,
    );
  }

  /// Updates the deployment configuration of an MPX instance.
  Future<UpdateMediatorInstanceDeploymentResponseMessage>
  updateMpxInstanceDeployment({
    required UpdateMpxInstanceDeploymentOptions options,
  }) async {
    final requestMessage = UpdateInstanceDeploymentRequestMessage.meetingPlace(
      id: const Uuid().v4(),
      to: [serviceDidDocument.id],
      options: options,
    );

    final responseMessage = await sendServiceMessage(requestMessage);

    return UpdateMediatorInstanceDeploymentResponseMessage(
      id: responseMessage.id,
      from: responseMessage.from,
      to: responseMessage.to,
      createdTime: responseMessage.createdTime,
      expiresTime: responseMessage.expiresTime,
      body: responseMessage.body,
    );
  }

  /// Updates the deployment configuration of a Trust Registry instance.
  Future<UpdateMediatorInstanceDeploymentResponseMessage>
  updateTrInstanceDeployment({
    required UpdateTrInstanceDeploymentOptions options,
  }) async {
    final requestMessage = UpdateInstanceDeploymentRequestMessage.trustRegistry(
      id: const Uuid().v4(),
      to: [serviceDidDocument.id],
      options: options,
    );

    final responseMessage = await sendServiceMessage(requestMessage);

    return UpdateMediatorInstanceDeploymentResponseMessage(
      id: responseMessage.id,
      from: responseMessage.from,
      to: responseMessage.to,
      createdTime: responseMessage.createdTime,
      expiresTime: responseMessage.expiresTime,
      body: responseMessage.body,
    );
  }

  /// Updates the configuration of a mediator instance.
  Future<UpdateMediatorInstanceConfigurationResponseMessage>
  updateMediatorInstanceConfiguration({
    required UpdateMediatorInstanceConfigurationOptions options,
  }) async {
    final requestMessage = UpdateInstanceConfigurationRequestMessage.mediator(
      id: const Uuid().v4(),
      to: [serviceDidDocument.id],
      options: options,
    );

    final responseMessage = await sendServiceMessage(requestMessage);

    return UpdateMediatorInstanceConfigurationResponseMessage(
      id: responseMessage.id,
      from: responseMessage.from,
      to: responseMessage.to,
      createdTime: responseMessage.createdTime,
      expiresTime: responseMessage.expiresTime,
      body: responseMessage.body,
    );
  }

  /// Gets the requests for mediators.
  Future<GetMediatorRequestsResponseMessage> getMediatorRequests({
    String? serviceId,
    int? limit,
    String? exclusiveStartKey,
  }) async {
    final requestMessage = GetRequestsMessage.mediator(
      id: const Uuid().v4(),
      to: [serviceDidDocument.id],
      options: GetMediatorInstanceRequestsRequestOptions(
        serviceId: serviceId,
        limit: limit,
        exclusiveStartKey: exclusiveStartKey,
      ),
    );

    final responseMessage = await sendServiceMessage(requestMessage);

    return GetMediatorRequestsResponseMessage(
      id: responseMessage.id,
      from: responseMessage.from,
      to: responseMessage.to,
      createdTime: responseMessage.createdTime,
      expiresTime: responseMessage.expiresTime,
      body: responseMessage.body,
    );
  }

  /// Gets the requests for MPX instances.
  Future<GetMpxRequestsResponseMessage> getMpxRequests({
    String? serviceId,
    int? limit,
    String? exclusiveStartKey,
  }) async {
    final requestMessage = GetRequestsMessage.meetingPlace(
      id: const Uuid().v4(),
      to: [serviceDidDocument.id],
      options: GetMpxInstanceRequestsRequestOptions(
        serviceId: serviceId,
        limit: limit,
        exclusiveStartKey: exclusiveStartKey,
      ),
    );

    final responseMessage = await sendServiceMessage(requestMessage);

    return GetMpxRequestsResponseMessage(
      id: responseMessage.id,
      from: responseMessage.from,
      to: responseMessage.to,
      createdTime: responseMessage.createdTime,
      expiresTime: responseMessage.expiresTime,
      body: responseMessage.body,
    );
  }

  /// Gets the requests for Trust Registry instances.
  Future<GetTrRequestsResponseMessage> getTrRequests({
    String? serviceId,
    int? limit,
    String? exclusiveStartKey,
  }) async {
    final requestMessage = GetRequestsMessage.trustRegistry(
      id: const Uuid().v4(),
      to: [serviceDidDocument.id],
      options: GetTrInstanceRequestsRequestOptions(
        serviceId: serviceId,
        limit: limit,
        exclusiveStartKey: exclusiveStartKey,
      ),
    );

    final responseMessage = await sendServiceMessage(requestMessage);

    return GetTrRequestsResponseMessage(
      id: responseMessage.id,
      from: responseMessage.from,
      to: responseMessage.to,
      createdTime: responseMessage.createdTime,
      expiresTime: responseMessage.expiresTime,
      body: responseMessage.body,
    );
  }

  /// Gets the list of MPX instances.
  Future<GetMpxInstancesListResponseMessage> getMpxInstancesList({
    int? limit,
    String? exclusiveStartKey,
  }) async {
    final requestMessage = GetInstancesListMessage.meetingPlace(
      id: const Uuid().v4(),
      to: [serviceDidDocument.id],
      options: GetMpxInstancesListRequestOptions(
        limit: limit,
        exclusiveStartKey: exclusiveStartKey,
      ),
    );

    final responseMessage = await sendServiceMessage(requestMessage);

    return GetMpxInstancesListResponseMessage(
      id: responseMessage.id,
      from: responseMessage.from,
      to: responseMessage.to,
      createdTime: responseMessage.createdTime,
      expiresTime: responseMessage.expiresTime,
      body: responseMessage.body,
    );
  }

  /// Gets the list of Trust Registry instances.
  Future<GetTrInstancesListResponseMessage> getTrInstancesList({
    int? limit,
    String? exclusiveStartKey,
  }) async {
    final requestMessage = GetInstancesListMessage.trustRegistry(
      id: const Uuid().v4(),
      to: [serviceDidDocument.id],
      options: GetTrInstancesListRequestOptions(
        limit: limit,
        exclusiveStartKey: exclusiveStartKey,
      ),
    );

    final responseMessage = await sendServiceMessage(requestMessage);

    return GetTrInstancesListResponseMessage(
      id: responseMessage.id,
      from: responseMessage.from,
      to: responseMessage.to,
      createdTime: responseMessage.createdTime,
      expiresTime: responseMessage.expiresTime,
      body: responseMessage.body,
    );
  }
}
