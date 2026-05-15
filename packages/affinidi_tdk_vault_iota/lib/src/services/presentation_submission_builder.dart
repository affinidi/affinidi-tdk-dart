import 'package:uuid/uuid.dart';

import '../models/pd_descriptor.dart';
import '../models/presentation_submission.dart';

/// Builds a [PresentationSubmission] from a definition ID and an ordered list
/// of descriptors.
abstract final class PresentationSubmissionBuilder {
  /// Builds a [PresentationSubmission] from a [definitionId] and an ordered
  /// list of [descriptors].
  ///
  /// Parameters:
  /// * [definitionId] - The ID of the Presentation Definition being satisfied.
  /// * [descriptors] - Ordered list of descriptors; position `i` maps to
  ///   `$.verifiableCredential[i]` in the VP.
  ///
  /// Returns a [PresentationSubmission] with a freshly generated UUID `id`.
  static PresentationSubmission build({
    required String definitionId,
    required List<PDDescriptor> descriptors,
  }) {
    return PresentationSubmission(
      id: const Uuid().v4(),
      definitionId: definitionId,
      descriptorMap: [
        for (var i = 0; i < descriptors.length; i++)
          DescriptorMapEntry(
            id: descriptors[i].id,
            format: 'ldp_vc',
            path: '\$.verifiableCredential[$i]',
          ),
      ],
    );
  }
}
