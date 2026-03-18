import 'dart:math';
import 'dart:typed_data';

import 'package:affinidi_tdk_vault/affinidi_tdk_vault.dart';
import 'package:affinidi_tdk_vault_data_manager/affinidi_tdk_vault_data_manager.dart';

void main() async {
  final labelAlice = 'Alice';
  final accountIndexAlice = 15;
  final vaultAlice = await _createVault(
    labelAlice,
    accountIndexAlice,
    seedIndex: 1,
  );
  final profileAlice = await _createProfile(
    vaultAlice,
    labelAlice,
    accountIndexAlice,
  );

  print('[Demo] Alice is adding a file ...');
  final timestamp = DateTime.now().millisecondsSinceEpoch;
  final random = Random().nextInt(1000000);
  final fileName = 'alice_file1_$timestamp-$random.txt';
  final file = await _addFileToProfile(profileAlice, profileAlice.id, fileName);

  final labelBob = 'Bob';
  final accountIndexBob = 15;
  final vaultBob = await _createVault(labelBob, accountIndexBob, seedIndex: 2);
  final profileBob = await _createProfile(vaultBob, labelBob, accountIndexBob);

  await _shareFile(
    fromVault: vaultAlice,
    toVault: vaultBob,
    fromProfile: profileAlice,
    toProfile: profileBob,
    file: file,
    permissions: [Permissions.read],
  );

  await _cleanupProfile(profileAlice, vaultAlice);
  await _cleanupProfile(profileBob, vaultBob);
}

Future<void> _shareFile({
  required Vault fromVault,
  required Vault toVault,
  required Profile fromProfile,
  required Profile toProfile,
  required Item file,
  required List<Permissions> permissions,
}) async {
  print(
    '[Demo] Sharing ${file.name} from ${fromProfile.name} to ${toProfile.name} ...',
  );
  final granteeDid = toProfile.did;

  var policy = await fromVault.getItemPermissionsPolicy(
    profileId: fromProfile.id,
    granteeDid: granteeDid,
  );

  policy.addPermission([file.id], permissions);

  final kek1 = await fromVault.setItemAccess(
    profileId: fromProfile.id,
    granteeDid: granteeDid,
    policy: policy,
  );

  final sharedItems = SharedItemsDto(
    kek: kek1,
    ownerProfileId: fromProfile.id,
    ownerProfileDID: fromProfile.did,
    itemIds: [file.id], // Can include multiple item IDs
  );

  await toVault.acceptSharedItems(
    profileId: toProfile.id,
    sharedItems: sharedItems,
  );

  print('[Demo] Sharing completed successfully');
}

Future<Vault> _createVault(
  String label,
  int accountIndex, {
  required int seedIndex,
}) async {
  print('[Demo] Initializing Vault $label ...');
  final keyStorage = InMemoryVaultStore();
  await keyStorage.setAccountIndex(accountIndex);

  final seed = Uint8List.fromList(List.generate(32, (idx) => idx + seedIndex));
  await keyStorage.setSeed(seed);

  const vfsRepositoryId = 'vfs';
  final profileRepositories = <String, ProfileRepository>{
    vfsRepositoryId: VfsProfileRepository(vfsRepositoryId),
  };

  final vault = await Vault.fromVaultStore(
    keyStorage,
    profileRepositories: profileRepositories,
    defaultProfileRepositoryId: vfsRepositoryId,
  );

  await vault.ensureInitialized();

  // Only needed to reuse account index when running test multiple times
  await _cleanupInitialProfilesIfNeeded(vault, label);

  return vault;
}

Future<void> _cleanupInitialProfilesIfNeeded(Vault vault, String label) async {
  print('[Demo] Retrieving $label Profiles ...');
  var profiles = await vault.listProfiles();
  print(
    '[Demo] ${profiles.isEmpty ? 'No profiles found' : 'Available profiles: ${profiles.length}'}',
  );
  _listProfileNames(profiles, label: 'Initial profile names');

  final hadProfiles = profiles.isNotEmpty;
  if (hadProfiles) {
    print('[Demo] Starting $label profile cleanup...');
    for (var profile in profiles) {
      print('[Demo] Deleting $label profile: ${profile.name}');
      await _deleteProfile(vault, profile);
    }

    profiles = await vault.listProfiles();
    if (profiles.isNotEmpty) {
      throw Exception('Cleanup failed: Found remaining profiles');
    }
    print('[Demo] All $label profiles successfully deleted');
  }
}

