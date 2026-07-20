import 'package:affinidi_tdk_common/affinidi_tdk_common.dart';
import 'package:dio/dio.dart';

import '../exceptions/tdk_exception_type.dart';
import '../http_status_code.dart';
import '../models/verifier_client_metadata.dart';
import 'verifier_metadata_service_interface.dart';

/// Implementation of [VerifierMetadataServiceInterface] that resolves verifier
/// identity either from an embedded metadata map or via a network request to
/// the Affinidi login configuration API.
class VerifierMetadataService implements VerifierMetadataServiceInterface {
  final String _baseUrl;
  final Dio _dio;

  static const _metadataPath = '/vpa/v1/login/configurations/metadata';

  static Never _throw(
    String message,
    TdkExceptionType type, {
    String? originalMessage,
  }) => throw TdkException(
    message: message,
    code: type.code,
    originalMessage: originalMessage,
  );

  /// Creates a new [VerifierMetadataService].
  ///
  /// [baseUrl] - the base URL of the Affinidi API.
  /// [dio] - optional Dio client; defaults to a new [Dio].
  VerifierMetadataService({required String baseUrl, Dio? dio})
    : _baseUrl = baseUrl,
      _dio = dio ?? Dio();

  @override
  Future<VerifierClientMetadata> fetchVerifierMetadata({
    required String clientId,
    String? clientMetadataUri,
    Map<String, dynamic>? clientMetadata,
  }) async {
    if (clientId.isEmpty) {
      _throw('clientId must not be empty.', TdkExceptionType.invalidClientId);
    }

    try {
      if (clientMetadata != null) {
        return VerifierClientMetadata.fromJson(clientMetadata);
      }

      final Uri uri;
      if (clientMetadataUri != null) {
        uri = Uri.parse(clientMetadataUri);
      } else {
        uri = Uri.parse(
          _baseUrl,
        ).replace(path: '$_metadataPath/${Uri.encodeComponent(clientId)}');
      }

      final response = await _dio.getUri<dynamic>(
        uri,
        options: Options(validateStatus: (_) => true),
      );

      if (response.statusCode != HttpStatusCode.ok) {
        _throw(
          'Verifier metadata request failed with status ${response.statusCode}.',
          TdkExceptionType.failedToFetchVerifierMetadata,
        );
      }

      final json = response.data;
      if (json is! Map<String, dynamic>) {
        _throw(
          'Verifier metadata response was not a JSON object.',
          TdkExceptionType.failedToFetchVerifierMetadata,
        );
      }
      return VerifierClientMetadata.fromJson(json);
    } on TdkException {
      rethrow;
    } catch (e) {
      _throw(
        'Failed to fetch verifier metadata.',
        TdkExceptionType.failedToFetchVerifierMetadata,
        originalMessage: e.toString(),
      );
    }
  }

  /// Releases the underlying HTTP client.
  ///
  /// Call this when the service is no longer needed.
  @override
  void dispose() {
    _dio.close();
  }
}
