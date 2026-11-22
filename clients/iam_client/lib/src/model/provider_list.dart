//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:affinidi_tdk_iam_client/src/model/provider_dto.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'provider_list.g.dart';

/// ProviderList
///
/// Properties:
/// * [providers]
@BuiltValue()
abstract class ProviderList
    implements Built<ProviderList, ProviderListBuilder> {
  @BuiltValueField(wireName: r'providers')
  BuiltList<ProviderDto> get providers;

  ProviderList._();

  factory ProviderList([void updates(ProviderListBuilder b)]) = _$ProviderList;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(ProviderListBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<ProviderList> get serializer => _$ProviderListSerializer();
}

class _$ProviderListSerializer implements PrimitiveSerializer<ProviderList> {
  @override
  final Iterable<Type> types = const [ProviderList, _$ProviderList];

  @override
  final String wireName = r'ProviderList';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    ProviderList object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'providers';
    yield serializers.serialize(
      object.providers,
      specifiedType: const FullType(BuiltList, [FullType(ProviderDto)]),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    ProviderList object, {
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
    required ProviderListBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'providers':
          final valueDes =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(BuiltList, [
                      FullType(ProviderDto),
                    ]),
                  )
                  as BuiltList<ProviderDto>;
          result.providers.replace(valueDes);
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  ProviderList deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = ProviderListBuilder();
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
