import 'package:ssi/ssi.dart' show VerifiableCredential;
import 'package:uuid/uuid.dart';

import '../models/pd_descriptor.dart';
import '../models/presentation_submission.dart';
import 'share_requirements_matcher_service.dart' show PexEvaluator;

/// Builds a [PresentationSubmission] from a definition ID, the requested
/// descriptors, and the credentials that populate the Verifiable Presentation.
abstract final class PresentationSubmissionBuilder {
  /// Builds a [PresentationSubmission] from a [definitionId], the requested
  /// [descriptors], and the ordered [credentials] embedded in the VP.
  ///
  /// Each `descriptor_map` entry's `path` must point at the credential in the
  /// VP that actually satisfies that descriptor. Rather than assuming the
  /// caller supplied credentials in descriptor order (which would make
  /// `$.verifiableCredential[i]` reference the wrong credential when the two
  /// lists diverge), each descriptor's field constraints are evaluated against
  /// [credentials] via [PexEvaluator] and the entry's `path` is resolved to the
  /// real index of its matching credential in the VP.
  ///
  /// Parameters:
  /// * [definitionId] - The ID of the Presentation Definition being satisfied.
  /// * [descriptors] - The Presentation Definition's input descriptors.
  /// * [credentials] - The ordered credentials embedded in the VP, where
  ///   position `i` corresponds to `$.verifiableCredential[i]`. This must be the
  ///   exact same list (and order) used to build the VP.
  ///
  /// Descriptors with no matching credential in [credentials] are omitted from
  /// the `descriptor_map`, since there is no VP entry they could reference. When
  /// several descriptors could be satisfied by the same set of credentials,
  /// each descriptor is greedily assigned a distinct credential where possible
  /// so a one-to-one mapping is preferred.
  ///
  /// Returns a [PresentationSubmission] with a freshly generated UUID `id`.
  static PresentationSubmission build({
    required String definitionId,
    required List<PDDescriptor> descriptors,
    required List<VerifiableCredential> credentials,
  }) {
    final descriptorMap = <DescriptorMapEntry>[];
    final usedIndices = <int>{};

    for (final descriptor in descriptors) {
      final matches = PexEvaluator.selectMatching(
        descriptor.toJson(),
        credentials,
      );
      if (matches.isEmpty) continue;

      final index = _resolveCredentialIndex(
        credentials: credentials,
        matches: matches,
        usedIndices: usedIndices,
      );
      if (index == null) continue;

      usedIndices.add(index);
      // JSON-LD VPs only: format is always 'ldp_vc' and no path_nested is
      // needed because each VC is embedded directly as a JSON-LD object.
      descriptorMap.add(
        DescriptorMapEntry(
          id: descriptor.id,
          format: 'ldp_vc',
          path: '\$.verifiableCredential[$index]',
        ),
      );
    }

    return PresentationSubmission(
      id: const Uuid().v4(),
      definitionId: definitionId,
      descriptorMap: descriptorMap,
    );
  }

  /// Returns the VP index of the credential to reference for a descriptor.
  ///
  /// Prefers the first matching credential whose index has not already been
  /// assigned to another descriptor, so distinct descriptors map to distinct
  /// credentials when possible. Falls back to the first match (even if its
  /// index is already used) when every match has been consumed, which allows a
  /// single credential to satisfy multiple descriptors. Returns `null` when no
  /// match can be located by identity within [credentials].
  static int? _resolveCredentialIndex({
    required List<VerifiableCredential> credentials,
    required List<VerifiableCredential> matches,
    required Set<int> usedIndices,
  }) {
    int? firstIndex;
    for (final match in matches) {
      final index = _identityIndexOf(credentials, match);
      if (index < 0) continue;
      firstIndex ??= index;
      if (!usedIndices.contains(index)) return index;
    }
    return firstIndex;
  }

  /// Returns the index of [target] within [credentials] by identity, or `-1`.
  ///
  /// Identity comparison is used because the matcher returns the same
  /// credential instances that populate the VP, and [VerifiableCredential] does
  /// not guarantee value equality.
  static int _identityIndexOf(
    List<VerifiableCredential> credentials,
    VerifiableCredential target,
  ) {
    for (var i = 0; i < credentials.length; i++) {
      if (identical(credentials[i], target)) return i;
    }
    return -1;
  }
}
