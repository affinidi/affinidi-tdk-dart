import 'package:json_annotation/json_annotation.dart';

import 'base_options.dart';

part 'get_mediator_instance_metadata_options.g.dart';

/// Options for getting mediator instance metadata.
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class GetMediatorInstanceMetadataOptions extends BaseOptions {
  @override
  @JsonKey(includeToJson: true)
  final String serviceType = 'mediator';

  /// The ID of the service instance.
  final String serviceId;

  /// Creates a [GetMediatorInstanceMetadataOptions] instance.
  GetMediatorInstanceMetadataOptions({required this.serviceId});

  /// Creates a [GetMediatorInstanceMetadataOptions] from a JSON map.
  factory GetMediatorInstanceMetadataOptions.fromJson(
    Map<String, dynamic> json,
  ) => _$GetMediatorInstanceMetadataOptionsFromJson(json);

  /// Converts the [GetMediatorInstanceMetadataOptions] instance to JSON.
  Map<String, dynamic> toJson() =>
      _$GetMediatorInstanceMetadataOptionsToJson(this);
}
