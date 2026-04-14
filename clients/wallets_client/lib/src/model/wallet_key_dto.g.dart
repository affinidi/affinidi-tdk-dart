// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'wallet_key_dto.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const WalletKeyDtoKeyTypeEnum _$walletKeyDtoKeyTypeEnum_secp256k1 =
    const WalletKeyDtoKeyTypeEnum._('secp256k1');
const WalletKeyDtoKeyTypeEnum _$walletKeyDtoKeyTypeEnum_ed25519 =
    const WalletKeyDtoKeyTypeEnum._('ed25519');
const WalletKeyDtoKeyTypeEnum _$walletKeyDtoKeyTypeEnum_p256 =
    const WalletKeyDtoKeyTypeEnum._('p256');

WalletKeyDtoKeyTypeEnum _$walletKeyDtoKeyTypeEnumValueOf(String name) {
  switch (name) {
    case 'secp256k1':
      return _$walletKeyDtoKeyTypeEnum_secp256k1;
    case 'ed25519':
      return _$walletKeyDtoKeyTypeEnum_ed25519;
    case 'p256':
      return _$walletKeyDtoKeyTypeEnum_p256;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<WalletKeyDtoKeyTypeEnum> _$walletKeyDtoKeyTypeEnumValues =
    BuiltSet<WalletKeyDtoKeyTypeEnum>(const <WalletKeyDtoKeyTypeEnum>[
      _$walletKeyDtoKeyTypeEnum_secp256k1,
      _$walletKeyDtoKeyTypeEnum_ed25519,
      _$walletKeyDtoKeyTypeEnum_p256,
    ]);

Serializer<WalletKeyDtoKeyTypeEnum> _$walletKeyDtoKeyTypeEnumSerializer =
    _$WalletKeyDtoKeyTypeEnumSerializer();

class _$WalletKeyDtoKeyTypeEnumSerializer
    implements PrimitiveSerializer<WalletKeyDtoKeyTypeEnum> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'secp256k1': 'secp256k1',
    'ed25519': 'ed25519',
    'p256': 'p256',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'secp256k1': 'secp256k1',
    'ed25519': 'ed25519',
    'p256': 'p256',
  };

  @override
  final Iterable<Type> types = const <Type>[WalletKeyDtoKeyTypeEnum];
  @override
  final String wireName = 'WalletKeyDtoKeyTypeEnum';

  @override
  Object serialize(
    Serializers serializers,
    WalletKeyDtoKeyTypeEnum object, {
    FullType specifiedType = FullType.unspecified,
  }) => _toWire[object.name] ?? object.name;

  @override
  WalletKeyDtoKeyTypeEnum deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => WalletKeyDtoKeyTypeEnum.valueOf(
    _fromWire[serialized] ?? (serialized is String ? serialized : ''),
  );
}

class _$WalletKeyDto extends WalletKeyDto {
  @override
  final String? keyId;
  @override
  final WalletKeyDtoKeyTypeEnum? keyType;
  @override
  final String? keyAri;
  @override
  final BuiltList<VerificationRelationship>? relationships;

  factory _$WalletKeyDto([void Function(WalletKeyDtoBuilder)? updates]) =>
      (WalletKeyDtoBuilder()..update(updates))._build();

  _$WalletKeyDto._({this.keyId, this.keyType, this.keyAri, this.relationships})
    : super._();
  @override
  WalletKeyDto rebuild(void Function(WalletKeyDtoBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  WalletKeyDtoBuilder toBuilder() => WalletKeyDtoBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is WalletKeyDto &&
        keyId == other.keyId &&
        keyType == other.keyType &&
        keyAri == other.keyAri &&
        relationships == other.relationships;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, keyId.hashCode);
    _$hash = $jc(_$hash, keyType.hashCode);
    _$hash = $jc(_$hash, keyAri.hashCode);
    _$hash = $jc(_$hash, relationships.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'WalletKeyDto')
          ..add('keyId', keyId)
          ..add('keyType', keyType)
          ..add('keyAri', keyAri)
          ..add('relationships', relationships))
        .toString();
  }
}

class WalletKeyDtoBuilder
    implements Builder<WalletKeyDto, WalletKeyDtoBuilder> {
  _$WalletKeyDto? _$v;

  String? _keyId;
  String? get keyId => _$this._keyId;
  set keyId(String? keyId) => _$this._keyId = keyId;

  WalletKeyDtoKeyTypeEnum? _keyType;
  WalletKeyDtoKeyTypeEnum? get keyType => _$this._keyType;
  set keyType(WalletKeyDtoKeyTypeEnum? keyType) => _$this._keyType = keyType;

  String? _keyAri;
  String? get keyAri => _$this._keyAri;
  set keyAri(String? keyAri) => _$this._keyAri = keyAri;

  ListBuilder<VerificationRelationship>? _relationships;
  ListBuilder<VerificationRelationship> get relationships =>
      _$this._relationships ??= ListBuilder<VerificationRelationship>();
  set relationships(ListBuilder<VerificationRelationship>? relationships) =>
      _$this._relationships = relationships;

  WalletKeyDtoBuilder() {
    WalletKeyDto._defaults(this);
  }

  WalletKeyDtoBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _keyId = $v.keyId;
      _keyType = $v.keyType;
      _keyAri = $v.keyAri;
      _relationships = $v.relationships?.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(WalletKeyDto other) {
    _$v = other as _$WalletKeyDto;
  }

  @override
  void update(void Function(WalletKeyDtoBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  WalletKeyDto build() => _build();

  _$WalletKeyDto _build() {
    _$WalletKeyDto _$result;
    try {
      _$result =
          _$v ??
          _$WalletKeyDto._(
            keyId: keyId,
            keyType: keyType,
            keyAri: keyAri,
            relationships: _relationships?.build(),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'relationships';
        _relationships?.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
          r'WalletKeyDto',
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
