//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:affinidi_tdk_wallets_client/src/model/verification_relationship.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'update_wallet_key_input.g.dart';

/// Input for updating an existing wallet key. Only supported for did:web wallets.
///
/// Properties:
/// * [relationships] - verification relationships for the key
@BuiltValue()
abstract class UpdateWalletKeyInput
    implements Built<UpdateWalletKeyInput, UpdateWalletKeyInputBuilder> {
  /// verification relationships for the key
  @BuiltValueField(wireName: r'relationships')
  BuiltList<VerificationRelationship>? get relationships;

  UpdateWalletKeyInput._();

  factory UpdateWalletKeyInput([void updates(UpdateWalletKeyInputBuilder b)]) =
      _$UpdateWalletKeyInput;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(UpdateWalletKeyInputBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<UpdateWalletKeyInput> get serializer =>
      _$UpdateWalletKeyInputSerializer();
}

class _$UpdateWalletKeyInputSerializer
    implements PrimitiveSerializer<UpdateWalletKeyInput> {
  @override
  final Iterable<Type> types = const [
    UpdateWalletKeyInput,
    _$UpdateWalletKeyInput,
  ];

  @override
  final String wireName = r'UpdateWalletKeyInput';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    UpdateWalletKeyInput object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
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
    UpdateWalletKeyInput object, {
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
    required UpdateWalletKeyInputBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
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
  UpdateWalletKeyInput deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = UpdateWalletKeyInputBuilder();
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
