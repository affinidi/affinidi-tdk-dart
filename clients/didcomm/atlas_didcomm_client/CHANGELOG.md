# Change Log

## 1.0.0-dev.1

- Initial version.

- BREAKING CHANGE: The minimum supported Dart SDK version has been updated to 3.8.0 (previously 3.6.0).
If your application targets a Dart SDK version below 3.8.0, it will no longer be compatible with TDK and you may encounter dependency resolution or installation errors.
To continue using TDK, please upgrade your application's Dart SDK to 3.8.0 or higher.

- BREAKING CHANGE: TDK depends on Dart SSI, which has been upgraded to a new major version.
This upgrade introduces breaking changes affecting multiple areas, including:
  - Verifiable Credentials
  - Verifiable Presentations
  - DID Documents

  After upgrading, you may experience:
  - Compile-time errors due to type changes
  - Runtime errors caused by stricter validation rules (for example:
  "The first element of @context must be a string URI, but found …")

  For full details on the changes and migration considerations, please refer to the official Dart SSI changelog:
  https://pub.dev/packages/ssi/changelog#300
