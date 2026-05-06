import 'src/iota_auth_provider.dart';

export 'package:affinidi_tdk_common/affinidi_tdk_common.dart' show TdkException;

/// Entry point for Iota core utilities.
class IotaCore {
  /// Exchanges a limited token for temporary AWS credentials used to connect
  /// to the Iota WebSocket endpoint.
  static Future<IotaCredentials> limitedTokenToIotaCredentials(
    String token,
  ) async {
    final iotaAuthProvider = IotaAuthProvider();
    return iotaAuthProvider.limitedTokenToIotaCredentials(token);
  }
}
