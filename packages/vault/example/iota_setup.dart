import 'dart:io';

import 'package:affinidi_tdk_auth_provider/affinidi_tdk_auth_provider.dart';
import 'package:affinidi_tdk_common/affinidi_tdk_common.dart';
import 'package:affinidi_tdk_iota_client/affinidi_tdk_iota_client.dart';
import 'package:affinidi_tdk_wallets_client/affinidi_tdk_wallets_client.dart';
import 'package:built_collection/built_collection.dart';
import 'package:dotenv/dotenv.dart';
import 'package:path/path.dart' as path;

import '../../integration_tests/test/helpers/strings_helper.dart';

const _walletName = 'VDSP Verifier Wallet';
const _configName = 'VDSP Verifier Config';

String get _envPath =>
    path.join(File(Platform.script.toFilePath()).parent.path, '.env');

AuthProvider _loadEnv() {
  final env = DotEnv()..load([_envPath]);
  final projectId = env['DEV_PROJECT_ID'];
  final tokenId = env['DEV_TOKEN_ID'];
  final privateKey = env['DEV_PRIVATE_KEY'];
  if (projectId == null || projectId.isEmpty) {
    throw Exception('Missing DEV_PROJECT_ID in $_envPath');
  }

  if (tokenId == null || tokenId.isEmpty) {
    throw Exception('Missing DEV_TOKEN_ID in $_envPath');
  }

  if (privateKey == null || privateKey.isEmpty) {
    throw Exception('Missing DEV_PRIVATE_KEY in $_envPath');
  }
  final envConfig = Environment.getEnvironmentConfig(EnvironmentType.dev);
  return AuthProvider.withEnv(
    projectId: projectId,
    tokenId: tokenId,
    privateKey: privateKey.replaceAll(r'\n', '\n'),
    passphrase: env['DEV_PASSPHRASE']?.isNotEmpty == true
        ? env['DEV_PASSPHRASE']!
        : null,
    apiGatewayUrl: envConfig.apiGwUrl,
    tokenEndpoint: envConfig.elementsAuthTokenUrl,
  );
}

class WalletSetupResult {
  const WalletSetupResult({required this.walletAri, required this.businessDid});
  final String walletAri;
  final String businessDid;
}

Future<WalletSetupResult> ensureWalletCreated() async {
  final authProvider = _loadEnv();

  final api = AffinidiTdkWalletsClient(
    authTokenHook: authProvider.fetchProjectScopedToken,
    basePathOverride: replaceBaseDomain(
      AffinidiTdkWalletsClient.basePath,
      Environment.fetchEnvironment().apiGwUrl,
    ),
  ).getWalletApi();
  final listResponse = await api.listWallets();
  final existing = listResponse.data?.wallets
      ?.where((w) => w.name == _walletName)
      .firstOrNull;

  final String walletId;
  final String walletAri;

  if (existing != null) {
    walletId = existing.id!;
    walletAri = existing.ari!;
  } else {
    final createInput = CreateWalletV2Input(
      (b) => b
        ..name = _walletName
        ..didMethod = CreateWalletV2InputDidMethodEnum.key
        ..algorithm = CreateWalletV2InputAlgorithmEnum.secp256k1,
    );
    final createResponse = await api.createWalletV2(
      createWalletV2Input: createInput,
    );
    final wallet = createResponse.data!.wallet!;
    walletId = wallet.id!;
    walletAri = wallet.ari!;
  }

  final walletResponse = await api.getWallet(walletId: walletId);
  final businessDid = walletResponse.data?.did;

  if (businessDid == null || businessDid.isEmpty) {
    throw Exception('Failed to retrieve DID for wallet with id $walletId');
  }

  return WalletSetupResult(walletAri: walletAri, businessDid: businessDid);
}

Future<IotaConfigResult> ensureIotaConfigurationCreated({
  required String walletAri,
}) async {
  return const IotaConfigResult(
    configurationId: 'e77ba030-23e0-4619-abee-745dd2e3cc48',
    queryId: '1f4ec195-9af9-4e7b-8acd-28ab9dee4102',
  );

  final authProvider = _loadEnv();
  final envConfig = Environment.getEnvironmentConfig(EnvironmentType.dev);
  final iotaClient = AffinidiTdkIotaClient(
    authTokenHook: authProvider.fetchProjectScopedToken,
    basePathOverride: replaceBaseDomain(
      AffinidiTdkIotaClient.basePath,
      envConfig.apiGwUrl,
    ),
  );

  final configs = iotaClient.getConfigurationsApi();
  final dcql = iotaClient.getDcqlQueryApi();

  final configsList = (await configs.listIotaConfigurations()).data;
  final existing =
      (configsList?.configurations.toList() ?? <IotaConfigurationDto>[])
          .where(
            (IotaConfigurationDto c) =>
                c.name == _configName && c.walletAri == walletAri,
          )
          .firstOrNull;
  if (existing != null) {
    final dcqlQueries = (await dcql.listDcqlQueries(
      configurationId: existing.configurationId,
    )).data;
    final queryId = dcqlQueries?.dcqlQueries.firstOrNull?.queryId ?? '';
    return IotaConfigResult(
      configurationId: existing.configurationId,
      queryId: queryId,
    );
  }

  final config = (await configs.createIotaConfiguration(
    createIotaConfigurationInput:
        (CreateIotaConfigurationInputBuilder()
              ..name = _configName
              ..walletAri = walletAri
              ..mode = CreateIotaConfigurationInputModeEnum.didcomm
              ..enableVerification = false
              ..enableConsentAuditLog = false
              ..redirectUris = ListBuilder<String>([
                'https://cis-qc-1.vercel.app/iota-callback',
              ])
              ..clientMetadata = (IotaConfigurationDtoClientMetadataBuilder()
                ..name = 'VDSP Verifier Example'
                ..logo = 'https://example.com/logo.png'
                ..origin = 'https://cis-qc-1.vercel.app/iota-callback'))
            .build(),
  )).data;
  if (config == null) throw Exception('Failed to create IOTA configuration');

  const dcqlJson =
      '{"credentials":[{"id":"email-claim","format":"ldp_vc","meta":{"type_values":[["Email"]]},"claims":[{"path":["credentialSubject","email"]}]}]}';

  final dcqlResult = await dcql.createDcqlQuery(
    configurationId: config.configurationId,
    createDcqlQueryInput:
        (CreateDcqlQueryInputBuilder()
              ..name = 'Email claim query'
              ..dcqlQuery = dcqlJson
              ..description = 'Query for email credential claim')
            .build(),
  );

  return IotaConfigResult(
    configurationId: config.configurationId,
    queryId: dcqlResult.data!.queryId,
  );
}

class IotaConfigResult {
  const IotaConfigResult({
    required this.configurationId,
    required this.queryId,
  });
  final String configurationId;
  final String queryId;
}

IotaApi getIotaApi() {
  final authProvider = _loadEnv();
  final envConfig = Environment.getEnvironmentConfig(EnvironmentType.dev);
  final iotaClient = AffinidiTdkIotaClient(
    authTokenHook: authProvider.fetchProjectScopedToken,
    basePathOverride: replaceBaseDomain(
      AffinidiTdkIotaClient.basePath,
      envConfig.apiGwUrl,
    ),
  );
  return iotaClient.getIotaApi();
}
