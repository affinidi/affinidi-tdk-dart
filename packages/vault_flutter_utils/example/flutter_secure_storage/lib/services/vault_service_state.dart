import 'package:affinidi_tdk_vault/affinidi_tdk_vault.dart';

class VaultServiceState {
  const VaultServiceState({this.error, this.vault});

  final String? error;
  final Vault? vault;

  static const _unset = Object();

  VaultServiceState copyWith({Object? error = _unset, Object? vault = _unset}) {
    return VaultServiceState(
      error: identical(error, _unset) ? this.error : error as String?,
      vault: identical(vault, _unset) ? this.vault : vault as Vault?,
    );
  }
}
