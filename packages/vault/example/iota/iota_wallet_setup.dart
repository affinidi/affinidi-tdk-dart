import 'dart:io';

import 'package:affinidi_tdk_auth_provider/affinidi_tdk_auth_provider.dart';
import 'package:affinidi_tdk_common/affinidi_tdk_common.dart';
import 'package:affinidi_tdk_wallets_client/affinidi_tdk_wallets_client.dart';

import 'package:dotenv/dotenv.dart';
import 'package:path/path.dart' as path;

import '../../../integration_tests/test/helpers/helpers.dart';

const _walletName = 'VDSP Verifier Wallet';

Future<String> ensureWalletCreated() async {
  final envPath = path.join(
    File(Platform.script.toFilePath()).parent.path,
    '.env',
  );
  final env = DotEnv()..load([envPath]);
  final cached = env['WALLET_ARI'];
  if (cached != null && cached.isNotEmpty) {
    return cached;
  }

  final projectId = env['DEV_PROJECT_ID'];
  final tokenId = env['DEV_TOKEN_ID'];
  final privateKey = env['DEV_PRIVATE_KEY'];
  if (projectId == null ||
      projectId.isEmpty ||
      tokenId == null ||
      tokenId.isEmpty ||
      privateKey == null ||
      privateKey.isEmpty) {
    throw Exception(
      'Missing DEV_PROJECT_ID, DEV_TOKEN_ID or DEV_PRIVATE_KEY in $envPath',
    );
  }

  final normalizedKey = privateKey.replaceAll(r'\n', '\n');
  final envConfig = Environment.getEnvironmentConfig(EnvironmentType.dev);
  final authProvider = AuthProvider.withEnv(
    projectId: projectId,
    tokenId: tokenId,
    privateKey: normalizedKey,
    passphrase: env['DEV_PASSPHRASE']?.isNotEmpty == true
        ? env['DEV_PASSPHRASE']!
        : null,
    apiGatewayUrl: envConfig.apiGwUrl,
    tokenEndpoint: envConfig.elementsAuthTokenUrl,
  );

  final api = AffinidiTdkWalletsClient(
    authTokenHook: authProvider.fetchProjectScopedToken,
    basePathOverride: replaceBaseDomain(
      AffinidiTdkWalletsClient.basePath,
      Environment.fetchEnvironment().apiGwUrl,
    ),
  ).getWalletApi();

  final wallets =
      (await api.listWallets()).data?.wallets?.toList() ?? <WalletDto>[];
  final existingAri = _findWalletAri(wallets);

  if (existingAri != null) {
    _writeWalletAri(envPath, existingAri);
    return existingAri;
  }

  final createInput = CreateWalletInput(
    (b) => b
      ..name = _walletName
      ..didMethod = CreateWalletInputDidMethodEnum.key,
  );

  final response = await api.createWallet(createWalletInput: createInput);
  final newAri = response.data!.wallet!.ari!;
  _writeWalletAri(envPath, newAri);
  return newAri;
}

String? _findWalletAri(List<WalletDto> wallets) {
  for (final w in wallets) {
    if (w.name == _walletName && w.ari != null) return w.ari;
  }
  return null;
}

void _writeWalletAri(String envPath, String ari) {
  final file = File(envPath);
  final content = file.existsSync() ? file.readAsStringSync() : '';
  final lines = content.split('\n');
  final idx = lines.indexWhere((l) => l.startsWith('WALLET_ARI='));
  final updated = idx >= 0
      ? (lines..[idx] = 'WALLET_ARI=$ari').join('\n')
      : '$content${content.endsWith('\n') ? '' : '\n'}WALLET_ARI=$ari';
  file.writeAsStringSync(updated);
}
