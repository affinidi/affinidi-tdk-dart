import 'package:affinidi_tdk_common/affinidi_tdk_common.dart';
import 'package:affinidi_tdk_common/src/exceptions/tdk_exception_type.dart';
import 'package:test/test.dart';

const _environmentOverride = String.fromEnvironment(
  'AFFINIDI_TDK_ENVIRONMENT_OVERRIDE',
  defaultValue: '',
);
const _regionOverride = String.fromEnvironment(
  'AFFINIDI_TDK_ENVIRONMENT_REGION_OVERRIDE',
  defaultValue: '',
);

EnvironmentType? _parseEnvironmentOverride(String raw) {
  if (raw.isEmpty) {
    return null;
  }

  for (final envType in EnvironmentType.values) {
    if (envType.value == raw) {
      return envType;
    }
  }

  return null;
}

ElementsRegion? _parseRegionOverride(String raw) {
  if (raw.isEmpty) {
    return null;
  }

  for (final region in ElementsRegion.values) {
    if (region.awsRegion == raw) {
      return region;
    }
  }

  return null;
}

void main() {
  final parsedEnvironmentOverride = _parseEnvironmentOverride(
    _environmentOverride,
  );
  final parsedRegionOverride = _parseRegionOverride(_regionOverride);
  final hasEnvironmentOverride = _environmentOverride.isNotEmpty;
  final hasRegionOverride = _regionOverride.isNotEmpty;
  final hasAnyOverride = hasEnvironmentOverride || hasRegionOverride;

  final mumbaiRegion = ElementsRegion.apSouth1;
  final envTypeLocal = EnvironmentType.local;
  final envTypeDev = EnvironmentType.dev;
  final envTypeProd = EnvironmentType.prod;
  final local = Environment.getEnvironmentConfig(envTypeLocal);
  final dev = Environment.getEnvironmentConfig(envTypeDev);
  final prod = Environment.getEnvironmentConfig(envTypeProd);

  group('Environment Tests', () {
    test(
      'getEnvironmentConfig falls back to provided inputs when no overrides are set',
      () {
        final config = Environment.getEnvironmentConfig(
          EnvironmentType.local,
          ElementsRegion.usEast1,
        );
        expect(config.environmentName, equals(EnvironmentType.local.value));
        expect(config.apiGwUrl, equals('https://use1.dev.api.affinidi.io'));
      },
      skip: hasAnyOverride
          ? 'Compile-time overrides are set; fallback behavior test is skipped.'
          : false,
    );

    test('getEnvironmentConfig applies environment override when provided', () {
      if (parsedEnvironmentOverride != null) {
        final config = Environment.getEnvironmentConfig(
          EnvironmentType.local,
          ElementsRegion.apSoutheast1,
        );
        expect(config.environmentName, equals(parsedEnvironmentOverride.value));
      } else if (hasEnvironmentOverride) {
        expect(
          () => Environment.getEnvironmentConfig(
            EnvironmentType.local,
            ElementsRegion.apSoutheast1,
          ),
          throwsA(
            isA<TdkException>().having(
              (e) => e.code,
              'code',
              TdkExceptionType.invalidEnvironmentOverride.code,
            ),
          ),
        );
      } else {
        final config = Environment.getEnvironmentConfig(
          EnvironmentType.local,
          ElementsRegion.apSoutheast1,
        );
        expect(config.environmentName, equals(EnvironmentType.local.value));
      }
    });

    test('getEnvironmentConfig applies region override when provided', () {
      if (hasEnvironmentOverride && parsedEnvironmentOverride == null) {
        expect(
          () => Environment.getEnvironmentConfig(
            EnvironmentType.dev,
            ElementsRegion.apSoutheast1,
          ),
          throwsA(
            isA<TdkException>().having(
              (e) => e.code,
              'code',
              TdkExceptionType.invalidEnvironmentOverride.code,
            ),
          ),
        );
        return;
      }

      if (parsedRegionOverride != null) {
        final config = Environment.getEnvironmentConfig(
          EnvironmentType.dev,
          ElementsRegion.apSoutheast1,
        );
        expect(
          config.apiGwUrl,
          equals(
            'https://${parsedRegionOverride.regionCode}.dev.api.affinidi.io',
          ),
        );
      } else if (hasRegionOverride) {
        expect(
          () => Environment.getEnvironmentConfig(
            EnvironmentType.dev,
            ElementsRegion.apSoutheast1,
          ),
          throwsA(
            isA<TdkException>().having(
              (e) => e.code,
              'code',
              TdkExceptionType.invalidEnvironmentRegionOverride.code,
            ),
          ),
        );
      } else {
        final config = Environment.getEnvironmentConfig(
          EnvironmentType.dev,
          ElementsRegion.apSoutheast1,
        );
        expect(config.apiGwUrl, equals('https://apse1.dev.api.affinidi.io'));
      }
    });

    test('invalid environment override throws', () {
      if (hasEnvironmentOverride && parsedEnvironmentOverride == null) {
        expect(
          () => Environment.getEnvironmentConfig(
            EnvironmentType.prod,
            ElementsRegion.apSoutheast1,
          ),
          throwsA(
            isA<TdkException>().having(
              (e) => e.code,
              'code',
              TdkExceptionType.invalidEnvironmentOverride.code,
            ),
          ),
        );
      } else {
        expect(
          () => Environment.getEnvironmentConfig(
            EnvironmentType.prod,
            ElementsRegion.apSoutheast1,
          ),
          returnsNormally,
        );
      }
    });

    test('invalid region override throws', () {
      if (hasEnvironmentOverride && parsedEnvironmentOverride == null) {
        expect(
          () => Environment.getEnvironmentConfig(
            EnvironmentType.prod,
            ElementsRegion.apSoutheast1,
          ),
          throwsA(
            isA<TdkException>().having(
              (e) => e.code,
              'code',
              TdkExceptionType.invalidEnvironmentOverride.code,
            ),
          ),
        );
        return;
      }

      if (hasRegionOverride && parsedRegionOverride == null) {
        expect(
          () => Environment.getEnvironmentConfig(
            EnvironmentType.prod,
            ElementsRegion.apSoutheast1,
          ),
          throwsA(
            isA<TdkException>().having(
              (e) => e.code,
              'code',
              TdkExceptionType.invalidEnvironmentRegionOverride.code,
            ),
          ),
        );
      } else {
        expect(
          () => Environment.getEnvironmentConfig(
            EnvironmentType.prod,
            ElementsRegion.apSoutheast1,
          ),
          returnsNormally,
        );
      }
    });

    test('fetchEnvironment returns prod by default', () {
      expect(
        Environment.fetchEnvironment().environmentName,
        equals(prod.environmentName),
      );
      expect(Environment.fetchEnvironment().apiGwUrl, equals(prod.apiGwUrl));
    });

    test('API Gateway URLs are correct', () {
      expect(
        Environment.fetchApiGwUrl(local),
        equals('https://apse1.dev.api.affinidi.io'),
      );
      expect(
        Environment.fetchApiGwUrl(dev),
        equals('https://apse1.dev.api.affinidi.io'),
      );
      expect(
        Environment.fetchApiGwUrl(prod),
        equals('https://apse1.api.affinidi.io'),
      );
      expect(
        Environment.fetchApiGwUrl(null, envTypeProd, mumbaiRegion),
        equals('https://aps1.api.affinidi.io'),
      );
      expect(
        Environment.fetchApiGwUrl(null, envTypeDev, mumbaiRegion),
        equals('https://aps1.dev.api.affinidi.io'),
      );
      expect(
        Environment.fetchApiGwUrl(null, envTypeLocal, mumbaiRegion),
        equals('https://aps1.dev.api.affinidi.io'),
      );
    });

    test('API Gateway URL defaults to prod', () {
      expect(
        Environment.fetchApiGwUrl(),
        equals('https://apse1.api.affinidi.io'),
      );
      expect(
        Environment.fetchEnvironment(region: mumbaiRegion).environmentName,
        equals(prod.environmentName),
      );
      expect(
        Environment.fetchEnvironment(region: mumbaiRegion).apiGwUrl,
        equals('https://aps1.api.affinidi.io'),
      );
    });

    test('Elements Auth Token URLs are correct', () {
      expect(
        Environment.fetchElementsAuthTokenUrl(local),
        equals(
          'https://apse1.dev.auth.developer.affinidi.io/auth/oauth2/token',
        ),
      );
      expect(
        Environment.fetchElementsAuthTokenUrl(dev),
        equals(
          'https://apse1.dev.auth.developer.affinidi.io/auth/oauth2/token',
        ),
      );
      expect(
        Environment.fetchElementsAuthTokenUrl(prod),
        equals('https://apse1.auth.developer.affinidi.io/auth/oauth2/token'),
      );
      expect(
        Environment.fetchElementsAuthTokenUrl(null, envTypeLocal, mumbaiRegion),
        equals('https://aps1.dev.auth.developer.affinidi.io/auth/oauth2/token'),
      );
      expect(
        Environment.fetchElementsAuthTokenUrl(null, envTypeDev, mumbaiRegion),
        equals('https://aps1.dev.auth.developer.affinidi.io/auth/oauth2/token'),
      );
      expect(
        Environment.fetchElementsAuthTokenUrl(null, envTypeProd, mumbaiRegion),
        equals('https://aps1.auth.developer.affinidi.io/auth/oauth2/token'),
      );
    });

    test('Elements Auth Token URL defaults to prod', () {
      expect(
        Environment.fetchElementsAuthTokenUrl(),
        equals('https://apse1.auth.developer.affinidi.io/auth/oauth2/token'),
      );
    });

    test('IoT URLs are correct', () {
      expect(
        Environment.fetchIotUrl(local),
        equals('a3sq1vuw0cw9an-ats.iot.ap-southeast-1.amazonaws.com'),
      );
      expect(
        Environment.fetchIotUrl(dev),
        equals('a3sq1vuw0cw9an-ats.iot.ap-southeast-1.amazonaws.com'),
      );
      expect(
        Environment.fetchIotUrl(prod),
        equals('a13pfgsvt8xhx-ats.iot.ap-southeast-1.amazonaws.com'),
      );
    });

    test('IoT URL defaults to prod', () {
      expect(
        Environment.fetchIotUrl(),
        equals('a13pfgsvt8xhx-ats.iot.ap-southeast-1.amazonaws.com'),
      );
    });

    test('Consumer Audience URLs are correct', () {
      expect(
        Environment.fetchConsumerAudienceUrl(local),
        equals(
          'https://apse1.dev.api.affinidi.io/iam/v1/consumer/oauth2/token',
        ),
      );
      expect(
        Environment.fetchConsumerAudienceUrl(dev),
        equals(
          'https://apse1.dev.api.affinidi.io/iam/v1/consumer/oauth2/token',
        ),
      );
      expect(
        Environment.fetchConsumerAudienceUrl(prod),
        equals('https://apse1.api.affinidi.io/iam/v1/consumer/oauth2/token'),
      );
      expect(
        Environment.fetchConsumerAudienceUrl(null, envTypeLocal, mumbaiRegion),
        equals('https://aps1.dev.api.affinidi.io/iam/v1/consumer/oauth2/token'),
      );
      expect(
        Environment.fetchConsumerAudienceUrl(null, envTypeDev, mumbaiRegion),
        equals('https://aps1.dev.api.affinidi.io/iam/v1/consumer/oauth2/token'),
      );
      expect(
        Environment.fetchConsumerAudienceUrl(null, envTypeProd, mumbaiRegion),
        equals('https://aps1.api.affinidi.io/iam/v1/consumer/oauth2/token'),
      );
    });

    test('Consumer Audience URL defaults to prod', () {
      expect(
        Environment.fetchConsumerAudienceUrl(),
        equals('https://apse1.api.affinidi.io/iam/v1/consumer/oauth2/token'),
      );
    });

    test('Consumer CIS URLs are correct', () {
      expect(
        Environment.fetchConsumerCisUrl(local),
        equals('https://apse1.dev.api.affinidi.io/cis'),
      );
      expect(
        Environment.fetchConsumerCisUrl(dev),
        equals('https://apse1.dev.api.affinidi.io/cis'),
      );
      expect(
        Environment.fetchConsumerCisUrl(prod),
        equals('https://apse1.api.affinidi.io/cis'),
      );
      expect(
        Environment.fetchConsumerCisUrl(null, envTypeLocal, mumbaiRegion),
        equals('https://aps1.dev.api.affinidi.io/cis'),
      );
      expect(
        Environment.fetchConsumerCisUrl(null, envTypeDev, mumbaiRegion),
        equals('https://aps1.dev.api.affinidi.io/cis'),
      );
      expect(
        Environment.fetchConsumerCisUrl(null, envTypeProd, mumbaiRegion),
        equals('https://aps1.api.affinidi.io/cis'),
      );
    });

    test('Consumer CIS URL defaults to prod', () {
      expect(
        Environment.fetchConsumerCisUrl(),
        equals('https://apse1.api.affinidi.io/cis'),
      );
    });

    test('Vault account audience URLs are correct', () {
      expect(
        Environment.fetchVaultAccountsAudienceUrl(local),
        equals('https://apse1.dev.api.affinidi.io/vfs/v1/accounts'),
      );
      expect(
        Environment.fetchVaultAccountsAudienceUrl(dev),
        equals('https://apse1.dev.api.affinidi.io/vfs/v1/accounts'),
      );
      expect(
        Environment.fetchVaultAccountsAudienceUrl(prod),
        equals('https://apse1.api.affinidi.io/vfs/v1/accounts'),
      );
      expect(
        Environment.fetchVaultAccountsAudienceUrl(
          null,
          envTypeLocal,
          mumbaiRegion,
        ),
        equals('https://aps1.dev.api.affinidi.io/vfs/v1/accounts'),
      );
      expect(
        Environment.fetchVaultAccountsAudienceUrl(
          null,
          envTypeDev,
          mumbaiRegion,
        ),
        equals('https://aps1.dev.api.affinidi.io/vfs/v1/accounts'),
      );
      expect(
        Environment.fetchVaultAccountsAudienceUrl(
          null,
          envTypeProd,
          mumbaiRegion,
        ),
        equals('https://aps1.api.affinidi.io/vfs/v1/accounts'),
      );
    });

    test('Vault account audience URL defaults to prod', () {
      expect(
        Environment.fetchVaultAccountsAudienceUrl(),
        equals('https://apse1.api.affinidi.io/vfs/v1/accounts'),
      );
    });
  });

  group('Vault Utils Tests', () {
    test('Elements Vault API URLs are correct', () {
      expect(
        VaultUtils.fetchElementsVaultApiUrl(local),
        equals('http://localhost:3000'),
      );
      expect(
        VaultUtils.fetchElementsVaultApiUrl(dev),
        equals('https://dev.api.vault.affinidi.com'),
      );
      expect(
        VaultUtils.fetchElementsVaultApiUrl(prod),
        equals('https://api.vault.affinidi.com'),
      );
    });

    test('Web Vault URLs are correct', () {
      expect(
        VaultUtils.fetchWebVaultUrl(local),
        equals('http://localhost:3001'),
      );
      expect(
        VaultUtils.fetchWebVaultUrl(dev),
        equals('https://vault.dev.affinidi.com'),
      );
      expect(
        VaultUtils.fetchWebVaultUrl(prod),
        equals('https://vault.affinidi.com'),
      );
    });

    test('Vault URL defaults to prod', () {
      expect(
        VaultUtils.fetchElementsVaultApiUrl(),
        equals('https://api.vault.affinidi.com'),
      );
    });

    test('Web Vault URL defaults to prod', () {
      expect(
        VaultUtils.fetchWebVaultUrl(),
        equals('https://vault.affinidi.com'),
      );
    });

    test('buildShareLink constructs correct URL', () {
      const request = 'test/request';
      const clientId = 'test-client-id';
      expect(
        VaultUtils.buildShareLink(request, clientId),
        equals(
          'https://vault.affinidi.com/login?request=test%2Frequest&client_id=test-client-id',
        ),
      );
    });

    test('buildClaimLink constructs correct URL', () {
      const credentialOfferUri = 'test/credential/uri';
      expect(
        VaultUtils.buildClaimLink(credentialOfferUri),
        equals(
          'https://vault.affinidi.com/claim?credential_offer_uri=test%2Fcredential%2Furi',
        ),
      );
    });
  });
}
