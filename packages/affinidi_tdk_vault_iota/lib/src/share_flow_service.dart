import 'package:affinidi_tdk_common/affinidi_tdk_common.dart';
import 'package:affinidi_tdk_cryptography/affinidi_tdk_cryptography.dart';

import 'exceptions/tdk_exception_type.dart';
import 'extensions/iota_payload_extensions.dart';
import 'models/iota_payload.dart';
import 'models/share_requirements.dart';
import 'share_flow_service_interface.dart';

/// Implementation of [ShareFlowServiceInterface] that parses and validates
/// OID4VP request URIs.
class ShareFlowService implements ShareFlowServiceInterface {
  final CryptographyServiceInterface _cryptography;

  static const _directPost = 'direct_post';
  static const _didScheme = 'did';

  /// Throws a [TdkException] with the given [message] and [type] code.
  ///
  /// [originalMessage] is an optional underlying error message to include.
  static Never _throw(
    String message,
    TdkExceptionType type, {
    String? originalMessage,
  }) => throw TdkException(
    message: message,
    code: type.code,
    originalMessage: originalMessage,
  );

  /// Creates a new [ShareFlowService] instance.
  ShareFlowService({required CryptographyServiceInterface cryptography})
    : _cryptography = cryptography;

  @override
  Future<Oid4vpShareRequest> validateOid4vpRequest(
    Uri uri, {
    String? walletDid,
  }) async {
    final embeddedException = uri.queryParameters['exception'];
    if (embeddedException != null) {
      _throw(
        'Request failed.',
        TdkExceptionType.parseFailure,
        originalMessage: embeddedException,
      );
    }

    final jwtToken = uri.queryParameters['request'];
    if (jwtToken == null) {
      _throw(
        'Non-Iota OID4VP URIs are not supported.',
        TdkExceptionType.parseFailure,
      );
    }

    final Map<String, dynamic> decoded;
    try {
      decoded = _cryptography.decodeJwtToken(token: jwtToken);
    } catch (e) {
      _throw(
        'Failed to decode JWT token.',
        TdkExceptionType.parseFailure,
        originalMessage: e.toString(),
      );
    }

    final IotaPayload payload;
    try {
      payload = IotaPayload.fromJson(decoded);
    } catch (e) {
      _throw(
        'JWT payload is missing required fields.',
        TdkExceptionType.parseFailure,
        originalMessage: e.toString(),
      );
    }

    if (payload.clientId.isEmpty) {
      _throw('client_id is required.', TdkExceptionType.missingClientId);
    }

    final verifyResult = _cryptography.verifyJwt(
      jwtToken: jwtToken,
      didKey: payload.clientId,
    );
    final isValidClientIdScheme = payload.clientIdScheme == _didScheme;
    final isValidAud =
        payload.aud == null || walletDid == null || payload.aud == walletDid;
    if (!verifyResult.isValid ||
        verifyResult.isExpired ||
        !isValidClientIdScheme ||
        !isValidAud) {
      _throw(
        'JWT is invalid or has expired.',
        TdkExceptionType.invalidOrExpiredJwt,
        originalMessage: verifyResult.errorMessage,
      );
    }

    if (payload.responseMode != _directPost) {
      _throw(
        'Invalid response_mode: ${payload.responseMode}.',
        TdkExceptionType.invalidResponseMode,
      );
    }

    return Oid4vpShareRequest(
      request: payload.toRequest(),
      presentationDefinition: payload.presentationDefinition,
      jwtAssertion: jwtToken,
      purpose: payload.purpose,
    );
  }
}
