# affinidi_tdk_vault_data_manager_client.model.PatchAccountInput

## Load the model package
```dart
import 'package:affinidi_tdk_vault_data_manager_client/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**didProof** | **String** | JWT that proves ownership of profile DID by requester | 
**encryptedDekek** | **String** | A base64 encoded data encryption key, encrypted using VFS public key, required for PATCH operation on account | 
**ownerProfileId** | **String** | A unique identifier of profile, required for PATCH operation on account | 
**ownerProfileDid** | **String** | DID that is associated with the profile, required for PATCH operation on account | 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


