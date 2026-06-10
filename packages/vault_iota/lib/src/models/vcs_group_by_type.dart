import 'dart:math';

import 'vc_availability.dart';

/// The matched credentials for a single requested input descriptor, grouped
/// by descriptor type.
///
/// [minimumVCsCountToShare] and [maximumVCsCountToShare] come from the
/// `submission_requirements` for the descriptor's group (defaulting to 1 when
/// no submission requirement is specified). [maximumVCsCountToShare] is `null`
/// when no upper bound is defined.
class VCsGroupByType {
  /// Creates a [VCsGroupByType].
  const VCsGroupByType({
    this.minimumVCsCountToShare = 1,
    this.maximumVCsCountToShare,
    required this.matchedVCs,
  });

  /// Minimum number of credentials from this group the verifier requires.
  final int minimumVCsCountToShare;

  /// Maximum number of credentials from this group the verifier accepts.
  ///
  /// `null` means the verifier imposes no upper limit.
  final int? maximumVCsCountToShare;

  /// All matched credentials (available and unavailable) for this descriptor.
  final List<VcAvailability> matchedVCs;

  /// Whether the verifier requires an exact fixed count of credentials.
  bool get hasFixedRequestedVCsCount =>
      maximumVCsCountToShare != null &&
      minimumVCsCountToShare == maximumVCsCountToShare;

  /// Whether the user has enough available credentials to satisfy the minimum.
  bool get hasEnoughVCsToShare =>
      allAvailableVCs.length >= minimumVCsCountToShare;

  /// Whether the user has more available credentials than the minimum required.
  bool get hasMoreThanEnoughVCsToShare =>
      allAvailableVCs.length > minimumVCsCountToShare;

  /// Whether the number of available credentials is within the maximum limit.
  ///
  /// Always `true` when [maximumVCsCountToShare] is `null` (unbounded).
  bool get hasLessOrEqualThanMaximumVCsToShare =>
      maximumVCsCountToShare == null ||
      allAvailableVCs.length <= maximumVCsCountToShare!;

  /// Whether the available count exactly matches both min and max.
  bool get hasMatchingAvailableVCsCountAsRequired =>
      maximumVCsCountToShare != null &&
      allAvailableVCs.length == minimumVCsCountToShare &&
      allAvailableVCs.length == maximumVCsCountToShare;

  /// The recommended set of credentials to share — up to [maximumVCsCountToShare]
  /// available credentials (all available when [maximumVCsCountToShare] is `null`).
  /// Only [VcAvailable] entries are included.
  List<VcAvailable> get recommendedMaximumVCs {
    final available = allAvailableVCs;
    final cap = maximumVCsCountToShare;
    return cap == null
        ? available
        : available.sublist(0, min(cap, available.length));
  }

  /// All credentials from [matchedVCs] that are available to share.
  List<VcAvailable> get allAvailableVCs =>
      matchedVCs.whereType<VcAvailable>().toList();
}
