import 'package:affinidi_tdk_common/affinidi_tdk_common.dart';

import '../exceptions/tdk_exception_type.dart';
import '../models/iota_consent_record.dart';
import 'enumerable_consent_storage.dart';

/// A [Restorable] that backs up and restores Iota consent history records.
///
/// Records are read from and written back to a consumer-provided
/// [EnumerableConsentStorage]. Each [IotaConsentRecord] is serialised with its
/// own `toJson`, so the section is self-describing and independent of the other
/// backup sources.
class IotaConsentHistoryBackupSource implements Restorable {
  /// Creates an [IotaConsentHistoryBackupSource].
  ///
  /// Parameters:
  /// * [consentStorage] - The enumerable storage read during backup and written
  ///   during restore.
  /// * [logger] - Optional logger; defaults to [Logger.instance].
  IotaConsentHistoryBackupSource({
    required EnumerableConsentStorage consentStorage,
    Logger? logger,
  }) : _consentStorage = consentStorage,
       _logger = logger ?? Logger.instance;

  final EnumerableConsentStorage _consentStorage;
  final Logger _logger;

  static const String _sectionKey = 'consentHistory';

  @override
  Future<Map<String, dynamic>> export() async {
    final records = await _consentStorage.listAll();
    return {
      _sectionKey: [for (final record in records) record.toJson()],
    };
  }

  @override
  Future<void> import(Map<String, dynamic> data) async {
    final section = data[_sectionKey];
    if (section is! List) {
      _logger.warning('Backup is missing the "$_sectionKey" section.');
      throw TdkException(
        message: 'Backup is missing the "$_sectionKey" section.',
        code: TdkExceptionType.invalidBackupFormat.code,
      );
    }

    for (final raw in section) {
      if (raw is! Map<String, dynamic>) {
        throw TdkException(
          message: 'The "$_sectionKey" backup section is malformed.',
          code: TdkExceptionType.invalidBackupFormat.code,
        );
      }
      await _consentStorage.saveOrUpdate(IotaConsentRecord.fromJson(raw));
    }
  }
}
