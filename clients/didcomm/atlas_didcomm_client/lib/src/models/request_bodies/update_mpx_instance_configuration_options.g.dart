// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'update_mpx_instance_configuration_options.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UpdateMpxInstanceConfigurationOptions
_$UpdateMpxInstanceConfigurationOptionsFromJson(Map<String, dynamic> json) =>
    UpdateMpxInstanceConfigurationOptions(
      serviceId: json['serviceId'] as String,
      acl: (json['acl'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, e as num),
      ),
    );

Map<String, dynamic> _$UpdateMpxInstanceConfigurationOptionsToJson(
  UpdateMpxInstanceConfigurationOptions instance,
) => <String, dynamic>{
  'serviceType': instance.serviceType,
  'serviceId': instance.serviceId,
  if (instance.acl case final value?) 'acl': value,
};
