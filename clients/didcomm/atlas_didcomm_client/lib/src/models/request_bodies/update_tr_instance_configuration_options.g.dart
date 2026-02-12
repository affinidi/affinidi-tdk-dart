// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'update_tr_instance_configuration_options.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UpdateTrInstanceConfigurationOptions
_$UpdateTrInstanceConfigurationOptionsFromJson(Map<String, dynamic> json) =>
    UpdateTrInstanceConfigurationOptions(
      serviceId: json['serviceId'] as String,
      acl: (json['acl'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, e as num),
      ),
    );

Map<String, dynamic> _$UpdateTrInstanceConfigurationOptionsToJson(
  UpdateTrInstanceConfigurationOptions instance,
) => <String, dynamic>{
  'serviceType': instance.serviceType,
  'serviceId': instance.serviceId,
  if (instance.acl case final value?) 'acl': value,
};
