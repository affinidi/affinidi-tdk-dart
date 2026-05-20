import 'dart:convert';

import 'package:affinidi_tdk_vault_iota/affinidi_tdk_vault_iota.dart';
import 'package:drift/drift.dart';

import 'database/database.dart' as db;

/// Drift-backed implementation of [ConsentRecordStore].
class DriftConsentRecordStore implements ConsentRecordStore {
  /// Creates a new instance of [DriftConsentRecordStore].
  const DriftConsentRecordStore({required db.Database database})
    : _database = database;

  final db.Database _database;

  @override
  Future<void> saveOrUpdate(IotaConsentRecord record) async {
    await _database
        .into(_database.consentRecords)
        .insertOnConflictUpdate(
          db.ConsentRecordsCompanion.insert(
            requestHash: record.requestHash,
            did: record.did,
            hash: record.hash,
            logo: Value(record.logo),
            siteUrl: Value(record.siteUrl),
            sharedAt: record.sharedAt,
            profileName: record.profileName,
            profileId: record.profileId,
            clientId: record.clientId,
            isAutoShareEnabled: record.isAutoShareEnabled,
            sharedVcIds: record.sharedVcIds.join(','),
            claimedVcTypesCsv: record.claimedVcTypesCsv,
            isConsentManagementEnabled: Value(
              record.isConsentManagementEnabled,
            ),
            historySharedData: Value(jsonEncode(record.historySharedData)),
          ),
        );
  }

  @override
  Future<IotaConsentRecord?> findByRequestHashAndDid(
    String requestHash,
    String did,
  ) async {
    final row =
        await (_database.select(_database.consentRecords)..where(
              (t) => t.requestHash.equals(requestHash) & t.did.equals(did),
            ))
            .getSingleOrNull();

    return row == null ? null : _toModel(row);
  }

  IotaConsentRecord _toModel(db.ConsentRecord row) {
    return IotaConsentRecord(
      hash: row.hash,
      requestHash: row.requestHash,
      logo: row.logo,
      siteUrl: row.siteUrl,
      did: row.did,
      sharedAt: row.sharedAt,
      profileName: row.profileName,
      profileId: row.profileId,
      clientId: row.clientId,
      isAutoShareEnabled: row.isAutoShareEnabled,
      sharedVcIds: row.sharedVcIds.isEmpty ? [] : row.sharedVcIds.split(','),
      claimedVcTypesCsv: row.claimedVcTypesCsv,
      isConsentManagementEnabled: row.isConsentManagementEnabled,
      historySharedData:
          (jsonDecode(row.historySharedData) as Map<String, dynamic>).map(
            (k, v) => MapEntry(k, v as String),
          ),
    );
  }
}
