//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'partial_profile_node_dto.g.dart';

/// PartialProfileNodeDto
///
/// Properties:
/// * [id] - A unique identifier of the profile node
/// * [name] - display name of the profile node
/// * [description] - Description of the profile node
/// * [accountIndex] - number that is used for profile DID derivation
/// * [profileMetadata] - A JSON string format containing metadata of the profile node
/// * [accountMetadata] - A JSON string format containing metadata of the account
@BuiltValue()
abstract class PartialProfileNodeDto
    implements Built<PartialProfileNodeDto, PartialProfileNodeDtoBuilder> {
  /// A unique identifier of the profile node
  @BuiltValueField(wireName: r'id')
  String get id;

  /// display name of the profile node
  @BuiltValueField(wireName: r'name')
  String get name;

  /// Description of the profile node
  @BuiltValueField(wireName: r'description')
  String? get description;

  /// number that is used for profile DID derivation
  @BuiltValueField(wireName: r'accountIndex')
  int get accountIndex;

  /// A JSON string format containing metadata of the profile node
  @BuiltValueField(wireName: r'profileMetadata')
  String? get profileMetadata;

  /// A JSON string format containing metadata of the account
  @BuiltValueField(wireName: r'accountMetadata')
  String? get accountMetadata;

  PartialProfileNodeDto._();

  factory PartialProfileNodeDto([
    void updates(PartialProfileNodeDtoBuilder b),
  ]) = _$PartialProfileNodeDto;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(PartialProfileNodeDtoBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<PartialProfileNodeDto> get serializer =>
      _$PartialProfileNodeDtoSerializer();
}

class _$PartialProfileNodeDtoSerializer
    implements PrimitiveSerializer<PartialProfileNodeDto> {
  @override
  final Iterable<Type> types = const [
    PartialProfileNodeDto,
    _$PartialProfileNodeDto,
  ];

  @override
  final String wireName = r'PartialProfileNodeDto';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    PartialProfileNodeDto object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'id';
    yield serializers.serialize(
      object.id,
      specifiedType: const FullType(String),
    );
    yield r'name';
    yield serializers.serialize(
      object.name,
      specifiedType: const FullType(String),
    );
    if (object.description != null) {
      yield r'description';
      yield serializers.serialize(
        object.description,
        specifiedType: const FullType(String),
      );
    }
    yield r'accountIndex';
    yield serializers.serialize(
      object.accountIndex,
      specifiedType: const FullType(int),
    );
    if (object.profileMetadata != null) {
      yield r'profileMetadata';
      yield serializers.serialize(
        object.profileMetadata,
        specifiedType: const FullType(String),
      );
    }
    if (object.accountMetadata != null) {
      yield r'accountMetadata';
      yield serializers.serialize(
        object.accountMetadata,
        specifiedType: const FullType(String),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    PartialProfileNodeDto object, {
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
    required PartialProfileNodeDtoBuilder result,
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
        case r'name':
          final valueDes =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(String),
                  )
                  as String;
          result.name = valueDes;
          break;
        case r'description':
          final valueDes =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(String),
                  )
                  as String;
          result.description = valueDes;
          break;
        case r'accountIndex':
          final valueDes =
              serializers.deserialize(value, specifiedType: const FullType(int))
                  as int;
          result.accountIndex = valueDes;
          break;
        case r'profileMetadata':
          final valueDes =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(String),
                  )
                  as String;
          result.profileMetadata = valueDes;
          break;
        case r'accountMetadata':
          final valueDes =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(String),
                  )
                  as String;
          result.accountMetadata = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  PartialProfileNodeDto deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = PartialProfileNodeDtoBuilder();
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
