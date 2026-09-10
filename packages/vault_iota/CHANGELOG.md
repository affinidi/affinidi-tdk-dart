## 2.0.0

> Note: This release has breaking changes.

 - **FIX**: use numeric dev version for vault iota (#240).
 - **FEAT**: add affinidi_tdk_vault_iota package (#102).
 - **BREAKING** **FEAT**: backup restore (#226).

## 1.0.0
- chore: Promote vault_iota to a stable release

## 1.0.0-dev.1

- BREAKING CHANGE: `ConsentStorage` adds `deleteByHash(...)`. External
	implementations and test doubles must implement the method and return whether
	a matching consent record was removed.
- BREAKING CHANGE: `IotaConsentRecordServiceInterface` adds
	`deleteConsentRecord(...)`. External implementations and test doubles must add
	the method to their override.
- Add `IotaConsentRecordService.deleteConsentRecord(...)`, reporting
	`consent_record_not_found` when no record matches and
	`failed_to_delete_consent_record` when storage deletion fails.

## 1.0.0-dev

- Initial version.
