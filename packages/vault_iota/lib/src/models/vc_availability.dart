import 'package:ssi/ssi.dart';

import 'vc_unavailability_reason.dart';

/// The availability status of a single verifiable credential that was matched
/// against a requested input descriptor.
///
/// Use a switch expression or `is` check to handle each case:
///
/// ```dart
/// switch (availability) {
///   case VcAvailable(:final vc):
///     // ready to share
///   case VcUnavailable(:final reason, :final bestMatchVc):
///     // not ready — inspect reason
/// }
/// ```
sealed class VcAvailability {
  const VcAvailability();
}

/// A credential that is present and valid — ready to share.
final class VcAvailable extends VcAvailability {
  /// Creates a [VcAvailable] with the given [vc].
  const VcAvailable({required this.vc});

  /// The matched credential.
  final VerifiableCredential vc;
}

/// A credential that cannot be shared, along with the reason why.
final class VcUnavailable extends VcAvailability {
  /// Creates a [VcUnavailable] with the given [reason] and optional [bestMatchVc].
  const VcUnavailable({required this.reason, this.bestMatchVc});

  /// Why the credential is unavailable.
  final VcUnavailabilityReason reason;

  /// The closest matching credential found, if any (e.g. an expired one).
  final VerifiableCredential? bestMatchVc;
}
