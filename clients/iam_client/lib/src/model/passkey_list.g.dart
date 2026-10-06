// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'passkey_list.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$PasskeyList extends PasskeyList {
  @override
  final BuiltList<PasskeyDto> passkeys;

  factory _$PasskeyList([void Function(PasskeyListBuilder)? updates]) =>
      (PasskeyListBuilder()..update(updates))._build();

  _$PasskeyList._({required this.passkeys}) : super._();
  @override
  PasskeyList rebuild(void Function(PasskeyListBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  PasskeyListBuilder toBuilder() => PasskeyListBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is PasskeyList && passkeys == other.passkeys;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, passkeys.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(
      r'PasskeyList',
    )..add('passkeys', passkeys)).toString();
  }
}

class PasskeyListBuilder implements Builder<PasskeyList, PasskeyListBuilder> {
  _$PasskeyList? _$v;

  ListBuilder<PasskeyDto>? _passkeys;
  ListBuilder<PasskeyDto> get passkeys =>
      _$this._passkeys ??= ListBuilder<PasskeyDto>();
  set passkeys(ListBuilder<PasskeyDto>? passkeys) =>
      _$this._passkeys = passkeys;

  PasskeyListBuilder() {
    PasskeyList._defaults(this);
  }

  PasskeyListBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _passkeys = $v.passkeys.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(PasskeyList other) {
    _$v = other as _$PasskeyList;
  }

  @override
  void update(void Function(PasskeyListBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  PasskeyList build() => _build();

  _$PasskeyList _build() {
    _$PasskeyList _$result;
    try {
      _$result = _$v ?? _$PasskeyList._(passkeys: passkeys.build());
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'passkeys';
        passkeys.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
          r'PasskeyList',
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
