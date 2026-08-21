import 'package:affinidi_tdk_common/affinidi_tdk_common.dart';

import '../passphrase_policy.dart';
import 'tdk_exception_type.dart';

/// Exception thrown when a backup passphrase violates its configured policy.
class PassphrasePolicyException extends TdkException {
  /// Creates a [PassphrasePolicyException].
  PassphrasePolicyException({required this.violation, required this.minLength})
    : super(
        message: 'Passphrase does not satisfy the required policy.',
        code: TdkExceptionType.weakPassphrase.code,
      );

  /// The specific policy rule that the passphrase violates.
  final PassphraseViolation violation;

  /// The minimum length configured by the policy.
  final int minLength;

  @override
  String toString() =>
      '${super.toString()}, violation: ${violation.code}, '
      'minLength: $minLength';
}
