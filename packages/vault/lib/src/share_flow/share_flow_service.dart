import 'package:affinidi_tdk_common/affinidi_tdk_common.dart';
import 'package:affinidi_tdk_cryptography/affinidi_tdk_cryptography.dart';

import '../exceptions/tdk_exception_type.dart';
import 'models/iota_payload.dart';
import 'models/iota_request.dart';
import 'models/request_purpose.dart';
import 'models/share_requirements.dart';
import 'share_flow_service_interface.dart';

/// Implementation of [ShareFlowServiceInterface] that parses and validates
/// OID4VP request URIs.
class ShareFlowService implements ShareFlowServiceInterface {
  final CryptographyServiceInterface _cryptography;

  static const _directPost = 'direct_post';
  static const _didScheme = 'did';

  /// Creates a new [ShareFlowService] instance.
  ShareFlowService({required CryptographyServiceInterface cryptography})
    : _cryptography = cryptography;

  @override
  Future<Oid4vpShareRequest> validateOid4vpRequest(Uri uri) async {
    final embeddedException = uri.queryParameters['exception'];
    if (embeddedException != null) {
      Error.throwWithStackTrace(
        TdkException(
          message: embeddedException,
          code: TdkExceptionType.parseFailure.code,
        ),
        StackTrace.current,
      );
    }

    final jwtToken = uri.queryParameters['request'];
    if (jwtToken == null) {
      Error.throwWithStackTrace(
        TdkException(
          message: 'Non-Iota OID4VP URIs are not supported.',
          code: TdkExceptionType.parseFailure.code,
        ),
        StackTrace.current,
      );
    }

    final Map<String, dynamic> decoded;
    try {
      decoded = _cryptography.decodeJwtToken(token: jwtToken);
    } catch (e) {
      Error.throwWithStackTrace(
        TdkException(
          message: 'Failed to decode JWT token.',
          code: TdkExceptionType.parseFailure.code,
          originalMessage: e.toString(),
        ),
        StackTrace.current,
      );
    }

    final IotaPayload payload;
    try {
      payload = IotaPayload.fromJson(decoded);
    } catch (e) {
      Error.throwWithStackTrace(
        TdkException(
          message: 'JWT payload is missing required fields.',
          code: TdkExceptionType.parseFailure.code,
          originalMessage: e.toString(),
        ),
        StackTrace.current,
      );
    }

    if (payload.clientId.isEmpty) {
      Error.throwWithStackTrace(
        TdkException(
          message: 'client_id is required.',
          code: TdkExceptionType.missingClientId.code,
        ),
        StackTrace.current,
      );
    }

    if (payload.clientIdScheme != _didScheme) {
      Error.throwWithStackTrace(
        TdkException(
          message: 'Unsupported client_id_scheme: ${payload.clientIdScheme}.',
          code: TdkExceptionType.parseFailure.code,
        ),
        StackTrace.current,
      );
    }

    final verifyResult = _cryptography.verifyJwt(
      jwtToken: jwtToken,
      didKey: payload.clientId,
    );
    if (!verifyResult.isValid || verifyResult.isExpired) {
      Error.throwWithStackTrace(
        TdkException(
          message: 'JWT is invalid or has expired.',
          code: TdkExceptionType.invalidOrExpiredJwt.code,
          originalMessage: verifyResult.errorMessage,
        ),
        StackTrace.current,
      );
    }

    if (payload.responseMode != _directPost) {
      Error.throwWithStackTrace(
        TdkException(
          message: 'Invalid response_mode: ${payload.responseMode}.',
          code: TdkExceptionType.invalidResponseMode.code,
        ),
        StackTrace.current,
      );
    }

    RequestPurpose? purpose;
    final rawPurpose = payload.presentationDefinition['purpose'];
    if (rawPurpose != null) {
      final parsed = RequestPurpose.fromJson(rawPurpose);
      if (parsed.isValid) {
        purpose = parsed;
      }
    }

    return Oid4vpShareRequest(
      request: IotaRequest.fromPayload(payload),
      presentationDefinition: payload.presentationDefinition,
      purpose: purpose,
    );
  }
}
