import '../../../models/request_bodies/get_mediator_instance_metadata_options.dart';
import '../../../models/request_bodies/get_mpx_instance_metadata_options.dart';
import '../../../models/request_bodies/get_tr_instance_metadata_options.dart';
import '../base_messages/base_request_message.dart';

/// Message for getting metadata of an instance.
class GetInstanceMetadataRequestMessage extends BaseRequestMessage {
  /// Creates a get instance metadata message.
  GetInstanceMetadataRequestMessage._({
    required super.id,
    required super.to,
    required super.operationName,
    super.from,
    super.createdTime,
    super.expiresTime,
    super.body = const {},
    super.threadId,
  });

  /// Creates a get mediator instance metadata message.
  factory GetInstanceMetadataRequestMessage.mediator({
    required String id,
    required List<String> to,
    required GetMediatorInstanceMetadataOptions options,
    String? from,
    DateTime? createdTime,
    DateTime? expiresTime,
    String? threadId,
  }) {
    return GetInstanceMetadataRequestMessage._(
      id: id,
      to: to,
      from: from,
      createdTime: createdTime,
      expiresTime: expiresTime,
      body: options.toJson(),
      threadId: threadId,
      operationName: 'getServiceInstanceMetadata',
    );
  }

  /// Creates a get meeting place instance metadata message.
  factory GetInstanceMetadataRequestMessage.meetingPlace({
    required String id,
    required List<String> to,
    required GetMpxInstanceMetadataOptions options,
    String? from,
    DateTime? createdTime,
    DateTime? expiresTime,
    String? threadId,
  }) {
    return GetInstanceMetadataRequestMessage._(
      id: id,
      to: to,
      from: from,
      createdTime: createdTime,
      expiresTime: expiresTime,
      body: options.toJson(),
      threadId: threadId,
      operationName: 'getServiceInstanceMetadata',
    );
  }

  /// Creates a get trust registry instance metadata message.
  factory GetInstanceMetadataRequestMessage.trustRegistry({
    required String id,
    required List<String> to,
    required GetTrInstanceMetadataOptions options,
    String? from,
    DateTime? createdTime,
    DateTime? expiresTime,
    String? threadId,
  }) {
    return GetInstanceMetadataRequestMessage._(
      id: id,
      to: to,
      from: from,
      createdTime: createdTime,
      expiresTime: expiresTime,
      body: options.toJson(),
      threadId: threadId,
      operationName: 'getServiceInstanceMetadata',
    );
  }
}
