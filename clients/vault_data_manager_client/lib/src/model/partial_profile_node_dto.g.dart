// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'partial_profile_node_dto.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$PartialProfileNodeDto extends PartialProfileNodeDto {
  @override
  final String id;
  @override
  final String name;
  @override
  final String? description;
  @override
  final int accountIndex;
  @override
  final String? profileMetadata;
  @override
  final String? accountMetadata;

  factory _$PartialProfileNodeDto([
    void Function(PartialProfileNodeDtoBuilder)? updates,
  ]) => (PartialProfileNodeDtoBuilder()..update(updates))._build();

  _$PartialProfileNodeDto._({
    required this.id,
    required this.name,
    this.description,
    required this.accountIndex,
    this.profileMetadata,
    this.accountMetadata,
  }) : super._();
  @override
  PartialProfileNodeDto rebuild(
    void Function(PartialProfileNodeDtoBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  PartialProfileNodeDtoBuilder toBuilder() =>
      PartialProfileNodeDtoBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is PartialProfileNodeDto &&
        id == other.id &&
        name == other.name &&
        description == other.description &&
        accountIndex == other.accountIndex &&
        profileMetadata == other.profileMetadata &&
        accountMetadata == other.accountMetadata;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, id.hashCode);
    _$hash = $jc(_$hash, name.hashCode);
    _$hash = $jc(_$hash, description.hashCode);
    _$hash = $jc(_$hash, accountIndex.hashCode);
    _$hash = $jc(_$hash, profileMetadata.hashCode);
    _$hash = $jc(_$hash, accountMetadata.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'PartialProfileNodeDto')
          ..add('id', id)
          ..add('name', name)
          ..add('description', description)
          ..add('accountIndex', accountIndex)
          ..add('profileMetadata', profileMetadata)
          ..add('accountMetadata', accountMetadata))
        .toString();
  }
}

class PartialProfileNodeDtoBuilder
    implements Builder<PartialProfileNodeDto, PartialProfileNodeDtoBuilder> {
  _$PartialProfileNodeDto? _$v;

  String? _id;
  String? get id => _$this._id;
  set id(String? id) => _$this._id = id;

  String? _name;
  String? get name => _$this._name;
  set name(String? name) => _$this._name = name;

  String? _description;
  String? get description => _$this._description;
  set description(String? description) => _$this._description = description;

  int? _accountIndex;
  int? get accountIndex => _$this._accountIndex;
  set accountIndex(int? accountIndex) => _$this._accountIndex = accountIndex;

  String? _profileMetadata;
  String? get profileMetadata => _$this._profileMetadata;
  set profileMetadata(String? profileMetadata) =>
      _$this._profileMetadata = profileMetadata;

  String? _accountMetadata;
  String? get accountMetadata => _$this._accountMetadata;
  set accountMetadata(String? accountMetadata) =>
      _$this._accountMetadata = accountMetadata;

  PartialProfileNodeDtoBuilder() {
    PartialProfileNodeDto._defaults(this);
  }

  PartialProfileNodeDtoBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _id = $v.id;
      _name = $v.name;
      _description = $v.description;
      _accountIndex = $v.accountIndex;
      _profileMetadata = $v.profileMetadata;
      _accountMetadata = $v.accountMetadata;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(PartialProfileNodeDto other) {
    _$v = other as _$PartialProfileNodeDto;
  }

  @override
  void update(void Function(PartialProfileNodeDtoBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  PartialProfileNodeDto build() => _build();

  _$PartialProfileNodeDto _build() {
    final _$result =
        _$v ??
        _$PartialProfileNodeDto._(
          id: BuiltValueNullFieldError.checkNotNull(
            id,
            r'PartialProfileNodeDto',
            'id',
          ),
          name: BuiltValueNullFieldError.checkNotNull(
            name,
            r'PartialProfileNodeDto',
            'name',
          ),
          description: description,
          accountIndex: BuiltValueNullFieldError.checkNotNull(
            accountIndex,
            r'PartialProfileNodeDto',
            'accountIndex',
          ),
          profileMetadata: profileMetadata,
          accountMetadata: accountMetadata,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
