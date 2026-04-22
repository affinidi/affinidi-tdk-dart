// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'patch_account_input.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$PatchAccountInput extends PatchAccountInput {
  @override
  final String didProof;
  @override
  final String encryptedDekek;
  @override
  final String ownerProfileId;
  @override
  final String ownerProfileDid;

  factory _$PatchAccountInput([
    void Function(PatchAccountInputBuilder)? updates,
  ]) => (PatchAccountInputBuilder()..update(updates))._build();

  _$PatchAccountInput._({
    required this.didProof,
    required this.encryptedDekek,
    required this.ownerProfileId,
    required this.ownerProfileDid,
  }) : super._();
  @override
  PatchAccountInput rebuild(void Function(PatchAccountInputBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  PatchAccountInputBuilder toBuilder() =>
      PatchAccountInputBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is PatchAccountInput &&
        didProof == other.didProof &&
        encryptedDekek == other.encryptedDekek &&
        ownerProfileId == other.ownerProfileId &&
        ownerProfileDid == other.ownerProfileDid;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, didProof.hashCode);
    _$hash = $jc(_$hash, encryptedDekek.hashCode);
    _$hash = $jc(_$hash, ownerProfileId.hashCode);
    _$hash = $jc(_$hash, ownerProfileDid.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'PatchAccountInput')
          ..add('didProof', didProof)
          ..add('encryptedDekek', encryptedDekek)
          ..add('ownerProfileId', ownerProfileId)
          ..add('ownerProfileDid', ownerProfileDid))
        .toString();
  }
}

class PatchAccountInputBuilder
    implements Builder<PatchAccountInput, PatchAccountInputBuilder> {
  _$PatchAccountInput? _$v;

  String? _didProof;
  String? get didProof => _$this._didProof;
  set didProof(String? didProof) => _$this._didProof = didProof;

  String? _encryptedDekek;
  String? get encryptedDekek => _$this._encryptedDekek;
  set encryptedDekek(String? encryptedDekek) =>
      _$this._encryptedDekek = encryptedDekek;

  String? _ownerProfileId;
  String? get ownerProfileId => _$this._ownerProfileId;
  set ownerProfileId(String? ownerProfileId) =>
      _$this._ownerProfileId = ownerProfileId;

  String? _ownerProfileDid;
  String? get ownerProfileDid => _$this._ownerProfileDid;
  set ownerProfileDid(String? ownerProfileDid) =>
      _$this._ownerProfileDid = ownerProfileDid;

  PatchAccountInputBuilder() {
    PatchAccountInput._defaults(this);
  }

  PatchAccountInputBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _didProof = $v.didProof;
      _encryptedDekek = $v.encryptedDekek;
      _ownerProfileId = $v.ownerProfileId;
      _ownerProfileDid = $v.ownerProfileDid;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(PatchAccountInput other) {
    _$v = other as _$PatchAccountInput;
  }

  @override
  void update(void Function(PatchAccountInputBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  PatchAccountInput build() => _build();

  _$PatchAccountInput _build() {
    final _$result =
        _$v ??
        _$PatchAccountInput._(
          didProof: BuiltValueNullFieldError.checkNotNull(
            didProof,
            r'PatchAccountInput',
            'didProof',
          ),
          encryptedDekek: BuiltValueNullFieldError.checkNotNull(
            encryptedDekek,
            r'PatchAccountInput',
            'encryptedDekek',
          ),
          ownerProfileId: BuiltValueNullFieldError.checkNotNull(
            ownerProfileId,
            r'PatchAccountInput',
            'ownerProfileId',
          ),
          ownerProfileDid: BuiltValueNullFieldError.checkNotNull(
            ownerProfileDid,
            r'PatchAccountInput',
            'ownerProfileDid',
          ),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
