//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:affinidi_tdk_iam_client/src/model/unexpected_error_details_inner.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'upstream_unavailable_error.g.dart';

/// UpstreamUnavailableError
///
/// Properties:
/// * [name]
/// * [message]
/// * [httpStatusCode]
/// * [traceId]
/// * [details]
@BuiltValue()
abstract class UpstreamUnavailableError
    implements
        Built<UpstreamUnavailableError, UpstreamUnavailableErrorBuilder> {
  @BuiltValueField(wireName: r'name')
  UpstreamUnavailableErrorNameEnum get name;
  // enum nameEnum {  UpstreamUnavailableError,  };

  @BuiltValueField(wireName: r'message')
  UpstreamUnavailableErrorMessageEnum get message;
  // enum messageEnum {  The upstream identity service is unavailable.,  };

  @BuiltValueField(wireName: r'httpStatusCode')
  UpstreamUnavailableErrorHttpStatusCodeEnum get httpStatusCode;
  // enum httpStatusCodeEnum {  424,  };

  @BuiltValueField(wireName: r'traceId')
  String get traceId;

  @BuiltValueField(wireName: r'details')
  BuiltList<UnexpectedErrorDetailsInner>? get details;

  UpstreamUnavailableError._();

  factory UpstreamUnavailableError([
    void updates(UpstreamUnavailableErrorBuilder b),
  ]) = _$UpstreamUnavailableError;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(UpstreamUnavailableErrorBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<UpstreamUnavailableError> get serializer =>
      _$UpstreamUnavailableErrorSerializer();
}

class _$UpstreamUnavailableErrorSerializer
    implements PrimitiveSerializer<UpstreamUnavailableError> {
  @override
  final Iterable<Type> types = const [
    UpstreamUnavailableError,
    _$UpstreamUnavailableError,
  ];

  @override
  final String wireName = r'UpstreamUnavailableError';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    UpstreamUnavailableError object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'name';
    yield serializers.serialize(
      object.name,
      specifiedType: const FullType(UpstreamUnavailableErrorNameEnum),
    );
    yield r'message';
    yield serializers.serialize(
      object.message,
      specifiedType: const FullType(UpstreamUnavailableErrorMessageEnum),
    );
    yield r'httpStatusCode';
    yield serializers.serialize(
      object.httpStatusCode,
      specifiedType: const FullType(UpstreamUnavailableErrorHttpStatusCodeEnum),
    );
    yield r'traceId';
    yield serializers.serialize(
      object.traceId,
      specifiedType: const FullType(String),
    );
    if (object.details != null) {
      yield r'details';
      yield serializers.serialize(
        object.details,
        specifiedType: const FullType(BuiltList, [
          FullType(UnexpectedErrorDetailsInner),
        ]),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    UpstreamUnavailableError object, {
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
    required UpstreamUnavailableErrorBuilder result,
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
                    specifiedType: const FullType(
                      UpstreamUnavailableErrorNameEnum,
                    ),
                  )
                  as UpstreamUnavailableErrorNameEnum;
          result.name = valueDes;
          break;
        case r'message':
          final valueDes =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(
                      UpstreamUnavailableErrorMessageEnum,
                    ),
                  )
                  as UpstreamUnavailableErrorMessageEnum;
          result.message = valueDes;
          break;
        case r'httpStatusCode':
          final valueDes =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(
                      UpstreamUnavailableErrorHttpStatusCodeEnum,
                    ),
                  )
                  as UpstreamUnavailableErrorHttpStatusCodeEnum;
          result.httpStatusCode = valueDes;
          break;
        case r'traceId':
          final valueDes =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(String),
                  )
                  as String;
          result.traceId = valueDes;
          break;
        case r'details':
          final valueDes =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(BuiltList, [
                      FullType(UnexpectedErrorDetailsInner),
                    ]),
                  )
                  as BuiltList<UnexpectedErrorDetailsInner>;
          result.details.replace(valueDes);
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  UpstreamUnavailableError deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = UpstreamUnavailableErrorBuilder();
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

class UpstreamUnavailableErrorNameEnum extends EnumClass {
  @BuiltValueEnumConst(wireName: r'UpstreamUnavailableError')
  static const UpstreamUnavailableErrorNameEnum upstreamUnavailableError =
      _$upstreamUnavailableErrorNameEnum_upstreamUnavailableError;

  static Serializer<UpstreamUnavailableErrorNameEnum> get serializer =>
      _$upstreamUnavailableErrorNameEnumSerializer;

  const UpstreamUnavailableErrorNameEnum._(String name) : super(name);

  static BuiltSet<UpstreamUnavailableErrorNameEnum> get values =>
      _$upstreamUnavailableErrorNameEnumValues;
  static UpstreamUnavailableErrorNameEnum valueOf(String name) =>
      _$upstreamUnavailableErrorNameEnumValueOf(name);
}

class UpstreamUnavailableErrorMessageEnum extends EnumClass {
  @BuiltValueEnumConst(
    wireName: r'The upstream identity service is unavailable.',
  )
  static const UpstreamUnavailableErrorMessageEnum
  theUpstreamIdentityServiceIsUnavailablePeriod =
      _$upstreamUnavailableErrorMessageEnum_theUpstreamIdentityServiceIsUnavailablePeriod;

  static Serializer<UpstreamUnavailableErrorMessageEnum> get serializer =>
      _$upstreamUnavailableErrorMessageEnumSerializer;

  const UpstreamUnavailableErrorMessageEnum._(String name) : super(name);

  static BuiltSet<UpstreamUnavailableErrorMessageEnum> get values =>
      _$upstreamUnavailableErrorMessageEnumValues;
  static UpstreamUnavailableErrorMessageEnum valueOf(String name) =>
      _$upstreamUnavailableErrorMessageEnumValueOf(name);
}

class UpstreamUnavailableErrorHttpStatusCodeEnum extends EnumClass {
  @BuiltValueEnumConst(wireNumber: 424)
  static const UpstreamUnavailableErrorHttpStatusCodeEnum number424 =
      _$upstreamUnavailableErrorHttpStatusCodeEnum_number424;

  static Serializer<UpstreamUnavailableErrorHttpStatusCodeEnum>
  get serializer => _$upstreamUnavailableErrorHttpStatusCodeEnumSerializer;

  const UpstreamUnavailableErrorHttpStatusCodeEnum._(String name) : super(name);

  static BuiltSet<UpstreamUnavailableErrorHttpStatusCodeEnum> get values =>
      _$upstreamUnavailableErrorHttpStatusCodeEnumValues;
  static UpstreamUnavailableErrorHttpStatusCodeEnum valueOf(String name) =>
      _$upstreamUnavailableErrorHttpStatusCodeEnumValueOf(name);
}
