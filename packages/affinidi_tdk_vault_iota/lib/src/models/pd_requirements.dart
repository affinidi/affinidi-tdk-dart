import 'pd_descriptor.dart';
import 'request_purpose.dart';
import 'submission_requirements.dart';
import 'verified_identity_document_info.dart';

/// The classified breakdown of what a Presentation Definition is requesting.
///
/// Produced by the PD classifier after inspecting the input descriptors of an
/// OID4VP Presentation Definition. Consumers use this to determine which steps
/// their share flow needs — credential selection, profile data entry, or an
/// identity verification redirect.
///
/// ## Categories
/// - [claimedDescriptors]: standard (third-party issued) VCs — the most
///   common case.
/// - [zpdLinkedDescriptors]: VCs that attest ZPD data (e.g. `Email`,
///   `PhoneNumber`). These require a ZPD-backed VC to be present.
/// - [idvDescriptors]: identity verification VCs (e.g. `Passport`,
///   `DriversLicense`) issued by a trusted IDV issuer. When non-empty, the
///   consumer should redirect the user to the IDV flow.
///
/// ## Profile data
/// - [dataPoints]: profile data paths (e.g. `$.person.properties.email`)
///   accumulated from ZPD and profile VC types.
/// - [zeroPartyVCs]: VC types that are `ProfileTemplate` or any `HIT*` type,
///   requiring the user to supply first-party profile data.
///
/// ## Helpers
/// - [claimedVCsRequested]: `true` if the request includes standard or IDV
///   credentials.
/// - [zpdRequested]: `true` if the request includes profile data or
///   ZPD-linked credentials.
/// - [shouldGenerateProfileVC]: `true` if a `ProfileTemplate` VC must be
///   generated for this request.
class PDRequirements {
  /// Creates a [PDRequirements] instance.
  const PDRequirements({
    required this.claimedDescriptors,
    required this.zpdLinkedDescriptors,
    required this.idvDescriptors,
    required this.dataPoints,
    required this.zeroPartyVCs,
    this.idvInfo,
    this.submissionRequirementsByGroup = const {},
    this.purpose,
  });

  /// Input descriptors for standard (third-party issued) VCs.
  final List<PDDescriptor> claimedDescriptors;

  /// Input descriptors for VCs that attest ZPD data (e.g. `Email`,
  /// `PhoneNumber`).
  final List<PDDescriptor> zpdLinkedDescriptors;

  /// Input descriptors for identity verification VCs (e.g. `Passport`,
  /// `DriversLicense`).
  final List<PDDescriptor> idvDescriptors;

  /// Profile data paths accumulated from ZPD and profile VC types.
  final Set<String> dataPoints;

  /// VC types that are `ProfileTemplate` or any `HIT*` type.
  final Set<String> zeroPartyVCs;

  /// Metadata about the requested identity verification document type.
  ///
  /// Non-null when [idvDescriptors] is non-empty.
  final VerifiedIdentityDocumentInfo? idvInfo;

  /// Maps group name to submission rules (min / max / count).
  final Map<String, SubmissionRequirements> submissionRequirementsByGroup;

  /// Human-readable purpose declared in the Presentation Definition.
  final RequestPurpose? purpose;

  /// Returns a copy of this [PDRequirements] with the given fields replaced.
  PDRequirements copyWith({
    List<PDDescriptor>? claimedDescriptors,
    List<PDDescriptor>? zpdLinkedDescriptors,
    List<PDDescriptor>? idvDescriptors,
    Set<String>? dataPoints,
    Set<String>? zeroPartyVCs,
    VerifiedIdentityDocumentInfo? idvInfo,
    Map<String, SubmissionRequirements>? submissionRequirementsByGroup,
    RequestPurpose? purpose,
  }) {
    return PDRequirements(
      claimedDescriptors: claimedDescriptors ?? this.claimedDescriptors,
      zpdLinkedDescriptors: zpdLinkedDescriptors ?? this.zpdLinkedDescriptors,
      idvDescriptors: idvDescriptors ?? this.idvDescriptors,
      dataPoints: dataPoints ?? this.dataPoints,
      zeroPartyVCs: zeroPartyVCs ?? this.zeroPartyVCs,
      idvInfo: idvInfo ?? this.idvInfo,
      submissionRequirementsByGroup:
          submissionRequirementsByGroup ?? this.submissionRequirementsByGroup,
      purpose: purpose ?? this.purpose,
    );
  }

  /// A Presentation Definition JSON containing only the ZPD-linked descriptors.
  ///
  /// Use this when building a VP for ZPD-linked VCs (e.g. `Email`,
  /// `PhoneNumber`).
  Map<String, dynamic> get zpdLinkedPD => {
    'id': 'pd_for_zpd_linked_vcs',
    'input_descriptors': zpdLinkedDescriptors.map((d) => d.toJson()).toList(),
  };

  /// A Presentation Definition JSON containing only the claimed (third-party)
  /// descriptors.
  ///
  /// Use this when building a VP for standard VCs.
  Map<String, dynamic> get claimedPD => {
    'id': 'pd_for_claimed_vcs',
    'input_descriptors': claimedDescriptors.map((d) => d.toJson()).toList(),
  };

  /// `true` if the request includes standard (third-party) or IDV credentials.
  bool get claimedVCsRequested =>
      claimedDescriptors.isNotEmpty || idvDescriptors.isNotEmpty;

  /// `true` if the request includes profile data or ZPD-linked credentials.
  bool get zpdRequested => dataPoints.isNotEmpty || zeroPartyVCs.isNotEmpty;

  /// `true` if a `ProfileTemplate` VC must be generated for this request.
  bool get shouldGenerateProfileVC => zeroPartyVCs.contains('ProfileTemplate');
}
