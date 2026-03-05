# Change Log

## 2.1.0

### Changes

---

Chore: Dependencies Update 

---

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
