/// Consumer-provided storage backend for OID4VP nonce replay protection.
///
/// OID4VP §11.2 requires wallets to enforce nonce uniqueness to prevent an
/// attacker from replaying a captured request JWT within its `exp` window.
/// See https://openid.net/specs/openid-4-verifiable-presentations-1_0.html#section-11.2
///
/// The default `NonceReplayCache` keeps consumed nonces in memory only, so
/// replay protection resets on every app restart. On mobile — where restarts
/// are common — implement this interface with a persistent store (e.g. secure
/// storage or a database) and inject it into `ShareFlowService` for
/// cross-session replay protection. This mirrors the `ConsentStorage` pattern.
abstract interface class NonceReplayStore {
  /// Atomically checks whether [nonce] has been seen and records it if not.
  ///
  /// Implementations MUST perform the check-and-record atomically so that two
  /// concurrent requests carrying the same [nonce] cannot both be treated as
  /// fresh.
  ///
  /// Parameters:
  /// * [nonce] - the nonce from the OID4VP request JWT payload.
  /// * [expEpochSeconds] - the `exp` claim from the same JWT (Unix seconds).
  ///   Implementations may use it to expire stored entries once the originating
  ///   token can no longer be replayed.
  ///
  /// Returns `true` if [nonce] was previously unseen (the request is fresh), or
  /// `false` if it has already been recorded (a replay).
  Future<bool> record(String nonce, int expEpochSeconds);
}
