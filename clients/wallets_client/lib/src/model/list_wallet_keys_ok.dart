//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:affinidi_tdk_wallets_client/src/model/wallet_key_dto.dart';
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'list_wallet_keys_ok.g.dart';

/// Response containing wallet keys
///
/// Properties:
/// * [keys] - list of wallet keys
@BuiltValue()
abstract class ListWalletKeysOK
    implements Built<ListWalletKeysOK, ListWalletKeysOKBuilder> {
  /// list of wallet keys
  @BuiltValueField(wireName: r'keys')
  BuiltList<WalletKeyDto> get keys;

  ListWalletKeysOK._();

  factory ListWalletKeysOK([void updates(ListWalletKeysOKBuilder b)]) =
      _$ListWalletKeysOK;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(ListWalletKeysOKBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<ListWalletKeysOK> get serializer =>
      _$ListWalletKeysOKSerializer();
}

class _$ListWalletKeysOKSerializer
    implements PrimitiveSerializer<ListWalletKeysOK> {
  @override
  final Iterable<Type> types = const [ListWalletKeysOK, _$ListWalletKeysOK];

  @override
  final String wireName = r'ListWalletKeysOK';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    ListWalletKeysOK object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'keys';
    yield serializers.serialize(
      object.keys,
      specifiedType: const FullType(BuiltList, [FullType(WalletKeyDto)]),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    ListWalletKeysOK object, {
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
    required ListWalletKeysOKBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'keys':
          final valueDes =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(BuiltList, [
                      FullType(WalletKeyDto),
                    ]),
                  )
                  as BuiltList<WalletKeyDto>;
          result.keys.replace(valueDes);
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  ListWalletKeysOK deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = ListWalletKeysOKBuilder();
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
