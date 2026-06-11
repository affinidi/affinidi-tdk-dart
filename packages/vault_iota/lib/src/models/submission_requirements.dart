import 'package:affinidi_tdk_common/affinidi_tdk_common.dart';

import '../exceptions/tdk_exception_type.dart';
import '../services/pd_classifier_constants.dart';

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

  /// Throws a [TdkException] with
  /// [TdkExceptionType.invalidPresentationDefinition] if the `from` key is
  /// absent or null.
  static Never _throw(String message) => throw TdkException(
    message: message,
    code: TdkExceptionType.invalidPresentationDefinition.code,
  );

  /// Creates a [SubmissionRequirements] from a JSON map.
  ///
  /// The group name is read from the `from` key per the OID4VP spec.
  factory SubmissionRequirements.fromJson(Map<String, dynamic> json) {
    final rawFrom = json[PdClassifierConstants.submissionRequirementsFromKey];
    if (rawFrom == null) {
      _throw(
        'submission_requirements entry is missing the required "from" field.',
      );
    }
    if (rawFrom is! String) {
      _throw('submission_requirements "from" field must be a string.');
    }

    int? toInt(String key) {
      final v = json[key];
      if (v == null) return null;
      if (v is int) return v;
      if (v is num) return v.toInt();
      _throw('submission_requirements "$key" field must be a number.');
    }

    final min = toInt(PdClassifierConstants.submissionRequirementsMinKey);
    final max = toInt(PdClassifierConstants.submissionRequirementsMaxKey);
    final count = toInt(PdClassifierConstants.submissionRequirementsCountKey);

    if ((min != null && max != null && min > max) ||
        (count != null && max != null && count > max) ||
        (count != null && min != null && count < min)) {
      _throw(
        'Malformed submission_requirements: invalid min/max/count combination.',
      );
    }

    return SubmissionRequirements(
      min: min,
      max: max,
      count: count,
      groupName: rawFrom,
    );
  }

  /// The minimum number of VCs that must be included from this group.
  ///
  /// Priority: [count] > [min] > 1 (default).
  int get minimumVCsCountToShare => count ?? min ?? 1;

  /// The maximum number of VCs that may be included from this group.
  ///
  /// Priority: [count] > [max].
  int? get maximumVCsCountToShare => count ?? max;
}
