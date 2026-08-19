import 'dart:typed_data';

import 'package:affinidi_tdk_vault/affinidi_tdk_vault.dart';
import 'package:test/test.dart';

class _Repository implements ProfileRepository {
  _Repository(this.id);

  @override
  final String id;

  @override
  Future<void> configure(Object configuration) async {}

  @override
  Future<Profile> createProfile({
    required String name,
    String? description,
    VaultCancelToken? cancelToken,
  }) => throw UnimplementedError();

  @override
  Future<void> deleteProfile(
    Profile profile, {
    VaultCancelToken? cancelToken,
  }) => throw UnimplementedError();

  @override
  Future<bool> isConfigured() async => true;

  @override
  Future<List<Profile>> listProfiles({VaultCancelToken? cancelToken}) async =>
      const [];

  @override
  Future<void> updateProfile(
    Profile profile, {
    VaultCancelToken? cancelToken,
  }) => throw UnimplementedError();
}

class _RestorableRepository extends _Repository implements Restorable {
  _RestorableRepository(super.id, {required this.value, required this.events});

  final String value;
  final List<String> events;
  Map<String, dynamic>? imported;

  @override
  Future<Map<String, dynamic>> export() async => {
    'version': '1.0.0',
    'value': value,
  };

  @override
  Future<void> validateImport(Map<String, dynamic> data) async {}

  @override
  Future<void> import(Map<String, dynamic> data) async {
    events.add(id);
    imported = data;
  }
}

class _NamedRestorable implements Restorable {
  _NamedRestorable(this.id, this.events);

  final String id;
  final List<String> events;
  Map<String, dynamic>? imported;

  @override
  Future<Map<String, dynamic>> export() async => {
    'version': '1.0.0',
    'value': id,
  };

  @override
  Future<void> validateImport(Map<String, dynamic> data) async {}

  @override
  Future<void> import(Map<String, dynamic> data) async {
    events.add(id);
    imported = data;
  }
}

class _TrackingVaultStore extends InMemoryVaultStore {
  _TrackingVaultStore(this.events);

  final List<String> events;

  @override
  Future<void> import(Map<String, dynamic> data) async {
    events.add('vaultStore');
    await super.import(data);
  }
}

Future<_TrackingVaultStore> _store(
  List<String> events, {
  int seedOffset = 0,
}) async {
  final store = _TrackingVaultStore(events);
  await store.setSeed(
    Uint8List.fromList(List.generate(32, (index) => index + seedOffset)),
  );
  await store.setAccountIndex(3);
  return store;
}

Future<Vault> _vault({
  required _TrackingVaultStore store,
  required Map<String, ProfileRepository> repositories,
  Map<String, Restorable> named = const {},
}) async {
  final vault = await Vault.fromVaultStore(
    store,
    profileRepositories: repositories,
    namedRestorables: named,
  );
  await vault.ensureInitialized();
  return vault;
}

void main() {
  group('Vault Restorable', () {
    test('exports repositories and named components by stable id', () async {
      final events = <String>[];
      final vault = await _vault(
        store: await _store(events),
        repositories: {
          'z-cloud': _Repository('z-cloud'),
          'a-edge': _RestorableRepository(
            'a-edge',
            value: 'profiles',
            events: events,
          ),
        },
        named: {'consentHistory': _NamedRestorable('consentHistory', events)},
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

    test('imports store, repositories, then named components', () async {
      final sourceEvents = <String>[];
      final source = await _vault(
        store: await _store(sourceEvents),
        repositories: {
          'edge': _RestorableRepository(
            'edge',
            value: 'profiles',
            events: sourceEvents,
          ),
        },
        named: {
          'consentHistory': _NamedRestorable('consentHistory', sourceEvents),
        },
      );
      final backup = await source.export();

      final targetEvents = <String>[];
      final repository = _RestorableRepository(
        'edge',
        value: 'empty',
        events: targetEvents,
      );
      final named = _NamedRestorable('consentHistory', targetEvents);
      final target = await _vault(
        store: await _store(targetEvents),
        repositories: {'edge': repository},
        named: {'consentHistory': named},
      );

      await target.import(backup);

      expect(targetEvents, ['vaultStore', 'edge', 'consentHistory']);
      expect(repository.imported, {'version': '1.0.0', 'value': 'profiles'});
      expect(named.imported, {'version': '1.0.0', 'value': 'consentHistory'});
    });

    test('rejects missing registrations before any import', () async {
      final sourceEvents = <String>[];
      final source = await _vault(
        store: await _store(sourceEvents),
        repositories: {
          'edge': _RestorableRepository(
            'edge',
            value: 'profiles',
            events: sourceEvents,
          ),
        },
        named: {'consentHistory': _NamedRestorable('named', sourceEvents)},
      );
      final backup = await source.export();

      final targetEvents = <String>[];
      final target = await _vault(
        store: await _store(targetEvents),
        repositories: {
          'edge': _RestorableRepository(
            'edge',
            value: 'empty',
            events: targetEvents,
          ),
        },
      );

      await expectLater(target.import(backup), throwsA(isA<TdkException>()));
      expect(targetEvents, isEmpty);
    });

    test('rejects a different wallet before any import', () async {
      final sourceEvents = <String>[];
      final source = await _vault(
        store: await _store(sourceEvents),
        repositories: {
          'edge': _RestorableRepository(
            'edge',
            value: 'profiles',
            events: sourceEvents,
          ),
        },
      );
      final backup = await source.export();

      final targetEvents = <String>[];
      final target = await _vault(
        store: await _store(targetEvents, seedOffset: 1),
        repositories: {
          'edge': _RestorableRepository(
            'edge',
            value: 'empty',
            events: targetEvents,
          ),
        },
      );

      await expectLater(target.import(backup), throwsA(isA<TdkException>()));
      expect(targetEvents, isEmpty);
    });

    test('routes colliding payload shapes only by repository id', () async {
      final events = <String>[];
      final source = await _vault(
        store: await _store(events),
        repositories: {
          'first': _RestorableRepository('first', value: 'one', events: events),
          'second': _RestorableRepository(
            'second',
            value: 'two',
            events: events,
          ),
        },
      );
      final backup = await source.export();

      final first = _RestorableRepository(
        'first',
        value: 'empty',
        events: events,
      );
      final second = _RestorableRepository(
        'second',
        value: 'empty',
        events: events,
      );
      final target = await _vault(
        store: await _store(events),
        repositories: {'first': first, 'second': second},
      );

      await target.import(backup);

      expect(first.imported?['value'], 'one');
      expect(second.imported?['value'], 'two');
    });
  });
}
