// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_account_with_profile_ok.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$CreateAccountWithProfileOK extends CreateAccountWithProfileOK {
  @override
  final int accountIndex;
  @override
  final String accountDid;
  @override
  final String profileId;
  @override
  final JsonObject? accountMetadata;

  factory _$CreateAccountWithProfileOK([
    void Function(CreateAccountWithProfileOKBuilder)? updates,
  ]) => (CreateAccountWithProfileOKBuilder()..update(updates))._build();

  _$CreateAccountWithProfileOK._({
    required this.accountIndex,
    required this.accountDid,
    required this.profileId,
    this.accountMetadata,
  }) : super._();
  @override
  CreateAccountWithProfileOK rebuild(
    void Function(CreateAccountWithProfileOKBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  CreateAccountWithProfileOKBuilder toBuilder() =>
      CreateAccountWithProfileOKBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is CreateAccountWithProfileOK &&
        accountIndex == other.accountIndex &&
        accountDid == other.accountDid &&
        profileId == other.profileId &&
        accountMetadata == other.accountMetadata;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, accountIndex.hashCode);
    _$hash = $jc(_$hash, accountDid.hashCode);
    _$hash = $jc(_$hash, profileId.hashCode);
    _$hash = $jc(_$hash, accountMetadata.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'CreateAccountWithProfileOK')
          ..add('accountIndex', accountIndex)
          ..add('accountDid', accountDid)
          ..add('profileId', profileId)
          ..add('accountMetadata', accountMetadata))
        .toString();
  }
}

class CreateAccountWithProfileOKBuilder
    implements
        Builder<CreateAccountWithProfileOK, CreateAccountWithProfileOKBuilder> {
  _$CreateAccountWithProfileOK? _$v;

  int? _accountIndex;
  int? get accountIndex => _$this._accountIndex;
  set accountIndex(int? accountIndex) => _$this._accountIndex = accountIndex;

  String? _accountDid;
  String? get accountDid => _$this._accountDid;
  set accountDid(String? accountDid) => _$this._accountDid = accountDid;

  String? _profileId;
  String? get profileId => _$this._profileId;
  set profileId(String? profileId) => _$this._profileId = profileId;

  JsonObject? _accountMetadata;
  JsonObject? get accountMetadata => _$this._accountMetadata;
  set accountMetadata(JsonObject? accountMetadata) =>
      _$this._accountMetadata = accountMetadata;

  CreateAccountWithProfileOKBuilder() {
    CreateAccountWithProfileOK._defaults(this);
  }

  CreateAccountWithProfileOKBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _accountIndex = $v.accountIndex;
      _accountDid = $v.accountDid;
      _profileId = $v.profileId;
      _accountMetadata = $v.accountMetadata;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(CreateAccountWithProfileOK other) {
    _$v = other as _$CreateAccountWithProfileOK;
  }

  @override
  void update(void Function(CreateAccountWithProfileOKBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  CreateAccountWithProfileOK build() => _build();

  _$CreateAccountWithProfileOK _build() {
    final _$result =
        _$v ??
        _$CreateAccountWithProfileOK._(
          accountIndex: BuiltValueNullFieldError.checkNotNull(
            accountIndex,
            r'CreateAccountWithProfileOK',
            'accountIndex',
          ),
          accountDid: BuiltValueNullFieldError.checkNotNull(
            accountDid,
            r'CreateAccountWithProfileOK',
            'accountDid',
          ),
          profileId: BuiltValueNullFieldError.checkNotNull(
            profileId,
            r'CreateAccountWithProfileOK',
            'profileId',
          ),
          accountMetadata: accountMetadata,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
