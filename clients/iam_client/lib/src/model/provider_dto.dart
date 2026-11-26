//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'provider_dto.g.dart';

/// ProviderDto
///
/// Properties:
/// * [id]
/// * [status]
@BuiltValue()
abstract class ProviderDto implements Built<ProviderDto, ProviderDtoBuilder> {
  @BuiltValueField(wireName: r'id')
  String get id;

  @BuiltValueField(wireName: r'status')
  ProviderDtoStatusEnum get status;
  // enum statusEnum {  linked,  unlinked,  };

  ProviderDto._();

  factory ProviderDto([void updates(ProviderDtoBuilder b)]) = _$ProviderDto;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(ProviderDtoBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<ProviderDto> get serializer => _$ProviderDtoSerializer();
}

class _$ProviderDtoSerializer implements PrimitiveSerializer<ProviderDto> {
  @override
  final Iterable<Type> types = const [ProviderDto, _$ProviderDto];

  @override
  final String wireName = r'ProviderDto';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    ProviderDto object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'id';
    yield serializers.serialize(
      object.id,
      specifiedType: const FullType(String),
    );
    yield r'status';
    yield serializers.serialize(
      object.status,
      specifiedType: const FullType(ProviderDtoStatusEnum),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    ProviderDto object, {
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
    required ProviderDtoBuilder result,
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
        case r'status':
          final valueDes =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(ProviderDtoStatusEnum),
                  )
                  as ProviderDtoStatusEnum;
          result.status = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  ProviderDto deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = ProviderDtoBuilder();
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

class ProviderDtoStatusEnum extends EnumClass {
  @BuiltValueEnumConst(wireName: r'linked')
  static const ProviderDtoStatusEnum linked = _$providerDtoStatusEnum_linked;
  @BuiltValueEnumConst(wireName: r'unlinked')
  static const ProviderDtoStatusEnum unlinked =
      _$providerDtoStatusEnum_unlinked;

  static Serializer<ProviderDtoStatusEnum> get serializer =>
      _$providerDtoStatusEnumSerializer;

  const ProviderDtoStatusEnum._(String name) : super(name);

  static BuiltSet<ProviderDtoStatusEnum> get values =>
      _$providerDtoStatusEnumValues;
  static ProviderDtoStatusEnum valueOf(String name) =>
      _$providerDtoStatusEnumValueOf(name);
}
