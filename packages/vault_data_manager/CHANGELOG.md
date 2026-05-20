

### Breaking Changes

 - `VaultDataManagerServiceInterface.createProfile(...)` now performs the account-and-profile flow in a single call and returns `Response<CreateAccountWithProfileOK>`.
 - `createProfile(...)` now requires `accountIndex`, `accountMetadata`, `profileDid`, `profileDidProof`, `profileKeyPair`, and `profileName`; `description` is now `profileDescription`.
 - `createFolder(...)` now returns the created `Folder`.
 - `VfsProfileRepository.createProfile(...)` now returns the created `Profile`.
 - `VaultDataManagerApiServiceInterface.getListOfProfiles(...)` now returns `Response<ListProfilesOK>` instead of `Response<ListRootNodeChildrenOK>` so account and profile metadata can be read from a single response.
 - `VaultDataManagerProfile` now requires `accountIndex` and may include `accountMetadata`, so existing mocks, fixtures, and consumers must be updated for the expanded model shape.
 - Configuration error checks must use `profile_not_configured` instead of the previous misspelled value.

### Added

 - Added `patchAccount(...)` to update shared storage account metadata without rewriting the full account payload.
 - Profile reconstruction from the profiles endpoint now carries `accountIndex` and optional `accountMetadata` through to `VaultDataManagerProfile`.

### Changed

 - Profile and account metadata are now read from `getListOfProfiles(...)` in a single response instead of separate lookups.
 - Shared access acceptance now patches account shared policies through the new backend endpoint, reducing network calls and returning an updated `Profile` immediately.
 - Incomplete VFS profiles without a usable encrypted DEKEK are skipped with warning logs instead of failing the full `listProfiles()` call.
 - HTTP clients are split and reused for auth, VFS, file, and public key traffic. Connection and receive timeouts are configurable via `AFFINIDI_API_TIMEOUT_MS` with a 15-second default, and idle timeout is configurable via `AFFINIDI_API_IDLE_TIMEOUT_MS` with a 30-second default. Encryption service initialization is lazy, and download connections disable persistent connections to reduce latency and stale-connection failures.
 - Folder creation now returns the created `Folder` directly instead of requiring a secondary lookup by node id.

### Migration

 - Update direct calls, mocks, and custom implementations of `VaultDataManagerServiceInterface.createProfile(...)` to provide account metadata and profile crypto material.
 - Update direct calls, mocks, and custom implementations of `VaultDataManagerApiServiceInterface.getListOfProfiles(...)` to expect `Response<ListProfilesOK>`.
 - Update custom mocks, fixtures, and code paths that construct `VaultDataManagerProfile` to include `accountIndex` and handle optional `accountMetadata`.
 - Update `createFolder(...)` call sites, mocks, and custom implementations to consume the returned `Folder` instead of a node id.
 - Rename any `profle_not_configured` checks to `profile_not_configured`.
 - If you implement or mock `VfsProfileRepository` through `ProfileRepository`, return a `Profile` from `createProfile(...)`.

## 2.0.9

 - Update a dependency to the latest release.

## 2.0.8

 - Update a dependency to the latest release.

