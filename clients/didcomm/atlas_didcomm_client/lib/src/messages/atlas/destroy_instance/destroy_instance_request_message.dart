import '../../../models/request_bodies/destroy_mediator_instance_options.dart';
import '../../../models/request_bodies/destroy_mpx_instance_options.dart';
import '../../../models/request_bodies/destroy_tr_instance_options.dart';
import '../base_messages/base_request_message.dart';

/// Message for destroying an instance.
class DestroyInstanceRequestMessage extends BaseRequestMessage {
  /// Creates a destroy instance message.
  DestroyInstanceRequestMessage._({
    required super.id,
    required super.to,
    required super.operationName,
    super.from,
    super.createdTime,
    super.expiresTime,
    super.body = const {},
    super.threadId,
  });

  /// Creates a destroy mediator instance message.
  factory DestroyInstanceRequestMessage.mediator({
    required String id,
    required List<String> to,
    required DestroyMediatorInstanceOptions options,
    String? from,
    DateTime? createdTime,
    DateTime? expiresTime,
    String? threadId,
  }) {
    return DestroyInstanceRequestMessage._(
      id: id,
      to: to,
      from: from,
      createdTime: createdTime,
      expiresTime: expiresTime,
      body: options.toJson(),
      threadId: threadId,
      operationName: 'destroyServiceInstance',
    );
  }

  /// Creates a destroy meeting place instance message.
  factory DestroyInstanceRequestMessage.meetingPlace({
    required String id,
    required List<String> to,
    required DestroyMpxInstanceOptions options,
    String? from,
    DateTime? createdTime,
    DateTime? expiresTime,
    String? threadId,
  }) {
    return DestroyInstanceRequestMessage._(
      id: id,
      to: to,
      from: from,
      createdTime: createdTime,
      expiresTime: expiresTime,
      body: options.toJson(),
      threadId: threadId,
      operationName: 'destroyServiceInstance',
    );
  }

  /// Creates a destroy trust registry instance message.
  factory DestroyInstanceRequestMessage.trustRegistry({
    required String id,
    required List<String> to,
    required DestroyTrInstanceOptions options,
    String? from,
    DateTime? createdTime,
    DateTime? expiresTime,
    String? threadId,
  }) {
    return DestroyInstanceRequestMessage._(
      id: id,
      to: to,
      from: from,
      createdTime: createdTime,
      expiresTime: expiresTime,
      body: options.toJson(),
      threadId: threadId,
      operationName: 'destroyServiceInstance',
    );
  }
}
