# Changelog

This root-level changelog lists the major or notable changes for this repository.

For detailed change histories and complete release notes for a specific client or package, see the changelog file inside the [`clients/`](https://github.com/affinidi/affinidi-tdk-dart/tree/main/clients) or [`packages/`](https://github.com/affinidi/affinidi-tdk-dart/tree/main/packages) directories.

---

## 2026‑05‑15

### Breaking Changes

- `affinidi_tdk_vault`, `affinidi_tdk_vault_data_manager`, `affinidi_tdk_vault_edge_provider`, and `affinidi_tdk_vault_edge_drift_provider` now expose profile creation and shared access APIs that return created or refreshed objects instead of `void`. See the package changelogs for migration steps.
- VFS profile provisioning now uses the combined account-and-profile flow, and configuration error checks now use the corrected `profile_not_configured` code.

### Added

- Added targeted Vault lookup APIs for profile retrieval, shared storage lookup by owner profile id, and per-profile storage usage checks.
- Added account patching support in Vault Data Manager so shared storage metadata can be updated without rewriting the full account payload.
- Folder creation APIs now return the created node id.

### Changed

- Reduced Vault and VFS latency by reusing dedicated auth, file, and public key HTTP connections, increasing idle timeouts, lazily initializing encryption material, and disabling persistent connections for download flows where it improves stability.
- Shared profile and shared item acceptance flows now return an updated `Profile`, so shared storage state is immediately available to callers.
- VFS profile listing is more resilient: incomplete profiles are skipped with warning logs instead of failing the full listing operation.
- Folder creation now uses the backend-returned node id, fixing folder creation flows that previously depended on follow-up lookups.

## 2026‑02‑19

### Breaking Changes

- Upgraded **Dart SSI** dependency to **version 3.0**.
  
  This introduces strict W3C specification compliance and security improvements for **Verifiable Credentials (VCs)** and **Decentralised Identifiers (DIDs)**.  
  For detailed changes and migration instructions, refer to the official [Dart SSI Changelog](https://github.com/affinidi/affinidi-ssi-dart/blob/main/CHANGELOG.md#300).

- Updated packages to support the Dart SSI 3.0 upgrade:

  - `affinidi_tdk_claim_verifiable_credential` – **v2.0.0**
  - `affinidi_tdk_consumer_auth_provider` – **v5.0.0**
  - `affinidi_tdk_vault` – **v2.0.0**
  - `affinidi_tdk_vault_data_manager` – **v2.0.0**
  - `affinidi_tdk_vault_edge_provider` – **v2.0.0**
  - `affinidi_tdk_vdsp` – **v2.0.0**
  - `affinidi_tdk_vdip` – **v2.0.0**
  - `affinidi_tdk_didcomm_mediator_client` – **v2.0.0**

- Updated the **minimum Dart SDK version** from **3.6.0** to **3.8.0** across all packages.

---

## 2025‑06‑05

### Breaking Changes

- Renamed  
  `oid4vci_claim_verifiable_credential` → `affinidi_tdk_claim_verifiable_credential`.

### Changed

- Repository migration updates:
  - Added **Melos** configuration.
  - Added **workspace pub** configuration.
  - Introduced enhanced **PR checks** for improved package management.

---

## Migration Note

This project was migrated from the original [Affinidi TDK](https://github.com/affinidi/affinidi-tdk) repository to a dedicated repository **Affinidi TDK for Dart**, as part of ongoing improvements to Affinidi’s open‑source ecosystem and development workflow.

If you need to access the previous versions of the source code, refer to the following locations:

- [Client](https://github.com/affinidi/affinidi-tdk/tree/3a6f0f531cca4d569fb66a0120235ff786e44623/clients/dart)
- [Libraries](https://github.com/affinidi/affinidi-tdk/tree/89669e3188b6ac2589f9fe20bca8515dba4755f2/libs/dart)
- [Packages](https://github.com/affinidi/affinidi-tdk/tree/799fb65d01df1cd9cb19a23288007fef5b8bf04c/packages/dart)

The `libraries` from the previous structure have now been consolidated into the `packages` folder in this repository.

---
