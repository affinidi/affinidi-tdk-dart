//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:affinidi_tdk_iam_client/src/model/unexpected_error_details_inner.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'malformed_upstream_response_error.g.dart';

/// MalformedUpstreamResponseError
///
/// Properties:
/// * [name]
/// * [message]
/// * [httpStatusCode]
/// * [traceId]
/// * [details]
@BuiltValue()
abstract class MalformedUpstreamResponseError
    implements
        Built<
          MalformedUpstreamResponseError,
          MalformedUpstreamResponseErrorBuilder
        > {
  @BuiltValueField(wireName: r'name')
  MalformedUpstreamResponseErrorNameEnum get name;
  // enum nameEnum {  MalformedUpstreamResponseError,  };

  @BuiltValueField(wireName: r'message')
  MalformedUpstreamResponseErrorMessageEnum get message;
  // enum messageEnum {  The upstream identity service returned an unexpected response.,  };

  @BuiltValueField(wireName: r'httpStatusCode')
  MalformedUpstreamResponseErrorHttpStatusCodeEnum get httpStatusCode;
  // enum httpStatusCodeEnum {  422,  };

  @BuiltValueField(wireName: r'traceId')
  String get traceId;

  @BuiltValueField(wireName: r'details')
  BuiltList<UnexpectedErrorDetailsInner>? get details;

  MalformedUpstreamResponseError._();

  factory MalformedUpstreamResponseError([
    void updates(MalformedUpstreamResponseErrorBuilder b),
  ]) = _$MalformedUpstreamResponseError;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(MalformedUpstreamResponseErrorBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<MalformedUpstreamResponseError> get serializer =>
      _$MalformedUpstreamResponseErrorSerializer();
}

class _$MalformedUpstreamResponseErrorSerializer
    implements PrimitiveSerializer<MalformedUpstreamResponseError> {
  @override
  final Iterable<Type> types = const [
    MalformedUpstreamResponseError,
    _$MalformedUpstreamResponseError,
  ];

  @override
  final String wireName = r'MalformedUpstreamResponseError';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    MalformedUpstreamResponseError object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'name';
    yield serializers.serialize(
      object.name,
      specifiedType: const FullType(MalformedUpstreamResponseErrorNameEnum),
    );
    yield r'message';
    yield serializers.serialize(
      object.message,
      specifiedType: const FullType(MalformedUpstreamResponseErrorMessageEnum),
    );
    yield r'httpStatusCode';
    yield serializers.serialize(
      object.httpStatusCode,
      specifiedType: const FullType(
        MalformedUpstreamResponseErrorHttpStatusCodeEnum,
      ),
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
    MalformedUpstreamResponseError object, {
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
    required MalformedUpstreamResponseErrorBuilder result,
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
                      MalformedUpstreamResponseErrorNameEnum,
                    ),
                  )
                  as MalformedUpstreamResponseErrorNameEnum;
          result.name = valueDes;
          break;
        case r'message':
          final valueDes =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(
                      MalformedUpstreamResponseErrorMessageEnum,
                    ),
                  )
                  as MalformedUpstreamResponseErrorMessageEnum;
          result.message = valueDes;
          break;
        case r'httpStatusCode':
          final valueDes =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(
                      MalformedUpstreamResponseErrorHttpStatusCodeEnum,
                    ),
                  )
                  as MalformedUpstreamResponseErrorHttpStatusCodeEnum;
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
  MalformedUpstreamResponseError deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = MalformedUpstreamResponseErrorBuilder();
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

class MalformedUpstreamResponseErrorNameEnum extends EnumClass {
  @BuiltValueEnumConst(wireName: r'MalformedUpstreamResponseError')
  static const MalformedUpstreamResponseErrorNameEnum
  malformedUpstreamResponseError =
      _$malformedUpstreamResponseErrorNameEnum_malformedUpstreamResponseError;

  static Serializer<MalformedUpstreamResponseErrorNameEnum> get serializer =>
      _$malformedUpstreamResponseErrorNameEnumSerializer;

  const MalformedUpstreamResponseErrorNameEnum._(String name) : super(name);

  static BuiltSet<MalformedUpstreamResponseErrorNameEnum> get values =>
      _$malformedUpstreamResponseErrorNameEnumValues;
  static MalformedUpstreamResponseErrorNameEnum valueOf(String name) =>
      _$malformedUpstreamResponseErrorNameEnumValueOf(name);
}

class MalformedUpstreamResponseErrorMessageEnum extends EnumClass {
  @BuiltValueEnumConst(
    wireName: r'The upstream identity service returned an unexpected response.',
  )
  static const MalformedUpstreamResponseErrorMessageEnum
  theUpstreamIdentityServiceReturnedAnUnexpectedResponsePeriod =
      _$malformedUpstreamResponseErrorMessageEnum_theUpstreamIdentityServiceReturnedAnUnexpectedResponsePeriod;

  static Serializer<MalformedUpstreamResponseErrorMessageEnum> get serializer =>
      _$malformedUpstreamResponseErrorMessageEnumSerializer;

  const MalformedUpstreamResponseErrorMessageEnum._(String name) : super(name);

  static BuiltSet<MalformedUpstreamResponseErrorMessageEnum> get values =>
      _$malformedUpstreamResponseErrorMessageEnumValues;
  static MalformedUpstreamResponseErrorMessageEnum valueOf(String name) =>
      _$malformedUpstreamResponseErrorMessageEnumValueOf(name);
}

class MalformedUpstreamResponseErrorHttpStatusCodeEnum extends EnumClass {
  @BuiltValueEnumConst(wireNumber: 422)
  static const MalformedUpstreamResponseErrorHttpStatusCodeEnum number422 =
      _$malformedUpstreamResponseErrorHttpStatusCodeEnum_number422;

  static Serializer<MalformedUpstreamResponseErrorHttpStatusCodeEnum>
  get serializer =>
      _$malformedUpstreamResponseErrorHttpStatusCodeEnumSerializer;

  const MalformedUpstreamResponseErrorHttpStatusCodeEnum._(String name)
    : super(name);

  static BuiltSet<MalformedUpstreamResponseErrorHttpStatusCodeEnum>
  get values => _$malformedUpstreamResponseErrorHttpStatusCodeEnumValues;
  static MalformedUpstreamResponseErrorHttpStatusCodeEnum valueOf(
    String name,
  ) => _$malformedUpstreamResponseErrorHttpStatusCodeEnumValueOf(name);
}
