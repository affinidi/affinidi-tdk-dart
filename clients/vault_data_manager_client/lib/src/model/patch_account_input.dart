//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'patch_account_input.g.dart';

/// PatchAccountInput
///
/// Properties:
/// * [didProof] - JWT that proves ownership of profile DID by requester
/// * [encryptedDekek] - A base64 encoded data encryption key, encrypted using VFS public key, required for PATCH operation on account
/// * [ownerProfileId] - A unique identifier of profile, required for PATCH operation on account
/// * [ownerProfileDid] - DID that is associated with the profile, required for PATCH operation on account
@BuiltValue()
abstract class PatchAccountInput
    implements Built<PatchAccountInput, PatchAccountInputBuilder> {
  /// JWT that proves ownership of profile DID by requester
  @BuiltValueField(wireName: r'didProof')
  String get didProof;

  /// A base64 encoded data encryption key, encrypted using VFS public key, required for PATCH operation on account
  @BuiltValueField(wireName: r'encryptedDekek')
  String get encryptedDekek;

  /// A unique identifier of profile, required for PATCH operation on account
  @BuiltValueField(wireName: r'ownerProfileId')
  String get ownerProfileId;

  /// DID that is associated with the profile, required for PATCH operation on account
  @BuiltValueField(wireName: r'ownerProfileDid')
  String get ownerProfileDid;

  PatchAccountInput._();

  factory PatchAccountInput([void updates(PatchAccountInputBuilder b)]) =
      _$PatchAccountInput;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(PatchAccountInputBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<PatchAccountInput> get serializer =>
      _$PatchAccountInputSerializer();
}

class _$PatchAccountInputSerializer
    implements PrimitiveSerializer<PatchAccountInput> {
  @override
  final Iterable<Type> types = const [PatchAccountInput, _$PatchAccountInput];

  @override
  final String wireName = r'PatchAccountInput';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    PatchAccountInput object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'didProof';
    yield serializers.serialize(
      object.didProof,
      specifiedType: const FullType(String),
    );
    yield r'encryptedDekek';
    yield serializers.serialize(
      object.encryptedDekek,
      specifiedType: const FullType(String),
    );
    yield r'ownerProfileId';
    yield serializers.serialize(
      object.ownerProfileId,
      specifiedType: const FullType(String),
    );
    yield r'ownerProfileDid';
    yield serializers.serialize(
      object.ownerProfileDid,
      specifiedType: const FullType(String),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    PatchAccountInput object, {
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
    required PatchAccountInputBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'didProof':
          final valueDes =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(String),
                  )
                  as String;
          result.didProof = valueDes;
          break;
        case r'encryptedDekek':
          final valueDes =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(String),
                  )
                  as String;
          result.encryptedDekek = valueDes;
          break;
        case r'ownerProfileId':
          final valueDes =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(String),
                  )
                  as String;
          result.ownerProfileId = valueDes;
          break;
        case r'ownerProfileDid':
          final valueDes =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(String),
                  )
                  as String;
          result.ownerProfileDid = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  PatchAccountInput deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = PatchAccountInputBuilder();
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
