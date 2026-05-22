## 3.0.0

> Note: This release has breaking changes.

 - **BREAKING** **FEAT**: adopt new optimised endpoints for profile operations (#92).



### Breaking Changes

 - `EdgeDriftProfileRepository.createProfile(...)` now returns the generated UUID for the new profile.
 - Upgraded the `affinidi_tdk_vault_edge_provider` dependency to version 3.

### Changed

 - Drift-backed profile creation now persists explicit UUID ids to satisfy the updated edge provider contract.

### Migration

 - Update any direct callers, mocks, or subclasses of `EdgeDriftProfileRepository` or `EdgeProfileRepositoryInterface` to use the returned profile id.
 - If your application depends directly on `affinidi_tdk_vault_edge_provider`, update it to version 3 before upgrading this package.

## 2.0.5

 - Update a dependency to the latest release.

## 2.0.4

 - Update a dependency to the latest release.

## 2.0.3

 - Update a dependency to the latest release.

## 2.0.2

 - Update a dependency to the latest release.

## 2.0.1

 - **FIX**: update packages score (#41).

## 2.0.0

- BREAKING CHANGE: The minimum supported Dart SDK version has been updated to 3.8.0 (previously 3.6.0).
If your application targets a Dart SDK version below 3.8.0, it will no longer be compatible with TDK and you may encounter dependency resolution or installation errors.
To continue using TDK, please upgrade your application's Dart SDK to 3.8.0 or higher.

## 1.6.0

- Dependencies Update 

## 1.5.0

- Dependencies Update 

## 1.2.3

- Dependencies Update 

## 1.2.2

- Dependencies Update 

## 1.2.1

- Dependencies Update 

## 1.2.0

- Dependencies Update 

## 1.0.5

- Dependencies Update 

## 1.0.4

- Dependencies Update 

## 1.0.3

- Dependencies Update 

## 1.0.2

- Dependencies Update 

## 1.0.1

- Dependencies Update 

## 1.0.0

- chore: remove experimental flag

## 1.0.0-dev.7

- Dependencies Update 

## 1.0.0-dev.6

- Dependencies Update 

## 1.0.0-dev.5

- Dependencies Update 

## 1.0.0-dev.4

- Dependencies Update 

## 1.0.0-dev.3

- Dependencies Update

## 1.0.0-dev.2

- Dependencies Update

## 1.0.0-dev.1

- Initial version.
