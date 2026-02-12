// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'update_mediator_instance_deployment_options.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UpdateMediatorInstanceDeploymentOptions
_$UpdateMediatorInstanceDeploymentOptionsFromJson(Map<String, dynamic> json) =>
    UpdateMediatorInstanceDeploymentOptions(
      serviceId: json['serviceId'] as String,
      serviceSize: $enumDecodeNullable(
        _$ServiceSizeEnumMap,
        json['serviceSize'],
      ),
      mediatorAclMode: $enumDecodeNullable(
        _$MediatorAclModeEnumMap,
        json['mediatorAclMode'],
      ),
      name: json['name'] as String?,
      description: json['description'] as String?,
      defaultMediatorDid: json['defaultMediatorDid'] as String?,
      administratorDids: json['administratorDids'] as String?,
      corsAllowedOrigins: json['corsAllowedOrigins'] as String?,
    );

Map<String, dynamic> _$UpdateMediatorInstanceDeploymentOptionsToJson(
  UpdateMediatorInstanceDeploymentOptions instance,
) => <String, dynamic>{
  'serviceType': instance.serviceType,
  'serviceId': instance.serviceId,
  if (_$ServiceSizeEnumMap[instance.serviceSize] case final value?)
    'serviceSize': value,
  if (_$MediatorAclModeEnumMap[instance.mediatorAclMode] case final value?)
    'mediatorAclMode': value,
  if (instance.name case final value?) 'name': value,
  if (instance.description case final value?) 'description': value,
  if (instance.defaultMediatorDid case final value?)
    'defaultMediatorDid': value,
  if (instance.administratorDids case final value?) 'administratorDids': value,
  if (instance.corsAllowedOrigins case final value?)
    'corsAllowedOrigins': value,
};

const _$ServiceSizeEnumMap = {
  ServiceSize.dev: 'dev',
  ServiceSize.tiny: 'tiny',
  ServiceSize.small: 'small',
  ServiceSize.medium: 'medium',
  ServiceSize.large: 'large',
};

const _$MediatorAclModeEnumMap = {
  MediatorAclMode.explicitDeny: 'explicit_deny',
  MediatorAclMode.explicitAllow: 'explicit_allow',
};
