# affinidi_tdk_wallets_client

Affinidi TDK dart client for Affinidi WALLETS


## Requirements

* Dart 3.6.0+
* Dio 5.0.0+ (https://pub.dev/packages/dio)

## Installation & Usage

### pub.dev
To use the package from [pub.dev](https://pub.dev), please include the following in pubspec.yaml
```yaml
dependencies:
  affinidi_tdk_wallets_client: ^1.15.0
```

### Github
This Dart package is published to Github, please include the following in pubspec.yaml
```yaml
dependencies:
  affinidi_tdk_wallets_client:
    git:
      url: https://github.com/affinidi/affinidi-tdk-dart.git
      ref: main
      path: clients/wallets_client
```

### Local development
To use the package from your local drive, please include the following in pubspec.yaml
```yaml
dependencies:
  affinidi_tdk_wallets_client:
    path: /path/to/affinidi_tdk_wallets_client
```

### Install dependencies

```bash
dart pub get
```

## Getting Started

Please follow the [installation procedure](#installation--usage) and then run the following:

```dart
import 'package:affinidi_tdk_wallets_client/affinidi_tdk_wallets_client.dart';


final api = AffinidiTdkWalletsClient().getRevocationApi();
final String projectId = projectId_example; // String | Description for projectId.
final String walletId = walletId_example; // String | Description for walletId.
final String statusId = statusId_example; // String | Description for statusId.

try {
    final response = await api.getRevocationCredentialStatus(projectId, walletId, statusId);
    print(response);
} catch on DioException (e) {
    print("Exception when calling RevocationApi->getRevocationCredentialStatus: $e\n");
}

```

## Documentation for API Endpoints

All URIs are relative to *https://apse1.api.affinidi.io/cwe*

Class | Method | HTTP request | Description
------------ | ------------- | ------------- | -------------
[*RevocationApi*](doc/RevocationApi.md) | [**getRevocationCredentialStatus**](doc/RevocationApi.md#getrevocationcredentialstatus) | **GET** /v1/projects/{projectId}/wallets/{walletId}/revocation-statuses/{statusId} | 
[*RevocationApi*](doc/RevocationApi.md) | [**getRevocationListCredential**](doc/RevocationApi.md#getrevocationlistcredential) | **GET** /v1/wallets/{walletId}/revocation-list/{listId} | Return revocation list credential.
[*RevocationApi*](doc/RevocationApi.md) | [**revokeCredential**](doc/RevocationApi.md#revokecredential) | **POST** /v1/wallets/{walletId}/revoke | Revoke Credential.
[*RevocationApi*](doc/RevocationApi.md) | [**revokeCredentials**](doc/RevocationApi.md#revokecredentials) | **POST** /v2/wallets/{walletId}/credentials/revoke | Revoke Credentials.
[*WalletApi*](doc/WalletApi.md) | [**createWallet**](doc/WalletApi.md#createwallet) | **POST** /v1/wallets | 
[*WalletApi*](doc/WalletApi.md) | [**createWalletV2**](doc/WalletApi.md#createwalletv2) | **POST** /v2/wallets | 
[*WalletApi*](doc/WalletApi.md) | [**deleteWallet**](doc/WalletApi.md#deletewallet) | **DELETE** /v1/wallets/{walletId} | 
[*WalletApi*](doc/WalletApi.md) | [**getWallet**](doc/WalletApi.md#getwallet) | **GET** /v1/wallets/{walletId} | 
[*WalletApi*](doc/WalletApi.md) | [**listWallets**](doc/WalletApi.md#listwallets) | **GET** /v1/wallets | 
[*WalletApi*](doc/WalletApi.md) | [**signCredential**](doc/WalletApi.md#signcredential) | **POST** /v1/wallets/{walletId}/sign-credential | 
[*WalletApi*](doc/WalletApi.md) | [**signCredentialsJwt**](doc/WalletApi.md#signcredentialsjwt) | **POST** /v2/wallets/{walletId}/credentials/jwt/sign | 
[*WalletApi*](doc/WalletApi.md) | [**signCredentialsLdp**](doc/WalletApi.md#signcredentialsldp) | **POST** /v2/wallets/{walletId}/credentials/ldp/sign | 
[*WalletApi*](doc/WalletApi.md) | [**signCredentialsSdJwt**](doc/WalletApi.md#signcredentialssdjwt) | **POST** /v2/wallets/{walletId}/credentials/sd-jwt/sign | 
[*WalletApi*](doc/WalletApi.md) | [**signJwtToken**](doc/WalletApi.md#signjwttoken) | **POST** /v1/wallets/{walletId}/sign-jwt | 
[*WalletApi*](doc/WalletApi.md) | [**signJwtV2**](doc/WalletApi.md#signjwtv2) | **POST** /v2/wallets/{walletId}/jwt/sign | Sign JWT.
[*WalletApi*](doc/WalletApi.md) | [**signPresentationsLdp**](doc/WalletApi.md#signpresentationsldp) | **POST** /v2/wallets/{walletId}/presentations/ldp/sign | 
[*WalletApi*](doc/WalletApi.md) | [**updateWallet**](doc/WalletApi.md#updatewallet) | **PATCH** /v1/wallets/{walletId} | 


## Documentation For Models

 - [AuthcryptMessageInput](doc/AuthcryptMessageInput.md)
 - [AuthcryptMessageResultDto](doc/AuthcryptMessageResultDto.md)
 - [CreateWalletInput](doc/CreateWalletInput.md)
 - [CreateWalletResponse](doc/CreateWalletResponse.md)
 - [CreateWalletV2Input](doc/CreateWalletV2Input.md)
 - [CreateWalletV2Response](doc/CreateWalletV2Response.md)
 - [EntityNotFoundError](doc/EntityNotFoundError.md)
 - [GetRevocationCredentialStatusOK](doc/GetRevocationCredentialStatusOK.md)
 - [GetRevocationListCredentialResultDto](doc/GetRevocationListCredentialResultDto.md)
 - [InvalidDidParameterError](doc/InvalidDidParameterError.md)
 - [InvalidParameterError](doc/InvalidParameterError.md)
 - [KeyNotFoundError](doc/KeyNotFoundError.md)
 - [NotFoundError](doc/NotFoundError.md)
 - [OperationForbiddenError](doc/OperationForbiddenError.md)
 - [RevokeCredentialInput](doc/RevokeCredentialInput.md)
 - [RevokeCredentialsInput](doc/RevokeCredentialsInput.md)
 - [ServiceErrorResponse](doc/ServiceErrorResponse.md)
 - [ServiceErrorResponseDetailsInner](doc/ServiceErrorResponseDetailsInner.md)
 - [SignCredential400Response](doc/SignCredential400Response.md)
 - [SignCredentialInputDto](doc/SignCredentialInputDto.md)
 - [SignCredentialInputDtoUnsignedCredentialParams](doc/SignCredentialInputDtoUnsignedCredentialParams.md)
 - [SignCredentialResultDto](doc/SignCredentialResultDto.md)
 - [SignCredentialsDm1LdInputDto](doc/SignCredentialsDm1LdInputDto.md)
 - [SignCredentialsDm1LdResultDto](doc/SignCredentialsDm1LdResultDto.md)
 - [SignCredentialsDm2SdJwtInputDto](doc/SignCredentialsDm2SdJwtInputDto.md)
 - [SignCredentialsDm2SdJwtResultDto](doc/SignCredentialsDm2SdJwtResultDto.md)
 - [SignCredentialsJwtInputDto](doc/SignCredentialsJwtInputDto.md)
 - [SignCredentialsJwtResultDto](doc/SignCredentialsJwtResultDto.md)
 - [SignCredentialsLdpInputDto](doc/SignCredentialsLdpInputDto.md)
 - [SignCredentialsLdpResultDto](doc/SignCredentialsLdpResultDto.md)
 - [SignJwtToken](doc/SignJwtToken.md)
 - [SignJwtTokenOK](doc/SignJwtTokenOK.md)
 - [SignJwtV2](doc/SignJwtV2.md)
 - [SignJwtV2OK](doc/SignJwtV2OK.md)
 - [SignMessageInput](doc/SignMessageInput.md)
 - [SignMessageResultDto](doc/SignMessageResultDto.md)
 - [SignPresentationLdpInputDto](doc/SignPresentationLdpInputDto.md)
 - [SignPresentationLdpResultDto](doc/SignPresentationLdpResultDto.md)
 - [SigningFailedError](doc/SigningFailedError.md)
 - [TooManyRequestsError](doc/TooManyRequestsError.md)
 - [UnpackMessageInput](doc/UnpackMessageInput.md)
 - [UnpackMessageResultDto](doc/UnpackMessageResultDto.md)
 - [UpdateWalletInput](doc/UpdateWalletInput.md)
 - [WalletDto](doc/WalletDto.md)
 - [WalletDtoKeysInner](doc/WalletDtoKeysInner.md)
 - [WalletV2Dto](doc/WalletV2Dto.md)
 - [WalletsListDto](doc/WalletsListDto.md)


## Documentation For Authorization


Authentication schemes defined for the API:
### ProjectTokenAuth

- **Type**: API key
- **API key parameter name**: authorization
- **Location**: HTTP header


## Author

info@affinidi.com

