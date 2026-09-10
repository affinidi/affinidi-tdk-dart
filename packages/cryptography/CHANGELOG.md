- BREAKING CHANGE: Replace the String-based `Pbkdf2(...)` API with
    `pbkdf2FromBytes(...)`, which accepts a caller-owned `Uint8List
    passwordBytes` and a `List<int> nonce`. External implementations must add
    the replacement method, and callers must migrate to mutable password bytes
    that can be securely wiped after use.
- Add `pbkdf2FromBytes(...)` for deriving keys from a caller-owned, zeroable
    passphrase buffer.
- Destroy the PBKDF2 implementation's internal passphrase key copy after use.
- Remove unconditional cryptographic operation timing messages from stdout.

## 3.0.0

- BREAKING CHANGE: The minimum supported Dart SDK version has been updated to 3.8.0 (previously 3.6.0).
If your application targets a Dart SDK version below 3.8.0, it will no longer be compatible with TDK and you may encounter dependency resolution or installation errors.
To continue using TDK, please upgrade your application's Dart SDK to 3.8.0 or higher.

## 1.0.0

- Initial version.
