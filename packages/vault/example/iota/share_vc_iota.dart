import 'package:affinidi_tdk_didcomm_mediator_client/affinidi_tdk_didcomm_mediator_client.dart'
    hide CredentialFormat;
import 'package:affinidi_tdk_vault/affinidi_tdk_vault.dart';
import 'package:affinidi_tdk_vault_data_manager/affinidi_tdk_vault_data_manager.dart';
import 'package:affinidi_tdk_vdsp/affinidi_tdk_vdsp.dart';
import 'package:dcql/dcql.dart';
import 'package:ssi/ssi.dart';
import 'package:uuid/uuid.dart';

import '../../../integration_tests/test/helpers/environment.dart';
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

  final configurationId = await ensureIotaConfigurationCreated(
    walletAri: walletSetup.walletAri,
  );
  prettyPrint('IOTA Configuration ID', object: configurationId);

  vault.listenForVdspRequests(
    onDataRequest: (message) async {
      if (defaultProfile.defaultCredentialStorage == null) {
        throw Exception(
          'Default Credential Storage was not configured in the vault',
        );
      }

      // Here you can select a profile and storage if you have multiple ones.
      // For simplicity, we use the default profile and its default credential storage.
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

      // Make sure a user reviews which credentials will be shared
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
    },
    onProblemReport: (message) async {
      prettyPrint('A problem has occurred', object: message);
      await ConnectionPool.instance.stopConnections();
    },
  );

  final verifier = await _initializeVerifier();

  final verifierChallenge = const Uuid().v4();
  final verifierDomain = 'test.verifier.com';

  verifier.listenForIncomingMessages(
    onDataResponse:
        ({
          required VdspDataResponseMessage message,
          required bool presentationAndCredentialsAreValid,
          VerifiablePresentation? verifiablePresentation,
          required VerificationResult presentationVerificationResult,
          required List<VerificationResult> credentialVerificationResults,
        }) async {
          prettyPrint(
            'Verifier received Data Response Message',
            object: message,
          );

          prettyPrint(
            'VP and VCs are valid',
            object: presentationAndCredentialsAreValid,
          );

          prettyPrint(
            'Verifiable Presentation',
            object: verifiablePresentation,
          );

          if (message.from != vault.messagingDid) {
            throw Exception('Unexpected sender DID: ${message.from}');
          }
          // domain and challenge check to prevent replay attacks
          final result =
              presentationAndCredentialsAreValid &&
              verifiablePresentation?.proof.first.challenge ==
                  verifierChallenge &&
              verifiablePresentation!.proof.first.domain?.first ==
                  verifierDomain;

          prettyPrint('Verification result', object: result);
          await ConnectionPool.instance.stopConnections();
        },
    onProblemReport: (message) async {
      prettyPrint('A problem has occurred', object: message);
      await ConnectionPool.instance.stopConnections();
    },
  );

  await ConnectionPool.instance.startConnections();

  await Future.wait([
    _configureAcl(
      mediatorDidDocument: verifier.mediatorClient.mediatorDidDocument,
      didManager: verifier.didManager,
      theirDids: [vault.messagingDid],
    ),
    _configureAcl(
      mediatorDidDocument: verifier.mediatorClient.mediatorDidDocument,
      didManager: vault.didManager,
      theirDids: [(await verifier.didManager.getDidDocument()).id],
    ),
  ]);

  await verifier.queryHolderData(
    holderDid: vault.messagingDid,
    dcqlQuery: DcqlCredentialQuery(
      credentials: [
        DcqlCredential(
          id: const Uuid().v4(),
          format: CredentialFormat.ldpVc,
          claims: [
            DcqlClaim(path: ['credentialSubject', 'email']),
          ],
        ),
      ],
    ),
    operation: 'registerAgent',
    proofContext: VdspQueryDataProofContext(
      challenge: verifierChallenge,
      domain: verifierDomain,
    ),
  );
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

Future<VdspVerifier> _initializeVerifier() async {
  final verifierKeyStore = InMemoryKeyStore();
  final verifierWallet = PersistentWallet(verifierKeyStore);

  final verifierDidManager = DidKeyManager(
    wallet: verifierWallet,
    store: InMemoryDidStore(),
  );

  final verifierKeyId = 'verifier-key-1';

  await verifierWallet.generateKey(
    keyType: KeyType.secp256k1,
    keyId: verifierKeyId,
  );
  await verifierDidManager.addVerificationMethod(verifierKeyId);

  // Resolve mediator DID from IOTA DID (did:web:did.affinidi.io:amb)
  final mediatorIotaDidDocument = await UniversalDIDResolver.defaultResolver
      .resolveDid(mediatorIotaDid);

  final mediatorService = mediatorIotaDidDocument.service
      .where((service) => service.type.toString() == 'DIDCommMessaging')
      .firstOrNull;

  if (mediatorService == null) {
    throw Exception(
      'No DIDCommMessaging service found when resolving $mediatorIotaDid',
    );
  }

  final mediatorDid = mediatorService.id.split('#').first;

  final mediatorDidDocument = await UniversalDIDResolver.defaultResolver
      .resolveDid(mediatorDid);

  return await VdspVerifier.init(
    mediatorDidDocument: mediatorDidDocument,
    didManager: verifierDidManager,
    clientOptions: const AffinidiClientOptions(),
    authorizationProvider: await AffinidiAuthorizationProvider.init(
      mediatorDidDocument: mediatorDidDocument,
      didManager: verifierDidManager,
    ),
  );
}

Future<void> _configureAcl({
  required DidDocument mediatorDidDocument,
  required DidManager didManager,
  required List<String> theirDids,
  DateTime? expiresTime,
}) async {
  final ownDidDocument = await didManager.getDidDocument();

  final mediatorClient = await DidcommMediatorClient.init(
    mediatorDidDocument: mediatorDidDocument,
    didManager: didManager,
    authorizationProvider: await AffinidiAuthorizationProvider.init(
      mediatorDidDocument: mediatorDidDocument,
      didManager: didManager,
    ),
    clientOptions: const AffinidiClientOptions(),
  );

  final accessListAddMessage = AccessListAddMessage(
    id: const Uuid().v4(),
    from: ownDidDocument.id,
    to: [mediatorClient.mediatorDidDocument.id],
    theirDids: theirDids,
    expiresTime: expiresTime,
  );

  await mediatorClient.sendAclManagementMessage(accessListAddMessage);
}
