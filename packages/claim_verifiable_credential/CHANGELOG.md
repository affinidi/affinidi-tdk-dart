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


## 1.4.0

### Changes

---

Fix: Dependencies Update (ssi)

---

## 1.3.0

### Changes

---

Fix: Dependencies Update

## 1.2.0

### Changes

---

Fix: Dependencies Update

---

## 1.1.0

### Changes

---

Promote package for the stable release, which encapsulates these feature(s):
* Enable claiming and storing verifiable credentials using Affinidi's credential issuance service.

---

## 1.0.0-dev.2

- Initial version.
