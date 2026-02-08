import 'package:json_annotation/json_annotation.dart';

import '../../../models/service_type/service_type.dart';
import '../base_messages/base_response_message.dart';

part 'deploy_instance_response_message.g.dart';

/// Base sealed class for all deploy instance responses.
sealed class DeployInstanceResponse {
  /// Private constructor to prevent external instantiation.
  const DeployInstanceResponse();

  /// Factory constructor to create the appropriate response type from JSON.
  factory DeployInstanceResponse.fromJson(Map<String, dynamic> json) {
    // Determine the type based on serviceType field
    final serviceType = json['serviceType'] as String?;
    return switch (serviceType) {
      'MEDIATOR' => DeployMediatorInstanceResponse.fromJson(json),
      'MPX' => DeployMpxInstanceResponse.fromJson(json),
      'TR' => DeployTrustRegistryInstanceResponse.fromJson(json),
      _ => throw ArgumentError(
        'Unknown deploy instance response type: $serviceType',
      ),
    };
  }

  /// Converts this response to JSON.
  Map<String, dynamic> toJson();

  /// The service ID.
  String get serviceId;

  /// The service request ID.
  String get serviceRequestId;

  /// The optional message.
  String? get message;

  /// The service type.
  ServiceType? get serviceType;
}

@JsonSerializable(includeIfNull: false, explicitToJson: true)
/// Response data for deploy mediator instance operation.
final class DeployMediatorInstanceResponse extends DeployInstanceResponse {
  /// The service ID.
  @override
  final String serviceId;

  /// The service request ID.
  @override
  final String serviceRequestId;

  /// The deployment message/status.
  @override
  final String? message;

  /// The service type.
  @override
  final ServiceType? serviceType;

  /// Creates a deploy mediator instance response.
  DeployMediatorInstanceResponse({
    required this.serviceId,
    required this.serviceRequestId,
    this.message,
    this.serviceType,
  }) : super();

  /// Creates a deploy mediator instance response from JSON.
  factory DeployMediatorInstanceResponse.fromJson(Map<String, dynamic> json) =>
      _$DeployMediatorInstanceResponseFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$DeployMediatorInstanceResponseToJson(this);
}

@JsonSerializable(includeIfNull: false, explicitToJson: true)
/// Response data for deploy MPX instance operation.
final class DeployMpxInstanceResponse extends DeployInstanceResponse {
  /// The service ID.
  @override
  final String serviceId;

  /// The service request ID.
  @override
  final String serviceRequestId;

  /// The deployment message/status.
  @override
  final String? message;

  /// The service type.
  @override
  final ServiceType? serviceType;

  /// Creates a deploy MPX instance response.
  DeployMpxInstanceResponse({
    required this.serviceId,
    required this.serviceRequestId,
    this.message,
    this.serviceType,
  }) : super();

  /// Creates a deploy MPX instance response from JSON.
  factory DeployMpxInstanceResponse.fromJson(Map<String, dynamic> json) =>
      _$DeployMpxInstanceResponseFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$DeployMpxInstanceResponseToJson(this);
}

@JsonSerializable(includeIfNull: false, explicitToJson: true)
/// Response data for deploy trust registry instance operation.
final class DeployTrustRegistryInstanceResponse extends DeployInstanceResponse {
  /// The service ID.
  @override
  final String serviceId;

  /// The service request ID.
  @override
  final String serviceRequestId;

  /// The deployment message/status.
  @override
  final String? message;

  /// The service type.
  @override
  final ServiceType? serviceType;

  /// Creates a deploy trust registry instance response.
  DeployTrustRegistryInstanceResponse({
    required this.serviceId,
    required this.serviceRequestId,
    this.message,
    this.serviceType,
  }) : super();

  /// Creates a deploy trust registry instance response from JSON.
  factory DeployTrustRegistryInstanceResponse.fromJson(
    Map<String, dynamic> json,
  ) => _$DeployTrustRegistryInstanceResponseFromJson(json);

  @override
  Map<String, dynamic> toJson() =>
      _$DeployTrustRegistryInstanceResponseToJson(this);
}

/// Response message for deploy instance operation.
class DeployInstanceResponseMessage
    extends BaseResponseMessage<DeployInstanceResponse> {
  /// Creates a deploy instance response message.
  DeployInstanceResponseMessage._({
    required super.id,
    required super.from,
    required super.to,
    required super.operationName,
    super.createdTime,
    super.expiresTime,
    super.threadId,
    super.body = const {},
  }) : super(fromJson: DeployInstanceResponse.fromJson);

  /// Creates a deploy mediator instance response message.
  factory DeployInstanceResponseMessage.mediator({
    required String id,
    required String from,
    required List<String> to,
    DateTime? createdTime,
    DateTime? expiresTime,
    String? threadId,
    Map<String, dynamic> body = const {},
  }) {
    return DeployInstanceResponseMessage._(
      id: id,
      from: from,
      to: to,
      createdTime: createdTime,
      expiresTime: expiresTime,
      threadId: threadId,
      body: body,
      operationName: 'deployServiceInstance',
    );
  }

  /// Creates a deploy MPX instance response message.
  factory DeployInstanceResponseMessage.meetingPlace({
    required String id,
    required String from,
    required List<String> to,
    DateTime? createdTime,
    DateTime? expiresTime,
    String? threadId,
    Map<String, dynamic> body = const {},
  }) {
    return DeployInstanceResponseMessage._(
      id: id,
      from: from,
      to: to,
      createdTime: createdTime,
      expiresTime: expiresTime,
      threadId: threadId,
      body: body,
      operationName: 'deployServiceInstance',
    );
  }

  /// Creates a deploy Trust Registry instance response message.
  factory DeployInstanceResponseMessage.trustRegistry({
    required String id,
    required String from,
    required List<String> to,
    DateTime? createdTime,
    DateTime? expiresTime,
    String? threadId,
    Map<String, dynamic> body = const {},
  }) {
    return DeployInstanceResponseMessage._(
      id: id,
      from: from,
      to: to,
      createdTime: createdTime,
      expiresTime: expiresTime,
      threadId: threadId,
      body: body,
      operationName: 'deployServiceInstance',
    );
  }
}
