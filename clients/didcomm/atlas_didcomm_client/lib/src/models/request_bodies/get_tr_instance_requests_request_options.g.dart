// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'get_tr_instance_requests_request_options.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GetTrInstanceRequestsRequestOptions
_$GetTrInstanceRequestsRequestOptionsFromJson(Map<String, dynamic> json) =>
    GetTrInstanceRequestsRequestOptions(
      serviceId: json['serviceId'] as String?,
      limit: (json['limit'] as num?)?.toInt(),
      exclusiveStartKey: json['exclusiveStartKey'] as String?,
    );

Map<String, dynamic> _$GetTrInstanceRequestsRequestOptionsToJson(
  GetTrInstanceRequestsRequestOptions instance,
) => <String, dynamic>{
  'serviceType': instance.serviceType,
  if (instance.serviceId case final value?) 'serviceId': value,
  if (instance.limit case final value?) 'limit': value,
  if (instance.exclusiveStartKey case final value?) 'exclusiveStartKey': value,
};
