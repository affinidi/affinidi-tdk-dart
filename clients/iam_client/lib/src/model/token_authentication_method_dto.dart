//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:affinidi_tdk_iam_client/src/model/token_private_key_authentication_method_dto_public_key_info.dart';
import 'package:built_collection/built_collection.dart';
import 'package:affinidi_tdk_iam_client/src/model/token_private_key_authentication_method_dto.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'token_authentication_method_dto.g.dart';

/// How the Token will be authenticate against our Authorization Server
///
/// Properties:
/// * [type]
/// * [signingAlgorithm]
/// * [publicKeyInfo]
@BuiltValue()
abstract class TokenAuthenticationMethodDto
    implements
        TokenPrivateKeyAuthenticationMethodDto,
        Built<
          TokenAuthenticationMethodDto,
          TokenAuthenticationMethodDtoBuilder
        > {
  TokenAuthenticationMethodDto._();

  factory TokenAuthenticationMethodDto([
    void updates(TokenAuthenticationMethodDtoBuilder b),
  ]) = _$TokenAuthenticationMethodDto;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(TokenAuthenticationMethodDtoBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<TokenAuthenticationMethodDto> get serializer =>
      _$TokenAuthenticationMethodDtoSerializer();
}

class _$TokenAuthenticationMethodDtoSerializer
    implements PrimitiveSerializer<TokenAuthenticationMethodDto> {
  @override
  final Iterable<Type> types = const [
    TokenAuthenticationMethodDto,
    _$TokenAuthenticationMethodDto,
  ];

  @override
  final String wireName = r'TokenAuthenticationMethodDto';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    TokenAuthenticationMethodDto object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'type';
    yield serializers.serialize(
      object.type,
      specifiedType: const FullType(
        TokenPrivateKeyAuthenticationMethodDtoTypeEnum,
      ),
    );
    yield r'signingAlgorithm';
    yield serializers.serialize(
      object.signingAlgorithm,
      specifiedType: const FullType(
        TokenPrivateKeyAuthenticationMethodDtoSigningAlgorithmEnum,
      ),
    );
    yield r'publicKeyInfo';
    yield serializers.serialize(
      object.publicKeyInfo,
      specifiedType: const FullType(
        TokenPrivateKeyAuthenticationMethodDtoPublicKeyInfo,
      ),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    TokenAuthenticationMethodDto object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(
      serializers,
      object,
      specifiedType: specifiedType,
    ).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required TokenAuthenticationMethodDtoBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'type':
          final valueDes =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(
                      TokenPrivateKeyAuthenticationMethodDtoTypeEnum,
                    ),
                  )
                  as TokenPrivateKeyAuthenticationMethodDtoTypeEnum;
          result.type = valueDes;
          break;
        case r'signingAlgorithm':
          final valueDes =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(
                      TokenPrivateKeyAuthenticationMethodDtoSigningAlgorithmEnum,
                    ),
                  )
                  as TokenPrivateKeyAuthenticationMethodDtoSigningAlgorithmEnum;
          result.signingAlgorithm = valueDes;
          break;
        case r'publicKeyInfo':
          final valueDes =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(
                      TokenPrivateKeyAuthenticationMethodDtoPublicKeyInfo,
                    ),
                  )
                  as TokenPrivateKeyAuthenticationMethodDtoPublicKeyInfo;
          result.publicKeyInfo.replace(valueDes);
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  TokenAuthenticationMethodDto deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = TokenAuthenticationMethodDtoBuilder();
    final serializedList = (serialized as Iterable<Object?>).toList();
    final unhandled = <Object?>[];
    _deserializeProperties(
      serializers,
      serialized,
      specifiedType: specifiedType,
      serializedList: serializedList,
      unhandled: unhandled,
      result: result,
    );
    return result.build();
  }
}

class TokenAuthenticationMethodDtoTypeEnum extends EnumClass {
  @BuiltValueEnumConst(wireName: r'PRIVATE_KEY')
  static const TokenAuthenticationMethodDtoTypeEnum PRIVATE_KEY =
      _$tokenAuthenticationMethodDtoTypeEnum_PRIVATE_KEY;

  static Serializer<TokenAuthenticationMethodDtoTypeEnum> get serializer =>
      _$tokenAuthenticationMethodDtoTypeEnumSerializer;

  const TokenAuthenticationMethodDtoTypeEnum._(String name) : super(name);

  static BuiltSet<TokenAuthenticationMethodDtoTypeEnum> get values =>
      _$tokenAuthenticationMethodDtoTypeEnumValues;
  static TokenAuthenticationMethodDtoTypeEnum valueOf(String name) =>
      _$tokenAuthenticationMethodDtoTypeEnumValueOf(name);
}

class TokenAuthenticationMethodDtoSigningAlgorithmEnum extends EnumClass {
  @BuiltValueEnumConst(wireName: r'RS256')
  static const TokenAuthenticationMethodDtoSigningAlgorithmEnum RS256 =
      _$tokenAuthenticationMethodDtoSigningAlgorithmEnum_RS256;
  @BuiltValueEnumConst(wireName: r'RS512')
  static const TokenAuthenticationMethodDtoSigningAlgorithmEnum RS512 =
      _$tokenAuthenticationMethodDtoSigningAlgorithmEnum_RS512;
  @BuiltValueEnumConst(wireName: r'ES256')
  static const TokenAuthenticationMethodDtoSigningAlgorithmEnum ES256 =
      _$tokenAuthenticationMethodDtoSigningAlgorithmEnum_ES256;
  @BuiltValueEnumConst(wireName: r'ES512')
  static const TokenAuthenticationMethodDtoSigningAlgorithmEnum ES512 =
      _$tokenAuthenticationMethodDtoSigningAlgorithmEnum_ES512;

  static Serializer<TokenAuthenticationMethodDtoSigningAlgorithmEnum>
  get serializer =>
      _$tokenAuthenticationMethodDtoSigningAlgorithmEnumSerializer;

  const TokenAuthenticationMethodDtoSigningAlgorithmEnum._(String name)
    : super(name);

  static BuiltSet<TokenAuthenticationMethodDtoSigningAlgorithmEnum>
  get values => _$tokenAuthenticationMethodDtoSigningAlgorithmEnumValues;
  static TokenAuthenticationMethodDtoSigningAlgorithmEnum valueOf(
    String name,
  ) => _$tokenAuthenticationMethodDtoSigningAlgorithmEnumValueOf(name);
}
