import 'package:json_annotation/json_annotation.dart';

import 'base_options.dart';

part 'destroy_mpx_instance_options.g.dart';

/// Options for destroying an MPX (Meeting Place) instance.
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class DestroyMpxInstanceOptions extends BaseOptions {
  @override
  @JsonKey(includeToJson: true)
  final String serviceType = 'mpx';

  /// The ID of the service instance to destroy.
  final String serviceId;

  /// Creates a [DestroyMpxInstanceOptions] instance.
  DestroyMpxInstanceOptions({required this.serviceId});

  /// Creates a [DestroyMpxInstanceOptions] from a JSON map.
  factory DestroyMpxInstanceOptions.fromJson(Map<String, dynamic> json) =>
      _$DestroyMpxInstanceOptionsFromJson(json);

  /// Converts the [DestroyMpxInstanceOptions] instance to JSON.
  Map<String, dynamic> toJson() => _$DestroyMpxInstanceOptionsToJson(this);
}
