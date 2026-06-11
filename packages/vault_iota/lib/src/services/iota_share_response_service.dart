import 'dart:convert';

import 'package:affinidi_tdk_common/affinidi_tdk_common.dart'
    show Logger, TdkException;
import 'package:dio/dio.dart';
import 'package:ssi/ssi.dart';

import '../exceptions/tdk_exception_type.dart';
import '../helpers/dcql_vc_adapter.dart';
import '../helpers/did_document_resolver.dart';
import '../helpers/presentation_definition_parser.dart';
import '../helpers/response_uri_trust_validator.dart';
import '../models/iota_request.dart';
import '../models/share_requirements.dart';
import 'iota_share_response_service_interface.dart';
import 'presentation_submission_builder.dart';
import 'vp_builder.dart';

/// Orchestrates the OID4VP share response: builds the VP, builds the
/// presentation submission (PEX only), and POSTs both directly to the
/// response URI supplied by the verifier in the OID4VP request.
class IotaShareResponseService implements IotaShareResponseServiceInterface {
  static const _didKeyPrefix = 'did:key:';

  final DidSigner _signer;
  final VpBuilderInterface _vpBuilder;
  final Dio _dio;
  final Logger _logger;
  final DcqlVcAdapter _vcAdapter;
  final DidDocumentResolver _didResolver;
  final ResponseUriTrustValidator? _responseUriTrustValidator;

  /// Creates an [IotaShareResponseService].
  ///
  /// Parameters:
  /// * [signer] - the DID signer that controls the holder's key.
  /// * [dio] - optional Dio client; defaults to a plain [Dio].
  /// * [vpBuilder] - custom VP builder; defaults to [VpBuilder].
  /// * [logger] - optional logger; defaults to [Logger.instance].
  /// * [didResolver] - custom DID resolver; defaults to the SSI resolver.
  /// * [responseUriTrustValidator] - optional policy hook for response URI
  ///   approval when the verifier DID document does not bind the URI host.
  IotaShareResponseService({
    required DidSigner signer,
    Dio? dio,
    VpBuilderInterface? vpBuilder,
    Logger? logger,
    DidDocumentResolver? didResolver,
    ResponseUriTrustValidator? responseUriTrustValidator,
  }) : _signer = signer,
       _dio = dio ?? Dio(),
       _vpBuilder = vpBuilder ?? const VpBuilder(),
       _logger = logger ?? Logger.instance,
       _vcAdapter = DcqlVcAdapter(logger: logger),
       _didResolver =
           didResolver ?? UniversalDIDResolver.defaultResolver.resolveDid,
       _responseUriTrustValidator = responseUriTrustValidator;

