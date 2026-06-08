import 'package:affinidi_tdk_common/affinidi_tdk_common.dart';

import '../exceptions/tdk_exception_type.dart';
import '../models/pd_descriptor.dart';

/// Pure-static helpers for reading the structural fields of a PEX
/// Presentation Definition.
///
/// Centralises the `input_descriptors` and `id` parsing shared by the
/// share-response and auto-consent paths so both fail the same way on a
/// malformed definition.
abstract final class PresentationDefinitionParser {
  /// Parses the `input_descriptors` array of [presentationDefinition].
  ///
  /// Parameters:
  /// * [presentationDefinition] - the raw PEX Presentation Definition JSON.
  ///
  /// Returns the parsed list of [PDDescriptor]s.
  /// Throws [TdkException] with code `invalid_presentation_definition` when
  /// `input_descriptors` is absent, not a list, or contains a malformed entry.
  static List<PDDescriptor> parseInputDescriptors(
    Map<String, dynamic> presentationDefinition,
  ) {
    final rawDescriptors = presentationDefinition['input_descriptors'];
    if (rawDescriptors is! List) {
      throw TdkException(
        message: 'Presentation definition is missing input_descriptors.',
        code: TdkExceptionType.invalidPresentationDefinition.code,
      );
    }

    try {
      return rawDescriptors
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
  }

  /// Parses the `id` of [presentationDefinition].
  ///
  /// Parameters:
  /// * [presentationDefinition] - the raw PEX Presentation Definition JSON.
  ///
  /// Returns the definition id.
  /// Throws [TdkException] with code `invalid_presentation_definition` when
  /// `id` is absent or not a string.
  static String parseDefinitionId(
    Map<String, dynamic> presentationDefinition,
  ) {
    final definitionId = presentationDefinition['id'];
    if (definitionId is! String) {
      throw TdkException(
        message: 'Presentation definition is missing a valid id.',
        code: TdkExceptionType.invalidPresentationDefinition.code,
      );
    }
    return definitionId;
  }
}
