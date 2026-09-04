- BREAKING CHANGE: `CryptographyServiceInterface` adds
    `pbkdf2FromBytes(...)`. External classes declared with
    `implements CryptographyServiceInterface` must implement the new method,
    accepting a caller-owned `Uint8List passwordBytes` and a `List<int> nonce`.
    Existing callers of `Pbkdf2(...)` continue to compile, but the String-based
    method is deprecated because its passphrase cannot be securely wiped from
    memory.
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
