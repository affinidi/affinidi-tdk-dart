import 'package:json_annotation/json_annotation.dart';

import 'base_options.dart';

part 'get_tr_instance_requests_request_options.g.dart';

/// Options for getting TR instance requests.
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class GetTrInstanceRequestsRequestOptions extends BaseOptions {
  @override
  @JsonKey(includeToJson: true)
  final String serviceType = 'tr';

  /// The ID of the service instance.
  final String? serviceId;

  /// Maximum number of requests to return.
  final int? limit;

  /// Exclusive start key for pagination.
  final String? exclusiveStartKey;

  /// Creates a [GetTrInstanceRequestsRequestOptions] instance.
  GetTrInstanceRequestsRequestOptions({
    this.serviceId,
    this.limit,
    this.exclusiveStartKey,
  });

  /// Creates a [GetTrInstanceRequestsRequestOptions] from a JSON map.
  factory GetTrInstanceRequestsRequestOptions.fromJson(
    Map<String, dynamic> json,
  ) => _$GetTrInstanceRequestsRequestOptionsFromJson(json);

  /// Converts the [GetTrInstanceRequestsRequestOptions] instance to JSON.
  Map<String, dynamic> toJson() =>
      _$GetTrInstanceRequestsRequestOptionsToJson(this);
}
