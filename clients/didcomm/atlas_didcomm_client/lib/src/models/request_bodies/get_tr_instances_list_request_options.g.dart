// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'get_tr_instances_list_request_options.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GetTrInstancesListRequestOptions _$GetTrInstancesListRequestOptionsFromJson(
  Map<String, dynamic> json,
) => GetTrInstancesListRequestOptions(
  limit: (json['limit'] as num?)?.toInt(),
  exclusiveStartKey: json['exclusiveStartKey'] as String?,
);

Map<String, dynamic> _$GetTrInstancesListRequestOptionsToJson(
  GetTrInstancesListRequestOptions instance,
) => <String, dynamic>{
  'serviceType': instance.serviceType,
  if (instance.limit case final value?) 'limit': value,
  if (instance.exclusiveStartKey case final value?) 'exclusiveStartKey': value,
};
