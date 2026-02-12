import 'package:json_annotation/json_annotation.dart';

import 'base_options.dart';

part 'get_mpx_instance_metadata_options.g.dart';

/// Options for getting MPX (Meeting Place) instance metadata.
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class GetMpxInstanceMetadataOptions extends BaseOptions {
  @override
  @JsonKey(includeToJson: true)
  final String serviceType = 'mpx';

  /// The ID of the service instance.
  final String serviceId;

  /// Creates a [GetMpxInstanceMetadataOptions] instance.
  GetMpxInstanceMetadataOptions({required this.serviceId});

  /// Creates a [GetMpxInstanceMetadataOptions] from a JSON map.
  factory GetMpxInstanceMetadataOptions.fromJson(Map<String, dynamic> json) =>
      _$GetMpxInstanceMetadataOptionsFromJson(json);

  /// Converts the [GetMpxInstanceMetadataOptions] instance to JSON.
  Map<String, dynamic> toJson() => _$GetMpxInstanceMetadataOptionsToJson(this);
}
