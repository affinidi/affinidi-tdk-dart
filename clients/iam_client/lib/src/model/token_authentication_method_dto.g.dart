// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'token_authentication_method_dto.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const TokenAuthenticationMethodDtoTypeEnum
_$tokenAuthenticationMethodDtoTypeEnum_PRIVATE_KEY =
    const TokenAuthenticationMethodDtoTypeEnum._('PRIVATE_KEY');

TokenAuthenticationMethodDtoTypeEnum
_$tokenAuthenticationMethodDtoTypeEnumValueOf(String name) {
  switch (name) {
    case 'PRIVATE_KEY':
      return _$tokenAuthenticationMethodDtoTypeEnum_PRIVATE_KEY;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<TokenAuthenticationMethodDtoTypeEnum>
_$tokenAuthenticationMethodDtoTypeEnumValues =
    BuiltSet<TokenAuthenticationMethodDtoTypeEnum>(
      const <TokenAuthenticationMethodDtoTypeEnum>[
        _$tokenAuthenticationMethodDtoTypeEnum_PRIVATE_KEY,
      ],
    );

const TokenAuthenticationMethodDtoSigningAlgorithmEnum
_$tokenAuthenticationMethodDtoSigningAlgorithmEnum_RS256 =
    const TokenAuthenticationMethodDtoSigningAlgorithmEnum._('RS256');
const TokenAuthenticationMethodDtoSigningAlgorithmEnum
_$tokenAuthenticationMethodDtoSigningAlgorithmEnum_RS512 =
    const TokenAuthenticationMethodDtoSigningAlgorithmEnum._('RS512');
const TokenAuthenticationMethodDtoSigningAlgorithmEnum
_$tokenAuthenticationMethodDtoSigningAlgorithmEnum_ES256 =
    const TokenAuthenticationMethodDtoSigningAlgorithmEnum._('ES256');
const TokenAuthenticationMethodDtoSigningAlgorithmEnum
_$tokenAuthenticationMethodDtoSigningAlgorithmEnum_ES512 =
    const TokenAuthenticationMethodDtoSigningAlgorithmEnum._('ES512');

TokenAuthenticationMethodDtoSigningAlgorithmEnum
_$tokenAuthenticationMethodDtoSigningAlgorithmEnumValueOf(String name) {
  switch (name) {
    case 'RS256':
      return _$tokenAuthenticationMethodDtoSigningAlgorithmEnum_RS256;
    case 'RS512':
      return _$tokenAuthenticationMethodDtoSigningAlgorithmEnum_RS512;
    case 'ES256':
      return _$tokenAuthenticationMethodDtoSigningAlgorithmEnum_ES256;
    case 'ES512':
      return _$tokenAuthenticationMethodDtoSigningAlgorithmEnum_ES512;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<TokenAuthenticationMethodDtoSigningAlgorithmEnum>
_$tokenAuthenticationMethodDtoSigningAlgorithmEnumValues =
    BuiltSet<TokenAuthenticationMethodDtoSigningAlgorithmEnum>(
      const <TokenAuthenticationMethodDtoSigningAlgorithmEnum>[
        _$tokenAuthenticationMethodDtoSigningAlgorithmEnum_RS256,
        _$tokenAuthenticationMethodDtoSigningAlgorithmEnum_RS512,
        _$tokenAuthenticationMethodDtoSigningAlgorithmEnum_ES256,
        _$tokenAuthenticationMethodDtoSigningAlgorithmEnum_ES512,
      ],
    );

Serializer<TokenAuthenticationMethodDtoTypeEnum>
_$tokenAuthenticationMethodDtoTypeEnumSerializer =
    _$TokenAuthenticationMethodDtoTypeEnumSerializer();
Serializer<TokenAuthenticationMethodDtoSigningAlgorithmEnum>
_$tokenAuthenticationMethodDtoSigningAlgorithmEnumSerializer =
    _$TokenAuthenticationMethodDtoSigningAlgorithmEnumSerializer();

class _$TokenAuthenticationMethodDtoTypeEnumSerializer
    implements PrimitiveSerializer<TokenAuthenticationMethodDtoTypeEnum> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'PRIVATE_KEY': 'PRIVATE_KEY',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'PRIVATE_KEY': 'PRIVATE_KEY',
  };

  @override
  final Iterable<Type> types = const <Type>[
    TokenAuthenticationMethodDtoTypeEnum,
  ];
  @override
  final String wireName = 'TokenAuthenticationMethodDtoTypeEnum';

  @override
  Object serialize(
    Serializers serializers,
    TokenAuthenticationMethodDtoTypeEnum object, {
    FullType specifiedType = FullType.unspecified,
  }) => _toWire[object.name] ?? object.name;

  @override
  TokenAuthenticationMethodDtoTypeEnum deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => TokenAuthenticationMethodDtoTypeEnum.valueOf(
    _fromWire[serialized] ?? (serialized is String ? serialized : ''),
  );
}

class _$TokenAuthenticationMethodDtoSigningAlgorithmEnumSerializer
    implements
        PrimitiveSerializer<TokenAuthenticationMethodDtoSigningAlgorithmEnum> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'RS256': 'RS256',
    'RS512': 'RS512',
    'ES256': 'ES256',
    'ES512': 'ES512',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'RS256': 'RS256',
    'RS512': 'RS512',
    'ES256': 'ES256',
    'ES512': 'ES512',
  };

  @override
  final Iterable<Type> types = const <Type>[
    TokenAuthenticationMethodDtoSigningAlgorithmEnum,
  ];
  @override
  final String wireName = 'TokenAuthenticationMethodDtoSigningAlgorithmEnum';

  @override
  Object serialize(
    Serializers serializers,
    TokenAuthenticationMethodDtoSigningAlgorithmEnum object, {
    FullType specifiedType = FullType.unspecified,
  }) => _toWire[object.name] ?? object.name;

  @override
  TokenAuthenticationMethodDtoSigningAlgorithmEnum deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => TokenAuthenticationMethodDtoSigningAlgorithmEnum.valueOf(
    _fromWire[serialized] ?? (serialized is String ? serialized : ''),
  );
}

