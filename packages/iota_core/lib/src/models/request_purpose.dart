import 'dart:convert';

/// Purpose metadata extracted from the presentation definition's `purpose` field.
///
/// Provides human-readable descriptions of why the verifier is requesting
/// the credentials.
class RequestPurpose {
  /// Human-readable description of the data collection purpose.
  final String? dataCollectionPurpose;

  /// Human-readable description of the specific request.
  final String? requestDescription;

  /// Creates a new [RequestPurpose] instance.
  ///
  /// Both [dataCollectionPurpose] and [requestDescription] are optional.
  const RequestPurpose({
    this.dataCollectionPurpose,
    this.requestDescription,
  });

  /// Creates a [RequestPurpose] from a JSON value.
  ///
  /// Accepts either a JSON-encoded [String] or a [Map<String, dynamic>].
  /// Returns an empty [RequestPurpose] if the input cannot be parsed.
  ///
  /// Parameters:
  /// - [json] - a JSON-encoded string or a map containing `data_collection_purpose`
  ///   and optionally `request_description`.
  factory RequestPurpose.fromJson(dynamic json) {
    Map<String, dynamic>? parsedJson;
    if (json is String) {
      try {
        parsedJson = jsonDecode(json) as Map<String, dynamic>;
      } catch (_) {
        return const RequestPurpose();
      }
    } else if (json is Map<String, dynamic>) {
      parsedJson = json;
    }

    if (parsedJson == null) {
      return const RequestPurpose();
    }

    if (parsedJson.containsKey('data_collection_purpose') &&
        parsedJson['data_collection_purpose'] == null) {
      return const RequestPurpose();
    }

    return RequestPurpose(
      dataCollectionPurpose:
          parsedJson['data_collection_purpose']?.toString(),
      requestDescription: parsedJson['request_description']?.toString(),
    );
  }

  /// Converts this [RequestPurpose] to a JSON map.
  ///
  /// Null fields are omitted from the output.
  Map<String, dynamic> toJson() => {
        if (dataCollectionPurpose != null)
          'data_collection_purpose': dataCollectionPurpose,
        if (requestDescription != null)
          'request_description': requestDescription,
      };

  /// Returns `true` when a non-empty [dataCollectionPurpose] is present.
  bool get isValid => dataCollectionPurpose?.isNotEmpty ?? false;

  /// Returns [requestDescription] when it is non-empty, otherwise `null`.
  String? get displayPurposeDescription =>
      (requestDescription?.isNotEmpty ?? false) ? requestDescription : null;
}
