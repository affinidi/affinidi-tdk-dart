import 'package:json_annotation/json_annotation.dart';

import 'base_options.dart';

part 'get_tr_instances_list_request_options.g.dart';

/// Options for getting a list of TR instances.
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class GetTrInstancesListRequestOptions extends BaseOptions {
  @override
  @JsonKey(includeToJson: true)
  final String serviceType = 'tr';

  /// The maximum number of instances to return.
  final int? limit;

  /// The exclusive start key for pagination.
  final String? exclusiveStartKey;

  /// Creates a [GetTrInstancesListRequestOptions] instance.
  GetTrInstancesListRequestOptions({this.limit, this.exclusiveStartKey});

  /// Creates a [GetTrInstancesListRequestOptions] from a JSON map.
  factory GetTrInstancesListRequestOptions.fromJson(
    Map<String, dynamic> json,
  ) => _$GetTrInstancesListRequestOptionsFromJson(json);

  /// Converts the [GetTrInstancesListRequestOptions] instance to a JSON map.
  Map<String, dynamic> toJson() =>
      _$GetTrInstancesListRequestOptionsToJson(this);
}
