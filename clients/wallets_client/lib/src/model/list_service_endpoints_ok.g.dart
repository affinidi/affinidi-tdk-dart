// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'list_service_endpoints_ok.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$ListServiceEndpointsOK extends ListServiceEndpointsOK {
  @override
  final BuiltList<ServiceEndpointDto> services;

  factory _$ListServiceEndpointsOK([
    void Function(ListServiceEndpointsOKBuilder)? updates,
  ]) => (ListServiceEndpointsOKBuilder()..update(updates))._build();

  _$ListServiceEndpointsOK._({required this.services}) : super._();
  @override
  ListServiceEndpointsOK rebuild(
    void Function(ListServiceEndpointsOKBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  ListServiceEndpointsOKBuilder toBuilder() =>
      ListServiceEndpointsOKBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is ListServiceEndpointsOK && services == other.services;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, services.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(
      r'ListServiceEndpointsOK',
    )..add('services', services)).toString();
  }
}

class ListServiceEndpointsOKBuilder
    implements Builder<ListServiceEndpointsOK, ListServiceEndpointsOKBuilder> {
  _$ListServiceEndpointsOK? _$v;

  ListBuilder<ServiceEndpointDto>? _services;
  ListBuilder<ServiceEndpointDto> get services =>
      _$this._services ??= ListBuilder<ServiceEndpointDto>();
  set services(ListBuilder<ServiceEndpointDto>? services) =>
      _$this._services = services;

  ListServiceEndpointsOKBuilder() {
    ListServiceEndpointsOK._defaults(this);
  }

  ListServiceEndpointsOKBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _services = $v.services.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(ListServiceEndpointsOK other) {
    _$v = other as _$ListServiceEndpointsOK;
  }

  @override
  void update(void Function(ListServiceEndpointsOKBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  ListServiceEndpointsOK build() => _build();

  _$ListServiceEndpointsOK _build() {
    _$ListServiceEndpointsOK _$result;
    try {
      _$result = _$v ?? _$ListServiceEndpointsOK._(services: services.build());
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'services';
        services.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
          r'ListServiceEndpointsOK',
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
