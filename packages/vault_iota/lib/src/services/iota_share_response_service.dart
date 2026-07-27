import 'dart:convert';

import 'package:affinidi_tdk_common/affinidi_tdk_common.dart'
    show Logger, TdkException;
import 'package:dio/dio.dart';
import 'package:ssi/ssi.dart';

import '../exceptions/tdk_exception_type.dart';
import '../helpers/presentation_definition_parser.dart';
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
  final Logger _logger;
  final List<String> _trustedVerifierHosts;

  /// Creates an [IotaShareResponseService].
  ///
  /// Parameters:
  /// * [signer] - the DID signer that controls the holder's key.
  /// * [dio] - optional Dio client; defaults to a plain [Dio].
  /// * [vpBuilder] - custom VP builder; defaults to [VpBuilder].
  /// * [logger] - optional logger; defaults to [Logger.instance].
  /// * [trustedVerifiersList] - list of trusted callback host names (e.g.
  ///   `['verifier.example.com']`) the VP may be posted to. Must contain at
  ///   least one entry. Entries must be plain host names with no scheme or path.
  factory IotaShareResponseService({
    required DidSigner signer,
    required List<String> trustedVerifiersList,
    Dio? dio,
    VpBuilderInterface? vpBuilder,
    Logger? logger,
  }) {
    if (trustedVerifiersList.isEmpty) {
      throw TdkException(
        message: 'trustedVerifiersList must not be empty.',
        code: TdkExceptionType.emptyTrustedVerifiersList.code,
      );
    }
    for (final host in trustedVerifiersList) {
      if (host.isEmpty || host.contains(RegExp(r'[/:@#?]'))) {
        throw TdkException(
          message:
              'trustedVerifiersList entry "$host" must be a plain host name '
              'with no scheme, port, path, or query.',
          code: TdkExceptionType.invalidResponseUri.code,
        );
      }
    }
    final trustedHosts = List<String>.unmodifiable(
      trustedVerifiersList.map((h) => h.toLowerCase()),
    );
    return IotaShareResponseService._(
      signer: signer,
      trustedVerifierHosts: trustedHosts,
      dio: dio ?? Dio(),
      vpBuilder: vpBuilder ?? const VpBuilder(),
      logger: logger ?? Logger.instance,
    );
  }

  IotaShareResponseService._({
    required DidSigner signer,
    required List<String> trustedVerifierHosts,
    required Dio dio,
    required VpBuilderInterface vpBuilder,
    required Logger logger,
  }) : _signer = signer,
       _trustedVerifierHosts = trustedVerifierHosts,
       _dio = dio,
       _vpBuilder = vpBuilder,
       _logger = logger;

  /// Builds and submits a Verifiable Presentation to the verifier callback endpoint.
  ///
  /// Parameters:
  /// * [shareRequest] - the parsed OID4VP request.
  /// * [selectedCredentials] - the credentials to include in the VP.
  /// * [acceptResponseUri] - the URI from the OID4VP request JWT to POST the VP to.
  ///
  /// Returns the redirect [Uri] provided by the endpoint, or `null`.
  /// Throws [TdkException] with code `invalid_response_uri` if the URI is
  /// malformed, not HTTPS, or contains an IP address.
  /// Throws [TdkException] with code `untrusted_response_uri` if the callback
  /// host is not in the trusted verifiers list.
  /// Throws [TdkException] with code `submission_failed` if the API call fails.
  @override
  Future<Uri?> submitShareResponse({
    required Oid4vpShareRequest shareRequest,
    required List<VerifiableCredential> selectedCredentials,
    required String acceptResponseUri,
  }) async {
    final parsed = selectedCredentials.map(_toParsedCredential).toList();
    switch (shareRequest) {
      case PexShareRequest pex:
        return _submitPexShareResponse(pex, parsed, acceptResponseUri);
      case DcqlShareRequest dcql:
        return _submitDcqlShareResponse(dcql, parsed, acceptResponseUri);
    }
  }

  /// Sends a rejection to the verifier callback endpoint.
  ///
  /// Parameters:
  /// * [shareRequest] - the parsed OID4VP request to reject.
  /// * [rejectResponseUri] - the URI from the OID4VP request JWT to POST the rejection to.
  ///
  /// Returns the redirect [Uri] provided by the endpoint, or `null`.
  /// Throws [TdkException] with code `invalid_response_uri` if the URI is
  /// malformed, not HTTPS, or contains an IP address.
  /// Throws [TdkException] with code `untrusted_response_uri` if the callback
  /// host is not in the trusted verifiers list.
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
    final pd = pex.presentationDefinition;
    final descriptors = PresentationDefinitionParser.parseInputDescriptors(pd);
    final definitionId = PresentationDefinitionParser.parseDefinitionId(pd);

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

  /// Builds and submits the DCQL Authorization Response.
  ///
  /// Per OpenID4VP 1.0 §8.1 ("Response Parameters"), the `vp_token` for a DCQL
  /// request is a JSON object whose keys are the `id` of each Credential Query
  /// in the request and whose values are the Presentation(s) that satisfy the
  /// respective query. With `multiple` omitted or `false` (the default), each
  /// value is a single Presentation. Unlike PEX, there is no
  /// `presentation_submission`.
  ///
  /// This wallet builds one Presentation carrying the shared credentials and
  /// maps every requested Credential Query id to it.
  ///
  /// See https://openid.net/specs/openid-4-verifiable-presentations-1_0.html#section-8.1
  ///
  /// Parameters:
  /// * [dcql] - the parsed DCQL share request.
  /// * [selectedCredentials] - the credentials the user agreed to share.
  /// * [acceptResponseUri] - the URI to POST the Authorization Response to.
  ///
  /// Returns the redirect [Uri] provided by the endpoint, or `null`.
  /// Throws [TdkException] with code `submission_failed` if the API call fails.
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

    final vpToken = <String, dynamic>{
      for (final credential in dcql.dcqlQuery.credentials) credential.id: vp,
    };

    return _postToUri(acceptResponseUri, {
      'state': dcql.request.state,
      'vp_token': jsonEncode(vpToken),
    });
  }

  Future<Uri?> _postToUri(String uri, Map<String, String> formData) async {
    final responseUri = _validateVerifierBoundUri(
      uri: uri,
      parameterName: 'response_uri',
    );

    try {
      final response = await _dio.post<Map<String, dynamic>>(
        responseUri.toString(),
        data: formData,
        options: Options(contentType: 'application/x-www-form-urlencoded'),
      );
      final redirectUri = response.data?['redirect_uri'] as String?;
      if (redirectUri == null) return null;
      return _validateRedirectUri(redirectUri);
    } catch (e, stackTrace) {
      if (e is TdkException) rethrow;
      _logger.warning(
        'Failed to submit OID4VP response to verifier callback URI: $e',
      );
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

  Uri? _validateRedirectUri(String redirectUri) {
    try {
      return _validateVerifierBoundUri(
        uri: redirectUri,
        parameterName: 'redirect_uri',
      );
    } on TdkException catch (e) {
      _logger.warning(
        'Ignoring unsafe redirect_uri from verifier: ${e.message}',
      );
      return null;
    }
  }

  Uri _validateVerifierBoundUri({
    required String uri,
    required String parameterName,
  }) {
    final parsed = _parseSafeHttpsUri(uri, parameterName);
    if (!_isTrustedHost(parsed)) {
      _throwUnboundResponseUri(parameterName: parameterName);
    }
    return parsed;
  }

  bool _isTrustedHost(Uri uri) =>
      _trustedVerifierHosts.contains(uri.host.toLowerCase());

  Never _throwUnboundResponseUri({required String parameterName}) =>
      throw TdkException(
        message: '$parameterName host is not in the trusted verifiers list.',
        code: TdkExceptionType.untrustedResponseUri.code,
      );

  Uri _parseSafeHttpsUri(String uri, String parameterName) {
    final parsed = Uri.tryParse(uri);
    if (parsed == null ||
        parsed.scheme != 'https' ||
        parsed.host.isEmpty ||
        parsed.userInfo.isNotEmpty ||
        parsed.fragment.isNotEmpty) {
      throw TdkException(
        message:
            '$parameterName must be an HTTPS URI without userinfo or fragment.',
        code: TdkExceptionType.invalidResponseUri.code,
      );
    }
    if (_isIpAddress(parsed.host)) {
      throw TdkException(
        message: '$parameterName must use a domain name, not an IP address.',
        code: TdkExceptionType.invalidResponseUri.code,
      );
    }
    return parsed;
  }

  static bool _isIpAddress(String host) =>
      RegExp(r'^\d{1,3}(\.\d{1,3}){3}$').hasMatch(host) || host.contains(':');

  ParsedVerifiableCredential<dynamic> _toParsedCredential(
    VerifiableCredential vc,
  ) {
    if (vc is ParsedVerifiableCredential<dynamic>) return vc;
    final serialized = jsonEncode(vc.toJson());
    final v1 = LdVcDm1Suite().tryParse(serialized);
    if (v1 != null) return v1;
    final v2 = LdVcDm2Suite().tryParse(serialized);
    if (v2 != null) return v2;
    throw TdkException(
      message: 'Credential ${vc.id} could not be parsed as a linked-data VC.',
      code: TdkExceptionType.parseFailure.code,
    );
  }
}
