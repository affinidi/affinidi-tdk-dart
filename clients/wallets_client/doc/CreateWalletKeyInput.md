# affinidi_tdk_wallets_client.model.CreateWalletKeyInput

## Load the model package
```dart
import 'package:affinidi_tdk_wallets_client/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**algorithm** | **String** | cryptographic algorithm for the new key | [optional] 
**keyType** | **String** | Deprecated alias of `algorithm`. Accepted for backward compatibility; prefer `algorithm`. If both are sent, `algorithm` takes precedence. | [optional] 
**relationships** | [**BuiltList&lt;VerificationRelationship&gt;**](VerificationRelationship.md) | verification relationships for the key. | 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


