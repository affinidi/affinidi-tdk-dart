//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:affinidi_tdk_vault_data_manager_client/src/model/partial_profile_node_dto.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'list_profiles_ok.g.dart';

/// ListProfilesOK
///
/// Properties:
/// * [nodes]
@BuiltValue()
abstract class ListProfilesOK
    implements Built<ListProfilesOK, ListProfilesOKBuilder> {
  @BuiltValueField(wireName: r'nodes')
  BuiltList<PartialProfileNodeDto>? get nodes;

  ListProfilesOK._();

  factory ListProfilesOK([void updates(ListProfilesOKBuilder b)]) =
      _$ListProfilesOK;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(ListProfilesOKBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<ListProfilesOK> get serializer =>
      _$ListProfilesOKSerializer();
}

class _$ListProfilesOKSerializer
    implements PrimitiveSerializer<ListProfilesOK> {
  @override
  final Iterable<Type> types = const [ListProfilesOK, _$ListProfilesOK];

  @override
  final String wireName = r'ListProfilesOK';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    ListProfilesOK object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    if (object.nodes != null) {
      yield r'nodes';
      yield serializers.serialize(
        object.nodes,
        specifiedType: const FullType(BuiltList, [
          FullType(PartialProfileNodeDto),
        ]),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    ListProfilesOK object, {
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
    required ListProfilesOKBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'nodes':
          final valueDes =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(BuiltList, [
                      FullType(PartialProfileNodeDto),
                    ]),
                  )
                  as BuiltList<PartialProfileNodeDto>;
          result.nodes.replace(valueDes);
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  ListProfilesOK deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = ListProfilesOKBuilder();
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
