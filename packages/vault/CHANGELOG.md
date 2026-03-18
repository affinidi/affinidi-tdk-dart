## 2.1.0

 - **FEAT**: cache and reuse profile details in share flow (#61).

# Change Log

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

## 1.16.0

### Changes

---

Chore: update example to include method to fetch item metadata

---

## 1.15.0

### Changes

---

feat: add time bound for profile sharing

* Added: Optional expiresAt when sharing profiles, enabling time bound profile access

---

## 1.14.0

### Changes

---

Chore: Dependencies Update 

---


## 1.13.0

### Changes

---

Feat: Time-Bound Sharing for Granular Access

* Added `expiresAt` parameter to `ItemPermissionsPolicy.addPermission()` to configure automatic expiration for shared items
* Shared items (files/folders) can now be shared with a time limit, after which access is automatically revoked by the backend
* If `expiresAt` is not provided, access remains until manually revoked (default behavior)
* `expiresAt` can be set to any date (past or future) to support testing scenarios

---

## 1.12.0

### Changes

---

Feat: Granular File and Folder Sharing

* Added `shareItem` method to share individual files/folders with specific permissions (read, write, or all)
* Added `revokeNodeAccess` method to revoke access to specific files/folders
* Added `getNodeAccess` method to retrieve access permissions for files/folders

---

## 1.11.2

### Changes

---

Chore: Dependencies Update 

---

## 1.10.1

### Changes

---

Chore: Combine CredentialStorage and FileStorage in SharedStorage interface 

---

## 1.10.0

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

Chore: Dependencies Update 

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


## 1.4.0

### Changes

---

Feat: Implement Progress Callback


## 1.3.0

### Changes

---

Fix: Dependencies Update


## 1.1.0

### Changes

---

Promote package for the stable release, which encapsulates these feature(s):

* Enables Vault creation using the Wallet implementation from the [SSI package](https://pub.dev/packages/ssi).

* Supports creating, managing, and deleting cloud profiles via Affinidi’s services using the [Affinidi Vault Data Manager package](https://pub.dev/packages/affinidi_tdk_vault_data_manager).

* Provides the ability to share cloud profiles and retrieve shared profiles.


---

## 1.0.0-dev.2

- Initial version.
