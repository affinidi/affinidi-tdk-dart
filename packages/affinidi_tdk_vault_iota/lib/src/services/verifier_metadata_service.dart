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

  static Never _throwInvalidClientId() => Error.throwWithStackTrace(
    TdkException(
      message: 'clientId must not be empty.',
      code: TdkExceptionType.invalidClientId.code,
    ),
    StackTrace.current,
  );

  static Never _throwFetchFailed(
    String message, {
    String? originalMessage,
    StackTrace? stackTrace,
  }) => Error.throwWithStackTrace(
    TdkException(
      message: message,
      code: TdkExceptionType.failedToFetchVerifierMetadata.code,
      originalMessage: originalMessage,
    ),
    stackTrace ?? StackTrace.current,
  );

  /// Creates a new [VerifierMetadataService].
  ///
  /// [baseUrl] - the base URL of the Affinidi API.
  /// [httpClient] - optional HTTP client; defaults to a new [http.Client].
  VerifierMetadataService({required String baseUrl, http.Client? httpClient})
    : _baseUrl = baseUrl,
      _httpClient = httpClient ?? http.Client();

  @override
  Future<VerifierClientMetadata> fetchVerifierMetadata({
    required String clientId,
    Map<String, dynamic>? clientMetadata,
  }) async {
    if (clientId.isEmpty) _throwInvalidClientId();

    try {
      if (clientMetadata != null) {
        return VerifierClientMetadata.fromJson(clientMetadata);
      }

      final uri = Uri.parse(
        _baseUrl,
      ).replace(path: '$_metadataPath/${Uri.encodeComponent(clientId)}');
      final response = await _httpClient.get(uri);

      if (response.statusCode != HttpStatusCode.ok) {
        _throwFetchFailed(
          'Verifier metadata request failed with status ${response.statusCode}.',
        );
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return VerifierClientMetadata.fromJson(json);
    } on TdkException {
      rethrow;
    } catch (e, stackTrace) {
      _throwFetchFailed(
        'Failed to fetch verifier metadata.',
        originalMessage: e.toString(),
        stackTrace: stackTrace,
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
