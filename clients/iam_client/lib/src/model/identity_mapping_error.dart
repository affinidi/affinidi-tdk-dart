//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:affinidi_tdk_iam_client/src/model/unexpected_error_details_inner.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'identity_mapping_error.g.dart';

/// IdentityMappingError
///
/// Properties:
/// * [name]
/// * [message]
/// * [httpStatusCode]
/// * [traceId]
/// * [details]
@BuiltValue()
abstract class IdentityMappingError
    implements Built<IdentityMappingError, IdentityMappingErrorBuilder> {
  @BuiltValueField(wireName: r'name')
  IdentityMappingErrorNameEnum get name;
  // enum nameEnum {  IdentityMappingError,  };

  @BuiltValueField(wireName: r'message')
  IdentityMappingErrorMessageEnum get message;
  // enum messageEnum {  Unable to map the authenticated principal to an identity.,  };

  @BuiltValueField(wireName: r'httpStatusCode')
  IdentityMappingErrorHttpStatusCodeEnum get httpStatusCode;
  // enum httpStatusCodeEnum {  404,  };

  @BuiltValueField(wireName: r'traceId')
  String get traceId;

  @BuiltValueField(wireName: r'details')
  BuiltList<UnexpectedErrorDetailsInner>? get details;

  IdentityMappingError._();

  factory IdentityMappingError([void updates(IdentityMappingErrorBuilder b)]) =
      _$IdentityMappingError;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(IdentityMappingErrorBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<IdentityMappingError> get serializer =>
      _$IdentityMappingErrorSerializer();
}

class _$IdentityMappingErrorSerializer
    implements PrimitiveSerializer<IdentityMappingError> {
  @override
  final Iterable<Type> types = const [
    IdentityMappingError,
    _$IdentityMappingError,
  ];

  @override
  final String wireName = r'IdentityMappingError';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    IdentityMappingError object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'name';
    yield serializers.serialize(
      object.name,
      specifiedType: const FullType(IdentityMappingErrorNameEnum),
    );
    yield r'message';
    yield serializers.serialize(
      object.message,
      specifiedType: const FullType(IdentityMappingErrorMessageEnum),
    );
    yield r'httpStatusCode';
    yield serializers.serialize(
      object.httpStatusCode,
      specifiedType: const FullType(IdentityMappingErrorHttpStatusCodeEnum),
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
    IdentityMappingError object, {
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
    required IdentityMappingErrorBuilder result,
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
                    specifiedType: const FullType(IdentityMappingErrorNameEnum),
                  )
                  as IdentityMappingErrorNameEnum;
          result.name = valueDes;
          break;
        case r'message':
          final valueDes =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(
                      IdentityMappingErrorMessageEnum,
                    ),
                  )
                  as IdentityMappingErrorMessageEnum;
          result.message = valueDes;
          break;
        case r'httpStatusCode':
          final valueDes =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(
                      IdentityMappingErrorHttpStatusCodeEnum,
                    ),
                  )
                  as IdentityMappingErrorHttpStatusCodeEnum;
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
  IdentityMappingError deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = IdentityMappingErrorBuilder();
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

class IdentityMappingErrorNameEnum extends EnumClass {
  @BuiltValueEnumConst(wireName: r'IdentityMappingError')
  static const IdentityMappingErrorNameEnum identityMappingError =
      _$identityMappingErrorNameEnum_identityMappingError;

  static Serializer<IdentityMappingErrorNameEnum> get serializer =>
      _$identityMappingErrorNameEnumSerializer;

  const IdentityMappingErrorNameEnum._(String name) : super(name);

  static BuiltSet<IdentityMappingErrorNameEnum> get values =>
      _$identityMappingErrorNameEnumValues;
  static IdentityMappingErrorNameEnum valueOf(String name) =>
      _$identityMappingErrorNameEnumValueOf(name);
}

class IdentityMappingErrorMessageEnum extends EnumClass {
  @BuiltValueEnumConst(
    wireName: r'Unable to map the authenticated principal to an identity.',
  )
  static const IdentityMappingErrorMessageEnum
  unableToMapTheAuthenticatedPrincipalToAnIdentityPeriod =
      _$identityMappingErrorMessageEnum_unableToMapTheAuthenticatedPrincipalToAnIdentityPeriod;

  static Serializer<IdentityMappingErrorMessageEnum> get serializer =>
      _$identityMappingErrorMessageEnumSerializer;

  const IdentityMappingErrorMessageEnum._(String name) : super(name);

  static BuiltSet<IdentityMappingErrorMessageEnum> get values =>
      _$identityMappingErrorMessageEnumValues;
  static IdentityMappingErrorMessageEnum valueOf(String name) =>
      _$identityMappingErrorMessageEnumValueOf(name);
}

class IdentityMappingErrorHttpStatusCodeEnum extends EnumClass {
  @BuiltValueEnumConst(wireNumber: 404)
  static const IdentityMappingErrorHttpStatusCodeEnum number404 =
      _$identityMappingErrorHttpStatusCodeEnum_number404;

  static Serializer<IdentityMappingErrorHttpStatusCodeEnum> get serializer =>
      _$identityMappingErrorHttpStatusCodeEnumSerializer;

  const IdentityMappingErrorHttpStatusCodeEnum._(String name) : super(name);

  static BuiltSet<IdentityMappingErrorHttpStatusCodeEnum> get values =>
      _$identityMappingErrorHttpStatusCodeEnumValues;
  static IdentityMappingErrorHttpStatusCodeEnum valueOf(String name) =>
      _$identityMappingErrorHttpStatusCodeEnumValueOf(name);
}
