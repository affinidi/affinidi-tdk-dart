/// String constants used when inspecting a Presentation Definition JSON map.
abstract final class PdClassifierConstants {
  // ── PD structure keys ────────────────────────────────────────────────────

  /// JSON key for the list of input descriptors in a PD.
  static const String inputDescriptorsKey = 'input_descriptors';

  /// JSON key for the constraints block of an input descriptor.
  static const String constraintsKey = 'constraints';

  /// JSON key for the fields list within a constraints block.
  static const String fieldsKey = 'fields';

  /// JSON key for the path list within a field.
  static const String pathKey = 'path';

  /// JSON key for the filter block within a field.
  static const String filterKey = 'filter';

  /// JSON key for the `contains` sub-filter within a filter.
  static const String containsKey = 'contains';

  /// JSON key for a regex pattern value within a filter.
  static const String patternKey = 'pattern';

  /// JSON key for a constant (exact-match) value within a filter.
  static const String constKey = 'const';

  /// JSON key for the type field in a filter (e.g. `"string"`).
  static const String typeKey = 'type';

  /// JSON key for the group name list on an input descriptor.
  static const String groupNameKey = 'group';

  /// JSON key for the purpose field of a PD.
  static const String purposeKey = 'purpose';

  // ── JSON-LD paths within a VC ────────────────────────────────────────────

  /// JSONPath to the `@context` field of a verifiable credential.
  static const String contextPath = r'$.@context';

  /// JSONPath to the `type` field of a verifiable credential.
  static const String typePath = r'$.type';

  // ── Submission requirements keys ─────────────────────────────────────────

  /// JSON key for the submission requirements array in a PD.
  static const String submissionRequirementsKey = 'submission_requirements';

  /// JSON key for the `min` field of a submission requirement.
  static const String submissionRequirementsMinKey = 'min';

  /// JSON key for the `max` field of a submission requirement.
  static const String submissionRequirementsMaxKey = 'max';

  /// JSON key for the `from` (group name) field of a submission requirement.
  static const String submissionRequirementsFromKey = 'from';

  /// JSON key for the `count` field of a submission requirement.
  static const String submissionRequirementsCountKey = 'count';

  // ── Profile / ZPD constants ──────────────────────────────────────────────

  /// JSON-LD context URL that identifies a `ProfileTemplate` VC.
  static const String profileContext =
      'https://schema.affinidi.io/profile-template/context.jsonld';

  /// VC type string for a `ProfileTemplate` zero-party data VC.
  static const String profileType = 'ProfileTemplate';

  /// VC type string for an identity verification document VC.
  static const String verifiedIdentityDocumentType = 'VerifiedIdentityDocument';
}
