import 'package:affinidi_tdk_common/affinidi_tdk_common.dart';

import '../exceptions/tdk_exception_type.dart';

/// Describes how credentials from a specific group must be submitted in a VP.
///
/// Parsed from the `submission_requirements` array of a Presentation
/// Definition. The JSON key for the group name is `from`.
class SubmissionRequirements {
  /// Creates a [SubmissionRequirements] instance.
  const SubmissionRequirements({
    this.min,
    this.max,
    this.count,
    required this.groupName,
  });

  /// Minimum number of credentials from this group to include.
  final int? min;

  /// Maximum number of credentials from this group to include.
  final int? max;

  /// Exact number of credentials from this group to include.
  final int? count;

  /// The group identifier this requirement applies to (JSON key: `from`).
  final String groupName;

  /// Creates a [SubmissionRequirements] from a JSON map.
  ///
  /// The group name is read from the `from` key per the OID4VP spec.
  /// Throws a [TdkException] with
  /// [TdkExceptionType.invalidPresentationDefinition] if the `from` key is
  /// absent or null.
  factory SubmissionRequirements.fromJson(Map<String, dynamic> json) {
    final groupName = json['from'] as String?;
    if (groupName == null) {
      Error.throwWithStackTrace(
        TdkException(
          message:
              'submission_requirements entry is missing the required "from" field.',
          code: TdkExceptionType.invalidPresentationDefinition.code,
        ),
        StackTrace.current,
      );
    }
    return SubmissionRequirements(
      min: json['min'] as int?,
      max: json['max'] as int?,
      count: json['count'] as int?,
      groupName: groupName,
    );
  }
}
