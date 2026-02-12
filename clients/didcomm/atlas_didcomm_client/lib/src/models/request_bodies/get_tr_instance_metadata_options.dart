import 'package:json_annotation/json_annotation.dart';

import 'base_options.dart';

part 'get_tr_instance_metadata_options.g.dart';

/// Options for getting Trust Registry (TR) instance metadata.
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class GetTrInstanceMetadataOptions extends BaseOptions {
  @override
  @JsonKey(includeToJson: true)
  final String serviceType = 'tr';

  /// The ID of the service instance.
  final String serviceId;

  /// Creates a [GetTrInstanceMetadataOptions] instance.
  GetTrInstanceMetadataOptions({required this.serviceId});

  /// Creates a [GetTrInstanceMetadataOptions] from a JSON map.
  factory GetTrInstanceMetadataOptions.fromJson(Map<String, dynamic> json) =>
      _$GetTrInstanceMetadataOptionsFromJson(json);

  /// Converts the [GetTrInstanceMetadataOptions] instance to JSON.
  Map<String, dynamic> toJson() => _$GetTrInstanceMetadataOptionsToJson(this);
}
