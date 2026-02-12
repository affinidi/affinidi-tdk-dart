import 'package:json_annotation/json_annotation.dart';

import 'base_options.dart';

part 'update_mediator_instance_configuration_options.g.dart';

/// Options for updating mediator instance configuration.
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class UpdateMediatorInstanceConfigurationOptions extends BaseOptions {
  @override
  @JsonKey(includeToJson: true)
  final String serviceType = 'mediator';

  /// The ID of the service instance.
  final String serviceId;

  /// ACL configuration for the instance.
  final Map<String, num>? acl;

  /// Creates a [UpdateMediatorInstanceConfigurationOptions] instance.
  UpdateMediatorInstanceConfigurationOptions({
    required this.serviceId,
    this.acl,
  });

  /// Creates a [UpdateMediatorInstanceConfigurationOptions] from a JSON map.
  factory UpdateMediatorInstanceConfigurationOptions.fromJson(
    Map<String, dynamic> json,
  ) => _$UpdateMediatorInstanceConfigurationOptionsFromJson(json);

  /// Converts the [UpdateMediatorInstanceConfigurationOptions] instance to JSON.
  Map<String, dynamic> toJson() =>
      _$UpdateMediatorInstanceConfigurationOptionsToJson(this);
}
