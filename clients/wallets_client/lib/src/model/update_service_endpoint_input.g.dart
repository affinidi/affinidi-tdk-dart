// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'update_service_endpoint_input.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$UpdateServiceEndpointInput extends UpdateServiceEndpointInput {
  @override
  final String? name;
  @override
  final String? description;
  @override
  final String? url;

  factory _$UpdateServiceEndpointInput([
    void Function(UpdateServiceEndpointInputBuilder)? updates,
  ]) => (UpdateServiceEndpointInputBuilder()..update(updates))._build();

  _$UpdateServiceEndpointInput._({this.name, this.description, this.url})
    : super._();
  @override
  UpdateServiceEndpointInput rebuild(
    void Function(UpdateServiceEndpointInputBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  UpdateServiceEndpointInputBuilder toBuilder() =>
      UpdateServiceEndpointInputBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is UpdateServiceEndpointInput &&
        name == other.name &&
        description == other.description &&
        url == other.url;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, name.hashCode);
    _$hash = $jc(_$hash, description.hashCode);
    _$hash = $jc(_$hash, url.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'UpdateServiceEndpointInput')
          ..add('name', name)
          ..add('description', description)
          ..add('url', url))
        .toString();
  }
}

class UpdateServiceEndpointInputBuilder
    implements
        Builder<UpdateServiceEndpointInput, UpdateServiceEndpointInputBuilder> {
  _$UpdateServiceEndpointInput? _$v;

  String? _name;
  String? get name => _$this._name;
  set name(String? name) => _$this._name = name;

  String? _description;
  String? get description => _$this._description;
  set description(String? description) => _$this._description = description;

  String? _url;
  String? get url => _$this._url;
  set url(String? url) => _$this._url = url;

  UpdateServiceEndpointInputBuilder() {
    UpdateServiceEndpointInput._defaults(this);
  }

  UpdateServiceEndpointInputBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _name = $v.name;
      _description = $v.description;
      _url = $v.url;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(UpdateServiceEndpointInput other) {
    _$v = other as _$UpdateServiceEndpointInput;
  }

  @override
  void update(void Function(UpdateServiceEndpointInputBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  UpdateServiceEndpointInput build() => _build();

  _$UpdateServiceEndpointInput _build() {
    final _$result =
        _$v ??
        _$UpdateServiceEndpointInput._(
          name: name,
          description: description,
          url: url,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
