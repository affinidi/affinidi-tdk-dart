import 'package:json_annotation/json_annotation.dart';

import 'base_options.dart';

part 'update_tr_instance_configuration_options.g.dart';

/// Options for updating Trust Registry (TR) instance configuration.
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class UpdateTrInstanceConfigurationOptions extends BaseOptions {
  @override
  @JsonKey(includeToJson: true)
  final String serviceType = 'tr';

  /// The ID of the service instance.
  final String serviceId;

  /// ACL configuration for the instance.
  final Map<String, num>? acl;

  /// Creates a [UpdateTrInstanceConfigurationOptions] instance.
  UpdateTrInstanceConfigurationOptions({required this.serviceId, this.acl});

  /// Creates a [UpdateTrInstanceConfigurationOptions] from a JSON map.
  factory UpdateTrInstanceConfigurationOptions.fromJson(
    Map<String, dynamic> json,
  ) => _$UpdateTrInstanceConfigurationOptionsFromJson(json);

  /// Converts the [UpdateTrInstanceConfigurationOptions] instance to JSON.
  Map<String, dynamic> toJson() =>
      _$UpdateTrInstanceConfigurationOptionsToJson(this);
}
