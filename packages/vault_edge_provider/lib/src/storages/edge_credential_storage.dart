import 'dart:convert';

import 'package:affinidi_tdk_vault/affinidi_tdk_vault.dart';
import 'package:synchronized/synchronized.dart';
import 'package:uuid/uuid.dart';

import '../../affinidi_tdk_vault_edge_provider.dart';

/// An Edge based implementation of [CredentialStorage] for storing and managing
/// verifiable credentials with encryption support.
class EdgeCredentialStorage implements CredentialStorage, Restorable {
  /// Creates a new instance of [EdgeCredentialStorage].
  ///
  /// [lock] allows an owning [EdgeProfileRepository] to serialize this
  /// storage with profile and file operations.
  EdgeCredentialStorage({
    required EdgeCredentialsRepositoryInterface repository,
    required String id,
    required String profileId,
    CredentialCodec? codec,
    required EdgeEncryptionServiceInterface encryptionService,
    Lock? lock,
  }) : _repository = repository,
       _id = id,
       _profileId = profileId,
       _codec = codec ?? CredentialCodec(),
       _encryptionService = encryptionService,
       _lock = lock ?? Lock(reentrant: true);

  final EdgeCredentialsRepositoryInterface _repository;
  final String _id;
  final String _profileId;
  final CredentialCodec _codec;
  final EdgeEncryptionServiceInterface _encryptionService;
  final Lock _lock;

  static const _backupVersion = '1.0.0';
  static const _pageSize = 50;
  static const _invalidBackupFormatCode = 'invalid_backup_format';

  @override
  String get id => _id;

  @override
  Future<void> deleteCredential({
    required String digitalCredentialId,
    VaultCancelToken? cancelToken,
  }) => _lock.synchronized(() async {
    final credentialData = await _repository.getCredentialData(
      credentialId: digitalCredentialId,
      cancelToken: cancelToken,
    );

    if (credentialData == null) {
      Error.throwWithStackTrace(
        TdkException(
          message: 'Credential not found',
          code: TdkExceptionType.credentialNotFound.code,
        ),
        StackTrace.current,
      );
    }

    await _repository.deleteCredential(
      credentialId: digitalCredentialId,
      cancelToken: cancelToken,
    );
  });

  @override
  Future<DigitalCredential> getCredential({
    required String digitalCredentialId,
    VaultCancelToken? cancelToken,
  }) => _lock.synchronized(() async {
    final credentialData = await _repository.getCredentialData(
      credentialId: digitalCredentialId,
      cancelToken: cancelToken,
    );

    if (credentialData == null) {
      Error.throwWithStackTrace(
        TdkException(
          message: 'Credential not found',
          code: TdkExceptionType.credentialNotFound.code,
        ),
        StackTrace.current,
      );
    }

    final decryptedContent = await _encryptionService.decryptData(
      credentialData.content,
    );

    return _codec.decode(
      credentialBytes: decryptedContent,
      id: credentialData.id,
    );
  });

  @override
  Future<PaginatedList<DigitalCredential>> listCredentials({
    int? limit,
    String? exclusiveStartItemId,
    VaultCancelToken? cancelToken,
  }) => _lock.synchronized(() async {
    final credentialDataList = await _repository.listCredentialData(
      profileId: _profileId,
      limit: limit,
      exclusiveStartItemId: exclusiveStartItemId,
      cancelToken: cancelToken,
    );

    final credentials = await Future.wait(
      credentialDataList.items.map((credentialData) async {
        final decryptedContent = await _encryptionService.decryptData(
          credentialData.content,
        );

        return _codec.decode(
          credentialBytes: decryptedContent,
          id: credentialData.id,
        );
      }),
    );

    return PaginatedList(
      items: credentials,
      lastEvaluatedItemId: credentialDataList.lastEvaluatedItemId,
    );
  });

  @override
  dynamic query(String pexQuery) {
    // TODO: implement query
    throw UnimplementedError();
  }

