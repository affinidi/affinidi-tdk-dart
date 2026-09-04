import 'dart:async';

import 'package:affinidi_tdk_vault_edge_provider/affinidi_tdk_vault_edge_provider.dart';

class MockEdgeProfileRepository implements EdgeProfileRepositoryInterface {
  String? lastCalledCreateProfileName;
  String? lastCalledCreateProfileDescription;
  String? lastCalledCreateProfileId;
  int? lastCalledCreateProfileAccountIndex;
  int createProfileCallCount = 0;
  Completer<void>? createProfileCalled;
  Completer<String>? createProfileCompleter;
  String? lastCalledDeletedProfileId;
  EdgeProfile? lastCalledUpdateProfile;
  bool lastCalledListProfiles = false;
  List<EdgeProfile> listProfilesReturnValue = [];
  bool hasAnyContentReturnValue = false;
  String? lastCalledHasAnyContentProfileId;

  @override
  Future<String> createProfile({
    required String name,
    String? description,
    required int accountIndex,
    String? id,
    VaultCancelToken? cancelToken,
  }) async {
    createProfileCallCount++;
    if (createProfileCalled != null && !createProfileCalled!.isCompleted) {
      createProfileCalled!.complete();
    }
    lastCalledCreateProfileName = name;
    lastCalledCreateProfileDescription = description;
    lastCalledCreateProfileId = id;
    lastCalledCreateProfileAccountIndex = accountIndex;
    if (createProfileCompleter != null) {
      return createProfileCompleter!.future;
    }
    return id ?? 'mock_profile_id';
  }

  @override
  Future<void> deleteProfile({
    required String profileId,
    VaultCancelToken? cancelToken,
  }) async {
    lastCalledDeletedProfileId = profileId;
  }

  @override
  Future<List<EdgeProfile>> listProfiles({
    VaultCancelToken? cancelToken,
  }) async {
    lastCalledListProfiles = true;
    return listProfilesReturnValue;
  }

  @override
  Future<void> updateProfile({
    required EdgeProfile profile,
    VaultCancelToken? cancelToken,
  }) async {
    lastCalledUpdateProfile = profile;
  }

  @override
  Future<bool> hasAnyContent(String profileId) async {
    lastCalledHasAnyContentProfileId = profileId;
    return hasAnyContentReturnValue;
  }
}
