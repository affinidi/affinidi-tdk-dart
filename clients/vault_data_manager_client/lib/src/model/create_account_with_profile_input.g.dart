// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_account_with_profile_input.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$CreateAccountWithProfileInput extends CreateAccountWithProfileInput {
  @override
  final int accountIndex;
  @override
  final String accountDid;
  @override
  final String didProof;
  @override
  final String? alias;
  @override
  final JsonObject? accountMetadata;
  @override
  final String? accountDescription;
  @override
  final String profileName;
  @override
  final String? profileDescription;
  @override
  final JsonObject? profileMetadata;
  @override
  final EdekInfo edekInfo;
  @override
  final String dek;

  factory _$CreateAccountWithProfileInput([
    void Function(CreateAccountWithProfileInputBuilder)? updates,
  ]) => (CreateAccountWithProfileInputBuilder()..update(updates))._build();

  _$CreateAccountWithProfileInput._({
    required this.accountIndex,
    required this.accountDid,
    required this.didProof,
    this.alias,
    this.accountMetadata,
    this.accountDescription,
    required this.profileName,
    this.profileDescription,
    this.profileMetadata,
    required this.edekInfo,
    required this.dek,
  }) : super._();
  @override
  CreateAccountWithProfileInput rebuild(
    void Function(CreateAccountWithProfileInputBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  CreateAccountWithProfileInputBuilder toBuilder() =>
      CreateAccountWithProfileInputBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is CreateAccountWithProfileInput &&
        accountIndex == other.accountIndex &&
        accountDid == other.accountDid &&
        didProof == other.didProof &&
        alias == other.alias &&
        accountMetadata == other.accountMetadata &&
        accountDescription == other.accountDescription &&
        profileName == other.profileName &&
        profileDescription == other.profileDescription &&
        profileMetadata == other.profileMetadata &&
        edekInfo == other.edekInfo &&
        dek == other.dek;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, accountIndex.hashCode);
    _$hash = $jc(_$hash, accountDid.hashCode);
    _$hash = $jc(_$hash, didProof.hashCode);
    _$hash = $jc(_$hash, alias.hashCode);
    _$hash = $jc(_$hash, accountMetadata.hashCode);
    _$hash = $jc(_$hash, accountDescription.hashCode);
    _$hash = $jc(_$hash, profileName.hashCode);
    _$hash = $jc(_$hash, profileDescription.hashCode);
    _$hash = $jc(_$hash, profileMetadata.hashCode);
    _$hash = $jc(_$hash, edekInfo.hashCode);
    _$hash = $jc(_$hash, dek.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'CreateAccountWithProfileInput')
          ..add('accountIndex', accountIndex)
          ..add('accountDid', accountDid)
          ..add('didProof', didProof)
          ..add('alias', alias)
          ..add('accountMetadata', accountMetadata)
          ..add('accountDescription', accountDescription)
          ..add('profileName', profileName)
          ..add('profileDescription', profileDescription)
          ..add('profileMetadata', profileMetadata)
          ..add('edekInfo', edekInfo)
          ..add('dek', dek))
        .toString();
  }
}

class CreateAccountWithProfileInputBuilder
    implements
        Builder<
          CreateAccountWithProfileInput,
          CreateAccountWithProfileInputBuilder
        > {
  _$CreateAccountWithProfileInput? _$v;

  int? _accountIndex;
  int? get accountIndex => _$this._accountIndex;
  set accountIndex(int? accountIndex) => _$this._accountIndex = accountIndex;

  String? _accountDid;
  String? get accountDid => _$this._accountDid;
  set accountDid(String? accountDid) => _$this._accountDid = accountDid;

  String? _didProof;
  String? get didProof => _$this._didProof;
  set didProof(String? didProof) => _$this._didProof = didProof;

  String? _alias;
  String? get alias => _$this._alias;
  set alias(String? alias) => _$this._alias = alias;

  JsonObject? _accountMetadata;
  JsonObject? get accountMetadata => _$this._accountMetadata;
  set accountMetadata(JsonObject? accountMetadata) =>
      _$this._accountMetadata = accountMetadata;

  String? _accountDescription;
  String? get accountDescription => _$this._accountDescription;
  set accountDescription(String? accountDescription) =>
      _$this._accountDescription = accountDescription;

  String? _profileName;
  String? get profileName => _$this._profileName;
  set profileName(String? profileName) => _$this._profileName = profileName;

  String? _profileDescription;
  String? get profileDescription => _$this._profileDescription;
  set profileDescription(String? profileDescription) =>
      _$this._profileDescription = profileDescription;

  JsonObject? _profileMetadata;
  JsonObject? get profileMetadata => _$this._profileMetadata;
  set profileMetadata(JsonObject? profileMetadata) =>
      _$this._profileMetadata = profileMetadata;

  EdekInfoBuilder? _edekInfo;
  EdekInfoBuilder get edekInfo => _$this._edekInfo ??= EdekInfoBuilder();
  set edekInfo(EdekInfoBuilder? edekInfo) => _$this._edekInfo = edekInfo;

  String? _dek;
  String? get dek => _$this._dek;
  set dek(String? dek) => _$this._dek = dek;

  CreateAccountWithProfileInputBuilder() {
    CreateAccountWithProfileInput._defaults(this);
  }

  CreateAccountWithProfileInputBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _accountIndex = $v.accountIndex;
      _accountDid = $v.accountDid;
      _didProof = $v.didProof;
      _alias = $v.alias;
      _accountMetadata = $v.accountMetadata;
      _accountDescription = $v.accountDescription;
      _profileName = $v.profileName;
      _profileDescription = $v.profileDescription;
      _profileMetadata = $v.profileMetadata;
      _edekInfo = $v.edekInfo.toBuilder();
      _dek = $v.dek;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(CreateAccountWithProfileInput other) {
    _$v = other as _$CreateAccountWithProfileInput;
  }

  @override
  void update(void Function(CreateAccountWithProfileInputBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  CreateAccountWithProfileInput build() => _build();

  _$CreateAccountWithProfileInput _build() {
    _$CreateAccountWithProfileInput _$result;
    try {
      _$result =
          _$v ??
          _$CreateAccountWithProfileInput._(
            accountIndex: BuiltValueNullFieldError.checkNotNull(
              accountIndex,
              r'CreateAccountWithProfileInput',
              'accountIndex',
            ),
            accountDid: BuiltValueNullFieldError.checkNotNull(
              accountDid,
              r'CreateAccountWithProfileInput',
              'accountDid',
            ),
            didProof: BuiltValueNullFieldError.checkNotNull(
              didProof,
              r'CreateAccountWithProfileInput',
              'didProof',
            ),
            alias: alias,
            accountMetadata: accountMetadata,
            accountDescription: accountDescription,
            profileName: BuiltValueNullFieldError.checkNotNull(
              profileName,
              r'CreateAccountWithProfileInput',
              'profileName',
            ),
            profileDescription: profileDescription,
            profileMetadata: profileMetadata,
            edekInfo: edekInfo.build(),
            dek: BuiltValueNullFieldError.checkNotNull(
              dek,
              r'CreateAccountWithProfileInput',
              'dek',
            ),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'edekInfo';
        edekInfo.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
          r'CreateAccountWithProfileInput',
          _$failedField,
          e.toString(),
        );
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
