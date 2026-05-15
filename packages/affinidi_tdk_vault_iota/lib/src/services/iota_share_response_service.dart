import 'dart:convert';

import 'package:affinidi_tdk_common/affinidi_tdk_common.dart';
import 'package:affinidi_tdk_iota_client/affinidi_tdk_iota_client.dart';
import 'package:meta/meta.dart';
import 'package:ssi/ssi.dart';

import '../exceptions/tdk_exception_type.dart';
import '../models/pd_descriptor.dart';
import 'presentation_submission_builder.dart';
import 'vp_builder.dart';

typedef VpBuilderFn =
    Future<Map<String, dynamic>> Function({
      required DidSigner signer,
      required List<ParsedVerifiableCredential<dynamic>> credentials,
      required String nonce,
      required String domain,
    });

/// Orchestrates the OID4VP share response: builds the VP, builds the
/// presentation submission, and posts both to the Iota callback endpoint.
class IotaShareResponseService {
  final CallbackApi _callbackApi;
  final DidSigner _signer;
  final Logger _logger;
  final VpBuilderFn _buildVp;

  /// Creates an [IotaShareResponseService].
  ///
  /// Parameters:
  /// * [callbackApi] - The Iota callback API client used to submit the VP.
  /// * [signer] - The DID signer that controls the holder's key.
  /// * [logger] - Optional logger; defaults to [Logger.instance].
  IotaShareResponseService({
    required CallbackApi callbackApi,
    required DidSigner signer,
    Logger? logger,
    @visibleForTesting VpBuilderFn? vpBuilderFn,
  })  : _callbackApi = callbackApi,
        _signer = signer,
        _logger = logger ?? Logger.instance,
        _buildVp = vpBuilderFn ?? VpBuilder.build;

  /// Builds and submits a Verifiable Presentation to the Iota callback endpoint.
  ///
  /// Parameters:
  /// * [state] - The `state` value from the OID4VP authorization request.
  /// * [nonce] - The `nonce` from the request JWT; used as the VP proof challenge.
  /// * [definitionId] - The ID of the Presentation Definition being satisfied.
  /// * [selectedCredentials] - Ordered pairs of (descriptor, credential). Position
  ///   `i` maps descriptor `i` to `$.verifiableCredential[i]` in the VP.
  ///
  /// Throws [TdkException] with code `submission_failed` if the API call fails.
  Future<void> submitShareResponse({
    required String state,
    required String nonce,
    required String clientId,
    required String definitionId,
    required List<(PDDescriptor, ParsedVerifiableCredential<dynamic>)>
        selectedCredentials,
  }) async {
    _logger.log(
      LogLevel.fine,
      'Building VP for ${selectedCredentials.length} credential(s)',
    );

    final descriptors = selectedCredentials.map((r) => r.$1).toList();
    final credentials = selectedCredentials.map((r) => r.$2).toList();

    final submission = PresentationSubmissionBuilder.build(
      definitionId: definitionId,
      descriptors: descriptors,
    );

    final vp = await _buildVp(
      signer: _signer,
      credentials: credentials,
      nonce: nonce,
      domain: clientId,
    );

    _logger.log(LogLevel.fine, 'Submitting share response (state: $state)');

    try {
      await _callbackApi.iotOIDC4VPCallback(
        callbackInput: CallbackInput(
          (b) => b
            ..state = state
            ..presentationSubmission = jsonEncode(submission.toJson())
            ..vpToken = jsonEncode(vp),
        ),
      );
    } catch (e, stackTrace) {
      Error.throwWithStackTrace(
        TdkException(
          message: 'Failed to submit share response',
          code: TdkExceptionType.submissionFailed.code,
          originalMessage: e.toString(),
        ),
        stackTrace,
      );
    }
  }
}

