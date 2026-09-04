import 'package:affinidi_tdk_vault_iota/affinidi_tdk_vault_iota.dart'
    hide TdkExceptionType;

import 'tdk_exception_type.dart';

/// Creates exceptions raised by consent storage operations.
abstract final class ConsentStorageException {
  /// Creates an exception when the record at [key] cannot be deserialized.
  static TdkException failedToReadRecord({
    required String key,
    required String originalMessage,
  }) => TdkException(
    message: 'Failed to deserialize consent record for key "$key".',
    code: TdkExceptionType.failedToReadConsentRecord.code,
    originalMessage: originalMessage,
  );
}
