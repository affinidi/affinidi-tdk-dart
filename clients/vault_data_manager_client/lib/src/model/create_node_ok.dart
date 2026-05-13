//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/json_object.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'create_node_ok.g.dart';

/// CreateNodeOK
///
/// Properties:
/// * [nodeId]
/// * [createdAt] - creation date/time
/// * [modifiedAt] - modification date/time
/// * [url]
/// * [link]
/// * [fields]
@BuiltValue()
abstract class CreateNodeOK
    implements Built<CreateNodeOK, CreateNodeOKBuilder> {
  @BuiltValueField(wireName: r'nodeId')
  String get nodeId;

  /// creation date/time
  @BuiltValueField(wireName: r'createdAt')
  String get createdAt;

  /// modification date/time
  @BuiltValueField(wireName: r'modifiedAt')
  String get modifiedAt;

  @BuiltValueField(wireName: r'url')
  String? get url;

  @BuiltValueField(wireName: r'link')
  String? get link;

  @BuiltValueField(wireName: r'fields')
  BuiltMap<String, JsonObject?>? get fields;

  CreateNodeOK._();

  factory CreateNodeOK([void updates(CreateNodeOKBuilder b)]) = _$CreateNodeOK;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(CreateNodeOKBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<CreateNodeOK> get serializer => _$CreateNodeOKSerializer();
}

class _$CreateNodeOKSerializer implements PrimitiveSerializer<CreateNodeOK> {
  @override
  final Iterable<Type> types = const [CreateNodeOK, _$CreateNodeOK];

  @override
  final String wireName = r'CreateNodeOK';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    CreateNodeOK object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'nodeId';
    yield serializers.serialize(
      object.nodeId,
      specifiedType: const FullType(String),
    );
    yield r'createdAt';
    yield serializers.serialize(
      object.createdAt,
      specifiedType: const FullType(String),
    );
    yield r'modifiedAt';
    yield serializers.serialize(
      object.modifiedAt,
      specifiedType: const FullType(String),
    );
    if (object.url != null) {
      yield r'url';
      yield serializers.serialize(
        object.url,
        specifiedType: const FullType(String),
      );
    }
    if (object.link != null) {
      yield r'link';
      yield serializers.serialize(
        object.link,
        specifiedType: const FullType(String),
      );
    }
    if (object.fields != null) {
      yield r'fields';
      yield serializers.serialize(
        object.fields,
        specifiedType: const FullType(BuiltMap, [
          FullType(String),
          FullType.nullable(JsonObject),
        ]),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    CreateNodeOK object, {
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
    required CreateNodeOKBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'nodeId':
          final valueDes =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(String),
                  )
                  as String;
          result.nodeId = valueDes;
          break;
        case r'createdAt':
          final valueDes =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(String),
                  )
                  as String;
          result.createdAt = valueDes;
          break;
        case r'modifiedAt':
          final valueDes =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(String),
                  )
                  as String;
          result.modifiedAt = valueDes;
          break;
        case r'url':
          final valueDes =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(String),
                  )
                  as String;
          result.url = valueDes;
          break;
        case r'link':
          final valueDes =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(String),
                  )
                  as String;
          result.link = valueDes;
          break;
        case r'fields':
          final valueDes =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(BuiltMap, [
                      FullType(String),
                      FullType.nullable(JsonObject),
                    ]),
                  )
                  as BuiltMap<String, JsonObject?>;
          result.fields.replace(valueDes);
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  CreateNodeOK deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = CreateNodeOKBuilder();
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