  @override
  Future<void> saveCredential({
    required VerifiableCredential verifiableCredential,
    VaultCancelToken? cancelToken,
  }) => _lock.synchronized(() async {
    await _saveCredential(
      credentialId: const Uuid().v4(),
      verifiableCredential: verifiableCredential,
      cancelToken: cancelToken,
    );
  });

  Future<void> _saveCredential({
    required String credentialId,
    required VerifiableCredential verifiableCredential,
    VaultCancelToken? cancelToken,
  }) async {
    final credentialName =
        verifiableCredential.type
            .where((type) => type != 'VerifiableCredential')
            .firstOrNull ??
        'Credential';

    final credentialContent = _codec.encode(verifiableCredential);

    // Encrypt the credential content
    final encryptedContent = await _encryptionService.encryptData(
      credentialContent,
    );

    await _repository.saveCredentialData(
      profileId: _profileId,
      credentialId: credentialId,
      credentialName: credentialName,
      credentialContent: encryptedContent,
      cancelToken: cancelToken,
    );
  }

  @override
  Future<Map<String, dynamic>> export() => _lock.synchronized(() async {
    final credentials = <Map<String, dynamic>>[];
    String? cursor;
    do {
      final page = await listCredentials(
        limit: _pageSize,
        exclusiveStartItemId: cursor,
      );
      for (final credential in page.items) {
        credentials.add({
          'id': credential.id,
          'verifiableCredential': credential.verifiableCredential.toJson(),
        });
      }
      cursor = page.lastEvaluatedItemId;
    } while (cursor != null);

    return {'version': _backupVersion, 'credentials': credentials};
  });

  @override
  Future<void> validateImport(Map<String, dynamic> data) =>
      _lock.synchronized(() async {
        _parseBackup(data);
      });

  @override
  Future<bool> isEmpty() => _lock.synchronized(() async {
    final page = await _repository.listCredentialData(
      profileId: _profileId,
      limit: 1,
    );
    return page.items.isEmpty;
  });

  @override
  Future<void> import(Map<String, dynamic> data) =>
      _lock.synchronized(() async {
        final credentials = _parseBackup(data);
        if (!await isEmpty()) {
          throw _restoreDestinationNotEmpty();
        }
        for (final (id, credential) in credentials) {
          await _saveCredential(
            credentialId: id,
            verifiableCredential: credential,
          );
        }
      });

  List<(String, VerifiableCredential)> _parseBackup(Map<String, dynamic> data) {
    const allowedKeys = {'version', 'credentials'};
    final rawCredentials = data['credentials'];
    if (data.keys.any((key) => !allowedKeys.contains(key)) ||
        data['version'] != _backupVersion ||
        rawCredentials is! List) {
      throw _invalidBackupFormat();
    }

    final credentials = <(String, VerifiableCredential)>[];
    final backupIds = <String>{};
    for (final rawCredential in rawCredentials) {
      if (rawCredential is! Map<String, dynamic> ||
          rawCredential.length != 2 ||
          !rawCredential.containsKey('id') ||
          !rawCredential.containsKey('verifiableCredential')) {
        throw _invalidBackupFormat();
      }
      final id = rawCredential['id'];
      if (id is! String || id.isEmpty || !backupIds.add(id)) {
        throw _invalidBackupFormat();
      }
      try {
        final credential = UniversalParser.parse(
          jsonEncode(rawCredential['verifiableCredential']),
        );
        credentials.add((id, credential));
      } catch (error) {
        throw _invalidBackupFormat(originalMessage: error.toString());
      }
    }

    return credentials;
  }

  TdkException _invalidBackupFormat({String? originalMessage}) => TdkException(
    message: 'The credential storage backup payload is malformed.',
    code: _invalidBackupFormatCode,
    originalMessage: originalMessage,
  );

  TdkException _restoreDestinationNotEmpty() => TdkException(
    message: 'Credential restore destination is not empty.',
    code: 'restore_destination_not_empty',
  );
}
