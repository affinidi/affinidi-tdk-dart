// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'update_mediator_instance_configuration_options.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UpdateMediatorInstanceConfigurationOptions
_$UpdateMediatorInstanceConfigurationOptionsFromJson(
  Map<String, dynamic> json,
) => UpdateMediatorInstanceConfigurationOptions(
  serviceId: json['serviceId'] as String,
  acl: (json['acl'] as Map<String, dynamic>?)?.map(
    (k, e) => MapEntry(k, e as num),
  ),
);

Map<String, dynamic> _$UpdateMediatorInstanceConfigurationOptionsToJson(
  UpdateMediatorInstanceConfigurationOptions instance,
) => <String, dynamic>{
  'serviceType': instance.serviceType,
  'serviceId': instance.serviceId,
  if (instance.acl case final value?) 'acl': value,
};
