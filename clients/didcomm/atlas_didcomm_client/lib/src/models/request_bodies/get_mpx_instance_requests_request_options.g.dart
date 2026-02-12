// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'get_mpx_instance_requests_request_options.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GetMpxInstanceRequestsRequestOptions
_$GetMpxInstanceRequestsRequestOptionsFromJson(Map<String, dynamic> json) =>
    GetMpxInstanceRequestsRequestOptions(
      serviceId: json['serviceId'] as String?,
      limit: (json['limit'] as num?)?.toInt(),
      exclusiveStartKey: json['exclusiveStartKey'] as String?,
    );

Map<String, dynamic> _$GetMpxInstanceRequestsRequestOptionsToJson(
  GetMpxInstanceRequestsRequestOptions instance,
) => <String, dynamic>{
  'serviceType': instance.serviceType,
  if (instance.serviceId case final value?) 'serviceId': value,
  if (instance.limit case final value?) 'limit': value,
  if (instance.exclusiveStartKey case final value?) 'exclusiveStartKey': value,
};
