/// Describes how credentials from a specific group must be submitted in a VP.
///
/// Parsed from the `submission_requirements` array of a Presentation
/// Definition. The JSON key for the group name is `from`.
class SubmissionRequirements {
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

  factory SubmissionRequirements.fromJson(Map<String, dynamic> json) {
    return SubmissionRequirements(
      min: json['min'] as int?,
      max: json['max'] as int?,
      count: json['count'] as int?,
      groupName: json['from'] as String,
    );
  }
}
