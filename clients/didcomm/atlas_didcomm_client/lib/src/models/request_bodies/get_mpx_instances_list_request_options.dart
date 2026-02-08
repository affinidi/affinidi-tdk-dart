import 'package:json_annotation/json_annotation.dart';

import 'base_options.dart';

part 'get_mpx_instances_list_request_options.g.dart';

/// Options for getting a list of MPX instances.
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class GetMpxInstancesListRequestOptions extends BaseOptions {
  @override
  @JsonKey(includeToJson: true)
  final String serviceType = 'mpx';

  /// The maximum number of instances to return.
  final int? limit;

  /// The exclusive start key for pagination.
  final String? exclusiveStartKey;

  /// Creates a [GetMpxInstancesListRequestOptions] instance.
  GetMpxInstancesListRequestOptions({this.limit, this.exclusiveStartKey});

  /// Creates a [GetMpxInstancesListRequestOptions] from a JSON map.
  factory GetMpxInstancesListRequestOptions.fromJson(
    Map<String, dynamic> json,
  ) => _$GetMpxInstancesListRequestOptionsFromJson(json);

  /// Converts the [GetMpxInstancesListRequestOptions] instance to a JSON map.
  Map<String, dynamic> toJson() =>
      _$GetMpxInstancesListRequestOptionsToJson(this);
}
