import 'dart:async';

import 'package:affinidi_tdk_didcomm_mediator_client/affinidi_tdk_didcomm_mediator_client.dart';
import 'package:affinidi_tdk_iota_client/affinidi_tdk_iota_client.dart';
import 'package:affinidi_tdk_vault/affinidi_tdk_vault.dart';
import 'package:affinidi_tdk_vault_data_manager/affinidi_tdk_vault_data_manager.dart';
import 'package:ssi/ssi.dart';
import 'package:uuid/uuid.dart';

import '../../integration_tests/test/helpers/environment.dart';

import 'iota_setup.dart';

const _emailCredentialType = 'Email';
const _defaultProfileName = 'Default Profile';

void main() async {
  // Run commands below in your terminal to generate keys for Receiver:
  // openssl rand -hex 32 > example/keys/alice_seed.txt

  final walletSetup = await ensureWalletCreated();
  prettyPrint('Wallet ARI', object: walletSetup.walletAri);
  prettyPrint('Business DID', object: walletSetup.businessDid);

  final vault = await _initializeVault(businessDids: [walletSetup.businessDid]);
  await _initializeProfiles(vault);

  final defaultProfile = (await vault.listProfiles()).firstWhere(
    (profile) => profile.name == _defaultProfileName,
  );

  await _initializeCredentials(defaultProfile);

  prettyPrint('Messaging DID', object: vault.messagingDid);

  final iotaConfig = await ensureIotaConfigurationCreated(
    walletAri: walletSetup.walletAri,
  );
  prettyPrint('IOTA Configuration ID', object: iotaConfig.configurationId);
  prettyPrint('IOTA Query ID', object: iotaConfig.queryId);

  final holderCompleted = Completer<void>();

  vault.listenForVdspRequests(
    onDataRequest: (message) async {
      if (defaultProfile.defaultCredentialStorage == null) {
        throw Exception(
          'Default Credential Storage was not configured in the vault',
        );
      }

      final queryResult = await vault.filterCredentialsForVdspQueryDataMessage(
        message,
        credentialStorage: defaultProfile.defaultCredentialStorage!,
      );

      if (!queryResult.dcqlResult!.fulfilled) {
        prettyPrint(
          'No credentials matched the query criteria',
          object: queryResult.dcqlResult,
        );
        return;
      }

      prettyPrint(
        'Credentials matching the query',
        object: queryResult.verifiableCredentials,
      );

      await vault.sendVdspDataResponse(
        requestMessage: message,
        verifiableCredentials: queryResult.verifiableCredentials,
        profile: defaultProfile,
        verifiablePresentationDataModel: VerifiableCredentialsDataModel.v1,
      );

      holderCompleted.complete();
    },
    onProblemReport: (message) async {
      prettyPrint('A problem has occurred', object: message);
      await ConnectionPool.instance.stopConnections();
    },
  );

  await ConnectionPool.instance.startConnections();

  final initiateResult = await _triggerIotaVdspRequest(
    configurationId: iotaConfig.configurationId,
    queryId: iotaConfig.queryId,
    holderDid: vault.messagingDid,
  );

  await holderCompleted.future;

  await Future<void>.delayed(
    const Duration(seconds: 10),
  ); // Wait for VP response to be ready

  final vpResponse = await _fetchIotaVdspResponse(
    configurationId: iotaConfig.configurationId,
    correlationId: initiateResult.correlationId,
    transactionId: initiateResult.transactionId,
  );

  prettyPrint('Verifier received Data Response Message', object: vpResponse);

  final presentationAndCredentialsAreValid =
      vpResponse != null &&
      (vpResponse.vpToken != null && vpResponse.vpToken!.isNotEmpty);
  prettyPrint(
    'VP and VCs are valid',
    object: presentationAndCredentialsAreValid,
  );

  prettyPrint('Verifiable Presentation', object: vpResponse?.vpToken);

  prettyPrint(
    'Presentation Submission',
    object: vpResponse?.presentationSubmission,
  );

  prettyPrint(
    'Verification result',
    object: presentationAndCredentialsAreValid,
  );
  await ConnectionPool.instance.stopConnections();
}

Future<Vault> _initializeVault({required List<String> businessDids}) async {
  final seed = await extractSeed('keys/alice_seed.txt');

  final vaultStore = InMemoryVaultStore();
  final accountIndex = 42;

  await vaultStore.setAccountIndex(accountIndex);
  await vaultStore.setSeed(seed);

  const vfsRepositoryId = 'vfs';
  final profileRepositories = <String, ProfileRepository>{
    vfsRepositoryId: VfsProfileRepository(vfsRepositoryId),
  };

  final vault = await Vault.fromVaultStore(
    vaultStore,
    profileRepositories: profileRepositories,
    defaultProfileRepositoryId: vfsRepositoryId,
    businessDids: businessDids,
  );

  await vault.ensureInitialized();
  print('Vault initialized successfully.');

  return vault;
}

