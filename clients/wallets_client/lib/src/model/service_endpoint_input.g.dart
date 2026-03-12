// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'service_endpoint_input.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const ServiceEndpointInputServiceTypeEnum
_$serviceEndpointInputServiceTypeEnum_dIDCommMessaging =
    const ServiceEndpointInputServiceTypeEnum._('dIDCommMessaging');
const ServiceEndpointInputServiceTypeEnum
_$serviceEndpointInputServiceTypeEnum_linkedDomains =
    const ServiceEndpointInputServiceTypeEnum._('linkedDomains');
const ServiceEndpointInputServiceTypeEnum
_$serviceEndpointInputServiceTypeEnum_identityHub =
    const ServiceEndpointInputServiceTypeEnum._('identityHub');
const ServiceEndpointInputServiceTypeEnum
_$serviceEndpointInputServiceTypeEnum_credentialRegistry =
    const ServiceEndpointInputServiceTypeEnum._('credentialRegistry');

ServiceEndpointInputServiceTypeEnum
_$serviceEndpointInputServiceTypeEnumValueOf(String name) {
  switch (name) {
    case 'dIDCommMessaging':
      return _$serviceEndpointInputServiceTypeEnum_dIDCommMessaging;
    case 'linkedDomains':
      return _$serviceEndpointInputServiceTypeEnum_linkedDomains;
    case 'identityHub':
      return _$serviceEndpointInputServiceTypeEnum_identityHub;
    case 'credentialRegistry':
      return _$serviceEndpointInputServiceTypeEnum_credentialRegistry;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<ServiceEndpointInputServiceTypeEnum>
_$serviceEndpointInputServiceTypeEnumValues =
    BuiltSet<ServiceEndpointInputServiceTypeEnum>(
      const <ServiceEndpointInputServiceTypeEnum>[
        _$serviceEndpointInputServiceTypeEnum_dIDCommMessaging,
        _$serviceEndpointInputServiceTypeEnum_linkedDomains,
        _$serviceEndpointInputServiceTypeEnum_identityHub,
        _$serviceEndpointInputServiceTypeEnum_credentialRegistry,
      ],
    );

Serializer<ServiceEndpointInputServiceTypeEnum>
_$serviceEndpointInputServiceTypeEnumSerializer =
    _$ServiceEndpointInputServiceTypeEnumSerializer();

class _$ServiceEndpointInputServiceTypeEnumSerializer
    implements PrimitiveSerializer<ServiceEndpointInputServiceTypeEnum> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'dIDCommMessaging': 'DIDCommMessaging',
    'linkedDomains': 'LinkedDomains',
    'identityHub': 'IdentityHub',
    'credentialRegistry': 'CredentialRegistry',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'DIDCommMessaging': 'dIDCommMessaging',
    'LinkedDomains': 'linkedDomains',
    'IdentityHub': 'identityHub',
    'CredentialRegistry': 'credentialRegistry',
  };

  @override
  final Iterable<Type> types = const <Type>[
    ServiceEndpointInputServiceTypeEnum,
  ];
  @override
  final String wireName = 'ServiceEndpointInputServiceTypeEnum';

  @override
  Object serialize(
    Serializers serializers,
    ServiceEndpointInputServiceTypeEnum object, {
    FullType specifiedType = FullType.unspecified,
  }) => _toWire[object.name] ?? object.name;

  @override
  ServiceEndpointInputServiceTypeEnum deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => ServiceEndpointInputServiceTypeEnum.valueOf(
    _fromWire[serialized] ?? (serialized is String ? serialized : ''),
  );
}

class _$ServiceEndpointInput extends ServiceEndpointInput {
  @override
  final String? name;
  @override
  final String? description;
  @override
  final String url;
  @override
  final ServiceEndpointInputServiceTypeEnum? serviceType;

  factory _$ServiceEndpointInput([
    void Function(ServiceEndpointInputBuilder)? updates,
  ]) => (ServiceEndpointInputBuilder()..update(updates))._build();

  _$ServiceEndpointInput._({
    this.name,
    this.description,
    required this.url,
    this.serviceType,
  }) : super._();
  @override
  ServiceEndpointInput rebuild(
    void Function(ServiceEndpointInputBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  ServiceEndpointInputBuilder toBuilder() =>
      ServiceEndpointInputBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is ServiceEndpointInput &&
        name == other.name &&
        description == other.description &&
        url == other.url &&
        serviceType == other.serviceType;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, name.hashCode);
    _$hash = $jc(_$hash, description.hashCode);
    _$hash = $jc(_$hash, url.hashCode);
    _$hash = $jc(_$hash, serviceType.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'ServiceEndpointInput')
          ..add('name', name)
          ..add('description', description)
          ..add('url', url)
          ..add('serviceType', serviceType))
        .toString();
  }
}

class ServiceEndpointInputBuilder
    implements Builder<ServiceEndpointInput, ServiceEndpointInputBuilder> {
  _$ServiceEndpointInput? _$v;

  String? _name;
  String? get name => _$this._name;
  set name(String? name) => _$this._name = name;

  String? _description;
  String? get description => _$this._description;
  set description(String? description) => _$this._description = description;

  String? _url;
  String? get url => _$this._url;
  set url(String? url) => _$this._url = url;

  ServiceEndpointInputServiceTypeEnum? _serviceType;
  ServiceEndpointInputServiceTypeEnum? get serviceType => _$this._serviceType;
  set serviceType(ServiceEndpointInputServiceTypeEnum? serviceType) =>
      _$this._serviceType = serviceType;

  ServiceEndpointInputBuilder() {
    ServiceEndpointInput._defaults(this);
  }

  ServiceEndpointInputBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _name = $v.name;
      _description = $v.description;
      _url = $v.url;
      _serviceType = $v.serviceType;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(ServiceEndpointInput other) {
    _$v = other as _$ServiceEndpointInput;
  }

  @override
  void update(void Function(ServiceEndpointInputBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  ServiceEndpointInput build() => _build();

  _$ServiceEndpointInput _build() {
    final _$result =
        _$v ??
        _$ServiceEndpointInput._(
          name: name,
          description: description,
          url: BuiltValueNullFieldError.checkNotNull(
            url,
            r'ServiceEndpointInput',
            'url',
          ),
          serviceType: serviceType,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
