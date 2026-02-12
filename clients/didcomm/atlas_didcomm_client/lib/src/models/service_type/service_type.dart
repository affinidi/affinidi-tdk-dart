import 'package:json_annotation/json_annotation.dart';

/// Service type enum.
enum ServiceType {
  /// Mediator service type.
  @JsonValue('MEDIATOR')
  mediator,

  /// Meeting place service type.
  @JsonValue('MPX')
  meetingPlace,

  /// Trust registry service type.
  @JsonValue('TR')
  trustRegistry,
}
