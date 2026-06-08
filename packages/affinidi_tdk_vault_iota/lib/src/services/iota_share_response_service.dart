import 'dart:convert';

import 'package:affinidi_tdk_common/affinidi_tdk_common.dart';
import 'package:dio/dio.dart';
import 'package:ssi/ssi.dart';

import '../exceptions/tdk_exception_type.dart';
import '../models/pd_descriptor.dart';
import '../models/share_requirements.dart';
import 'iota_share_response_service_interface.dart';
import 'presentation_submission_builder.dart';
import 'vp_builder.dart';

/// Orchestrates the OID4VP share response: builds the VP, builds the
/// presentation submission (PEX only), and POSTs both directly to the
/// response URI supplied by the verifier in the OID4VP request.
class IotaShareResponseService implements IotaShareResponseServiceInterface {
  final DidSigner _signer;
  final VpBuilderInterface _vpBuilder;
  final Dio _dio;

  /// Creates an [IotaShareResponseService].
  ///
  /// Parameters:
  /// * [signer] - the DID signer that controls the holder's key.
  /// * [dio] - optional Dio client; defaults to a plain [Dio].
  /// * [vpBuilder] - custom VP builder; defaults to [VpBuilder].
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
  /// * [shareRequest] - the parsed OID4VP request.
  /// * [selectedCredentials] - the credentials to include in the VP.
  /// * [acceptResponseUri] - the URI from the OID4VP request JWT to POST the VP to.
  ///
  /// Returns the redirect [Uri] provided by the endpoint, or `null`.
  /// Throws [TdkException] with code `submission_failed` if the API call fails.
  @override
  Future<Uri?> submitShareResponse({
    required Oid4vpShareRequest shareRequest,
    required List<ParsedVerifiableCredential<dynamic>> selectedCredentials,
    required String acceptResponseUri,
  }) async {
    switch (shareRequest) {
      case PexShareRequest pex:
        return _submitPexShareResponse(
          pex,
          selectedCredentials,
          acceptResponseUri,
        );
      case DcqlShareRequest dcql:
        return _submitDcqlShareResponse(
          dcql,
          selectedCredentials,
          acceptResponseUri,
        );
    }
  }

  /// Sends a rejection to the verifier callback endpoint.
  ///
  /// Parameters:
  /// * [shareRequest] - the parsed OID4VP request to reject.
  /// * [rejectResponseUri] - the URI from the OID4VP request JWT to POST the rejection to.
  ///
  /// Returns the redirect [Uri] provided by the endpoint, or `null`.
  /// Throws [TdkException] with code `submission_failed` if the API call fails.
  @override
  Future<Uri?> rejectShareResponse({
    required Oid4vpShareRequest shareRequest,
    required String rejectResponseUri,
  }) async {
    return _postToUri(rejectResponseUri, {
      'state': shareRequest.request.state,
      'error': 'access_denied',
    });
  }

  Future<Uri?> _submitPexShareResponse(
    PexShareRequest pex,
    List<ParsedVerifiableCredential<dynamic>> selectedCredentials,
    String acceptResponseUri,
  ) async {
    final rawDescriptors = pex.presentationDefinition['input_descriptors'];
    if (rawDescriptors is! List) {
      throw TdkException(
        message: 'Presentation definition is missing input_descriptors.',
        code: TdkExceptionType.invalidPresentationDefinition.code,
      );
    }

    final List<PDDescriptor> descriptors;
    try {
      descriptors = rawDescriptors
          .map((e) => PDDescriptor.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e, stackTrace) {
      Error.throwWithStackTrace(
        TdkException(
          message: 'Malformed input_descriptors in presentation definition.',
          code: TdkExceptionType.invalidPresentationDefinition.code,
          originalMessage: e.toString(),
        ),
        stackTrace,
      );
    }

    final definitionId = pex.presentationDefinition['id'];
    if (definitionId is! String) {
      throw TdkException(
        message: 'Presentation definition is missing a valid id.',
        code: TdkExceptionType.invalidPresentationDefinition.code,
      );
    }

    final submission = PresentationSubmissionBuilder.build(
      definitionId: definitionId,
      descriptors: descriptors,
    );

    final vp = await _vpBuilder.build(
      signer: _signer,
      credentials: selectedCredentials,
      nonce: pex.request.nonce,
      domain: pex.request.clientId,
    );

    return _postToUri(acceptResponseUri, {
      'state': pex.request.state,
      'vp_token': jsonEncode(vp),
      'presentation_submission': jsonEncode(submission.toJson()),
    });
  }

  Future<Uri?> _submitDcqlShareResponse(
    DcqlShareRequest dcql,
    List<ParsedVerifiableCredential<dynamic>> selectedCredentials,
    String acceptResponseUri,
  ) async {
    final vp = await _vpBuilder.build(
      signer: _signer,
      credentials: selectedCredentials,
      nonce: dcql.request.nonce,
      domain: dcql.request.clientId,
    );

    return _postToUri(acceptResponseUri, {
      'state': dcql.request.state,
      'vp_token': jsonEncode(vp),
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
      if (e is TdkException) rethrow;
      Error.throwWithStackTrace(
        TdkException(
          message: 'Failed to send share response.',
          code: TdkExceptionType.submissionFailed.code,
          originalMessage: e.toString(),
        ),
        stackTrace,
      );
    }
  }
}
