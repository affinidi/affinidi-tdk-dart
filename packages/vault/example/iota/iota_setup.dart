import 'dart:io';

import 'package:affinidi_tdk_auth_provider/affinidi_tdk_auth_provider.dart';
import 'package:affinidi_tdk_common/affinidi_tdk_common.dart';
import 'package:affinidi_tdk_wallets_client/affinidi_tdk_wallets_client.dart';

import 'package:dotenv/dotenv.dart';
import 'package:path/path.dart' as path;

import '../../../integration_tests/test/helpers/helpers.dart';

const _walletName = 'VDSP Verifier Wallet';

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

Future<String> ensureWalletCreated() async {
  final authProvider = _loadEnv();

  final api = AffinidiTdkWalletsClient(
    authTokenHook: authProvider.fetchProjectScopedToken,
    basePathOverride: replaceBaseDomain(
      AffinidiTdkWalletsClient.basePath,
      Environment.fetchEnvironment().apiGwUrl,
    ),
  ).getWalletApi();

  final createInput = CreateWalletInput(
    (b) => b
      ..name = _walletName
      ..didMethod = CreateWalletInputDidMethodEnum.key,
  );

  final response = await api.createWallet(createWalletInput: createInput);
  final newAri = response.data!.wallet!.ari!;
  return newAri;
}
