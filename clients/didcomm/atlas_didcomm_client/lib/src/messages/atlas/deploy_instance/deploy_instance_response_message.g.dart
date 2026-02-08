// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'deploy_instance_response_message.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DeployMediatorInstanceResponse _$DeployMediatorInstanceResponseFromJson(
  Map<String, dynamic> json,
) => DeployMediatorInstanceResponse(
  serviceId: json['serviceId'] as String,
  serviceRequestId: json['serviceRequestId'] as String,
  message: json['message'] as String?,
  serviceType: $enumDecodeNullable(_$ServiceTypeEnumMap, json['serviceType']),
);

Map<String, dynamic> _$DeployMediatorInstanceResponseToJson(
  DeployMediatorInstanceResponse instance,
) => <String, dynamic>{
  'serviceId': instance.serviceId,
  'serviceRequestId': instance.serviceRequestId,
  if (instance.message case final value?) 'message': value,
  if (_$ServiceTypeEnumMap[instance.serviceType] case final value?)
    'serviceType': value,
};

const _$ServiceTypeEnumMap = {
  ServiceType.mediator: 'MEDIATOR',
  ServiceType.meetingPlace: 'MPX',
  ServiceType.trustRegistry: 'TR',
};

DeployMpxInstanceResponse _$DeployMpxInstanceResponseFromJson(
  Map<String, dynamic> json,
) => DeployMpxInstanceResponse(
  serviceId: json['serviceId'] as String,
  serviceRequestId: json['serviceRequestId'] as String,
  message: json['message'] as String?,
  serviceType: $enumDecodeNullable(_$ServiceTypeEnumMap, json['serviceType']),
);

Map<String, dynamic> _$DeployMpxInstanceResponseToJson(
  DeployMpxInstanceResponse instance,
) => <String, dynamic>{
  'serviceId': instance.serviceId,
  'serviceRequestId': instance.serviceRequestId,
  if (instance.message case final value?) 'message': value,
  if (_$ServiceTypeEnumMap[instance.serviceType] case final value?)
    'serviceType': value,
};

DeployTrustRegistryInstanceResponse
_$DeployTrustRegistryInstanceResponseFromJson(Map<String, dynamic> json) =>
    DeployTrustRegistryInstanceResponse(
      serviceId: json['serviceId'] as String,
      serviceRequestId: json['serviceRequestId'] as String,
      message: json['message'] as String?,
      serviceType: $enumDecodeNullable(
        _$ServiceTypeEnumMap,
        json['serviceType'],
      ),
    );

Map<String, dynamic> _$DeployTrustRegistryInstanceResponseToJson(
  DeployTrustRegistryInstanceResponse instance,
) => <String, dynamic>{
  'serviceId': instance.serviceId,
  'serviceRequestId': instance.serviceRequestId,
  if (instance.message case final value?) 'message': value,
  if (_$ServiceTypeEnumMap[instance.serviceType] case final value?)
    'serviceType': value,
};