## 2.0.7

 - **FIX**: folder creation lookup by fetching children with max limit (#104).

## 2.0.6

 - Update a dependency to the latest release.

## 2.0.5

 - Update a dependency to the latest release.

## 2.0.4

 - Update a dependency to the latest release.

## 2.0.3

 - **FIX**: Improve storage limit error handling and expose vault storage usage API (#85).

## 2.0.2

 - Update a dependency to the latest release.

## 2.0.1

 - **FIX**: remove call to list profiles while creating a new profile (#59).

## 2.0.0

- BREAKING CHANGE: The minimum supported Dart SDK version has been updated to 3.8.0 (previously 3.6.0).
If your application targets a Dart SDK version below 3.8.0, it will no longer be compatible with TDK and you may encounter dependency resolution or installation errors.
To continue using TDK, please upgrade your application's Dart SDK to 3.8.0 or higher.

- BREAKING CHANGE: Dart SSI Major Version Upgrade
TDK depends on Dart SSI, which has been upgraded to a new major version.

Below is the list of all the breaking changes introduced in SSI package:
- BREAKING: VerifiableCredential MUST exist in VC type field (v1).
- BREAKING: VerifiablePresentation MUST exist in VP type fields (v1 & v2).
- BREAKING: Data Integrity proofs require proper @context entries (VC v2 context OR Data Integrity context).
- BREAKING: Service types must use StringServiceType or SetServiceType classes.
- BREAKING: Issuer DID must match proof verificationMethod DID.
- BREAKING: Proof IDs must be unique and non-empty within credentials.
- BREAKING: Proof types cannot be null or empty strings.
- BREAKING: Proof purpose must match document type - VCs use assertionMethod, VPs use authentication.
- BREAKING: Credentials and presentations must be within their validity period for verification.
- BREAKING: SD-JWT credentials validate exp and nbf claims.
- BREAKING: Stricter proof field structure validation.

Migration guide for SSI changes can be seen here
This upgrade introduces breaking changes affecting multiple areas, including:
- Verifiable Credentials
- Verifiable Presentations
- DID Documents

After upgrading, you may experience:
- Compile-time errors due to type changes
- Runtime errors caused by stricter validation rules (for example: “The first element of @context must be a string URI, but found …”)


## 1.15.0

### Changes

---

Chore: Dependencies Update 

---


## 1.14.0

### Changes

---

feat: add time bound for profile sharing

* Deprecated: grantAccessVfs in favor of item level addess and clarified profileId docs 

---

## 1.13.0

### Changes

---

Chore: Dependencies Update 

---


## 1.12.0

### Changes

---

Feat: Time-Bound Sharing for Granular Access

* Added `expiresAt` support to `setItemsAccessVfs` method for automatic expiration of shared items
* Updated permission groups to include optional `expiresAt` field for time-bound access control
* Updated `VaultDataManagerSharedAccessApiServiceInterface` to support `expiresAt` in permission groups
* Updated dependency constraint for `affinidi_tdk_consumer_iam_client` to `^1.2.0` to support `GetAccessOutput` and `getAccessVfs` methods

---


## 1.11.0

### Changes

---

Feat: Granular Node-Level Access Control

* Added GET endpoint support for retrieving node access permissions (`getNodeAccessVfs`)
* Added `grantNodeAccessMultiple` method to `ProfileAccessSharing` interface for sending multiple permission groups in a single API call
* Fixed permission grouping to preserve separate permission groups (READ, WRITE) when sharing multiple files with different permissions
* Made both `affinidiTdkIamClient` and `affinidiTdkConsumerIamClient` optional in `VaultDataManagerSharedAccessApiService`

---

## 1.10.2

### Changes

---

Chore: Dependencies Update 

---

## 1.9.0

### Changes

---

Chore: Dependencies Update 

---

## 1.8.0

### Changes

---

Feat: Add Environment variable for consumer token

---

## 1.7.0

### Changes

---

Fix: Dependencies Update (ssi)

---

## 1.5.0

### Changes

---

Fix: Dependencies Update

---


## 1.4.0

### Changes

---

Feat: Implement progress callback


## 1.3.0

### Changes

---

Fix: RightsEnum enum value references
* Fixed `RightsEnum` enum value references in permissions extension and test fixtures
* Updated `permissions_extensions.dart` to use correct enum values: `RightsEnum.vfsRead` and `RightsEnum.vfsWrite`
* Updated `permissions_fixtures.dart` to use correct enum values: `RightsEnum.vfsRead` and `RightsEnum.vfsWrite`
* Resolved linter errors where `RightsEnum.read` and `RightsEnum.write` were incorrectly referenced

---


## 1.2.0

### Changes

---

Fix: Dependencies Update

---

## 1.1.0

### Changes

---

Promote package for the stable release, which encapsulates the following feature(s):
* Manages cloud storage for:
    * Profiles
    * Files and Folders
    * Credentials
* Provides encryption service to encrypt/decrypt stored data

---

## 1.0.0-dev.2

- Initial version.
