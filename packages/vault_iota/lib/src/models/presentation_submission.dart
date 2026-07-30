/// A Presentation Submission as defined by the PEX 2.0 specification.
///
/// Describes the link between the Verifiable Presentation and the Presentation
/// Definition, telling the verifier which credential satisfies which descriptor.
class PresentationSubmission {
  /// The unique identifier of this submission.
  final String id;

  /// The identifier of the Presentation Definition this submission satisfies.
  final String definitionId;

  /// The ordered mapping from descriptor IDs to credential paths in the VP.
  final List<DescriptorMapEntry> descriptorMap;

  /// Creates a [PresentationSubmission].
  const PresentationSubmission({
    required this.id,
    required this.definitionId,
    required this.descriptorMap,
  });

  /// Serialises this submission to a JSON map.
  Map<String, dynamic> toJson() => {
    'id': id,
    'definition_id': definitionId,
    'descriptor_map': descriptorMap.map((e) => e.toJson()).toList(),
  };
}

/// A single entry in a [PresentationSubmission]'s `descriptor_map`.
///
/// Maps one input descriptor to the JSONPath of its credential inside the VP.
class DescriptorMapEntry {
  /// The input descriptor ID this entry satisfies.
  final String id;

  /// The credential format, e.g. `ldp_vc` or `jwt_vc`.
  final String format;

  /// The JSONPath to the credential inside the VP, e.g. `$.verifiableCredential[0]`.
  final String path;

  /// Creates a [DescriptorMapEntry].
  const DescriptorMapEntry({
    required this.id,
    required this.format,
    required this.path,
  });

  /// Serialises this entry to a JSON map.
  Map<String, dynamic> toJson() => {'id': id, 'format': format, 'path': path};
}
