//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'wallet_did_type.g.dart';

class WalletDidType extends EnumClass {
  /// DID method type for the wallet
  @BuiltValueEnumConst(wireName: r'WEB')
  static const WalletDidType WEB = _$WEB;

  /// DID method type for the wallet
  @BuiltValueEnumConst(wireName: r'KEY')
  static const WalletDidType KEY = _$KEY;

  static Serializer<WalletDidType> get serializer => _$walletDidTypeSerializer;

  const WalletDidType._(String name) : super(name);

  static BuiltSet<WalletDidType> get values => _$values;
  static WalletDidType valueOf(String name) => _$valueOf(name);
}

/// Optionally, enum_class can generate a mixin to go with your enum for use
/// with Angular. It exposes your enum constants as getters. So, if you mix it
/// in to your Dart component class, the values become available to the
/// corresponding Angular template.
///
/// Trigger mixin generation by writing a line like this one next to your enum.
abstract class WalletDidTypeMixin = Object with _$WalletDidTypeMixin;
