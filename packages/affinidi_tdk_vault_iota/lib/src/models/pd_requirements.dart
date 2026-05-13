import 'pd_descriptor.dart';
import 'request_purpose.dart';
import 'submission_requirements.dart';
import 'verified_identity_document_info.dart';

/// The classified breakdown of what a Presentation Definition is requesting.
///
/// Produced by the PD classifier after inspecting the input descriptors of an
/// OID4VP Presentation Definition. Consumers use this to determine which steps
/// their share flow needs — credential selection or an identity verification
/// redirect.
///
/// ## Categories
/// - [claimedDescriptors]: standard (third-party issued) VCs — the most
///   common case.
/// - [idvDescriptors]: identity verification VCs (e.g. `Passport`,
///   `DriversLicense`) issued by a trusted IDV issuer. When non-empty, the
///   consumer should redirect the user to the IDV flow.
///
/// ## Helpers
/// - [claimedVCsRequested]: `true` if the request includes standard or IDV
///   credentials.
class PDRequirements {
  /// Creates a [PDRequirements] instance.
  const PDRequirements({
    required this.claimedDescriptors,
    required this.idvDescriptors,
    this.idvInfo,
    this.submissionRequirementsByGroup = const {},
    this.purpose,
  });

  /// Input descriptors for standard (third-party issued) VCs.
  final List<PDDescriptor> claimedDescriptors;

  /// Input descriptors for identity verification VCs (e.g. `Passport`,
  /// `DriversLicense`).
  final List<PDDescriptor> idvDescriptors;

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
    List<PDDescriptor>? idvDescriptors,
    VerifiedIdentityDocumentInfo? idvInfo,
    Map<String, SubmissionRequirements>? submissionRequirementsByGroup,
    RequestPurpose? purpose,
  }) {
    return PDRequirements(
      claimedDescriptors: claimedDescriptors ?? this.claimedDescriptors,
      idvDescriptors: idvDescriptors ?? this.idvDescriptors,
      idvInfo: idvInfo ?? this.idvInfo,
      submissionRequirementsByGroup:
          submissionRequirementsByGroup ?? this.submissionRequirementsByGroup,
      purpose: purpose ?? this.purpose,
    );
  }

  /// A Presentation Definition JSON containing only the claimed (third-party)
  /// descriptors.
  Map<String, dynamic> get claimedPD => {
    'id': 'pd_for_claimed_vcs',
    'input_descriptors': claimedDescriptors.map((d) => d.toJson()).toList(),
  };

  /// `true` if the request includes standard (third-party) or IDV credentials.
  bool get claimedVCsRequested =>
      claimedDescriptors.isNotEmpty || idvDescriptors.isNotEmpty;
}
