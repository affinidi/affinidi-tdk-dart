//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'passkey_dto.g.dart';

/// PasskeyDto
///
/// Properties:
/// * [id]
/// * [displayName]
/// * [createdAt] - creation date and time in ISO-8601 format, e.g. 2023-09-20T07:12:13
@BuiltValue()
abstract class PasskeyDto implements Built<PasskeyDto, PasskeyDtoBuilder> {
  @BuiltValueField(wireName: r'id')
  String get id;

  @BuiltValueField(wireName: r'displayName')
  String get displayName;

  /// creation date and time in ISO-8601 format, e.g. 2023-09-20T07:12:13
  @BuiltValueField(wireName: r'createdAt')
  String get createdAt;

  PasskeyDto._();

  factory PasskeyDto([void updates(PasskeyDtoBuilder b)]) = _$PasskeyDto;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(PasskeyDtoBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<PasskeyDto> get serializer => _$PasskeyDtoSerializer();
}

class _$PasskeyDtoSerializer implements PrimitiveSerializer<PasskeyDto> {
  @override
  final Iterable<Type> types = const [PasskeyDto, _$PasskeyDto];

  @override
  final String wireName = r'PasskeyDto';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    PasskeyDto object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'id';
    yield serializers.serialize(
      object.id,
      specifiedType: const FullType(String),
    );
    yield r'displayName';
    yield serializers.serialize(
      object.displayName,
      specifiedType: const FullType(String),
    );
    yield r'createdAt';
    yield serializers.serialize(
      object.createdAt,
      specifiedType: const FullType(String),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    PasskeyDto object, {
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
    required PasskeyDtoBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'id':
          final valueDes =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(String),
                  )
                  as String;
          result.id = valueDes;
          break;
        case r'displayName':
          final valueDes =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(String),
                  )
                  as String;
          result.displayName = valueDes;
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
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  PasskeyDto deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = PasskeyDtoBuilder();
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
