abstract class BaseOptions {
  // TODO: add enum instead of hardcoding service type when Atlas is case insensitive for service types in path
  /// mediator, mpx, tr
  String get serviceType;

  const BaseOptions();
}
