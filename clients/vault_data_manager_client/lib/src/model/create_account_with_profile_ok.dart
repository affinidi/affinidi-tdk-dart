//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/json_object.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'create_account_with_profile_ok.g.dart';

/// CreateAccountWithProfileOK
///
/// Properties:
/// * [accountIndex]
/// * [accountDid] - number that is used for profile DID derivation
/// * [profileId] - A unique, randomly generated identifier of created profile
/// * [accountMetadata] - Metadata of account
@BuiltValue()
abstract class CreateAccountWithProfileOK
    implements
        Built<CreateAccountWithProfileOK, CreateAccountWithProfileOKBuilder> {
  @BuiltValueField(wireName: r'accountIndex')
  int get accountIndex;

  /// number that is used for profile DID derivation
  @BuiltValueField(wireName: r'accountDid')
  String get accountDid;

  /// A unique, randomly generated identifier of created profile
  @BuiltValueField(wireName: r'profileId')
  String get profileId;

  /// Metadata of account
  @BuiltValueField(wireName: r'accountMetadata')
  JsonObject? get accountMetadata;

  CreateAccountWithProfileOK._();

  factory CreateAccountWithProfileOK([
    void updates(CreateAccountWithProfileOKBuilder b),
  ]) = _$CreateAccountWithProfileOK;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(CreateAccountWithProfileOKBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<CreateAccountWithProfileOK> get serializer =>
      _$CreateAccountWithProfileOKSerializer();
}

class _$CreateAccountWithProfileOKSerializer
    implements PrimitiveSerializer<CreateAccountWithProfileOK> {
  @override
  final Iterable<Type> types = const [
    CreateAccountWithProfileOK,
    _$CreateAccountWithProfileOK,
  ];

  @override
  final String wireName = r'CreateAccountWithProfileOK';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    CreateAccountWithProfileOK object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'accountIndex';
    yield serializers.serialize(
      object.accountIndex,
      specifiedType: const FullType(int),
    );
    yield r'accountDid';
    yield serializers.serialize(
      object.accountDid,
      specifiedType: const FullType(String),
    );
    yield r'profileId';
    yield serializers.serialize(
      object.profileId,
      specifiedType: const FullType(String),
    );
    if (object.accountMetadata != null) {
      yield r'accountMetadata';
      yield serializers.serialize(
        object.accountMetadata,
        specifiedType: const FullType(JsonObject),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    CreateAccountWithProfileOK object, {
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
    required CreateAccountWithProfileOKBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'accountIndex':
          final valueDes =
              serializers.deserialize(value, specifiedType: const FullType(int))
                  as int;
          result.accountIndex = valueDes;
          break;
        case r'accountDid':
          final valueDes =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(String),
                  )
                  as String;
          result.accountDid = valueDes;
          break;
        case r'profileId':
          final valueDes =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(String),
                  )
                  as String;
          result.profileId = valueDes;
          break;
        case r'accountMetadata':
          final valueDes =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(JsonObject),
                  )
                  as JsonObject;
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
  CreateAccountWithProfileOK deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = CreateAccountWithProfileOKBuilder();
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
