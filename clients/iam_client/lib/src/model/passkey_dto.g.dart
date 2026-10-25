// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'passkey_dto.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$PasskeyDto extends PasskeyDto {
  @override
  final String id;
  @override
  final String displayName;
  @override
  final String createdAt;

  factory _$PasskeyDto([void Function(PasskeyDtoBuilder)? updates]) =>
      (PasskeyDtoBuilder()..update(updates))._build();

  _$PasskeyDto._({
    required this.id,
    required this.displayName,
    required this.createdAt,
  }) : super._();
  @override
  PasskeyDto rebuild(void Function(PasskeyDtoBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  PasskeyDtoBuilder toBuilder() => PasskeyDtoBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is PasskeyDto &&
        id == other.id &&
        displayName == other.displayName &&
        createdAt == other.createdAt;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, id.hashCode);
    _$hash = $jc(_$hash, displayName.hashCode);
    _$hash = $jc(_$hash, createdAt.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'PasskeyDto')
          ..add('id', id)
          ..add('displayName', displayName)
          ..add('createdAt', createdAt))
        .toString();
  }
}

class PasskeyDtoBuilder implements Builder<PasskeyDto, PasskeyDtoBuilder> {
  _$PasskeyDto? _$v;

  String? _id;
  String? get id => _$this._id;
  set id(String? id) => _$this._id = id;

  String? _displayName;
  String? get displayName => _$this._displayName;
  set displayName(String? displayName) => _$this._displayName = displayName;

  String? _createdAt;
  String? get createdAt => _$this._createdAt;
  set createdAt(String? createdAt) => _$this._createdAt = createdAt;

  PasskeyDtoBuilder() {
    PasskeyDto._defaults(this);
  }

  PasskeyDtoBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _id = $v.id;
      _displayName = $v.displayName;
      _createdAt = $v.createdAt;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(PasskeyDto other) {
    _$v = other as _$PasskeyDto;
  }

  @override
  void update(void Function(PasskeyDtoBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  PasskeyDto build() => _build();

  _$PasskeyDto _build() {
    final _$result =
        _$v ??
        _$PasskeyDto._(
          id: BuiltValueNullFieldError.checkNotNull(id, r'PasskeyDto', 'id'),
          displayName: BuiltValueNullFieldError.checkNotNull(
            displayName,
            r'PasskeyDto',
            'displayName',
          ),
          createdAt: BuiltValueNullFieldError.checkNotNull(
            createdAt,
            r'PasskeyDto',
            'createdAt',
          ),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
