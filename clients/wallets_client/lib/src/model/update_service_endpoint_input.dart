//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'update_service_endpoint_input.g.dart';

/// Input for updating a service endpoint
///
/// Properties:
/// * [name] - Alphanumeric string with common punctuation (max 100 characters)
/// * [description] - Alphanumeric string with common punctuation (max 500 characters)
/// * [url] - HTTP or HTTPS URL
@BuiltValue()
abstract class UpdateServiceEndpointInput
    implements
        Built<UpdateServiceEndpointInput, UpdateServiceEndpointInputBuilder> {
  /// Alphanumeric string with common punctuation (max 100 characters)
  @BuiltValueField(wireName: r'name')
  String? get name;

  /// Alphanumeric string with common punctuation (max 500 characters)
  @BuiltValueField(wireName: r'description')
  String? get description;

  /// HTTP or HTTPS URL
  @BuiltValueField(wireName: r'url')
  String? get url;

  UpdateServiceEndpointInput._();

  factory UpdateServiceEndpointInput([
    void updates(UpdateServiceEndpointInputBuilder b),
  ]) = _$UpdateServiceEndpointInput;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(UpdateServiceEndpointInputBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<UpdateServiceEndpointInput> get serializer =>
      _$UpdateServiceEndpointInputSerializer();
}

class _$UpdateServiceEndpointInputSerializer
    implements PrimitiveSerializer<UpdateServiceEndpointInput> {
  @override
  final Iterable<Type> types = const [
    UpdateServiceEndpointInput,
    _$UpdateServiceEndpointInput,
  ];

  @override
  final String wireName = r'UpdateServiceEndpointInput';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    UpdateServiceEndpointInput object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    if (object.name != null) {
      yield r'name';
      yield serializers.serialize(
        object.name,
        specifiedType: const FullType(String),
      );
    }
    if (object.description != null) {
      yield r'description';
      yield serializers.serialize(
        object.description,
        specifiedType: const FullType(String),
      );
    }
    if (object.url != null) {
      yield r'url';
      yield serializers.serialize(
        object.url,
        specifiedType: const FullType(String),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    UpdateServiceEndpointInput object, {
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
    required UpdateServiceEndpointInputBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
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
        case r'url':
          final valueDes =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(String),
                  )
                  as String;
          result.url = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  UpdateServiceEndpointInput deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = UpdateServiceEndpointInputBuilder();
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
