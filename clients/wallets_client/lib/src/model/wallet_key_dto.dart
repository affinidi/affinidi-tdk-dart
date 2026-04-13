//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:affinidi_tdk_wallets_client/src/model/verification_relationship.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'wallet_key_dto.g.dart';

/// Detailed information about a wallet key. Multiple keys are only supported for did:web wallets.
///
/// Properties:
/// * [keyId] - wallet-scoped key identifier (e.g., \"key-1\")
/// * [keyType] - cryptographic algorithm used by this key
/// * [keyAri] - ARI identifier for the key (e.g., \"ari:key:...\")
/// * [relationships] - verification relationships this key supports
@BuiltValue()
abstract class WalletKeyDto
    implements Built<WalletKeyDto, WalletKeyDtoBuilder> {
  /// wallet-scoped key identifier (e.g., \"key-1\")
  @BuiltValueField(wireName: r'keyId')
  String? get keyId;

  /// cryptographic algorithm used by this key
  @BuiltValueField(wireName: r'keyType')
  WalletKeyDtoKeyTypeEnum? get keyType;
  // enum keyTypeEnum {  secp256k1,  ed25519,  p256,  };

  /// ARI identifier for the key (e.g., \"ari:key:...\")
  @BuiltValueField(wireName: r'keyAri')
  String? get keyAri;

  /// verification relationships this key supports
  @BuiltValueField(wireName: r'relationships')
  BuiltList<VerificationRelationship>? get relationships;

  WalletKeyDto._();

  factory WalletKeyDto([void updates(WalletKeyDtoBuilder b)]) = _$WalletKeyDto;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(WalletKeyDtoBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<WalletKeyDto> get serializer => _$WalletKeyDtoSerializer();
}

class _$WalletKeyDtoSerializer implements PrimitiveSerializer<WalletKeyDto> {
  @override
  final Iterable<Type> types = const [WalletKeyDto, _$WalletKeyDto];

  @override
  final String wireName = r'WalletKeyDto';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    WalletKeyDto object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    if (object.keyId != null) {
      yield r'keyId';
      yield serializers.serialize(
        object.keyId,
        specifiedType: const FullType(String),
      );
    }
    if (object.keyType != null) {
      yield r'keyType';
      yield serializers.serialize(
        object.keyType,
        specifiedType: const FullType(WalletKeyDtoKeyTypeEnum),
      );
    }
    if (object.keyAri != null) {
      yield r'keyAri';
      yield serializers.serialize(
        object.keyAri,
        specifiedType: const FullType(String),
      );
    }
    if (object.relationships != null) {
      yield r'relationships';
      yield serializers.serialize(
        object.relationships,
        specifiedType: const FullType(BuiltList, [
          FullType(VerificationRelationship),
        ]),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    WalletKeyDto object, {
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
    required WalletKeyDtoBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'keyId':
          final valueDes =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(String),
                  )
                  as String;
          result.keyId = valueDes;
          break;
        case r'keyType':
          final valueDes =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(WalletKeyDtoKeyTypeEnum),
                  )
                  as WalletKeyDtoKeyTypeEnum;
          result.keyType = valueDes;
          break;
        case r'keyAri':
          final valueDes =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(String),
                  )
                  as String;
          result.keyAri = valueDes;
          break;
        case r'relationships':
          final valueDes =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(BuiltList, [
                      FullType(VerificationRelationship),
                    ]),
                  )
                  as BuiltList<VerificationRelationship>;
          result.relationships.replace(valueDes);
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  WalletKeyDto deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = WalletKeyDtoBuilder();
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

class WalletKeyDtoKeyTypeEnum extends EnumClass {
  /// cryptographic algorithm used by this key
  @BuiltValueEnumConst(wireName: r'secp256k1')
  static const WalletKeyDtoKeyTypeEnum secp256k1 =
      _$walletKeyDtoKeyTypeEnum_secp256k1;

  /// cryptographic algorithm used by this key
  @BuiltValueEnumConst(wireName: r'ed25519')
  static const WalletKeyDtoKeyTypeEnum ed25519 =
      _$walletKeyDtoKeyTypeEnum_ed25519;

  /// cryptographic algorithm used by this key
  @BuiltValueEnumConst(wireName: r'p256')
  static const WalletKeyDtoKeyTypeEnum p256 = _$walletKeyDtoKeyTypeEnum_p256;

  static Serializer<WalletKeyDtoKeyTypeEnum> get serializer =>
      _$walletKeyDtoKeyTypeEnumSerializer;

  const WalletKeyDtoKeyTypeEnum._(String name) : super(name);

  static BuiltSet<WalletKeyDtoKeyTypeEnum> get values =>
      _$walletKeyDtoKeyTypeEnumValues;
  static WalletKeyDtoKeyTypeEnum valueOf(String name) =>
      _$walletKeyDtoKeyTypeEnumValueOf(name);
}
