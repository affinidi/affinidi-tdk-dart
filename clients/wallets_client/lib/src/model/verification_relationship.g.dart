// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'verification_relationship.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const VerificationRelationship _$authentication =
    const VerificationRelationship._('authentication');
const VerificationRelationship _$assertionMethod =
    const VerificationRelationship._('assertionMethod');
const VerificationRelationship _$keyAgreement =
    const VerificationRelationship._('keyAgreement');
const VerificationRelationship _$capabilityInvocation =
    const VerificationRelationship._('capabilityInvocation');
const VerificationRelationship _$capabilityDelegation =
    const VerificationRelationship._('capabilityDelegation');

VerificationRelationship _$valueOf(String name) {
  switch (name) {
    case 'authentication':
      return _$authentication;
    case 'assertionMethod':
      return _$assertionMethod;
    case 'keyAgreement':
      return _$keyAgreement;
    case 'capabilityInvocation':
      return _$capabilityInvocation;
    case 'capabilityDelegation':
      return _$capabilityDelegation;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<VerificationRelationship> _$values =
    BuiltSet<VerificationRelationship>(const <VerificationRelationship>[
      _$authentication,
      _$assertionMethod,
      _$keyAgreement,
      _$capabilityInvocation,
      _$capabilityDelegation,
    ]);

class _$VerificationRelationshipMeta {
  const _$VerificationRelationshipMeta();
  VerificationRelationship get authentication => _$authentication;
  VerificationRelationship get assertionMethod => _$assertionMethod;
  VerificationRelationship get keyAgreement => _$keyAgreement;
  VerificationRelationship get capabilityInvocation => _$capabilityInvocation;
  VerificationRelationship get capabilityDelegation => _$capabilityDelegation;
  VerificationRelationship valueOf(String name) => _$valueOf(name);
  BuiltSet<VerificationRelationship> get values => _$values;
}

mixin _$VerificationRelationshipMixin {
  // ignore: non_constant_identifier_names
  _$VerificationRelationshipMeta get VerificationRelationship =>
      const _$VerificationRelationshipMeta();
}

Serializer<VerificationRelationship> _$verificationRelationshipSerializer =
    _$VerificationRelationshipSerializer();

class _$VerificationRelationshipSerializer
    implements PrimitiveSerializer<VerificationRelationship> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'authentication': 'authentication',
    'assertionMethod': 'assertionMethod',
    'keyAgreement': 'keyAgreement',
    'capabilityInvocation': 'capabilityInvocation',
    'capabilityDelegation': 'capabilityDelegation',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'authentication': 'authentication',
    'assertionMethod': 'assertionMethod',
    'keyAgreement': 'keyAgreement',
    'capabilityInvocation': 'capabilityInvocation',
    'capabilityDelegation': 'capabilityDelegation',
  };

  @override
  final Iterable<Type> types = const <Type>[VerificationRelationship];
  @override
  final String wireName = 'VerificationRelationship';

  @override
  Object serialize(
    Serializers serializers,
    VerificationRelationship object, {
    FullType specifiedType = FullType.unspecified,
  }) => _toWire[object.name] ?? object.name;

  @override
  VerificationRelationship deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => VerificationRelationship.valueOf(
    _fromWire[serialized] ?? (serialized is String ? serialized : ''),
  );
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
