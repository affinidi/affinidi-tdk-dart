import 'dart:typed_data';

import '../helpers/vault_cancel_token.dart';
import '../permissions.dart';
import '../storage_interfaces/profile_access_sharing.dart';
import '../storage_interfaces/profile_repository.dart';

/// A decorator for [ProfileRepository] that also implements [ProfileAccessSharing]
/// and invalidates cache on sharing-related mutations.
class CacheInvalidatingProfileAccessSharing implements ProfileAccessSharing {
  /// Creates an instance of [CacheInvalidatingProfileAccessSharing].
  CacheInvalidatingProfileAccessSharing(
    this._accessSharing, {
    required void Function() onProfilesMutated,
  }) : _onProfilesMutated = onProfilesMutated;

  final ProfileAccessSharing _accessSharing;
  final void Function() _onProfilesMutated;

  @override
  Future<Uint8List> grantItemAccessMultiple({
    required int accountIndex,
    required String granteeDid,
    required List<
      ({List<String> itemIds, Permissions permissions, DateTime? expiresAt})
    >
    permissionGroups,
    VaultCancelToken? cancelToken,
  }) {
    return _accessSharing.grantItemAccessMultiple(
      accountIndex: accountIndex,
      granteeDid: granteeDid,
      permissionGroups: permissionGroups,
      cancelToken: cancelToken,
    );
  }

  @override
  Future<void> revokeItemAccess({
    required int accountIndex,
    required String granteeDid,
    required List<String> itemIds,
    VaultCancelToken? cancelToken,
  }) {
    return _accessSharing.revokeItemAccess(
      accountIndex: accountIndex,
      granteeDid: granteeDid,
      itemIds: itemIds,
      cancelToken: cancelToken,
    );
  }

  @override
  Future<Map<String, dynamic>> getItemAccess({
    required int accountIndex,
    required String granteeDid,
    VaultCancelToken? cancelToken,
  }) {
    return _accessSharing.getItemAccess(
      accountIndex: accountIndex,
      granteeDid: granteeDid,
      cancelToken: cancelToken,
    );
  }

  @override
  Future<void> receiveItemAccess({
    required int accountIndex,
    required String ownerProfileId,
    required Uint8List kek,
    required String ownerProfileDid,
    VaultCancelToken? cancelToken,
  }) async {
    await _accessSharing.receiveItemAccess(
      accountIndex: accountIndex,
      ownerProfileId: ownerProfileId,
      kek: kek,
      ownerProfileDid: ownerProfileDid,
      cancelToken: cancelToken,
    );
    _onProfilesMutated();
  }
}
