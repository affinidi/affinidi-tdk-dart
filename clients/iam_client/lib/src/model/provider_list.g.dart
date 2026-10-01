// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'provider_list.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$ProviderList extends ProviderList {
  @override
  final BuiltList<ProviderDto> providers;

  factory _$ProviderList([void Function(ProviderListBuilder)? updates]) =>
      (ProviderListBuilder()..update(updates))._build();

  _$ProviderList._({required this.providers}) : super._();
  @override
  ProviderList rebuild(void Function(ProviderListBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  ProviderListBuilder toBuilder() => ProviderListBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is ProviderList && providers == other.providers;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, providers.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(
      r'ProviderList',
    )..add('providers', providers)).toString();
  }
}

class ProviderListBuilder
    implements Builder<ProviderList, ProviderListBuilder> {
  _$ProviderList? _$v;

  ListBuilder<ProviderDto>? _providers;
  ListBuilder<ProviderDto> get providers =>
      _$this._providers ??= ListBuilder<ProviderDto>();
  set providers(ListBuilder<ProviderDto>? providers) =>
      _$this._providers = providers;

  ProviderListBuilder() {
    ProviderList._defaults(this);
  }

  ProviderListBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _providers = $v.providers.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(ProviderList other) {
    _$v = other as _$ProviderList;
  }

  @override
  void update(void Function(ProviderListBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  ProviderList build() => _build();

  _$ProviderList _build() {
    _$ProviderList _$result;
    try {
      _$result = _$v ?? _$ProviderList._(providers: providers.build());
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'providers';
        providers.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
          r'ProviderList',
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
