import 'package:json_annotation/json_annotation.dart';

import 'base_options.dart';

part 'get_mpx_instance_requests_request_options.g.dart';

/// Options for getting MPX instance requests.
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class GetMpxInstanceRequestsRequestOptions extends BaseOptions {
  @override
  @JsonKey(includeToJson: true)
  final String serviceType = 'mpx';

  /// The ID of the service instance.
  final String? serviceId;

  /// Maximum number of requests to return.
  final int? limit;

  /// Exclusive start key for pagination.
  final String? exclusiveStartKey;

  /// Creates a [GetMpxInstanceRequestsRequestOptions] instance.
  GetMpxInstanceRequestsRequestOptions({
    this.serviceId,
    this.limit,
    this.exclusiveStartKey,
  });

  /// Creates a [GetMpxInstanceRequestsRequestOptions] from a JSON map.
  factory GetMpxInstanceRequestsRequestOptions.fromJson(
    Map<String, dynamic> json,
  ) => _$GetMpxInstanceRequestsRequestOptionsFromJson(json);

  /// Converts the [GetMpxInstanceRequestsRequestOptions] instance to JSON.
  Map<String, dynamic> toJson() =>
      _$GetMpxInstanceRequestsRequestOptionsToJson(this);
}
