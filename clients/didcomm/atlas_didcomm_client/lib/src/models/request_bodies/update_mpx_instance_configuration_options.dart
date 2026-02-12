import 'package:json_annotation/json_annotation.dart';

import 'base_options.dart';

part 'update_mpx_instance_configuration_options.g.dart';

/// Options for updating MPX (Meeting Place) instance configuration.
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class UpdateMpxInstanceConfigurationOptions extends BaseOptions {
  @override
  @JsonKey(includeToJson: true)
  final String serviceType = 'mpx';

  /// The ID of the service instance.
  final String serviceId;

  /// ACL configuration for the instance.
  final Map<String, num>? acl;

  /// Creates a [UpdateMpxInstanceConfigurationOptions] instance.
  UpdateMpxInstanceConfigurationOptions({required this.serviceId, this.acl});

  /// Creates a [UpdateMpxInstanceConfigurationOptions] from a JSON map.
  factory UpdateMpxInstanceConfigurationOptions.fromJson(
    Map<String, dynamic> json,
  ) => _$UpdateMpxInstanceConfigurationOptionsFromJson(json);

  /// Converts the [UpdateMpxInstanceConfigurationOptions] instance to JSON.
  Map<String, dynamic> toJson() =>
      _$UpdateMpxInstanceConfigurationOptionsToJson(this);
}
