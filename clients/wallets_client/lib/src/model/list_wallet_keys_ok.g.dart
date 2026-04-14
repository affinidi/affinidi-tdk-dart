// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'list_wallet_keys_ok.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$ListWalletKeysOK extends ListWalletKeysOK {
  @override
  final BuiltList<WalletKeyDto> keys;

  factory _$ListWalletKeysOK([
    void Function(ListWalletKeysOKBuilder)? updates,
  ]) => (ListWalletKeysOKBuilder()..update(updates))._build();

  _$ListWalletKeysOK._({required this.keys}) : super._();
  @override
  ListWalletKeysOK rebuild(void Function(ListWalletKeysOKBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  ListWalletKeysOKBuilder toBuilder() =>
      ListWalletKeysOKBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is ListWalletKeysOK && keys == other.keys;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, keys.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(
      r'ListWalletKeysOK',
    )..add('keys', keys)).toString();
  }
}

class ListWalletKeysOKBuilder
    implements Builder<ListWalletKeysOK, ListWalletKeysOKBuilder> {
  _$ListWalletKeysOK? _$v;

  ListBuilder<WalletKeyDto>? _keys;
  ListBuilder<WalletKeyDto> get keys =>
      _$this._keys ??= ListBuilder<WalletKeyDto>();
  set keys(ListBuilder<WalletKeyDto>? keys) => _$this._keys = keys;

  ListWalletKeysOKBuilder() {
    ListWalletKeysOK._defaults(this);
  }

  ListWalletKeysOKBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _keys = $v.keys.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(ListWalletKeysOK other) {
    _$v = other as _$ListWalletKeysOK;
  }

  @override
  void update(void Function(ListWalletKeysOKBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  ListWalletKeysOK build() => _build();

  _$ListWalletKeysOK _build() {
    _$ListWalletKeysOK _$result;
    try {
      _$result = _$v ?? _$ListWalletKeysOK._(keys: keys.build());
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'keys';
        keys.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
          r'ListWalletKeysOK',
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
