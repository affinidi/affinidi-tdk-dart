import '../../../models/request_bodies/update_mediator_instance_deployment_options.dart';
import '../../../models/request_bodies/update_mpx_instance_deployment_options.dart';
import '../../../models/request_bodies/update_tr_instance_deployment_options.dart';
import '../base_messages/base_request_message.dart';

/// Message for updating instance deployment.
class UpdateInstanceDeploymentRequestMessage extends BaseRequestMessage {
  /// Creates an update instance deployment message.
  UpdateInstanceDeploymentRequestMessage._({
    required super.id,
    required super.to,
    required super.operationName,
    super.from,
    super.createdTime,
    super.expiresTime,
    super.body = const {},
    super.threadId,
  });

  /// Creates an update mediator instance deployment message.
  factory UpdateInstanceDeploymentRequestMessage.mediator({
    required String id,
    required List<String> to,
    required UpdateMediatorInstanceDeploymentOptions options,
    String? from,
    DateTime? createdTime,
    DateTime? expiresTime,
    String? threadId,
  }) {
    return UpdateInstanceDeploymentRequestMessage._(
      id: id,
      to: to,
      from: from,
      createdTime: createdTime,
      expiresTime: expiresTime,
      body: options.toJson(),
      threadId: threadId,
      operationName: 'updateServiceInstanceDeployment',
    );
  }

  /// Creates an update meeting place instance deployment message.
  factory UpdateInstanceDeploymentRequestMessage.meetingPlace({
    required String id,
    required List<String> to,
    required UpdateMpxInstanceDeploymentOptions options,
    String? from,
    DateTime? createdTime,
    DateTime? expiresTime,
    String? threadId,
  }) {
    return UpdateInstanceDeploymentRequestMessage._(
      id: id,
      to: to,
      from: from,
      createdTime: createdTime,
      expiresTime: expiresTime,
      body: options.toJson(),
      threadId: threadId,
      operationName: 'updateServiceInstanceDeployment',
    );
  }

  /// Creates an update trust registry instance deployment message.
  factory UpdateInstanceDeploymentRequestMessage.trustRegistry({
    required String id,
    required List<String> to,
    required UpdateTrInstanceDeploymentOptions options,
    String? from,
    DateTime? createdTime,
    DateTime? expiresTime,
    String? threadId,
  }) {
    return UpdateInstanceDeploymentRequestMessage._(
      id: id,
      to: to,
      from: from,
      createdTime: createdTime,
      expiresTime: expiresTime,
      body: options.toJson(),
      threadId: threadId,
      operationName: 'updateServiceInstanceDeployment',
    );
  }
}
