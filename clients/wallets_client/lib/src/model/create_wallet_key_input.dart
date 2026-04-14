//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:affinidi_tdk_wallets_client/src/model/verification_relationship.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'create_wallet_key_input.g.dart';

/// Input for adding a new key to a wallet. Only supported for did:web ATM.
///
/// Properties:
/// * [keyType] - cryptographic algorithm for the new key
/// * [relationships] - verification relationships for the key.
@BuiltValue()
abstract class CreateWalletKeyInput
    implements Built<CreateWalletKeyInput, CreateWalletKeyInputBuilder> {
  /// cryptographic algorithm for the new key
  @BuiltValueField(wireName: r'keyType')
  CreateWalletKeyInputKeyTypeEnum get keyType;
  // enum keyTypeEnum {  secp256k1,  ed25519,  p256,  };

  /// verification relationships for the key.
  @BuiltValueField(wireName: r'relationships')
  BuiltList<VerificationRelationship> get relationships;

  CreateWalletKeyInput._();

  factory CreateWalletKeyInput([void updates(CreateWalletKeyInputBuilder b)]) =
      _$CreateWalletKeyInput;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(CreateWalletKeyInputBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<CreateWalletKeyInput> get serializer =>
      _$CreateWalletKeyInputSerializer();
}

class _$CreateWalletKeyInputSerializer
    implements PrimitiveSerializer<CreateWalletKeyInput> {
  @override
  final Iterable<Type> types = const [
    CreateWalletKeyInput,
    _$CreateWalletKeyInput,
  ];

  @override
  final String wireName = r'CreateWalletKeyInput';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    CreateWalletKeyInput object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'keyType';
    yield serializers.serialize(
      object.keyType,
      specifiedType: const FullType(CreateWalletKeyInputKeyTypeEnum),
    );
    yield r'relationships';
    yield serializers.serialize(
      object.relationships,
      specifiedType: const FullType(BuiltList, [
        FullType(VerificationRelationship),
      ]),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    CreateWalletKeyInput object, {
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
    required CreateWalletKeyInputBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'keyType':
          final valueDes =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(
                      CreateWalletKeyInputKeyTypeEnum,
                    ),
                  )
                  as CreateWalletKeyInputKeyTypeEnum;
          result.keyType = valueDes;
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
  CreateWalletKeyInput deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = CreateWalletKeyInputBuilder();
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

class CreateWalletKeyInputKeyTypeEnum extends EnumClass {
  /// cryptographic algorithm for the new key
  @BuiltValueEnumConst(wireName: r'secp256k1')
  static const CreateWalletKeyInputKeyTypeEnum secp256k1 =
      _$createWalletKeyInputKeyTypeEnum_secp256k1;

  /// cryptographic algorithm for the new key
  @BuiltValueEnumConst(wireName: r'ed25519')
  static const CreateWalletKeyInputKeyTypeEnum ed25519 =
      _$createWalletKeyInputKeyTypeEnum_ed25519;

  /// cryptographic algorithm for the new key
  @BuiltValueEnumConst(wireName: r'p256')
  static const CreateWalletKeyInputKeyTypeEnum p256 =
      _$createWalletKeyInputKeyTypeEnum_p256;

  static Serializer<CreateWalletKeyInputKeyTypeEnum> get serializer =>
      _$createWalletKeyInputKeyTypeEnumSerializer;

  const CreateWalletKeyInputKeyTypeEnum._(String name) : super(name);

  static BuiltSet<CreateWalletKeyInputKeyTypeEnum> get values =>
      _$createWalletKeyInputKeyTypeEnumValues;
  static CreateWalletKeyInputKeyTypeEnum valueOf(String name) =>
      _$createWalletKeyInputKeyTypeEnumValueOf(name);
}
