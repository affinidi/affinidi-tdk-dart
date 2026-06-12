import 'package:affinidi_tdk_common/affinidi_tdk_common.dart';
import 'package:affinidi_tdk_cryptography/affinidi_tdk_cryptography.dart';

import 'exceptions/tdk_exception_type.dart';
import 'models/iota_payload.dart';
import 'models/share_requirements.dart';
import 'share_flow_service_interface.dart';
import 'utils/nonce_replay_cache.dart';

/// Implementation of [ShareFlowServiceInterface] that parses and validates
/// OID4VP request URIs.
class ShareFlowService implements ShareFlowServiceInterface {
  final CryptographyServiceInterface _cryptography;
  final NonceReplayCache _replayCache;

  static const _directPost = 'direct_post';
  static const _vpToken = 'vp_token';
  static const _didScheme = 'did';
  // OID4VP JWTs have a short lifetime; 60 s tolerance allows for reasonable
  // clock skew while still rejecting future-dated tokens.
  static const _iatToleranceSeconds = 60;

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
  ///
  /// Parameters:
  /// * [replayCache] - optional nonce replay cache; defaults to a new in-memory
  ///   cache. Inject a custom instance to share state across service instances.
  ShareFlowService({
    required CryptographyServiceInterface cryptography,
    NonceReplayCache? replayCache,
  }) : _cryptography = cryptography,
       _replayCache = replayCache ?? NonceReplayCache();

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
    if (!verifyResult.isValid) {
      _throw(
        'JWT signature verification failed.',
        TdkExceptionType.invalidOrExpiredJwt,
        originalMessage: verifyResult.errorMessage,
      );
    }
    if (verifyResult.isExpired) {
      _throw(
        'JWT has expired.',
        TdkExceptionType.invalidOrExpiredJwt,
        originalMessage: verifyResult.errorMessage,
      );
    }
    if (payload.clientIdScheme != _didScheme) {
      _throw(
        "client_id_scheme must be '$_didScheme', "
        'got: ${payload.clientIdScheme}.',
        TdkExceptionType.invalidClientIdScheme,
      );
    }
    if (payload.aud != null && walletDid != null && payload.aud != walletDid) {
      _throw(
        'JWT aud does not match the wallet DID.',
        TdkExceptionType.invalidAudience,
      );
    }

    // Reject future-dated tokens (iat > now + tolerance) to prevent issuance
    // of JWTs with a fabricated timestamp that extends their effective lifetime.
    final iatBound =
        DateTime.now().millisecondsSinceEpoch ~/ 1000 + _iatToleranceSeconds;
    if (payload.iat > iatBound) {
      _throw('JWT iat is in the future.', TdkExceptionType.invalidOrExpiredJwt);
    }

    // OID4VP §11.2: enforce nonce uniqueness to prevent replay within the
    // JWT exp window.
    // See: https://openid.net/specs/openid-4-verifiable-presentations-1_0.html#section-11.2
    if (!_replayCache.record(payload.nonce, payload.exp)) {
      _throw(
        'Request nonce has already been consumed. Possible JWT replay attack.',
        TdkExceptionType.replayDetected,
      );
    }

    if (payload.responseMode != _directPost) {
      _throw(
        'Invalid response_mode: ${payload.responseMode}.',
        TdkExceptionType.invalidResponseMode,
      );
    }

    if (payload.responseType != _vpToken) {
      _throw(
        'Invalid response_type: ${payload.responseType}.',
        TdkExceptionType.invalidResponseType,
      );
    }

    return Oid4vpShareRequest.fromPayload(payload, jwtAssertion: jwtToken);
  }
}
