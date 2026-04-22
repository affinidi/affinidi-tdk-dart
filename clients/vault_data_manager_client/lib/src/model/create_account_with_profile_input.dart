//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:affinidi_tdk_vault_data_manager_client/src/model/edek_info.dart';
import 'package:built_value/json_object.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'create_account_with_profile_input.g.dart';

/// CreateAccountWithProfileInput
///
/// Properties:
/// * [accountIndex] - number that is used for profile DID derivation
/// * [accountDid] - DID that is associated with the account number
/// * [didProof] - JWT that proves ownership of profile DID by requester
/// * [alias] - Alias of account
/// * [accountMetadata] - Metadata of account
/// * [accountDescription] - Description of account
/// * [profileName] - Name of the profile node
/// * [profileDescription] - Description of the profile node
/// * [profileMetadata] - Metadata of the profile
/// * [edekInfo]
/// * [dek] - A base64 encoded data encryption key, encrypted using VFS public key
@BuiltValue()
abstract class CreateAccountWithProfileInput
    implements
        Built<
          CreateAccountWithProfileInput,
          CreateAccountWithProfileInputBuilder
        > {
  /// number that is used for profile DID derivation
  @BuiltValueField(wireName: r'accountIndex')
  int get accountIndex;

  /// DID that is associated with the account number
  @BuiltValueField(wireName: r'accountDid')
  String get accountDid;

  /// JWT that proves ownership of profile DID by requester
  @BuiltValueField(wireName: r'didProof')
  String get didProof;

  /// Alias of account
  @BuiltValueField(wireName: r'alias')
  String? get alias;

  /// Metadata of account
  @BuiltValueField(wireName: r'accountMetadata')
  JsonObject? get accountMetadata;

  /// Description of account
  @BuiltValueField(wireName: r'accountDescription')
  String? get accountDescription;

  /// Name of the profile node
  @BuiltValueField(wireName: r'profileName')
  String get profileName;

  /// Description of the profile node
  @BuiltValueField(wireName: r'profileDescription')
  String? get profileDescription;

  /// Metadata of the profile
  @BuiltValueField(wireName: r'profileMetadata')
  JsonObject? get profileMetadata;

  @BuiltValueField(wireName: r'edekInfo')
  EdekInfo get edekInfo;

  /// A base64 encoded data encryption key, encrypted using VFS public key
  @BuiltValueField(wireName: r'dek')
  String get dek;

  CreateAccountWithProfileInput._();

  factory CreateAccountWithProfileInput([
    void updates(CreateAccountWithProfileInputBuilder b),
  ]) = _$CreateAccountWithProfileInput;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(CreateAccountWithProfileInputBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<CreateAccountWithProfileInput> get serializer =>
      _$CreateAccountWithProfileInputSerializer();
}

class _$CreateAccountWithProfileInputSerializer
    implements PrimitiveSerializer<CreateAccountWithProfileInput> {
  @override
  final Iterable<Type> types = const [
    CreateAccountWithProfileInput,
    _$CreateAccountWithProfileInput,
  ];

  @override
  final String wireName = r'CreateAccountWithProfileInput';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    CreateAccountWithProfileInput object, {
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
    yield r'didProof';
    yield serializers.serialize(
      object.didProof,
      specifiedType: const FullType(String),
    );
    if (object.alias != null) {
      yield r'alias';
      yield serializers.serialize(
        object.alias,
        specifiedType: const FullType(String),
      );
    }
    if (object.accountMetadata != null) {
      yield r'accountMetadata';
      yield serializers.serialize(
        object.accountMetadata,
        specifiedType: const FullType(JsonObject),
      );
    }
    if (object.accountDescription != null) {
      yield r'accountDescription';
      yield serializers.serialize(
        object.accountDescription,
        specifiedType: const FullType(String),
      );
    }
    yield r'profileName';
    yield serializers.serialize(
      object.profileName,
      specifiedType: const FullType(String),
    );
    if (object.profileDescription != null) {
      yield r'profileDescription';
      yield serializers.serialize(
        object.profileDescription,
        specifiedType: const FullType(String),
      );
    }
    if (object.profileMetadata != null) {
      yield r'profileMetadata';
      yield serializers.serialize(
        object.profileMetadata,
        specifiedType: const FullType(JsonObject),
      );
    }
    yield r'edekInfo';
    yield serializers.serialize(
      object.edekInfo,
      specifiedType: const FullType(EdekInfo),
    );
    yield r'dek';
    yield serializers.serialize(
      object.dek,
      specifiedType: const FullType(String),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    CreateAccountWithProfileInput object, {
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
    required CreateAccountWithProfileInputBuilder result,
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
        case r'didProof':
          final valueDes =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(String),
                  )
                  as String;
          result.didProof = valueDes;
          break;
        case r'alias':
          final valueDes =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(String),
                  )
                  as String;
          result.alias = valueDes;
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
        case r'accountDescription':
          final valueDes =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(String),
                  )
                  as String;
          result.accountDescription = valueDes;
          break;
        case r'profileName':
          final valueDes =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(String),
                  )
                  as String;
          result.profileName = valueDes;
          break;
        case r'profileDescription':
          final valueDes =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(String),
                  )
                  as String;
          result.profileDescription = valueDes;
          break;
        case r'profileMetadata':
          final valueDes =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(JsonObject),
                  )
                  as JsonObject;
          result.profileMetadata = valueDes;
          break;
        case r'edekInfo':
          final valueDes =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(EdekInfo),
                  )
                  as EdekInfo;
          result.edekInfo.replace(valueDes);
          break;
        case r'dek':
          final valueDes =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(String),
                  )
                  as String;
          result.dek = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  CreateAccountWithProfileInput deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = CreateAccountWithProfileInputBuilder();
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
