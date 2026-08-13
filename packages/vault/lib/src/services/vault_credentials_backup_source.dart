import 'dart:convert';

import 'package:affinidi_tdk_common/affinidi_tdk_common.dart';
import 'package:ssi/ssi.dart';

import '../exceptions/tdk_exception_type.dart';
import '../storage_interfaces/credential_storage.dart';
import '../storage_interfaces/profile_repository.dart';
import 'vault_profiles_backup_source.dart';

/// A [Restorable] that backs up and restores the verifiable credentials stored
/// under every profile of a [ProfileRepository].
///
/// Credentials are grouped by the owning profile's `did` (see
/// [VaultProfilesBackupSource.didKey]) so they can be reattached after the
/// profiles are recreated. This source must be registered after
/// [VaultProfilesBackupSource] so the target profiles already exist on import.
class VaultCredentialsBackupSource implements Restorable {
  /// Creates a [VaultCredentialsBackupSource].
  ///
  /// Parameters:
  /// * [profileRepository] - The repository whose profiles' credentials are
  ///   backed up and restored.
  /// * [pageSize] - Page size used when enumerating credentials.
  /// * [logger] - Optional logger; defaults to [Logger.instance].
  VaultCredentialsBackupSource({
    required ProfileRepository profileRepository,
    int pageSize = 50,
    Logger? logger,
  }) : _profileRepository = profileRepository,
       _pageSize = pageSize,
       _logger = logger ?? Logger.instance;

  final ProfileRepository _profileRepository;
  final int _pageSize;
  final Logger _logger;

  static const String _sectionKey = 'credentials';

  @override
  Future<Map<String, dynamic>> export() async {
    final byDid = <String, List<dynamic>>{};
    for (final profile in await _profileRepository.listProfiles()) {
      final storage = profile.defaultCredentialStorage;
      if (storage == null) {
        continue;
      }
      byDid[profile.did] = await _exportCredentials(storage);
    }
    return {_sectionKey: byDid};
  }

  Future<List<dynamic>> _exportCredentials(CredentialStorage storage) async {
    final credentials = <dynamic>[];
    String? cursor;
    do {
      final page = await storage.listCredentials(
        limit: _pageSize,
        exclusiveStartItemId: cursor,
      );
      for (final credential in page.items) {
        credentials.add(credential.verifiableCredential.toJson());
      }
      cursor = page.lastEvaluatedItemId;
    } while (cursor != null);
    return credentials;
  }

  @override
  Future<void> import(Map<String, dynamic> data) async {
    final section = data[_sectionKey];
    if (section is! Map<String, dynamic>) {
      _logger.warning('Backup is missing the "$_sectionKey" section.');
      throw TdkException(
        message: 'Backup is missing the "$_sectionKey" section.',
        code: TdkExceptionType.invalidBackupFormat.code,
      );
    }

    final profilesByDid = {
      for (final profile in await _profileRepository.listProfiles())
        profile.did: profile,
    };

    for (final entry in section.entries) {
      final did = entry.key;
      final credentials = entry.value;
      if (credentials is! List) {
        throw TdkException(
          message: 'The "$_sectionKey" backup section is malformed.',
          code: TdkExceptionType.invalidBackupFormat.code,
        );
      }

      final storage = profilesByDid[did]?.defaultCredentialStorage;
      if (storage == null) {
        _logger.warning(
          'Skipping credentials for unknown or storage-less profile.',
        );
        continue;
      }

      for (final raw in credentials) {
        final verifiableCredential = _parseCredential(raw);
        await storage.saveCredential(
          verifiableCredential: verifiableCredential,
        );
      }
    }
  }

  VerifiableCredential _parseCredential(dynamic raw) {
    try {
      return UniversalParser.parse(jsonEncode(raw));
    } catch (error, stackTrace) {
      _logger.warning('Failed to parse a backed-up credential: $error');
      Error.throwWithStackTrace(
        TdkException(
          message: 'The "$_sectionKey" backup section contains invalid data.',
          code: TdkExceptionType.invalidBackupFormat.code,
        ),
        stackTrace,
      );
    }
  }
}
