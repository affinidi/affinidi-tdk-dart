import 'package:affinidi_tdk_vault/affinidi_tdk_vault.dart';
import 'package:mocktail/mocktail.dart';

class MockProfileRepository extends Mock implements ProfileRepository {}

/// Builds a real [Profile] for tests, optionally wiring credential and file
/// storages so the default-storage getters resolve to injected mocks.
Profile buildTestProfile({
  required String did,
  required int accountIndex,
  String name = 'Profile',
  String? description,
  String? profilePictureURI,
  Map<String, CredentialStorage> credentialStorages = const {},
  Map<String, FileStorage> fileStorages = const {},
}) {
  return Profile(
    id: 'id-$did',
    accountIndex: accountIndex,
    name: name,
    did: did,
    description: description,
    profilePictureURI: profilePictureURI,
    profileRepositoryId: 'repo',
    fileStorages: fileStorages,
    credentialStorages: credentialStorages,
    sharedStorages: const {},
  );
}
