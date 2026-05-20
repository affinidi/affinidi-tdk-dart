import 'package:affinidi_tdk_vault_edge_drift_provider/src/database/database.dart';
import 'package:affinidi_tdk_vault_edge_drift_provider/src/edge_drift_consent_record_store.dart';
import 'package:drift/native.dart';
import 'package:test/test.dart';

import 'fixtures/consent_record_fixtures.dart';

void main() {
  late Database database;
  late DriftConsentRecordStore store;

  setUp(() {
    database = Database(NativeDatabase.memory());
    store = DriftConsentRecordStore(database: database);
  });

  tearDown(() async {
    await database.close();
  });

  group('DriftConsentRecordStore', () {
    group('findByRequestHashAndDid', () {
      test('returns null when no record exists', () async {
        final result = await store.findByRequestHashAndDid(
          ConsentRecordFixtures.requestHash,
          ConsentRecordFixtures.did,
        );

        expect(result, isNull);
      });

      test(
        'returns null for a different did with the same requestHash',
        () async {
          await store.saveOrUpdate(ConsentRecordFixtures.create());

          final result = await store.findByRequestHashAndDid(
            ConsentRecordFixtures.requestHash,
            'did:key:other_holder',
          );

          expect(result, isNull);
        },
      );
    });

    group('saveOrUpdate', () {
      test('persists a new record that can then be retrieved', () async {
        final record = ConsentRecordFixtures.create();

        await store.saveOrUpdate(record);

        final retrieved = await store.findByRequestHashAndDid(
          record.requestHash,
          record.profileDid,
        );

        expect(retrieved, isNotNull);
        expect(retrieved!.requestHash, record.requestHash);
        expect(retrieved.profileDid, record.profileDid);
        expect(retrieved.hash, record.hash);
        expect(retrieved.logo, record.logo);
        expect(retrieved.siteUrl, record.siteUrl);
        expect(retrieved.sharedAt, record.sharedAt);
        expect(retrieved.profileName, record.profileName);
        expect(retrieved.profileId, record.profileId);
        expect(retrieved.clientId, record.clientId);
        expect(retrieved.isAutoShareEnabled, record.isAutoShareEnabled);
        expect(retrieved.sharedVcIds, record.sharedVcIds);
        expect(retrieved.claimedVcTypesCsv, record.claimedVcTypesCsv);
      });

      test(
        'replaces an existing record with the same requestHash and did',
        () async {
          await store.saveOrUpdate(ConsentRecordFixtures.create());

          final updated = ConsentRecordFixtures.create(
            hash: 'updated_hash',
            sharedVcIds: ['vc-1', 'vc-2', 'vc-3'],
            isAutoShareEnabled: true,
          );

          await store.saveOrUpdate(updated);

          final retrieved = await store.findByRequestHashAndDid(
            updated.requestHash,
            updated.profileDid,
          );

          expect(retrieved!.hash, 'updated_hash');
          expect(retrieved.sharedVcIds, ['vc-1', 'vc-2', 'vc-3']);
          expect(retrieved.isAutoShareEnabled, isTrue);
        },
      );

      test('stores records for different dids independently', () async {
        final recordA = ConsentRecordFixtures.create(did: 'did:key:holder_a');
        final recordB = ConsentRecordFixtures.create(
          did: 'did:key:holder_b',
          hash: 'hash_b',
        );

        await store.saveOrUpdate(recordA);
        await store.saveOrUpdate(recordB);

        final retrievedA = await store.findByRequestHashAndDid(
          ConsentRecordFixtures.requestHash,
          'did:key:holder_a',
        );
        final retrievedB = await store.findByRequestHashAndDid(
          ConsentRecordFixtures.requestHash,
          'did:key:holder_b',
        );

        expect(retrievedA!.profileDid, 'did:key:holder_a');
        expect(retrievedB!.profileDid, 'did:key:holder_b');
        expect(retrievedB.hash, 'hash_b');
      });
    });
  });
}
