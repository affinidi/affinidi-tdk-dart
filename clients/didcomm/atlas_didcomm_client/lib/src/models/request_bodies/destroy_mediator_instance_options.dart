import 'package:json_annotation/json_annotation.dart';

import 'base_options.dart';

part 'destroy_mediator_instance_options.g.dart';

/// Options for destroying a mediator instance.
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class DestroyMediatorInstanceOptions extends BaseOptions {
  @override
  @JsonKey(includeToJson: true)
  final String serviceType = 'mediator';

  /// The ID of the service instance to destroy.
  final String serviceId;

  /// Creates a [DestroyMediatorInstanceOptions] instance.
  DestroyMediatorInstanceOptions({required this.serviceId});

  /// Creates a [DestroyMediatorInstanceOptions] from a JSON map.
  factory DestroyMediatorInstanceOptions.fromJson(Map<String, dynamic> json) =>
      _$DestroyMediatorInstanceOptionsFromJson(json);

  /// Converts the [DestroyMediatorInstanceOptions] instance to JSON.
  Map<String, dynamic> toJson() => _$DestroyMediatorInstanceOptionsToJson(this);
}
