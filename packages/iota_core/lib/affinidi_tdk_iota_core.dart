import 'src/iota_auth_provider.dart';

export 'package:affinidi_tdk_common/affinidi_tdk_common.dart' show TdkException;

export 'src/exceptions/tdk_exception_type.dart';
export 'src/models/iota_payload.dart';
export 'src/models/iota_request.dart';
export 'src/models/request_purpose.dart';
export 'src/models/share_requirements.dart';
export 'src/services/iota_service.dart';
export 'src/services/iota_service_interface.dart';

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
