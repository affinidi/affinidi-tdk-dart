import 'package:affinidi_tdk_vault_iota/src/utils/nonce_replay_cache.dart';
import 'package:test/test.dart';

void main() {
  group('NonceReplayCache', () {
    test('returns true when recording a fresh nonce', () async {
      final cache = NonceReplayCache();

      final isFresh = await cache.record('nonce-1', 9999999999);

      expect(isFresh, isTrue);
    });

    test(
      'returns false when recording the same nonce twice before expiry',
      () async {
        final cache = NonceReplayCache();

        final first = await cache.record('nonce-1', 9999999999);
        final second = await cache.record('nonce-1', 9999999999);

        expect(first, isTrue);
        expect(second, isFalse);
      },
    );

    test(
      'treats a nonce as fresh again after its stored expiry has passed',
      () async {
        final cache = NonceReplayCache();

        final first = await cache.record('nonce-1', 0);
        final second = await cache.record('nonce-1', 9999999999);

        expect(first, isTrue);
        expect(second, isTrue);
      },
    );

    test('does not purge non-expired entries', () async {
      final cache = NonceReplayCache();

      final first = await cache.record('nonce-1', 9999999999);
      final second = await cache.record('nonce-2', 9999999999);
      final replay = await cache.record('nonce-1', 9999999999);

      expect(first, isTrue);
      expect(second, isTrue);
      expect(replay, isFalse);
    });
  });
}