  /// Builds and submits a Verifiable Presentation to the verifier callback endpoint.
  ///
  /// Parameters:
  /// * [shareRequest] - the parsed OID4VP request.
  /// * [selectedCredentials] - the credentials to include in the VP.
  /// * [acceptResponseUri] - the URI from the OID4VP request JWT to POST the VP to.
  ///
  /// Returns the redirect [Uri] provided by the endpoint, or `null`.
  /// Throws [TdkException] with code `invalid_response_uri` if the response URI
  /// is unsafe or not declared by the verifier DID service endpoints.
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
  /// Throws [TdkException] with code `invalid_response_uri` if the response URI
  /// is unsafe or not declared by the verifier DID service endpoints.
  /// Throws [TdkException] with code `submission_failed` if the API call fails.
  @override
  Future<Uri?> rejectShareResponse({
    required Oid4vpShareRequest shareRequest,
    required String rejectResponseUri,
  }) async {
    return _postToUri(shareRequest.request, rejectResponseUri, {
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

    return _postToUri(pex.request, acceptResponseUri, {
      'state': pex.request.state,
      'vp_token': jsonEncode(vp),
      'presentation_submission': jsonEncode(submission.toJson()),
    });
  }

  /// Builds and submits the DCQL Authorization Response.
  ///
  /// Per the OpenID4VP 1.0 specification (section 8.1, "Response Parameters"),
  /// the `vp_token` for a DCQL request MUST be a JSON object whose keys are the
  /// `id` of each Credential Query in the request and whose values are arrays of
  /// the Presentations that satisfy the respective query. With `multiple`
  /// omitted or `false` (the default), the array contains exactly one
  /// Presentation. Credential Queries with no matching Credentials are omitted.
  /// Unlike PEX, there is no `presentation_submission`.
  ///
  /// See https://openid.net/specs/openid-4-verifiable-presentations-1_0.html#section-8.1
  ///
  /// Parameters:
  /// * [dcql] - the parsed DCQL share request.
  /// * [selectedCredentials] - the credentials the user agreed to share.
  /// * [acceptResponseUri] - the URI to POST the Authorization Response to.
  ///
  /// Returns the redirect [Uri] provided by the endpoint, or `null`.
  /// Throws [TdkException] with code `invalid_response_uri` if the response URI
  /// is unsafe or not declared by the verifier DID service endpoints.
  /// Throws [TdkException] with code `submission_failed` if the API call fails.
  Future<Uri?> _submitDcqlShareResponse(
    DcqlShareRequest dcql,
    List<ParsedVerifiableCredential<dynamic>> selectedCredentials,
    String acceptResponseUri,
  ) async {
    // OID4VP 1.0 requires `vp_token` (DCQL) to be a JSON object where:
    // - key: Credential Query `id`
    // - value: array of one or more Presentations matching that query
    // - when `multiple` is omitted or false, the array contains exactly one
    //   Presentation
    // - optional Credential Queries with no matches MUST be omitted
    // - each Presentation can be a string or object per Appendix B encoding
    // Spec: https://openid.net/specs/openid-4-verifiable-presentations-1_0.html#section-8.1
    final vpToken = <String, dynamic>{};
    final unassigned = List<ParsedVerifiableCredential<dynamic>>.of(
      selectedCredentials,
    );

    for (final credential in dcql.dcqlQuery.credentials) {
      final List<ParsedVerifiableCredential<dynamic>> presentations;

      if (credential.multiple) {
        final taken = <ParsedVerifiableCredential<dynamic>>[];
        for (final vc in List<ParsedVerifiableCredential<dynamic>>.of(
          unassigned,
        )) {
          if (_vcAdapter.vcMatchesDcqlCredential(credential, vc)) {
            taken.add(vc);
            unassigned.remove(vc);
          }
        }
        if (taken.isEmpty) continue;
        presentations = taken;
      } else {
        final match = unassigned
            .where((vc) => _vcAdapter.vcMatchesDcqlCredential(credential, vc))
            .firstOrNull;
        if (match == null) continue;
        unassigned.remove(match);
        presentations = [match];
      }

      // Per OID4VP spec Appendix B.1: when require_cryptographic_holder_binding
      // is false, return the Verifiable Credential as-is without wrapping it in
      // a VP. The default (null or true) always builds a signed VP.
      if (credential.requireCryptographicHolderBinding == false) {
        vpToken[credential.id] = presentations
            .map((vc) => vc.toJson())
            .toList();
      } else {
        vpToken[credential.id] = await Future.wait(
          presentations.map(
            (vc) => _vpBuilder.build(
              signer: _signer,
              credentials: [vc],
              nonce: dcql.request.nonce,
              domain: dcql.request.clientId,
            ),
          ),
        );
      }
    }

    _assertRequiredQueriesCovered(dcql, vpToken);

    return _postToUri(dcql.request, acceptResponseUri, {
      'state': dcql.request.state,
      'vp_token': jsonEncode(vpToken),
    });
  }

  /// Throws [TdkException] with [TdkExceptionType.incompleteCredentialSelection]
  /// if the built `vpToken` does not satisfy every required credential query.
  ///
  /// When `DcqlCredentialQuery.credentialSets` is absent or empty every query
  /// is required. When credential sets are present every set whose `required`
  /// flag is `true` must have at least one option where all query IDs appear in
  /// `vpToken`.
  void _assertRequiredQueriesCovered(
    DcqlShareRequest dcql,
    Map<String, dynamic> vpToken,
  ) {
    final covered = vpToken.keys.toSet();
    final credentialSets = dcql.dcqlQuery.credentialSets;

    if (credentialSets == null || credentialSets.isEmpty) {
      final missing = dcql.dcqlQuery.credentials
          .where((c) => !covered.contains(c.id))
          .map((c) => c.id)
          .toList();
      if (missing.isNotEmpty) {
        throw TdkException(
          message:
              'Required DCQL credential queries have no matching credentials: '
              '${missing.join(', ')}.',
          code: TdkExceptionType.incompleteCredentialSelection.code,
        );
      }
    } else {
      final allSatisfied = credentialSets
          .where((s) => s.required)
          .every(
            (set) => set.options.any((opt) => opt.every(covered.contains)),
          );
      if (!allSatisfied) {
        throw TdkException(
          message:
              'Required DCQL credential set cannot be satisfied with the '
              'selected credentials.',
          code: TdkExceptionType.incompleteCredentialSelection.code,
        );
      }
    }
  }

  Future<Uri?> _postToUri(
    IotaRequest request,
    String uri,
    Map<String, String> formData,
  ) async {
    final responseUri = await _validateVerifierBoundUri(
      request: request,
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
      return _validateRedirectUri(request, redirectUri);
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

  Future<Uri?> _validateRedirectUri(
    IotaRequest request,
    String redirectUri,
  ) async {
    try {
      return await _validateVerifierBoundUri(
        request: request,
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

  Future<Uri> _validateVerifierBoundUri({
    required IotaRequest request,
    required String uri,
    required String parameterName,
  }) async {
    final parsed = _parseSafeHttpsUri(uri, parameterName);
    // OID4VP direct_post requires response_uri to be permitted by the
    // client identifier rules, and recommends validating the response URI
    // using the authenticated client identifier and request integrity.
    // See: https://openid.net/specs/openid-4-verifiable-presentations-1_0.html#section-8.2
    // See: https://openid.net/specs/openid-4-verifiable-presentations-1_0.html#section-14.3.1
    final allowedHosts = await _allowedHostsForRequest(request);

    if (!allowedHosts.contains(parsed.host.toLowerCase())) {
      if (await _isExplicitlyTrustedUri(
        request: request,
        uri: parsed,
        parameterName: parameterName,
      )) {
        return parsed;
      }

      _throwUnboundResponseUri(request: request, parameterName: parameterName);
    }

    return parsed;
  }

  Future<Set<String>> _allowedHostsForRequest(IotaRequest request) async {
    return _allowedHostsForClientId(request.clientId);
  }

  Future<bool> _isExplicitlyTrustedUri({
    required IotaRequest request,
    required Uri uri,
    required String parameterName,
  }) async {
    final validator = _responseUriTrustValidator;
    if (validator == null) return false;

    try {
      return validator(
        request: request,
        uri: uri,
        parameterName: parameterName,
      );
    } catch (e, stackTrace) {
      Error.throwWithStackTrace(
        TdkException(
          message: 'Response URI trust validator failed.',
          code: TdkExceptionType.invalidResponseUri.code,
          originalMessage: e.toString(),
        ),
        stackTrace,
      );
    }
  }

  Never _throwUnboundResponseUri({
    required IotaRequest request,
    required String parameterName,
  }) => throw TdkException(
    message: request.clientId.startsWith(_didKeyPrefix)
        ? '$parameterName host cannot be verified from did:key client_id. '
              'Provide a responseUriTrustValidator to explicitly approve '
              'trusted verifier callback hosts.'
        : '$parameterName host is not declared in the client_id DID serviceEndpoint.',
    code: TdkExceptionType.invalidResponseUri.code,
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
    return parsed;
  }

  Future<Set<String>> _allowedHostsForClientId(String clientId) async {
    try {
      final didDocument = await _didResolver(clientId);
      final hosts = didDocument.service
          .expand((service) => _endpointUris(service.serviceEndpoint))
          .map(Uri.tryParse)
          .whereType<Uri>()
          .where((uri) => uri.scheme == 'https' && uri.host.isNotEmpty)
          .map((uri) => uri.host.toLowerCase())
          .toSet();

      return hosts;
    } on TdkException {
      rethrow;
    } catch (e, stackTrace) {
      Error.throwWithStackTrace(
        TdkException(
          message:
              'Failed to resolve client_id DID for response_uri validation.',
          code: TdkExceptionType.invalidResponseUri.code,
          originalMessage: e.toString(),
        ),
        stackTrace,
      );
    }
  }

  Iterable<String> _endpointUris(ServiceEndpointValue endpoint) sync* {
    switch (endpoint) {
      case StringEndpoint(:final url):
        yield url;
      case MapEndpoint(:final data):
        yield* _nestedStringValues(data);
      case SetEndpoint(:final endpoints):
        for (final endpoint in endpoints) {
          yield* _endpointUris(endpoint);
        }
    }
  }

  Iterable<String> _nestedStringValues(Object? value) sync* {
    switch (value) {
      case String stringValue:
        yield stringValue;
      case Iterable<Object?> iterableValue:
        for (final item in iterableValue) {
          yield* _nestedStringValues(item);
        }
      case Map<Object?, Object?> mapValue:
        for (final item in mapValue.values) {
          yield* _nestedStringValues(item);
        }
    }
  }
}