Future<void> _cleanupProfile(Profile profile, Vault vault) async {
  print('[Demo] ${profile.name} is deleting all files...');
  final storage = profile.defaultFileStorage!;
  final filesPage = await storage.getFolder(folderId: profile.id);
  await Future.wait(
    filesPage.items.map((item) => storage.deleteFile(fileId: item.id)),
  );

  print('[Demo] ${profile.name} is deleting all profiles...');
  final profiles = await vault.listProfiles();
  await Future.wait(profiles.map((p) => _deleteProfile(vault, p)));
}

Future<void> _deleteProfile(Vault vault, Profile profile) async {
  await _deleteFolder(vault: vault, profile: profile, folderId: profile.id);
  await vault.defaultProfileRepository.deleteProfile(profile);
}

Future<void> _deleteFolder({
  required Vault vault,
  required Profile profile,
  required String folderId,
}) async {
  String? exclusiveStartItemId;
  final storage = profile.defaultFileStorage!;
  try {
    do {
      final page = await storage.getFolder(
        folderId: folderId,
        limit: 20,
        exclusiveStartItemId: exclusiveStartItemId,
      );

      for (final item in page.items) {
        if (item is Folder) {
          await _deleteFolder(
            vault: vault,
            profile: profile,
            folderId: item.id,
          );
        } else if (item is File) {
          await storage.deleteFile(fileId: item.id);
        }
      }

      exclusiveStartItemId = page.lastEvaluatedItemId;
    } while (exclusiveStartItemId != null);
  } catch (e) {
    print(
      '[Demo] Error while deleting folder $folderId in profile ${profile.name}: ${e.toString()}',
    );
  }
  if (folderId != profile.id) {
    await storage.deleteFolder(folderId: folderId);
  }
}

Future<Profile> _createProfile(
  Vault vault,
  String name,
  int accountIndex,
) async {
  final newAccountIndex = accountIndex + 1;
  final existingProfiles = await vault.listProfiles();
  final existingProfile = existingProfiles
      .where((profile) => profile.accountIndex == newAccountIndex)
      .firstOrNull;

  if (existingProfile == null) {
    print('[Demo] Creating profile for $name ...');
    try {
      final profileRepository = vault.defaultProfileRepository;
      await profileRepository.createProfile(name: '$name $newAccountIndex');
    } on TdkException catch (error) {
      print(
        [
          error.code,
          '[Demo] ${error.message}',
          error.originalMessage,
        ].join('\n'),
      );
      rethrow;
    }
  }

  final profiles = await vault.listProfiles();
  _listProfileNames(profiles, label: name);

  final profile = profiles
      .where((p) => p.accountIndex == newAccountIndex)
      .firstOrNull;

  if (profile == null) {
    throw UnsupportedError('Failed to create profile for $name');
  }

  return profile;
}

Future<Item> _addFileToProfile(
  Profile profile,
  String folderId,
  String fileName,
) async {
  final storage = profile.defaultFileStorage!;
  final fileContent = Uint8List.fromList([1, 2, 3]);
  await storage.createFile(
    fileName: fileName,
    data: fileContent,
    parentFolderId: folderId,
  );

  final page = await storage.getFolder(folderId: folderId);

  final file = page.items.where((item) => item.name == fileName).firstOrNull;

  if (file == null) {
    throw UnsupportedError(
      'Failed to create file $fileName in profile ${profile.name}',
    );
  }

  return file;
}

void _listProfileNames(List<Profile> profiles, {required String label}) {
  if (profiles.isEmpty) {
    print('[Demo] List of profiles is empty');
    return;
  }

  final names = profiles
      .map(
        (profile) =>
            '${profile.name} | ${profile.accountIndex} | ${profile.did} ',
      )
      .join(', ');
  print('[Demo] $label: $names');
}