class _$TokenAuthenticationMethodDto extends TokenAuthenticationMethodDto {
  @override
  final TokenPrivateKeyAuthenticationMethodDtoTypeEnum type;
  @override
  final TokenPrivateKeyAuthenticationMethodDtoSigningAlgorithmEnum
  signingAlgorithm;
  @override
  final TokenPrivateKeyAuthenticationMethodDtoPublicKeyInfo publicKeyInfo;

  factory _$TokenAuthenticationMethodDto([
    void Function(TokenAuthenticationMethodDtoBuilder)? updates,
  ]) => (TokenAuthenticationMethodDtoBuilder()..update(updates))._build();

  _$TokenAuthenticationMethodDto._({
    required this.type,
    required this.signingAlgorithm,
    required this.publicKeyInfo,
  }) : super._();
  @override
  TokenAuthenticationMethodDto rebuild(
    void Function(TokenAuthenticationMethodDtoBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  TokenAuthenticationMethodDtoBuilder toBuilder() =>
      TokenAuthenticationMethodDtoBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is TokenAuthenticationMethodDto &&
        type == other.type &&
        signingAlgorithm == other.signingAlgorithm &&
        publicKeyInfo == other.publicKeyInfo;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, type.hashCode);
    _$hash = $jc(_$hash, signingAlgorithm.hashCode);
    _$hash = $jc(_$hash, publicKeyInfo.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'TokenAuthenticationMethodDto')
          ..add('type', type)
          ..add('signingAlgorithm', signingAlgorithm)
          ..add('publicKeyInfo', publicKeyInfo))
        .toString();
  }
}

class TokenAuthenticationMethodDtoBuilder
    implements
        Builder<
          TokenAuthenticationMethodDto,
          TokenAuthenticationMethodDtoBuilder
        >,
        TokenPrivateKeyAuthenticationMethodDtoBuilder {
  _$TokenAuthenticationMethodDto? _$v;

  TokenPrivateKeyAuthenticationMethodDtoTypeEnum? _type;
  TokenPrivateKeyAuthenticationMethodDtoTypeEnum? get type => _$this._type;
  set type(covariant TokenPrivateKeyAuthenticationMethodDtoTypeEnum? type) =>
      _$this._type = type;

  TokenPrivateKeyAuthenticationMethodDtoSigningAlgorithmEnum? _signingAlgorithm;
  TokenPrivateKeyAuthenticationMethodDtoSigningAlgorithmEnum?
  get signingAlgorithm => _$this._signingAlgorithm;
  set signingAlgorithm(
    covariant TokenPrivateKeyAuthenticationMethodDtoSigningAlgorithmEnum?
    signingAlgorithm,
  ) => _$this._signingAlgorithm = signingAlgorithm;

  TokenPrivateKeyAuthenticationMethodDtoPublicKeyInfoBuilder? _publicKeyInfo;
  TokenPrivateKeyAuthenticationMethodDtoPublicKeyInfoBuilder
  get publicKeyInfo => _$this._publicKeyInfo ??=
      TokenPrivateKeyAuthenticationMethodDtoPublicKeyInfoBuilder();
  set publicKeyInfo(
    covariant TokenPrivateKeyAuthenticationMethodDtoPublicKeyInfoBuilder?
    publicKeyInfo,
  ) => _$this._publicKeyInfo = publicKeyInfo;

  TokenAuthenticationMethodDtoBuilder() {
    TokenAuthenticationMethodDto._defaults(this);
  }

  TokenAuthenticationMethodDtoBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _type = $v.type;
      _signingAlgorithm = $v.signingAlgorithm;
      _publicKeyInfo = $v.publicKeyInfo.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(covariant TokenAuthenticationMethodDto other) {
    _$v = other as _$TokenAuthenticationMethodDto;
  }

  @override
  void update(void Function(TokenAuthenticationMethodDtoBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  TokenAuthenticationMethodDto build() => _build();

  _$TokenAuthenticationMethodDto _build() {
    _$TokenAuthenticationMethodDto _$result;
    try {
      _$result =
          _$v ??
          _$TokenAuthenticationMethodDto._(
            type: BuiltValueNullFieldError.checkNotNull(
              type,
              r'TokenAuthenticationMethodDto',
              'type',
            ),
            signingAlgorithm: BuiltValueNullFieldError.checkNotNull(
              signingAlgorithm,
              r'TokenAuthenticationMethodDto',
              'signingAlgorithm',
            ),
            publicKeyInfo: publicKeyInfo.build(),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'publicKeyInfo';
        publicKeyInfo.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
          r'TokenAuthenticationMethodDto',
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
