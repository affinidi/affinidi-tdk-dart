import 'package:affinidi_tdk_vault/affinidi_tdk_vault.dart';

class FakeProfileRepository implements ProfileRepository {
  FakeProfileRepository(this.id);

  @override
  final String id;

  @override
  Future<void> configure(Object configuration) async {}

  @override
  Future<bool> isConfigured() async => true;

  @override
  Future<List<Profile>> listProfiles({VaultCancelToken? cancelToken}) async =>
      const [];

  @override
  Future<Profile> createProfile({
    required String name,
    String? description,
    VaultCancelToken? cancelToken,
  }) => throw UnimplementedError();

  @override
  Future<void> updateProfile(
    Profile profile, {
    VaultCancelToken? cancelToken,
  }) => throw UnimplementedError();

  @override
  Future<void> deleteProfile(
    Profile profile, {
    VaultCancelToken? cancelToken,
  }) => throw UnimplementedError();
}
