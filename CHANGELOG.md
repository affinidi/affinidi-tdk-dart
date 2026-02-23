# Changelog

All notable changes to this project are documented in this file.

---

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

- [Client](https://github.com/affinidi/affinidi-tdk/tree/main/clients/dart)
- [Libraries](https://github.com/affinidi/affinidi-tdk/tree/main/libs/dart)
- [Packages](https://github.com/affinidi/affinidi-tdk/tree/main/packages/dart)

The `libraries` from the previous structure have now been consolidated into the `packages` folder in this repository.

---
