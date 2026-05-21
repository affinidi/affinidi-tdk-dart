import '../models/submission_requirements.dart';

/// Helpers for determining how many VCs must be included from a group when
/// building a VP submission.
extension SubmissionRequirementsX on SubmissionRequirements {
  /// The minimum number of VCs that must be included from this group.
  ///
  /// Priority: [SubmissionRequirements.count] > [SubmissionRequirements.min]
  /// > 1 (default).
  int get minimumVCsCountToShare => count ?? min ?? 1;

  /// The maximum number of VCs that may be included from this group.
  ///
  /// Priority: [SubmissionRequirements.count] > [SubmissionRequirements.max].
  int? get maximumVCsCountToShare => count ?? max;
}
