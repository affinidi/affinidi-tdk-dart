# affinidi_tdk_iam_client.api.AccountsApi

## Load the API package
```dart
import 'package:affinidi_tdk_iam_client/api.dart';
```

All URIs are relative to *https://apse1.api.affinidi.io/iam*

Method | HTTP request | Description
------------- | ------------- | -------------
[**listAccountPasskeys**](AccountsApi.md#listaccountpasskeys) | **GET** /v1/accounts/passkeys | 
[**listAccountProviders**](AccountsApi.md#listaccountproviders) | **GET** /v1/accounts/providers | 


# **listAccountPasskeys**
> PasskeyList listAccountPasskeys()



### Example
```dart
import 'package:affinidi_tdk_iam_client/api.dart';
// TODO Configure API key authorization: UserTokenAuth
//defaultApiClient.getAuthentication<ApiKeyAuth>('UserTokenAuth').apiKey = 'YOUR_API_KEY';
// uncomment below to setup prefix (e.g. Bearer) for API key, if needed
//defaultApiClient.getAuthentication<ApiKeyAuth>('UserTokenAuth').apiKeyPrefix = 'Bearer';

final api = AffinidiTdkIamClient().getAccountsApi();

try {
    final response = api.listAccountPasskeys();
    print(response);
} catch on DioException (e) {
    print('Exception when calling AccountsApi->listAccountPasskeys: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**PasskeyList**](PasskeyList.md)

### Authorization

[UserTokenAuth](../README.md#UserTokenAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **listAccountProviders**
> ProviderList listAccountProviders()



### Example
```dart
import 'package:affinidi_tdk_iam_client/api.dart';
// TODO Configure API key authorization: UserTokenAuth
//defaultApiClient.getAuthentication<ApiKeyAuth>('UserTokenAuth').apiKey = 'YOUR_API_KEY';
// uncomment below to setup prefix (e.g. Bearer) for API key, if needed
//defaultApiClient.getAuthentication<ApiKeyAuth>('UserTokenAuth').apiKeyPrefix = 'Bearer';

final api = AffinidiTdkIamClient().getAccountsApi();

try {
    final response = api.listAccountProviders();
    print(response);
} catch on DioException (e) {
    print('Exception when calling AccountsApi->listAccountProviders: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**ProviderList**](ProviderList.md)

### Authorization

[UserTokenAuth](../README.md#UserTokenAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

