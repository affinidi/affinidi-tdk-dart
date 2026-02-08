import 'package:json_annotation/json_annotation.dart';

import 'base_options.dart';

part 'destroy_tr_instance_options.g.dart';

/// Options for destroying a Trust Registry (TR) instance.
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class DestroyTrInstanceOptions extends BaseOptions {
  @override
  @JsonKey(includeToJson: true)
  final String serviceType = 'tr';

  /// The ID of the service instance to destroy.
  final String serviceId;

  /// Creates a [DestroyTrInstanceOptions] instance.
  DestroyTrInstanceOptions({required this.serviceId});

  /// Creates a [DestroyTrInstanceOptions] from a JSON map.
  factory DestroyTrInstanceOptions.fromJson(Map<String, dynamic> json) =>
      _$DestroyTrInstanceOptionsFromJson(json);

  /// Converts the [DestroyTrInstanceOptions] instance to JSON.
  Map<String, dynamic> toJson() => _$DestroyTrInstanceOptionsToJson(this);
}
