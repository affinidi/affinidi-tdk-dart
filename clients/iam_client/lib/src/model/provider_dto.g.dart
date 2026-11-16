// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'provider_dto.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const ProviderDtoStatusEnum _$providerDtoStatusEnum_linked =
    const ProviderDtoStatusEnum._('linked');
const ProviderDtoStatusEnum _$providerDtoStatusEnum_unlinked =
    const ProviderDtoStatusEnum._('unlinked');

ProviderDtoStatusEnum _$providerDtoStatusEnumValueOf(String name) {
  switch (name) {
    case 'linked':
      return _$providerDtoStatusEnum_linked;
    case 'unlinked':
      return _$providerDtoStatusEnum_unlinked;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<ProviderDtoStatusEnum> _$providerDtoStatusEnumValues =
    BuiltSet<ProviderDtoStatusEnum>(const <ProviderDtoStatusEnum>[
      _$providerDtoStatusEnum_linked,
      _$providerDtoStatusEnum_unlinked,
    ]);

Serializer<ProviderDtoStatusEnum> _$providerDtoStatusEnumSerializer =
    _$ProviderDtoStatusEnumSerializer();

class _$ProviderDtoStatusEnumSerializer
    implements PrimitiveSerializer<ProviderDtoStatusEnum> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'linked': 'linked',
    'unlinked': 'unlinked',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'linked': 'linked',
    'unlinked': 'unlinked',
  };

  @override
  final Iterable<Type> types = const <Type>[ProviderDtoStatusEnum];
  @override
  final String wireName = 'ProviderDtoStatusEnum';

  @override
  Object serialize(
    Serializers serializers,
    ProviderDtoStatusEnum object, {
    FullType specifiedType = FullType.unspecified,
  }) => _toWire[object.name] ?? object.name;

  @override
  ProviderDtoStatusEnum deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => ProviderDtoStatusEnum.valueOf(
    _fromWire[serialized] ?? (serialized is String ? serialized : ''),
  );
}

class _$ProviderDto extends ProviderDto {
  @override
  final String id;
  @override
  final ProviderDtoStatusEnum status;

  factory _$ProviderDto([void Function(ProviderDtoBuilder)? updates]) =>
      (ProviderDtoBuilder()..update(updates))._build();

  _$ProviderDto._({required this.id, required this.status}) : super._();
  @override
  ProviderDto rebuild(void Function(ProviderDtoBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  ProviderDtoBuilder toBuilder() => ProviderDtoBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is ProviderDto && id == other.id && status == other.status;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, id.hashCode);
    _$hash = $jc(_$hash, status.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'ProviderDto')
          ..add('id', id)
          ..add('status', status))
        .toString();
  }
}

class ProviderDtoBuilder implements Builder<ProviderDto, ProviderDtoBuilder> {
  _$ProviderDto? _$v;

  String? _id;
  String? get id => _$this._id;
  set id(String? id) => _$this._id = id;

  ProviderDtoStatusEnum? _status;
  ProviderDtoStatusEnum? get status => _$this._status;
  set status(ProviderDtoStatusEnum? status) => _$this._status = status;

  ProviderDtoBuilder() {
    ProviderDto._defaults(this);
  }

  ProviderDtoBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _id = $v.id;
      _status = $v.status;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(ProviderDto other) {
    _$v = other as _$ProviderDto;
  }

  @override
  void update(void Function(ProviderDtoBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  ProviderDto build() => _build();

  _$ProviderDto _build() {
    final _$result =
        _$v ??
        _$ProviderDto._(
          id: BuiltValueNullFieldError.checkNotNull(id, r'ProviderDto', 'id'),
          status: BuiltValueNullFieldError.checkNotNull(
            status,
            r'ProviderDto',
            'status',
          ),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
