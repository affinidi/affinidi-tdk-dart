import 'package:affinidi_tdk_vault/affinidi_tdk_vault.dart';
import 'package:affinidi_tdk_vault_data_manager/affinidi_tdk_vault_data_manager.dart';
import 'package:didcomm/didcomm.dart';
import 'package:ssi/ssi.dart';
import 'package:uuid/uuid.dart';

import '../../integration_tests/test/helpers/environment.dart';

const _emailCredentialType = 'Email';
const _defaultProfileName = 'Default Profile';

void main() async {
  // Run commands below in your terminal to generate keys for Receiver:
  // openssl rand -hex 32 > example/keys/alice_seed.txt

  final vault = await _initializeVault();
  await _initializeProfiles(vault);

  final defaultProfile = (await vault.listProfiles()).firstWhere(
    (profile) => profile.name == _defaultProfileName,
  );

  await _initializeCredentials(defaultProfile);

  print('Messaging DID: ${vault.messagingDid}');

  vault.listenForVdipRequests(
    onDataRequest: (message) {},
    onProblemReport: (message) {},
  );

  await ConnectionPool.instance.startConnections();
}

Future<Vault> _initializeVault() async {
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

  final unsignedCredential = VcDataModelV2(
    context: JsonLdContext.fromJson([
      dmV2ContextUrl,
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
    type: {'VerifiableCredential', _emailCredentialType},
    credentialSubject: [
      CredentialSubject.fromJson({'id': holderDid, 'email': email}),
    ],
  );

  final suite = LdVcDm2Suite();
  final issuedCredential = await suite.issue(
    unsignedData: unsignedCredential,
    proofGenerator: DataIntegrityEcdsaJcsGenerator(signer: issuerSigner),
  );

  return issuedCredential;
}
