import 'dart:convert';

import 'package:affinidi_tdk_common/affinidi_tdk_common.dart';
import 'package:dio/dio.dart';
import 'package:ssi/ssi.dart';

import '../exceptions/tdk_exception_type.dart';
import '../models/pd_descriptor.dart';
import 'iota_share_response_service_interface.dart';
import 'presentation_submission_builder.dart';
import 'vp_builder.dart';

/// Orchestrates the OID4VP share response: builds the VP, builds the
/// presentation submission, and POSTs both directly to the response URI
/// supplied by the verifier in the OID4VP request.
class IotaShareResponseService implements IotaShareResponseServiceInterface {
  final DidSigner _signer;
  final VpBuilderInterface _vpBuilder;
  final Dio _dio;

  /// Creates an [IotaShareResponseService].
  ///
  /// Parameters:
  /// * [signer] - The DID signer that controls the holder's key.
  /// * [dio] - Dio client used for POSTing to the response URI. Defaults to a plain [Dio].
  /// * [vpBuilder] - Custom VP builder; defaults to [VpBuilder].
  IotaShareResponseService({
    required DidSigner signer,
    Dio? dio,
    Logger? logger,
    VpBuilderInterface? vpBuilder,
  }) : _signer = signer,
       _dio = dio ?? Dio(),
       _vpBuilder = vpBuilder ?? const VpBuilder();

  /// Builds and submits a Verifiable Presentation to the verifier callback endpoint.
  ///
  /// Parameters:
  /// * [state] - The `state` value from the OID4VP authorization request.
  /// * [nonce] - The `nonce` from the request JWT; used as the VP proof challenge.
  /// * [clientId] - The `client_id` from the request JWT; used as the VP proof domain.
  /// * [definitionId] - The ID of the Presentation Definition being satisfied.
  /// * [selectedCredentials] - Ordered list of `(descriptor, credential)` pairs.
  ///   Position `i` maps `descriptor` `i` to `$.verifiableCredential[i]` in the VP.
  /// * [acceptResponseUri] - Full URL from the OID4VP request to POST the response to.
  ///
  /// Returns the redirect [Uri] provided by the endpoint, or `null`.
  /// Throws [TdkException] with code `submission_failed` if the API call fails.
  @override
  Future<Uri?> submitShareResponse({
    required String state,
    required String nonce,
    required String clientId,
    required String definitionId,
    required List<
      ({
        PDDescriptor descriptor,
        ParsedVerifiableCredential<dynamic> credential,
      })
    >
    selectedCredentials,
    required String acceptResponseUri,
  }) async {
    final descriptors = selectedCredentials.map((r) => r.descriptor).toList();
    final credentials = selectedCredentials.map((r) => r.credential).toList();

    final submission = PresentationSubmissionBuilder.build(
      definitionId: definitionId,
      descriptors: descriptors,
    );

    final vp = await _vpBuilder.build(
      signer: _signer,
      credentials: credentials,
      nonce: nonce,
      domain: clientId,
    );

    return _postToUri(acceptResponseUri, {
      'state': state,
      'presentation_submission': jsonEncode(submission.toJson()),
      'vp_token': jsonEncode(vp),
    });
  }

  /// Sends a rejection to the verifier callback endpoint.
  ///
  /// Parameters:
  /// * [state] - The `state` value from the OID4VP authorization request.
  /// * [rejectResponseUri] - Full URL from the OID4VP request to POST the rejection to.
  ///
  /// Returns the redirect [Uri] provided by the endpoint, or `null`.
  /// Throws [TdkException] with code `submission_failed` if the API call fails.
  @override
  Future<Uri?> rejectShareResponse({
    required String state,
    required String rejectResponseUri,
  }) async {
    return _postToUri(rejectResponseUri, {
      'state': state,
      'error': 'access_denied',
    });
  }

  Future<Uri?> _postToUri(String uri, Map<String, String> formData) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        uri,
        data: formData,
        options: Options(contentType: 'application/x-www-form-urlencoded'),
      );
      final redirectUri = response.data?['redirect_uri'] as String?;
      return redirectUri != null ? Uri.tryParse(redirectUri) : null;
    } catch (e, stackTrace) {
      Error.throwWithStackTrace(
        TdkException(
          message: 'Failed to send share response callback',
          code: TdkExceptionType.submissionFailed.code,
          originalMessage: e.toString(),
        ),
        stackTrace,
      );
    }
  }
}
