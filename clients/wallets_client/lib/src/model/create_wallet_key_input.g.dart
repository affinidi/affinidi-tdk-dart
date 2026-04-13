// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_wallet_key_input.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const CreateWalletKeyInputKeyTypeEnum
_$createWalletKeyInputKeyTypeEnum_secp256k1 =
    const CreateWalletKeyInputKeyTypeEnum._('secp256k1');
const CreateWalletKeyInputKeyTypeEnum
_$createWalletKeyInputKeyTypeEnum_ed25519 =
    const CreateWalletKeyInputKeyTypeEnum._('ed25519');
const CreateWalletKeyInputKeyTypeEnum _$createWalletKeyInputKeyTypeEnum_p256 =
    const CreateWalletKeyInputKeyTypeEnum._('p256');

CreateWalletKeyInputKeyTypeEnum _$createWalletKeyInputKeyTypeEnumValueOf(
  String name,
) {
  switch (name) {
    case 'secp256k1':
      return _$createWalletKeyInputKeyTypeEnum_secp256k1;
    case 'ed25519':
      return _$createWalletKeyInputKeyTypeEnum_ed25519;
    case 'p256':
      return _$createWalletKeyInputKeyTypeEnum_p256;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<CreateWalletKeyInputKeyTypeEnum>
_$createWalletKeyInputKeyTypeEnumValues =
    BuiltSet<CreateWalletKeyInputKeyTypeEnum>(
      const <CreateWalletKeyInputKeyTypeEnum>[
        _$createWalletKeyInputKeyTypeEnum_secp256k1,
        _$createWalletKeyInputKeyTypeEnum_ed25519,
        _$createWalletKeyInputKeyTypeEnum_p256,
      ],
    );

Serializer<CreateWalletKeyInputKeyTypeEnum>
_$createWalletKeyInputKeyTypeEnumSerializer =
    _$CreateWalletKeyInputKeyTypeEnumSerializer();

class _$CreateWalletKeyInputKeyTypeEnumSerializer
    implements PrimitiveSerializer<CreateWalletKeyInputKeyTypeEnum> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'secp256k1': 'secp256k1',
    'ed25519': 'ed25519',
    'p256': 'p256',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'secp256k1': 'secp256k1',
    'ed25519': 'ed25519',
    'p256': 'p256',
  };

  @override
  final Iterable<Type> types = const <Type>[CreateWalletKeyInputKeyTypeEnum];
  @override
  final String wireName = 'CreateWalletKeyInputKeyTypeEnum';

  @override
  Object serialize(
    Serializers serializers,
    CreateWalletKeyInputKeyTypeEnum object, {
    FullType specifiedType = FullType.unspecified,
  }) => _toWire[object.name] ?? object.name;

  @override
  CreateWalletKeyInputKeyTypeEnum deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => CreateWalletKeyInputKeyTypeEnum.valueOf(
    _fromWire[serialized] ?? (serialized is String ? serialized : ''),
  );
}

class _$CreateWalletKeyInput extends CreateWalletKeyInput {
  @override
  final CreateWalletKeyInputKeyTypeEnum keyType;
  @override
  final BuiltList<VerificationRelationship> relationships;

  factory _$CreateWalletKeyInput([
    void Function(CreateWalletKeyInputBuilder)? updates,
  ]) => (CreateWalletKeyInputBuilder()..update(updates))._build();

  _$CreateWalletKeyInput._({required this.keyType, required this.relationships})
    : super._();
  @override
  CreateWalletKeyInput rebuild(
    void Function(CreateWalletKeyInputBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  CreateWalletKeyInputBuilder toBuilder() =>
      CreateWalletKeyInputBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is CreateWalletKeyInput &&
        keyType == other.keyType &&
        relationships == other.relationships;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, keyType.hashCode);
    _$hash = $jc(_$hash, relationships.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'CreateWalletKeyInput')
          ..add('keyType', keyType)
          ..add('relationships', relationships))
        .toString();
  }
}

class CreateWalletKeyInputBuilder
    implements Builder<CreateWalletKeyInput, CreateWalletKeyInputBuilder> {
  _$CreateWalletKeyInput? _$v;

  CreateWalletKeyInputKeyTypeEnum? _keyType;
  CreateWalletKeyInputKeyTypeEnum? get keyType => _$this._keyType;
  set keyType(CreateWalletKeyInputKeyTypeEnum? keyType) =>
      _$this._keyType = keyType;

  ListBuilder<VerificationRelationship>? _relationships;
  ListBuilder<VerificationRelationship> get relationships =>
      _$this._relationships ??= ListBuilder<VerificationRelationship>();
  set relationships(ListBuilder<VerificationRelationship>? relationships) =>
      _$this._relationships = relationships;

  CreateWalletKeyInputBuilder() {
    CreateWalletKeyInput._defaults(this);
  }

  CreateWalletKeyInputBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _keyType = $v.keyType;
      _relationships = $v.relationships.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(CreateWalletKeyInput other) {
    _$v = other as _$CreateWalletKeyInput;
  }

  @override
  void update(void Function(CreateWalletKeyInputBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  CreateWalletKeyInput build() => _build();

  _$CreateWalletKeyInput _build() {
    _$CreateWalletKeyInput _$result;
    try {
      _$result =
          _$v ??
          _$CreateWalletKeyInput._(
            keyType: BuiltValueNullFieldError.checkNotNull(
              keyType,
              r'CreateWalletKeyInput',
              'keyType',
            ),
            relationships: relationships.build(),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'relationships';
        relationships.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
          r'CreateWalletKeyInput',
          _$failedField,
          e.toString(),
        );
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
