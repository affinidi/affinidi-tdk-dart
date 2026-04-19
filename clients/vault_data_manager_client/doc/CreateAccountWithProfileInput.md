# affinidi_tdk_vault_data_manager_client.model.CreateAccountWithProfileInput

## Load the model package
```dart
import 'package:affinidi_tdk_vault_data_manager_client/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**accountIndex** | **int** | number that is used for profile DID derivation | 
**accountDid** | **String** | DID that is associated with the account number | 
**didProof** | **String** | JWT that proves ownership of profile DID by requester | 
**alias** | **String** | Alias of account | [optional] 
**accountMetadata** | [**JsonObject**](.md) | Metadata of account | [optional] 
**accountDescription** | **String** | Description of account | [optional] 
**profileName** | **String** | Name of the profile node | 
**profileDescription** | **String** | Description of the profile node | [optional] 
**profileMetadata** | [**JsonObject**](.md) | Metadata of the profile | [optional] 
**edekInfo** | [**EdekInfo**](EdekInfo.md) |  | 
**dek** | **String** | A base64 encoded data encryption key, encrypted using VFS public key | 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


