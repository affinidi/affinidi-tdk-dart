//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:affinidi_tdk_wallets_client/src/model/service_endpoint_dto.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'list_service_endpoints_ok.g.dart';

/// Response containing service endpoints
///
/// Properties:
/// * [services] - list of service endpoints
@BuiltValue()
abstract class ListServiceEndpointsOK
    implements Built<ListServiceEndpointsOK, ListServiceEndpointsOKBuilder> {
  /// list of service endpoints
  @BuiltValueField(wireName: r'services')
  BuiltList<ServiceEndpointDto> get services;

  ListServiceEndpointsOK._();

  factory ListServiceEndpointsOK([
    void updates(ListServiceEndpointsOKBuilder b),
  ]) = _$ListServiceEndpointsOK;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(ListServiceEndpointsOKBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<ListServiceEndpointsOK> get serializer =>
      _$ListServiceEndpointsOKSerializer();
}

class _$ListServiceEndpointsOKSerializer
    implements PrimitiveSerializer<ListServiceEndpointsOK> {
  @override
  final Iterable<Type> types = const [
    ListServiceEndpointsOK,
    _$ListServiceEndpointsOK,
  ];

  @override
  final String wireName = r'ListServiceEndpointsOK';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    ListServiceEndpointsOK object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'services';
    yield serializers.serialize(
      object.services,
      specifiedType: const FullType(BuiltList, [FullType(ServiceEndpointDto)]),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    ListServiceEndpointsOK object, {
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
    required ListServiceEndpointsOKBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'services':
          final valueDes =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(BuiltList, [
                      FullType(ServiceEndpointDto),
                    ]),
                  )
                  as BuiltList<ServiceEndpointDto>;
          result.services.replace(valueDes);
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  ListServiceEndpointsOK deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = ListServiceEndpointsOKBuilder();
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
