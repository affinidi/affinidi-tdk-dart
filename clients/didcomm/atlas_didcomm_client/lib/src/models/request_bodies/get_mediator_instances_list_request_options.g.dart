// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'get_mediator_instances_list_request_options.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GetMediatorInstancesListRequestOptions
_$GetMediatorInstancesListRequestOptionsFromJson(Map<String, dynamic> json) =>
    GetMediatorInstancesListRequestOptions(
      limit: (json['limit'] as num?)?.toInt(),
      exclusiveStartKey: json['exclusiveStartKey'] as String?,
    );

Map<String, dynamic> _$GetMediatorInstancesListRequestOptionsToJson(
  GetMediatorInstancesListRequestOptions instance,
) => <String, dynamic>{
  'serviceType': instance.serviceType,
  if (instance.limit case final value?) 'limit': value,
  if (instance.exclusiveStartKey case final value?) 'exclusiveStartKey': value,
};
