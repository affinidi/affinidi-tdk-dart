# affinidi_tdk_wallets_client.model.WalletKeyDto

## Load the model package
```dart
import 'package:affinidi_tdk_wallets_client/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**keyId** | **String** | wallet-scoped key identifier (e.g., \"key-1\") | [optional] 
**keyType** | **String** | cryptographic algorithm used by this key | [optional] 
**keyAri** | **String** | ARI identifier for the key (e.g., \"ari:key:...\") | [optional] 
**relationships** | [**BuiltList&lt;VerificationRelationship&gt;**](VerificationRelationship.md) | verification relationships this key supports | [optional] 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


