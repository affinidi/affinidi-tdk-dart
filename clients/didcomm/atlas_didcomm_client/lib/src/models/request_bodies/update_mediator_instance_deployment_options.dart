import 'package:json_annotation/json_annotation.dart';

import '../mediator_acl_mode/mediator_acl_mode.dart';
import '../service_size/service_size.dart';
import 'base_options.dart';

part 'update_mediator_instance_deployment_options.g.dart';

/// Options for updating the deployment configuration of a mediator instance.
///
/// All fields are optional to support partial updates.
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class UpdateMediatorInstanceDeploymentOptions extends BaseOptions {
  @override
  @JsonKey(includeToJson: true)
  final String serviceType = 'mediator';

  /// The ID of the service instance.
  final String serviceId;

  /// The size of the service instance.
  ///
  /// Available sizes: dev, tiny, small, medium, large.
  /// This is an optional field.
  final ServiceSize? serviceSize;

  /// The ACL (Access Control List) mode for the mediator.
  ///
  /// - `explicit_deny`: Deny access by default, only allow explicitly listed DIDs.
  /// - `explicit_allow`: Allow access by default, only deny explicitly listed DIDs.
  ///
  /// This is an optional field.
  final MediatorAclMode? mediatorAclMode;

  /// The human-readable name for the mediator instance.
  ///
  /// This is an optional field.
  final String? name;

  /// A description of the mediator instance.
  ///
  /// This is an optional field.
  final String? description;

  /// The default mediator DID for the mediator instance.
  ///
  /// This is an optional field.
  final String? defaultMediatorDid;

  /// Comma-separated list of administrator DIDs.
  ///
  /// These DIDs will have administrative privileges for the mediator instance.
  /// This is an optional field.
  final String? administratorDids;

  /// Comma-separated list of allowed origins for CORS (Cross-Origin Resource Sharing).
  ///
  /// Specify exact origins (e.g., 'https://example.com,https://app.example.com')
  /// or use '*' to allow all origins.
  ///
  /// Warning: Using '*' in production may pose security risks.
  /// This is an optional field.
  final String? corsAllowedOrigins;

  /// Creates a [UpdateMediatorInstanceDeploymentOptions] instance.
  const UpdateMediatorInstanceDeploymentOptions({
    required this.serviceId,
    this.serviceSize,
    this.mediatorAclMode,
    this.name,
    this.description,
    this.defaultMediatorDid,
    this.administratorDids,
    this.corsAllowedOrigins,
  });

  /// Creates a [UpdateMediatorInstanceDeploymentOptions] from a JSON map.
  factory UpdateMediatorInstanceDeploymentOptions.fromJson(
    Map<String, dynamic> json,
  ) => _$UpdateMediatorInstanceDeploymentOptionsFromJson(json);

  /// Converts the [UpdateMediatorInstanceDeploymentOptions] instance to JSON.
  Map<String, dynamic> toJson() =>
      _$UpdateMediatorInstanceDeploymentOptionsToJson(this);
}
