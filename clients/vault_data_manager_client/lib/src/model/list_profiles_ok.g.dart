// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'list_profiles_ok.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$ListProfilesOK extends ListProfilesOK {
  @override
  final BuiltList<PartialProfileNodeDto>? nodes;

  factory _$ListProfilesOK([void Function(ListProfilesOKBuilder)? updates]) =>
      (ListProfilesOKBuilder()..update(updates))._build();

  _$ListProfilesOK._({this.nodes}) : super._();
  @override
  ListProfilesOK rebuild(void Function(ListProfilesOKBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  ListProfilesOKBuilder toBuilder() => ListProfilesOKBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is ListProfilesOK && nodes == other.nodes;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, nodes.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(
      r'ListProfilesOK',
    )..add('nodes', nodes)).toString();
  }
}

class ListProfilesOKBuilder
    implements Builder<ListProfilesOK, ListProfilesOKBuilder> {
  _$ListProfilesOK? _$v;

  ListBuilder<PartialProfileNodeDto>? _nodes;
  ListBuilder<PartialProfileNodeDto> get nodes =>
      _$this._nodes ??= ListBuilder<PartialProfileNodeDto>();
  set nodes(ListBuilder<PartialProfileNodeDto>? nodes) => _$this._nodes = nodes;

  ListProfilesOKBuilder() {
    ListProfilesOK._defaults(this);
  }

  ListProfilesOKBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _nodes = $v.nodes?.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(ListProfilesOK other) {
    _$v = other as _$ListProfilesOK;
  }

  @override
  void update(void Function(ListProfilesOKBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  ListProfilesOK build() => _build();

  _$ListProfilesOK _build() {
    _$ListProfilesOK _$result;
    try {
      _$result = _$v ?? _$ListProfilesOK._(nodes: _nodes?.build());
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'nodes';
        _nodes?.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
          r'ListProfilesOK',
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
