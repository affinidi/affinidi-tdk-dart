# affinidi_tdk_wallets_client.api.WalletApi

## Load the API package
```dart
import 'package:affinidi_tdk_wallets_client/api.dart';
```

All URIs are relative to *https://apse1.api.affinidi.io/cwe*

Method | HTTP request | Description
------------- | ------------- | -------------
[**createServiceEndpoint**](WalletApi.md#createserviceendpoint) | **POST** /v2/wallets/{walletId}/services | 
[**createWallet**](WalletApi.md#createwallet) | **POST** /v1/wallets | 
[**createWalletKey**](WalletApi.md#createwalletkey) | **POST** /v2/wallets/{walletId}/keys | 
[**createWalletV2**](WalletApi.md#createwalletv2) | **POST** /v2/wallets | 
[**deleteWallet**](WalletApi.md#deletewallet) | **DELETE** /v1/wallets/{walletId} | 
[**getWallet**](WalletApi.md#getwallet) | **GET** /v1/wallets/{walletId} | 
[**listServiceEndpoints**](WalletApi.md#listserviceendpoints) | **GET** /v2/wallets/{walletId}/services | 
[**listWalletKeys**](WalletApi.md#listwalletkeys) | **GET** /v2/wallets/{walletId}/keys | 
[**listWallets**](WalletApi.md#listwallets) | **GET** /v1/wallets | 
[**removeServiceEndpoint**](WalletApi.md#removeserviceendpoint) | **DELETE** /v2/wallets/{walletId}/services/{serviceId} | 
[**removeWalletKey**](WalletApi.md#removewalletkey) | **DELETE** /v2/wallets/{walletId}/keys/{keyId} | 
[**signCredential**](WalletApi.md#signcredential) | **POST** /v1/wallets/{walletId}/sign-credential | 
[**signCredentialsJwt**](WalletApi.md#signcredentialsjwt) | **POST** /v2/wallets/{walletId}/credentials/jwt/sign | 
[**signCredentialsLdp**](WalletApi.md#signcredentialsldp) | **POST** /v2/wallets/{walletId}/credentials/ldp/sign | 
[**signCredentialsSdJwt**](WalletApi.md#signcredentialssdjwt) | **POST** /v2/wallets/{walletId}/credentials/sd-jwt/sign | 
[**signJwtToken**](WalletApi.md#signjwttoken) | **POST** /v1/wallets/{walletId}/sign-jwt | 
[**signJwtV2**](WalletApi.md#signjwtv2) | **POST** /v2/wallets/{walletId}/jwt/sign | Sign JWT.
[**signPresentationsLdp**](WalletApi.md#signpresentationsldp) | **POST** /v2/wallets/{walletId}/presentations/ldp/sign | 
[**updateServiceEndpoint**](WalletApi.md#updateserviceendpoint) | **PATCH** /v2/wallets/{walletId}/services/{serviceId} | 
[**updateWallet**](WalletApi.md#updatewallet) | **PATCH** /v1/wallets/{walletId} | 
[**updateWalletKey**](WalletApi.md#updatewalletkey) | **PATCH** /v2/wallets/{walletId}/keys/{keyId} | 


# **createServiceEndpoint**
> ServiceEndpointDto createServiceEndpoint(walletId, serviceEndpointInput)



Add service endpoint to wallet, this applies to did:web only

### Example
```dart
import 'package:affinidi_tdk_wallets_client/api.dart';
// TODO Configure API key authorization: ProjectTokenAuth
//defaultApiClient.getAuthentication<ApiKeyAuth>('ProjectTokenAuth').apiKey = 'YOUR_API_KEY';
// uncomment below to setup prefix (e.g. Bearer) for API key, if needed
//defaultApiClient.getAuthentication<ApiKeyAuth>('ProjectTokenAuth').apiKeyPrefix = 'Bearer';

final api = AffinidiTdkWalletsClient().getWalletApi();
final String walletId = walletId_example; // String | id of the wallet
final ServiceEndpointInput serviceEndpointInput = ; // ServiceEndpointInput | AddServiceEndpoint

try {
    final response = api.createServiceEndpoint(walletId, serviceEndpointInput);
    print(response);
} catch on DioException (e) {
    print('Exception when calling WalletApi->createServiceEndpoint: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **walletId** | **String**| id of the wallet | 
 **serviceEndpointInput** | [**ServiceEndpointInput**](ServiceEndpointInput.md)| AddServiceEndpoint | 

### Return type

[**ServiceEndpointDto**](ServiceEndpointDto.md)

### Authorization

[ProjectTokenAuth](../README.md#ProjectTokenAuth)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **createWallet**
> CreateWalletResponse createWallet(createWalletInput)



creates a wallet

### Example
```dart
import 'package:affinidi_tdk_wallets_client/api.dart';
// TODO Configure API key authorization: ProjectTokenAuth
//defaultApiClient.getAuthentication<ApiKeyAuth>('ProjectTokenAuth').apiKey = 'YOUR_API_KEY';
// uncomment below to setup prefix (e.g. Bearer) for API key, if needed
//defaultApiClient.getAuthentication<ApiKeyAuth>('ProjectTokenAuth').apiKeyPrefix = 'Bearer';

final api = AffinidiTdkWalletsClient().getWalletApi();
final CreateWalletInput createWalletInput = {"name":"AliceWallet","description":"Personal wallet using did:key","didMethod":"key"}; // CreateWalletInput | CreateWallet

try {
    final response = api.createWallet(createWalletInput);
    print(response);
} catch on DioException (e) {
    print('Exception when calling WalletApi->createWallet: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **createWalletInput** | [**CreateWalletInput**](CreateWalletInput.md)| CreateWallet | [optional] 

### Return type

[**CreateWalletResponse**](CreateWalletResponse.md)

### Authorization

[ProjectTokenAuth](../README.md#ProjectTokenAuth)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **createWalletKey**
> WalletKeyDto createWalletKey(walletId, createWalletKeyInput)



Add a new key to the wallet, this applies to did:web only

### Example
```dart
import 'package:affinidi_tdk_wallets_client/api.dart';
// TODO Configure API key authorization: ProjectTokenAuth
//defaultApiClient.getAuthentication<ApiKeyAuth>('ProjectTokenAuth').apiKey = 'YOUR_API_KEY';
// uncomment below to setup prefix (e.g. Bearer) for API key, if needed
//defaultApiClient.getAuthentication<ApiKeyAuth>('ProjectTokenAuth').apiKeyPrefix = 'Bearer';

final api = AffinidiTdkWalletsClient().getWalletApi();
final String walletId = walletId_example; // String | id of the wallet
final CreateWalletKeyInput createWalletKeyInput = ; // CreateWalletKeyInput | CreateWalletKey

try {
    final response = api.createWalletKey(walletId, createWalletKeyInput);
    print(response);
} catch on DioException (e) {
    print('Exception when calling WalletApi->createWalletKey: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **walletId** | **String**| id of the wallet | 
 **createWalletKeyInput** | [**CreateWalletKeyInput**](CreateWalletKeyInput.md)| CreateWalletKey | 

### Return type

[**WalletKeyDto**](WalletKeyDto.md)

### Authorization

[ProjectTokenAuth](../README.md#ProjectTokenAuth)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **createWalletV2**
> CreateWalletV2Response createWalletV2(createWalletV2Input)



Create v2 wallet

### Example
```dart
import 'package:affinidi_tdk_wallets_client/api.dart';
// TODO Configure API key authorization: ProjectTokenAuth
//defaultApiClient.getAuthentication<ApiKeyAuth>('ProjectTokenAuth').apiKey = 'YOUR_API_KEY';
// uncomment below to setup prefix (e.g. Bearer) for API key, if needed
//defaultApiClient.getAuthentication<ApiKeyAuth>('ProjectTokenAuth').apiKeyPrefix = 'Bearer';

final api = AffinidiTdkWalletsClient().getWalletApi();
final CreateWalletV2Input createWalletV2Input = ; // CreateWalletV2Input | CreateWallet

try {
    final response = api.createWalletV2(createWalletV2Input);
    print(response);
} catch on DioException (e) {
    print('Exception when calling WalletApi->createWalletV2: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **createWalletV2Input** | [**CreateWalletV2Input**](CreateWalletV2Input.md)| CreateWallet | [optional] 

### Return type

[**CreateWalletV2Response**](CreateWalletV2Response.md)

### Authorization

[ProjectTokenAuth](../README.md#ProjectTokenAuth)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **deleteWallet**
> deleteWallet(walletId)



delete wallet by walletId

### Example
```dart
import 'package:affinidi_tdk_wallets_client/api.dart';
// TODO Configure API key authorization: ProjectTokenAuth
//defaultApiClient.getAuthentication<ApiKeyAuth>('ProjectTokenAuth').apiKey = 'YOUR_API_KEY';
// uncomment below to setup prefix (e.g. Bearer) for API key, if needed
//defaultApiClient.getAuthentication<ApiKeyAuth>('ProjectTokenAuth').apiKeyPrefix = 'Bearer';

final api = AffinidiTdkWalletsClient().getWalletApi();
final String walletId = walletId_example; // String | id of the wallet

try {
    api.deleteWallet(walletId);
} catch on DioException (e) {
    print('Exception when calling WalletApi->deleteWallet: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **walletId** | **String**| id of the wallet | 

### Return type

void (empty response body)

### Authorization

[ProjectTokenAuth](../README.md#ProjectTokenAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: Not defined

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getWallet**
> WalletDto getWallet(walletId)



get wallet details using wallet Id.

### Example
```dart
import 'package:affinidi_tdk_wallets_client/api.dart';
// TODO Configure API key authorization: ProjectTokenAuth
//defaultApiClient.getAuthentication<ApiKeyAuth>('ProjectTokenAuth').apiKey = 'YOUR_API_KEY';
// uncomment below to setup prefix (e.g. Bearer) for API key, if needed
//defaultApiClient.getAuthentication<ApiKeyAuth>('ProjectTokenAuth').apiKeyPrefix = 'Bearer';

final api = AffinidiTdkWalletsClient().getWalletApi();
final String walletId = walletId_example; // String | id of the wallet

try {
    final response = api.getWallet(walletId);
    print(response);
} catch on DioException (e) {
    print('Exception when calling WalletApi->getWallet: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **walletId** | **String**| id of the wallet | 

### Return type

[**WalletDto**](WalletDto.md)

### Authorization

[ProjectTokenAuth](../README.md#ProjectTokenAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **listServiceEndpoints**
> ListServiceEndpointsOK listServiceEndpoints(walletId)



List service endpoints in wallet, this applies to did:web only

### Example
```dart
import 'package:affinidi_tdk_wallets_client/api.dart';
// TODO Configure API key authorization: ProjectTokenAuth
//defaultApiClient.getAuthentication<ApiKeyAuth>('ProjectTokenAuth').apiKey = 'YOUR_API_KEY';
// uncomment below to setup prefix (e.g. Bearer) for API key, if needed
//defaultApiClient.getAuthentication<ApiKeyAuth>('ProjectTokenAuth').apiKeyPrefix = 'Bearer';

final api = AffinidiTdkWalletsClient().getWalletApi();
final String walletId = walletId_example; // String | id of the wallet

try {
    final response = api.listServiceEndpoints(walletId);
    print(response);
} catch on DioException (e) {
    print('Exception when calling WalletApi->listServiceEndpoints: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **walletId** | **String**| id of the wallet | 

### Return type

[**ListServiceEndpointsOK**](ListServiceEndpointsOK.md)

### Authorization

[ProjectTokenAuth](../README.md#ProjectTokenAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **listWalletKeys**
> ListWalletKeysOK listWalletKeys(walletId)



List all keys in the wallet, this applies to did:web only

### Example
```dart
import 'package:affinidi_tdk_wallets_client/api.dart';
// TODO Configure API key authorization: ProjectTokenAuth
//defaultApiClient.getAuthentication<ApiKeyAuth>('ProjectTokenAuth').apiKey = 'YOUR_API_KEY';
// uncomment below to setup prefix (e.g. Bearer) for API key, if needed
//defaultApiClient.getAuthentication<ApiKeyAuth>('ProjectTokenAuth').apiKeyPrefix = 'Bearer';

final api = AffinidiTdkWalletsClient().getWalletApi();
final String walletId = walletId_example; // String | id of the wallet

try {
    final response = api.listWalletKeys(walletId);
    print(response);
} catch on DioException (e) {
    print('Exception when calling WalletApi->listWalletKeys: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **walletId** | **String**| id of the wallet | 

### Return type

[**ListWalletKeysOK**](ListWalletKeysOK.md)

### Authorization

[ProjectTokenAuth](../README.md#ProjectTokenAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **listWallets**
> WalletsListDto listWallets(didType)



lists all wallets

### Example
```dart
import 'package:affinidi_tdk_wallets_client/api.dart';
// TODO Configure API key authorization: ProjectTokenAuth
//defaultApiClient.getAuthentication<ApiKeyAuth>('ProjectTokenAuth').apiKey = 'YOUR_API_KEY';
// uncomment below to setup prefix (e.g. Bearer) for API key, if needed
//defaultApiClient.getAuthentication<ApiKeyAuth>('ProjectTokenAuth').apiKeyPrefix = 'Bearer';

final api = AffinidiTdkWalletsClient().getWalletApi();
final WalletDidType didType = ; // WalletDidType | 

try {
    final response = api.listWallets(didType);
    print(response);
} catch on DioException (e) {
    print('Exception when calling WalletApi->listWallets: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **didType** | [**WalletDidType**](.md)|  | [optional] 

### Return type

[**WalletsListDto**](WalletsListDto.md)

### Authorization

[ProjectTokenAuth](../README.md#ProjectTokenAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **removeServiceEndpoint**
> removeServiceEndpoint(walletId, serviceId)



Remove service endpoint from wallet, this applies to did:web only

### Example
```dart
import 'package:affinidi_tdk_wallets_client/api.dart';
// TODO Configure API key authorization: ProjectTokenAuth
//defaultApiClient.getAuthentication<ApiKeyAuth>('ProjectTokenAuth').apiKey = 'YOUR_API_KEY';
// uncomment below to setup prefix (e.g. Bearer) for API key, if needed
//defaultApiClient.getAuthentication<ApiKeyAuth>('ProjectTokenAuth').apiKeyPrefix = 'Bearer';

final api = AffinidiTdkWalletsClient().getWalletApi();
final String walletId = walletId_example; // String | id of the wallet
final String serviceId = serviceId_example; // String | id of the service endpoint to remove

try {
    api.removeServiceEndpoint(walletId, serviceId);
} catch on DioException (e) {
    print('Exception when calling WalletApi->removeServiceEndpoint: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **walletId** | **String**| id of the wallet | 
 **serviceId** | **String**| id of the service endpoint to remove | 

### Return type

void (empty response body)

### Authorization

[ProjectTokenAuth](../README.md#ProjectTokenAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: Not defined

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **removeWalletKey**
> removeWalletKey(walletId, keyId)



Remove a key from the wallet, this applies to did:web only

### Example
```dart
import 'package:affinidi_tdk_wallets_client/api.dart';
// TODO Configure API key authorization: ProjectTokenAuth
//defaultApiClient.getAuthentication<ApiKeyAuth>('ProjectTokenAuth').apiKey = 'YOUR_API_KEY';
// uncomment below to setup prefix (e.g. Bearer) for API key, if needed
//defaultApiClient.getAuthentication<ApiKeyAuth>('ProjectTokenAuth').apiKeyPrefix = 'Bearer';

final api = AffinidiTdkWalletsClient().getWalletApi();
final String walletId = walletId_example; // String | id of the wallet
final String keyId = keyId_example; // String | id of the key to remove

try {
    api.removeWalletKey(walletId, keyId);
} catch on DioException (e) {
    print('Exception when calling WalletApi->removeWalletKey: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **walletId** | **String**| id of the wallet | 
 **keyId** | **String**| id of the key to remove | 

### Return type

void (empty response body)

### Authorization

[ProjectTokenAuth](../README.md#ProjectTokenAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **signCredential**
> SignCredentialResultDto signCredential(walletId, signCredentialInputDto)



signs credential with the wallet

### Example
```dart
import 'package:affinidi_tdk_wallets_client/api.dart';
// TODO Configure API key authorization: ProjectTokenAuth
//defaultApiClient.getAuthentication<ApiKeyAuth>('ProjectTokenAuth').apiKey = 'YOUR_API_KEY';
// uncomment below to setup prefix (e.g. Bearer) for API key, if needed
//defaultApiClient.getAuthentication<ApiKeyAuth>('ProjectTokenAuth').apiKeyPrefix = 'Bearer';

final api = AffinidiTdkWalletsClient().getWalletApi();
final String walletId = walletId_example; // String | id of the wallet
final SignCredentialInputDto signCredentialInputDto = ; // SignCredentialInputDto | SignCredential

try {
    final response = api.signCredential(walletId, signCredentialInputDto);
    print(response);
} catch on DioException (e) {
    print('Exception when calling WalletApi->signCredential: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **walletId** | **String**| id of the wallet | 
 **signCredentialInputDto** | [**SignCredentialInputDto**](SignCredentialInputDto.md)| SignCredential | 

### Return type

[**SignCredentialResultDto**](SignCredentialResultDto.md)

### Authorization

[ProjectTokenAuth](../README.md#ProjectTokenAuth)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **signCredentialsJwt**
> SignCredentialsJwtResultDto signCredentialsJwt(walletId, signCredentialsJwtInputDto)



signs credential with the wallet v2

### Example
```dart
import 'package:affinidi_tdk_wallets_client/api.dart';
// TODO Configure API key authorization: ProjectTokenAuth
//defaultApiClient.getAuthentication<ApiKeyAuth>('ProjectTokenAuth').apiKey = 'YOUR_API_KEY';
// uncomment below to setup prefix (e.g. Bearer) for API key, if needed
//defaultApiClient.getAuthentication<ApiKeyAuth>('ProjectTokenAuth').apiKeyPrefix = 'Bearer';

final api = AffinidiTdkWalletsClient().getWalletApi();
final String walletId = walletId_example; // String | id of the wallet
final SignCredentialsJwtInputDto signCredentialsJwtInputDto = ; // SignCredentialsJwtInputDto | signCredentialsJwt

try {
    final response = api.signCredentialsJwt(walletId, signCredentialsJwtInputDto);
    print(response);
} catch on DioException (e) {
    print('Exception when calling WalletApi->signCredentialsJwt: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **walletId** | **String**| id of the wallet | 
 **signCredentialsJwtInputDto** | [**SignCredentialsJwtInputDto**](SignCredentialsJwtInputDto.md)| signCredentialsJwt | 

### Return type

[**SignCredentialsJwtResultDto**](SignCredentialsJwtResultDto.md)

### Authorization

[ProjectTokenAuth](../README.md#ProjectTokenAuth)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **signCredentialsLdp**
> SignCredentialsLdpResultDto signCredentialsLdp(walletId, signCredentialsLdpInputDto)



signs credential with the wallet v2

### Example
```dart
import 'package:affinidi_tdk_wallets_client/api.dart';
// TODO Configure API key authorization: ProjectTokenAuth
//defaultApiClient.getAuthentication<ApiKeyAuth>('ProjectTokenAuth').apiKey = 'YOUR_API_KEY';
// uncomment below to setup prefix (e.g. Bearer) for API key, if needed
//defaultApiClient.getAuthentication<ApiKeyAuth>('ProjectTokenAuth').apiKeyPrefix = 'Bearer';

final api = AffinidiTdkWalletsClient().getWalletApi();
final String walletId = walletId_example; // String | id of the wallet
final SignCredentialsLdpInputDto signCredentialsLdpInputDto = ; // SignCredentialsLdpInputDto | signCredentialsLdp

try {
    final response = api.signCredentialsLdp(walletId, signCredentialsLdpInputDto);
    print(response);
} catch on DioException (e) {
    print('Exception when calling WalletApi->signCredentialsLdp: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **walletId** | **String**| id of the wallet | 
 **signCredentialsLdpInputDto** | [**SignCredentialsLdpInputDto**](SignCredentialsLdpInputDto.md)| signCredentialsLdp | 

### Return type

[**SignCredentialsLdpResultDto**](SignCredentialsLdpResultDto.md)

### Authorization

[ProjectTokenAuth](../README.md#ProjectTokenAuth)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **signCredentialsSdJwt**
> SignCredentialsDm2SdJwtResultDto signCredentialsSdJwt(walletId, signCredentialsDm2SdJwtInputDto)



signs credential with the wallet v2

### Example
```dart
import 'package:affinidi_tdk_wallets_client/api.dart';
// TODO Configure API key authorization: ProjectTokenAuth
//defaultApiClient.getAuthentication<ApiKeyAuth>('ProjectTokenAuth').apiKey = 'YOUR_API_KEY';
// uncomment below to setup prefix (e.g. Bearer) for API key, if needed
//defaultApiClient.getAuthentication<ApiKeyAuth>('ProjectTokenAuth').apiKeyPrefix = 'Bearer';

final api = AffinidiTdkWalletsClient().getWalletApi();
final String walletId = walletId_example; // String | id of the wallet
final SignCredentialsDm2SdJwtInputDto signCredentialsDm2SdJwtInputDto = ; // SignCredentialsDm2SdJwtInputDto | SignCredentialsDm1SdJwt

try {
    final response = api.signCredentialsSdJwt(walletId, signCredentialsDm2SdJwtInputDto);
    print(response);
} catch on DioException (e) {
    print('Exception when calling WalletApi->signCredentialsSdJwt: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **walletId** | **String**| id of the wallet | 
 **signCredentialsDm2SdJwtInputDto** | [**SignCredentialsDm2SdJwtInputDto**](SignCredentialsDm2SdJwtInputDto.md)| SignCredentialsDm1SdJwt | 

### Return type

[**SignCredentialsDm2SdJwtResultDto**](SignCredentialsDm2SdJwtResultDto.md)

### Authorization

[ProjectTokenAuth](../README.md#ProjectTokenAuth)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **signJwtToken**
> SignJwtTokenOK signJwtToken(walletId, signJwtToken)



signs a jwt token with the wallet

### Example
```dart
import 'package:affinidi_tdk_wallets_client/api.dart';
// TODO Configure API key authorization: ProjectTokenAuth
//defaultApiClient.getAuthentication<ApiKeyAuth>('ProjectTokenAuth').apiKey = 'YOUR_API_KEY';
// uncomment below to setup prefix (e.g. Bearer) for API key, if needed
//defaultApiClient.getAuthentication<ApiKeyAuth>('ProjectTokenAuth').apiKeyPrefix = 'Bearer';

final api = AffinidiTdkWalletsClient().getWalletApi();
final String walletId = walletId_example; // String | id of the wallet.
final SignJwtToken signJwtToken = ; // SignJwtToken | SignJwtToken

try {
    final response = api.signJwtToken(walletId, signJwtToken);
    print(response);
} catch on DioException (e) {
    print('Exception when calling WalletApi->signJwtToken: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **walletId** | **String**| id of the wallet. | 
 **signJwtToken** | [**SignJwtToken**](SignJwtToken.md)| SignJwtToken | 

### Return type

[**SignJwtTokenOK**](SignJwtTokenOK.md)

### Authorization

[ProjectTokenAuth](../README.md#ProjectTokenAuth)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **signJwtV2**
> SignJwtV2ResultDto signJwtV2(walletId, signJwtV2InputDto)

Sign JWT.

Sign a JSON Web Token (JWT).

### Example
```dart
import 'package:affinidi_tdk_wallets_client/api.dart';
// TODO Configure API key authorization: ProjectTokenAuth
//defaultApiClient.getAuthentication<ApiKeyAuth>('ProjectTokenAuth').apiKey = 'YOUR_API_KEY';
// uncomment below to setup prefix (e.g. Bearer) for API key, if needed
//defaultApiClient.getAuthentication<ApiKeyAuth>('ProjectTokenAuth').apiKeyPrefix = 'Bearer';

final api = AffinidiTdkWalletsClient().getWalletApi();
final String walletId = walletId_example; // String | id of the wallet
final SignJwtV2InputDto signJwtV2InputDto = ; // SignJwtV2InputDto | SignJwtV2

try {
    final response = api.signJwtV2(walletId, signJwtV2InputDto);
    print(response);
} catch on DioException (e) {
    print('Exception when calling WalletApi->signJwtV2: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **walletId** | **String**| id of the wallet | 
 **signJwtV2InputDto** | [**SignJwtV2InputDto**](SignJwtV2InputDto.md)| SignJwtV2 | 

### Return type

[**SignJwtV2ResultDto**](SignJwtV2ResultDto.md)

### Authorization

[ProjectTokenAuth](../README.md#ProjectTokenAuth)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **signPresentationsLdp**
> SignPresentationLdpResultDto signPresentationsLdp(walletId, signPresentationLdpInputDto)



signs presentation with the wallet

### Example
```dart
import 'package:affinidi_tdk_wallets_client/api.dart';
// TODO Configure API key authorization: ProjectTokenAuth
//defaultApiClient.getAuthentication<ApiKeyAuth>('ProjectTokenAuth').apiKey = 'YOUR_API_KEY';
// uncomment below to setup prefix (e.g. Bearer) for API key, if needed
//defaultApiClient.getAuthentication<ApiKeyAuth>('ProjectTokenAuth').apiKeyPrefix = 'Bearer';

final api = AffinidiTdkWalletsClient().getWalletApi();
final String walletId = walletId_example; // String | id of the wallet
final SignPresentationLdpInputDto signPresentationLdpInputDto = ; // SignPresentationLdpInputDto | signPresentationLdp

try {
    final response = api.signPresentationsLdp(walletId, signPresentationLdpInputDto);
    print(response);
} catch on DioException (e) {
    print('Exception when calling WalletApi->signPresentationsLdp: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **walletId** | **String**| id of the wallet | 
 **signPresentationLdpInputDto** | [**SignPresentationLdpInputDto**](SignPresentationLdpInputDto.md)| signPresentationLdp | 

### Return type

[**SignPresentationLdpResultDto**](SignPresentationLdpResultDto.md)

### Authorization

[ProjectTokenAuth](../README.md#ProjectTokenAuth)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **updateServiceEndpoint**
> ServiceEndpointDto updateServiceEndpoint(walletId, serviceId, updateServiceEndpointInput)



Update service endpoint in wallet, this applies to did:web only

### Example
```dart
import 'package:affinidi_tdk_wallets_client/api.dart';
// TODO Configure API key authorization: ProjectTokenAuth
//defaultApiClient.getAuthentication<ApiKeyAuth>('ProjectTokenAuth').apiKey = 'YOUR_API_KEY';
// uncomment below to setup prefix (e.g. Bearer) for API key, if needed
//defaultApiClient.getAuthentication<ApiKeyAuth>('ProjectTokenAuth').apiKeyPrefix = 'Bearer';

final api = AffinidiTdkWalletsClient().getWalletApi();
final String walletId = walletId_example; // String | id of the wallet
final String serviceId = serviceId_example; // String | id of the service endpoint to update
final UpdateServiceEndpointInput updateServiceEndpointInput = ; // UpdateServiceEndpointInput | UpdateServiceEndpoint

try {
    final response = api.updateServiceEndpoint(walletId, serviceId, updateServiceEndpointInput);
    print(response);
} catch on DioException (e) {
    print('Exception when calling WalletApi->updateServiceEndpoint: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **walletId** | **String**| id of the wallet | 
 **serviceId** | **String**| id of the service endpoint to update | 
 **updateServiceEndpointInput** | [**UpdateServiceEndpointInput**](UpdateServiceEndpointInput.md)| UpdateServiceEndpoint | 

### Return type

[**ServiceEndpointDto**](ServiceEndpointDto.md)

### Authorization

[ProjectTokenAuth](../README.md#ProjectTokenAuth)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **updateWallet**
> WalletDto updateWallet(walletId, updateWalletInput)



update wallet details using wallet Id.

### Example
```dart
import 'package:affinidi_tdk_wallets_client/api.dart';
// TODO Configure API key authorization: ProjectTokenAuth
//defaultApiClient.getAuthentication<ApiKeyAuth>('ProjectTokenAuth').apiKey = 'YOUR_API_KEY';
// uncomment below to setup prefix (e.g. Bearer) for API key, if needed
//defaultApiClient.getAuthentication<ApiKeyAuth>('ProjectTokenAuth').apiKeyPrefix = 'Bearer';

final api = AffinidiTdkWalletsClient().getWalletApi();
final String walletId = walletId_example; // String | id of the wallet
final UpdateWalletInput updateWalletInput = ; // UpdateWalletInput | UpdateWallet

try {
    final response = api.updateWallet(walletId, updateWalletInput);
    print(response);
} catch on DioException (e) {
    print('Exception when calling WalletApi->updateWallet: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **walletId** | **String**| id of the wallet | 
 **updateWalletInput** | [**UpdateWalletInput**](UpdateWalletInput.md)| UpdateWallet | 

### Return type

[**WalletDto**](WalletDto.md)

### Authorization

[ProjectTokenAuth](../README.md#ProjectTokenAuth)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **updateWalletKey**
> WalletKeyDto updateWalletKey(walletId, keyId, updateWalletKeyInput)



Update a wallet key's verification relationships, this applies to did:web only

### Example
```dart
import 'package:affinidi_tdk_wallets_client/api.dart';
// TODO Configure API key authorization: ProjectTokenAuth
//defaultApiClient.getAuthentication<ApiKeyAuth>('ProjectTokenAuth').apiKey = 'YOUR_API_KEY';
// uncomment below to setup prefix (e.g. Bearer) for API key, if needed
//defaultApiClient.getAuthentication<ApiKeyAuth>('ProjectTokenAuth').apiKeyPrefix = 'Bearer';

final api = AffinidiTdkWalletsClient().getWalletApi();
final String walletId = walletId_example; // String | id of the wallet
final String keyId = keyId_example; // String | wallet-scoped key identifier to update
final UpdateWalletKeyInput updateWalletKeyInput = ; // UpdateWalletKeyInput | UpdateWalletKey

try {
    final response = api.updateWalletKey(walletId, keyId, updateWalletKeyInput);
    print(response);
} catch on DioException (e) {
    print('Exception when calling WalletApi->updateWalletKey: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **walletId** | **String**| id of the wallet | 
 **keyId** | **String**| wallet-scoped key identifier to update | 
 **updateWalletKeyInput** | [**UpdateWalletKeyInput**](UpdateWalletKeyInput.md)| UpdateWalletKey | 

### Return type

[**WalletKeyDto**](WalletKeyDto.md)

### Authorization

[ProjectTokenAuth](../README.md#ProjectTokenAuth)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

