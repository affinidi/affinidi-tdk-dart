import 'package:affinidi_tdk_common/affinidi_tdk_common.dart';
import 'package:affinidi_tdk_cryptography/affinidi_tdk_cryptography.dart';

import '../exceptions/tdk_exception_type.dart';
import '../models/iota_payload.dart';
import '../models/iota_request.dart';
import '../models/request_purpose.dart';
import '../models/share_requirements.dart';
import 'iota_service_interface.dart';

/// Implementation of [IotaServiceInterface] that parses and validates
/// Iota OID4VP request URIs.
///
/// Decodes the JWT from the `request` query parameter, verifies its
/// signature and expiry via [CryptographyServiceInterface], and maps
/// the payload to a structured [Oid4vpShareRequest].
///
/// Example:
/// ```dart
/// final service = IotaService(
///   cryptography: MyCryptographyService(),
/// );
/// final shareRequest = await service.validateOid4vpRequest(
///   Uri.parse('openid4vp://authorize?request=<jwt>'),
/// );
/// print(shareRequest.request.nonce);
/// ```
class IotaService implements IotaServiceInterface {
  final CryptographyServiceInterface _cryptography;

  static const _directPost = 'direct_post';
  static const _didScheme = 'did';

  /// Creates a new [IotaService] instance.
  ///
  /// Parameters:
  /// - [cryptography] - service used to decode and verify the JWT.
  IotaService({required CryptographyServiceInterface cryptography})
    : _cryptography = cryptography;

  /// Parses and validates an Iota OID4VP request URI.
  ///
  /// [uri] - the OID4VP request URI containing a `request` JWT query parameter.
  ///
  /// Returns an [Oid4vpShareRequest] with the normalised request parameters,
  /// presentation definition, and optional purpose metadata.
  ///
  /// Throws:
  /// - [TdkException] if the URI cannot be parsed or a required field is missing.
  ///   - `parse_failure`: when the `request` query parameter is absent or the URI
  ///     carries an embedded exception.
  ///   - `invalid_or_expired_jwt`: when the JWT cannot be decoded, the signature
  ///     is invalid, it has expired, or `client_id_scheme` is not `did`.
  ///   - `missing_client_id`: when the `client_id` field is absent from the payload.
  ///   - `invalid_response_mode`: when `response_mode` is not `direct_post`.
  @override
  Future<Oid4vpShareRequest> validateOid4vpRequest(Uri uri) async {
    // Surface any error the caller embedded in the URI.
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

    // Only the Iota path (JWT in ?request=) is supported.
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

    // Decode JWT body → IotaPayload.
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

    final payload = IotaPayload.fromJson(decoded);

    // Verify JWT signature and expiry against the client DID.
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

    // Only the did: scheme is accepted.
    if (payload.clientIdScheme != _didScheme) {
      Error.throwWithStackTrace(
        TdkException(
          message: 'Unsupported client_id_scheme: ${payload.clientIdScheme}.',
          code: TdkExceptionType.invalidOrExpiredJwt.code,
        ),
        StackTrace.current,
      );
    }

    // client_id must be present.
    if (payload.clientId.isEmpty) {
      Error.throwWithStackTrace(
        TdkException(
          message: 'client_id is required.',
          code: TdkExceptionType.missingClientId.code,
        ),
        StackTrace.current,
      );
    }

    // Only direct_post response_mode is supported.
    if (payload.responseMode != _directPost) {
      Error.throwWithStackTrace(
        TdkException(
          message: 'Invalid response_mode: ${payload.responseMode}.',
          code: TdkExceptionType.invalidResponseMode.code,
        ),
        StackTrace.current,
      );
    }

    // Extract optional purpose from the presentation definition.
    RequestPurpose? purpose;
    final rawPurpose = payload.presentationDefinition['purpose'];
    if (rawPurpose != null) {
      try {
        final parsed = RequestPurpose.fromJson(rawPurpose);
        if (parsed.isValid) {
          purpose = parsed;
        }
      } catch (_) {
        // Malformed purpose is non-fatal — treat as absent.
      }
    }

    return Oid4vpShareRequest(
      request: IotaRequest.fromPayload(payload),
      presentationDefinition: payload.presentationDefinition,
      purpose: purpose,
    );
  }
}
