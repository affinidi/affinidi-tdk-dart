import 'dart:convert';

import 'package:affinidi_tdk_common/affinidi_tdk_common.dart' show TdkException;
import 'package:dcql/dcql.dart'
    show
        DcqlCredential,
        DcqlCredentialQuery,
        DigitalCredential,
        W3CDigitalCredential;
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

  /// Creates an [IotaShareResponseService].
  ///
  /// Parameters:
  /// * [signer] - the DID signer that controls the holder's key.
  /// * [dio] - optional Dio client; defaults to a plain [Dio].
  /// * [vpBuilder] - custom VP builder; defaults to [VpBuilder].
  IotaShareResponseService({
    required DidSigner signer,
    Dio? dio,
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
  /// Throws [TdkException] with code `submission_failed` if the API call fails.
  Future<Uri?> _submitDcqlShareResponse(
    DcqlShareRequest dcql,
    List<ParsedVerifiableCredential<dynamic>> selectedCredentials,
    String acceptResponseUri,
  ) async {
    final vpToken = <String, List<Map<String, dynamic>>>{};

    for (final credential in dcql.dcqlQuery.credentials) {
      final matched = selectedCredentials
          .where((vc) => _vcMatchesDcqlCredential(credential, vc))
          .toList();
      if (matched.isEmpty) continue;

      // Per the spec: when `multiple` is `false` (the default) return exactly
      // one Presentation; when `true` return one Presentation per matching
      // Credential.
      final credentialGroups = credential.multiple
          ? matched.map((vc) => [vc]).toList()
          : [
              [matched.first],
            ];

      // Per OID4VP spec Appendix B.1: when require_cryptographic_holder_binding
      // is false, return each Verifiable Credential as-is without wrapping it
      // in a VP. The default (null or true) always builds a signed VP.
      if (credential.requireCryptographicHolderBinding == false) {
        vpToken[credential.id] = credentialGroups
            .map((creds) => creds.first.toJson())
            .toList();
      } else {
        vpToken[credential.id] = await Future.wait(
          credentialGroups.map(
            (credentials) => _vpBuilder.build(
              signer: _signer,
              credentials: credentials,
              nonce: dcql.request.nonce,
              domain: dcql.request.clientId,
            ),
          ),
        );
      }
    }

    return _postToUri(acceptResponseUri, {
      'state': dcql.request.state,
      'vp_token': jsonEncode(vpToken),
    });
  }

  /// Returns `true` if [vc] matches the given DCQL [credential] query.
  static bool _vcMatchesDcqlCredential(
    DcqlCredential credential,
    VerifiableCredential vc,
  ) {
    final wrapped = _toDigitalCredential(vc);
    if (wrapped == null) return false;
    final query = DcqlCredentialQuery(credentials: [credential]);
    final result = query.query([wrapped]);
    return result.verifiableCredentials[credential.id]?.isNotEmpty == true;
  }

  /// Wraps a [VerifiableCredential] for evaluation by the `dcql` package.
  /// Returns `null` for unsupported formats.
  static DigitalCredential? _toDigitalCredential(VerifiableCredential vc) {
    final contextUri = vc.context.firstUri?.toString();
    try {
      if (contextUri == dmV1ContextUrl) {
        return W3CDigitalCredential.fromLdVcDataModelV1(vc.toJson());
      }
      if (contextUri == dmV2ContextUrl) {
        return W3CDigitalCredential.fromLdVcDataModelV2(vc.toJson());
      }
      return null;
    } on Exception {
      return null;
    }
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
