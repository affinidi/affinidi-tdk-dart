import 'dart:convert';

import 'package:affinidi_tdk_common/affinidi_tdk_common.dart';
import 'package:http/http.dart' as http;

import '../exceptions/tdk_exception_type.dart';
import '../http_status_code.dart';
import '../models/verifier_client_metadata.dart';
import 'verifier_metadata_service_interface.dart';

/// Implementation of [VerifierMetadataServiceInterface] that resolves verifier
/// identity either from an embedded metadata map or via a network request to
/// the Affinidi login configuration API.
class VerifierMetadataService implements VerifierMetadataServiceInterface {
  final String _baseUrl;
  final http.Client _httpClient;

  static const _metadataPath = '/vpa/v1/login/configurations/metadata';

  /// Creates a new [VerifierMetadataService].
  ///
  /// [baseUrl] - the base URL of the Affinidi API
  /// (e.g. `https://apse1.api.affinidi.io`).
  /// [httpClient] - optional HTTP client; defaults to a new [http.Client].
  VerifierMetadataService({
    required String baseUrl,
    http.Client? httpClient,
  })  : _baseUrl = baseUrl,
        _httpClient = httpClient ?? http.Client();

  @override
  Future<VerifierClientMetadata> fetchVerifierMetadata({
    required String clientId,
    Uri? clientMetadataUri,
    Map<String, dynamic>? embeddedClientMetadata,
  }) async {
    try {
      if (embeddedClientMetadata != null) {
        return VerifierClientMetadata.fromJson(embeddedClientMetadata);
      }

      final uri =
          clientMetadataUri ?? Uri.parse('$_baseUrl$_metadataPath/$clientId');
      final response = await _httpClient.get(uri);

      if (response.statusCode != HttpStatusCode.ok) {
        Error.throwWithStackTrace(
          TdkException(
            message:
                'Verifier metadata request failed with status ${response.statusCode}.',
            code: TdkExceptionType.verifierMetadataFetchFailed.code,
          ),
          StackTrace.current,
        );
      }

      final Map<String, dynamic> json =
          jsonDecode(response.body) as Map<String, dynamic>;
      return VerifierClientMetadata.fromJson(json);
    } on TdkException {
      rethrow;
    } catch (e) {
      Error.throwWithStackTrace(
        TdkException(
          message: 'Failed to fetch verifier metadata.',
          code: TdkExceptionType.verifierMetadataFetchFailed.code,
          originalMessage: e.toString(),
        ),
        StackTrace.current,
      );
    }
  }

  /// Releases the underlying HTTP client.
  ///
  /// Call this when the service is no longer needed.
  @override
  void dispose() {
    _httpClient.close();
  }
}