Future<void> _initializeProfiles(Vault vault) async {
  final profiles = await vault.listProfiles();

  final hasDefaultProfile = profiles.any(
    (profile) => profile.name == _defaultProfileName,
  );

  if (!hasDefaultProfile) {
    print('Creating Default Profile...');

    await vault.defaultProfileRepository.createProfile(
      name: _defaultProfileName,
    );
  }

  print('Profiles are ready.');
}

Future<void> _initializeCredentials(Profile profile) async {
  final credentials = await profile.defaultCredentialStorage!.listCredentials();

  final hasEmailCredential = credentials.items.any(
    (credential) =>
        credential.verifiableCredential.type.contains(_emailCredentialType),
  );

  if (!hasEmailCredential) {
    print('Creating Email Credential...');

    final emailCredential = await _createEmailCredential(
      email: 'user@example.com',
      holderDid: profile.did,
    );

    await profile.defaultCredentialStorage!.saveCredential(
      verifiableCredential: emailCredential,
    );
  }

  print('Credentials are ready.');
}

Future<VerifiableCredential> _createEmailCredential({
  required String email,
  required String holderDid,
}) async {
  final issuerKeyStore = InMemoryKeyStore();
  final issuerWallet = PersistentWallet(issuerKeyStore);

  final issuerKeyId = 'issuer-key-1';
  await issuerWallet.generateKey(keyType: KeyType.p256, keyId: issuerKeyId);

  final issuerDidManager = DidKeyManager(
    wallet: issuerWallet,
    store: InMemoryDidStore(),
  );

  await issuerDidManager.addVerificationMethod(issuerKeyId);

  final issuerSigner = await issuerDidManager.getSigner(
    issuerDidManager.assertionMethod.first,
  );

  final unsignedCredential = VcDataModelV1(
    context: JsonLdContext.fromJson([
      dmV1ContextUrl,
      'https://schema.affinidi.io/TEmailV1R0.jsonld',
    ]),
    credentialSchema: [
      CredentialSchema(
        id: Uri.parse('https://schema.affinidi.io/TEmailV1R0.json'),
        type: 'JsonSchemaValidator2018',
      ),
    ],
    id: Uri.parse(const Uuid().v4()),
    issuer: Issuer.uri(issuerSigner.did),
    issuanceDate: DateTime.now().toUtc(),
    type: {'VerifiableCredential', _emailCredentialType},
    credentialSubject: [
      CredentialSubject.fromJson({'id': holderDid, 'email': email}),
    ],
  );

  final suite = LdVcDm1Suite();
  final issuedCredential = await suite.issue(
    unsignedData: unsignedCredential,
    proofGenerator: Secp256k1Signature2019Generator(signer: issuerSigner),
  );

  return issuedCredential;
}

class _InitiateResult {
  _InitiateResult({required this.correlationId, required this.transactionId});
  final String correlationId;
  final String transactionId;
}

Future<_InitiateResult> _triggerIotaVdspRequest({
  required String configurationId,
  required String queryId,
  required String holderDid,
}) async {
  final iotaApi = getIotaApi();

  final correlationId = const Uuid().v4();
  final nonce = correlationId.substring(0, 10);

  final input =
      (InitiateDataSharingRequestInputBuilder()
            ..configurationId = configurationId
            ..queryId = queryId
            ..correlationId = correlationId
            ..nonce = nonce
            ..redirectUri = 'https://cis-qc-1.vercel.app/iota-callback'
            ..mode = InitiateDataSharingRequestInputModeEnum.didcomm
            ..userDid = holderDid)
          .build();

  final response = await iotaApi.initiateDataSharingRequest(
    initiateDataSharingRequestInput: input,
  );

  final data = response.data?.data;

  if (data == null) {
    throw Exception('Failed to initiate IOTA data sharing request');
  }

  return _InitiateResult(
    correlationId: data.correlationId,
    transactionId: data.transactionId,
  );
}

Future<FetchIOTAVPResponseOK?> _fetchIotaVdspResponse({
  required String configurationId,
  required String correlationId,
  required String transactionId,
}) async {
  final iotaApi = getIotaApi();

  try {
    final input =
        (FetchIOTAVPResponseInputBuilder()
              ..configurationId = configurationId
              ..correlationId = correlationId
              ..transactionId = transactionId
              ..responseCode = transactionId)
            .build();
    final response = await iotaApi.fetchIotaVpResponse(
      fetchIOTAVPResponseInput: input,
    );
    final data = response.data;
    if (data?.vpToken != null || data?.presentationSubmission != null) {
      return data;
    }
  } catch (e, stackTrace) {
    print('Error fetching IOTA VP response:');
    print(e);
    print(stackTrace);
  }
  return null;
}
