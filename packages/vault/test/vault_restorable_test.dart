import 'package:affinidi_tdk_vault/affinidi_tdk_vault.dart';
import 'package:test/test.dart';

import 'fakes/fake_profile_repository.dart';
import 'fakes/fake_restorable.dart';
import 'fakes/fake_restorable_profile_repository.dart';
import 'fixtures/vault_restorable_fixtures.dart';

void main() {
  group('When rolling back before an import', () {
    test('it preserves registered repository and component state', () async {
      final events = <String>[];
      final repository = FakeRestorableProfileRepository(
        'edge',
        value: 'user-data',
        events: events,
      )..importedData = {'value': 'user-data'};
      final named = FakeRestorable(id: 'consentHistory', events: events)
        ..importedData = {'value': 'user-data'};
      final vault = await VaultRestorableFixtures.vault(
        store: await VaultRestorableFixtures.store(events),
        repositories: {'edge': repository},
        named: {'consentHistory': named},
      );

      await vault.rollbackImport();

      expect(repository.importedData, {'value': 'user-data'});
      expect(named.importedData, {'value': 'user-data'});
      expect(repository.rollbackCalls, 0);
      expect(named.rollbackCalls, 0);
    });

    test('it preserves VaultStore data', () async {
      final store = await VaultRestorableFixtures.store([]);
      final seed = await store.getSeed();

      await store.rollbackImport();

      expect(await store.getSeed(), seed);
      expect(await store.getAccountIndex(), 3);
    });
  });

  group('When exporting restorable state', () {
    test('it exports repositories and named components by stable ID', () async {
      final events = <String>[];
      final vault = await VaultRestorableFixtures.vault(
        store: await VaultRestorableFixtures.store(events),
        repositories: {
          'z-cloud': FakeProfileRepository('z-cloud'),
          'a-edge': FakeRestorableProfileRepository(
            'a-edge',
            value: 'profiles',
            events: events,
          ),
        },
        named: {
          'consentHistory': FakeRestorable(
            id: 'consentHistory',
            events: events,
          ),
        },
      );

      final exported = await vault.export();
      final repositories = exported['repositories'] as Map<String, dynamic>;

      expect(repositories['manifest'], [
        {'id': 'a-edge', 'restorable': true},
        {'id': 'z-cloud', 'restorable': false},
      ]);
      expect(repositories['data'], {
        'a-edge': {'version': '1.0.0', 'value': 'profiles'},
      });
      expect(exported['namedComponents'], {
        'consentHistory': {'version': '1.0.0', 'value': 'consentHistory'},
      });
    });
  });

  group('When importing restorable state', () {
    test('it imports repositories before named components', () async {
      final sourceEvents = <String>[];
      final source = await VaultRestorableFixtures.vault(
        store: await VaultRestorableFixtures.store(sourceEvents),
        repositories: {
          'edge': FakeRestorableProfileRepository(
            'edge',
            value: 'profiles',
            events: sourceEvents,
          ),
        },
        named: {
          'consentHistory': FakeRestorable(
            id: 'consentHistory',
            events: sourceEvents,
          ),
        },
      );
      final backup = await source.export();

      final targetEvents = <String>[];
      final repository = FakeRestorableProfileRepository(
        'edge',
        value: 'empty',
        events: targetEvents,
      );
      final named = FakeRestorable(id: 'consentHistory', events: targetEvents);
      final target = await VaultRestorableFixtures.vault(
        store: await VaultRestorableFixtures.store(targetEvents),
        repositories: {'edge': repository},
        named: {'consentHistory': named},
      );

      await target.import(backup);

      expect(targetEvents, ['edge', 'consentHistory']);
      expect(repository.importedData, {
        'version': '1.0.0',
        'value': 'profiles',
      });
      expect(named.importedData, {
        'version': '1.0.0',
        'value': 'consentHistory',
      });
    });

    test('it rejects missing registrations before any import', () async {
      final sourceEvents = <String>[];
      final source = await VaultRestorableFixtures.vault(
        store: await VaultRestorableFixtures.store(sourceEvents),
        repositories: {
          'edge': FakeRestorableProfileRepository(
            'edge',
            value: 'profiles',
            events: sourceEvents,
          ),
        },
        named: {
          'consentHistory': FakeRestorable(id: 'named', events: sourceEvents),
        },
      );
      final backup = await source.export();

      final targetEvents = <String>[];
      final target = await VaultRestorableFixtures.vault(
        store: await VaultRestorableFixtures.store(targetEvents),
        repositories: {
          'edge': FakeRestorableProfileRepository(
            'edge',
            value: 'empty',
            events: targetEvents,
          ),
        },
      );

      await expectLater(target.import(backup), throwsA(isA<TdkException>()));
      expect(targetEvents, isEmpty);
    });

    test('it rejects a different wallet before any import', () async {
      final sourceEvents = <String>[];
      final source = await VaultRestorableFixtures.vault(
        store: await VaultRestorableFixtures.store(sourceEvents),
        repositories: {
          'edge': FakeRestorableProfileRepository(
            'edge',
            value: 'profiles',
            events: sourceEvents,
          ),
        },
      );
      final backup = await source.export();

      final targetEvents = <String>[];
      final target = await VaultRestorableFixtures.vault(
        store: await VaultRestorableFixtures.store(targetEvents, seedOffset: 1),
        repositories: {
          'edge': FakeRestorableProfileRepository(
            'edge',
            value: 'empty',
            events: targetEvents,
          ),
        },
      );

      await expectLater(target.import(backup), throwsA(isA<TdkException>()));
      expect(targetEvents, isEmpty);
    });

    test('it routes colliding payload shapes only by repository ID', () async {
      final events = <String>[];
      final source = await VaultRestorableFixtures.vault(
        store: await VaultRestorableFixtures.store(events),
        repositories: {
          'first': FakeRestorableProfileRepository(
            'first',
            value: 'one',
            events: events,
          ),
          'second': FakeRestorableProfileRepository(
            'second',
            value: 'two',
            events: events,
          ),
        },
      );
      final backup = await source.export();

      final first = FakeRestorableProfileRepository(
        'first',
        value: 'empty',
        events: events,
      );
      final second = FakeRestorableProfileRepository(
        'second',
        value: 'empty',
        events: events,
      );
      final target = await VaultRestorableFixtures.vault(
        store: await VaultRestorableFixtures.store(events),
        repositories: {'first': first, 'second': second},
      );

      await target.import(backup);

      expect(first.importedData?['value'], 'one');
      expect(second.importedData?['value'], 'two');
    });
  });
}
