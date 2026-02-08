import 'package:json_annotation/json_annotation.dart';

import 'base_options.dart';

part 'get_mediator_instances_list_request_options.g.dart';

/// Options for getting a list of mediator instances.
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class GetMediatorInstancesListRequestOptions extends BaseOptions {
  @override
  @JsonKey(includeToJson: true)
  final String serviceType = 'mediator';

  /// The maximum number of instances to return.
  final int? limit;

  /// The exclusive start key for pagination.
  final String? exclusiveStartKey;

  /// Creates a [GetMediatorInstancesListRequestOptions] instance.
  GetMediatorInstancesListRequestOptions({this.limit, this.exclusiveStartKey});

  /// Creates a [GetMediatorInstancesListRequestOptions] from a JSON map.
  factory GetMediatorInstancesListRequestOptions.fromJson(
    Map<String, dynamic> json,
  ) => _$GetMediatorInstancesListRequestOptionsFromJson(json);

  /// Converts the [GetMediatorInstancesListRequestOptions] instance to a JSON map.
  Map<String, dynamic> toJson() =>
      _$GetMediatorInstancesListRequestOptionsToJson(this);
}
