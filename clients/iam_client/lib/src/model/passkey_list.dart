//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:affinidi_tdk_iam_client/src/model/passkey_dto.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'passkey_list.g.dart';

/// PasskeyList
///
/// Properties:
/// * [passkeys]
@BuiltValue()
abstract class PasskeyList implements Built<PasskeyList, PasskeyListBuilder> {
  @BuiltValueField(wireName: r'passkeys')
  BuiltList<PasskeyDto> get passkeys;

  PasskeyList._();

  factory PasskeyList([void updates(PasskeyListBuilder b)]) = _$PasskeyList;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(PasskeyListBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<PasskeyList> get serializer => _$PasskeyListSerializer();
}

class _$PasskeyListSerializer implements PrimitiveSerializer<PasskeyList> {
  @override
  final Iterable<Type> types = const [PasskeyList, _$PasskeyList];

  @override
  final String wireName = r'PasskeyList';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    PasskeyList object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'passkeys';
    yield serializers.serialize(
      object.passkeys,
      specifiedType: const FullType(BuiltList, [FullType(PasskeyDto)]),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    PasskeyList object, {
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
    required PasskeyListBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'passkeys':
          final valueDes =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(BuiltList, [
                      FullType(PasskeyDto),
                    ]),
                  )
                  as BuiltList<PasskeyDto>;
          result.passkeys.replace(valueDes);
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  PasskeyList deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = PasskeyListBuilder();
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
