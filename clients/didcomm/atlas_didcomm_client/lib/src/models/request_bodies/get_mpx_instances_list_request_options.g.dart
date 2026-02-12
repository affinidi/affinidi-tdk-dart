// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'get_mpx_instances_list_request_options.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GetMpxInstancesListRequestOptions _$GetMpxInstancesListRequestOptionsFromJson(
  Map<String, dynamic> json,
) => GetMpxInstancesListRequestOptions(
  limit: (json['limit'] as num?)?.toInt(),
  exclusiveStartKey: json['exclusiveStartKey'] as String?,
);

Map<String, dynamic> _$GetMpxInstancesListRequestOptionsToJson(
  GetMpxInstancesListRequestOptions instance,
) => <String, dynamic>{
  'serviceType': instance.serviceType,
  if (instance.limit case final value?) 'limit': value,
  if (instance.exclusiveStartKey case final value?) 'exclusiveStartKey': value,
};
