import 'package:json_annotation/json_annotation.dart';

import 'base_options.dart';

part 'get_mediator_instance_requests_request_options.g.dart';

/// Options for getting mediator instance requests.
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class GetMediatorInstanceRequestsRequestOptions extends BaseOptions {
  @override
  @JsonKey(includeToJson: true)
  final String serviceType = 'mediator';

  /// The ID of the service instance.
  final String? serviceId;

  /// Maximum number of requests to return.
  final int? limit;

  /// Exclusive start key for pagination.
  final String? exclusiveStartKey;

  /// Creates a [GetMediatorInstanceRequestsRequestOptions] instance.
  GetMediatorInstanceRequestsRequestOptions({
    this.serviceId,
    this.limit,
    this.exclusiveStartKey,
  });

  /// Creates a [GetMediatorInstanceRequestsRequestOptions] from a JSON map.
  factory GetMediatorInstanceRequestsRequestOptions.fromJson(
    Map<String, dynamic> json,
  ) => _$GetMediatorInstanceRequestsRequestOptionsFromJson(json);

  /// Converts the [GetMediatorInstanceRequestsRequestOptions] instance to JSON.
  Map<String, dynamic> toJson() =>
      _$GetMediatorInstanceRequestsRequestOptionsToJson(this);
}
