/// Internal HTTP status code constants.
///
/// Avoids importing `dart:io` (not supported on web) while keeping
/// status code checks readable across the package.
abstract final class HttpStatusCode {
  /// Standard HTTP 200 OK.
  static const int ok = 200;
}
