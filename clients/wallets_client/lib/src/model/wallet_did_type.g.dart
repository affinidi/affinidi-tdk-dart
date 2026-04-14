// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'wallet_did_type.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const WalletDidType _$WEB = const WalletDidType._('WEB');
const WalletDidType _$KEY = const WalletDidType._('KEY');

WalletDidType _$valueOf(String name) {
  switch (name) {
    case 'WEB':
      return _$WEB;
    case 'KEY':
      return _$KEY;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<WalletDidType> _$values = BuiltSet<WalletDidType>(
  const <WalletDidType>[_$WEB, _$KEY],
);

class _$WalletDidTypeMeta {
  const _$WalletDidTypeMeta();
  WalletDidType get WEB => _$WEB;
  WalletDidType get KEY => _$KEY;
  WalletDidType valueOf(String name) => _$valueOf(name);
  BuiltSet<WalletDidType> get values => _$values;
}

mixin _$WalletDidTypeMixin {
  // ignore: non_constant_identifier_names
  _$WalletDidTypeMeta get WalletDidType => const _$WalletDidTypeMeta();
}

Serializer<WalletDidType> _$walletDidTypeSerializer =
    _$WalletDidTypeSerializer();

class _$WalletDidTypeSerializer implements PrimitiveSerializer<WalletDidType> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'WEB': 'WEB',
    'KEY': 'KEY',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'WEB': 'WEB',
    'KEY': 'KEY',
  };

  @override
  final Iterable<Type> types = const <Type>[WalletDidType];
  @override
  final String wireName = 'WalletDidType';

  @override
  Object serialize(
    Serializers serializers,
    WalletDidType object, {
    FullType specifiedType = FullType.unspecified,
  }) => _toWire[object.name] ?? object.name;

  @override
  WalletDidType deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => WalletDidType.valueOf(
    _fromWire[serialized] ?? (serialized is String ? serialized : ''),
  );
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
