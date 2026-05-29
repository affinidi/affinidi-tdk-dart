import 'dart:convert';

import 'package:affinidi_tdk_common/affinidi_tdk_common.dart';
import 'package:affinidi_tdk_iota_client/affinidi_tdk_iota_client.dart';
import 'package:ssi/ssi.dart';

import '../exceptions/tdk_exception_type.dart';
import '../models/vp_data_model.dart';
import '../models/pd_descriptor.dart';
import 'iota_share_response_service_interface.dart';
import 'presentation_submission_builder.dart';
import 'vp_builder.dart';

/// Orchestrates the OID4VP share response: builds the VP, builds the
/// presentation submission, and posts both to the Iota callback endpoint.
class IotaShareResponseService implements IotaShareResponseServiceInterface {
  final CallbackApi _approveCallbackApi;
  final CallbackApi _rejectCallbackApi;
  final DidSigner _signer;
  final Logger _logger;
  final VpBuilderInterface _vpBuilder;

  /// Creates an [IotaShareResponseService].
  ///
  /// Parameters:
  /// * [approveCallbackApi] - API client for the accept (share) callback endpoint.
  /// * [rejectCallbackApi] - API client for the reject callback endpoint.
  ///   Defaults to [approveCallbackApi] when not provided.
  /// * [signer] - The DID signer that controls the holder's key.
  /// * [logger] - Optional logger; defaults to [Logger.instance].
  /// * [vpBuilder] - Custom VP builder; defaults to [VpBuilder].
  IotaShareResponseService({
    required CallbackApi approveCallbackApi,
    CallbackApi? rejectCallbackApi,
    required DidSigner signer,
    Logger? logger,
    VpBuilderInterface? vpBuilder,
  }) : _approveCallbackApi = approveCallbackApi,
       _rejectCallbackApi = rejectCallbackApi ?? approveCallbackApi,
       _signer = signer,
       _logger = logger ?? Logger.instance,
       _vpBuilder = vpBuilder ?? const VpBuilder();

  /// Builds and submits a Verifiable Presentation to the Iota callback endpoint.
  ///
  /// Parameters:
  /// * [state] - The `state` value from the OID4VP authorization request.
  /// * [nonce] - The `nonce` from the request JWT; used as the VP proof challenge.
  /// * [clientId] - The `client_id` from the request JWT; used as the VP proof domain.
  /// * [definitionId] - The ID of the Presentation Definition being satisfied.
  /// * [selectedCredentials] - Ordered list of `(descriptor, credential)` pairs.
  ///   Position `i` maps `descriptor` `i` to `$.verifiableCredential[i]` in the VP.
  /// * [dataModel] - Whether to wrap the credentials in a DM v1 or DM v2 VP.
  ///
  /// Returns the redirect [Uri] provided by the endpoint, or `null`.
  /// Throws [TdkException] with code `submission_failed` if the API call fails.
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
    required VpDataModel dataModel,
  }) async {
    _logger.log(
      LogLevel.fine,
      'Building VP for ${selectedCredentials.length} credential(s)',
    );

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
      dataModel: dataModel,
    );

    _logger.log(LogLevel.fine, 'Submitting share response (state: $state)');

    return _postCallback(
      _approveCallbackApi,
      CallbackInput(
        (b) => b
          ..state = state
          ..presentationSubmission = jsonEncode(submission.toJson())
          ..vpToken = jsonEncode(vp),
      ),
    );
  }

  /// Sends a rejection to the Iota callback endpoint.
  ///
  /// Parameters:
  /// * [state] - The `state` value from the OID4VP authorization request.
  ///
  /// Returns the redirect [Uri] provided by the endpoint, or `null`.
  /// Throws [TdkException] with code `submission_failed` if the API call fails.
  Future<Uri?> rejectShareResponse({required String state}) async {
    _logger.log(LogLevel.fine, 'Rejecting share response (state: $state)');

    return _postCallback(
      _rejectCallbackApi,
      CallbackInput(
        (b) => b
          ..state = state
          ..error = 'access_denied',
      ),
    );
  }

  Future<Uri?> _postCallback(CallbackApi api, CallbackInput input) async {
    try {
      final response = await api.iotOIDC4VPCallback(callbackInput: input);
      final redirectUri = response.data?.redirectUri;
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
