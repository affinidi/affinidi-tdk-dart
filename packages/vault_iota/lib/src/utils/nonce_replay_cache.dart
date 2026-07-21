import '../services/nonce_replay_store.dart';

/// An in-memory cache that detects replayed OID4VP request nonces.
///
/// Each nonce is stored alongside the expiry epoch of its originating JWT.
/// Expired entries are purged lazily on every [record] call to prevent
/// unbounded memory growth.
///
/// OID4VP §11.2 requires wallets to enforce nonce uniqueness to prevent an
/// attacker from replaying a captured JWT multiple times within its `exp`
/// window. See https://openid.net/specs/openid-4-verifiable-presentations-1_0.html#section-11.2
///
/// This is the default [NonceReplayStore] used by `ShareFlowService`. It is
/// scoped to the lifetime of the `ShareFlowService` instance, so replay
/// protection resets on every app restart. For persistent cross-session replay
/// protection, provide a [NonceReplayStore] backed by a persistent store (the
/// same approach as `ConsentStorage`).
class NonceReplayCache implements NonceReplayStore {
  final Map<String, int> _seen = {};

  /// Records [nonce] and returns `true` if it is fresh, `false` if replayed.
  ///
  /// Parameters:
  /// * [nonce] - the nonce from the OID4VP JWT payload.
  /// * [expEpochSeconds] - the `exp` claim from the same JWT (Unix seconds).
  @override
  Future<bool> record(String nonce, int expEpochSeconds) async {
    _purgeExpired();
    if (_seen.containsKey(nonce)) return false;
    _seen[nonce] = expEpochSeconds;
    return true;
  }

  /// Removes all entries whose JWT expiry has already passed.
  void _purgeExpired() {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    _seen.removeWhere((_, exp) => exp < now);
  }
}
