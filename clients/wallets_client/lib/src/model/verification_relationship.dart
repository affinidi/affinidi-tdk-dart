//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'verification_relationship.g.dart';

class VerificationRelationship extends EnumClass {
  /// DID document verification relationship
  @BuiltValueEnumConst(wireName: r'authentication')
  static const VerificationRelationship authentication = _$authentication;

  /// DID document verification relationship
  @BuiltValueEnumConst(wireName: r'assertionMethod')
  static const VerificationRelationship assertionMethod = _$assertionMethod;

  /// DID document verification relationship
  @BuiltValueEnumConst(wireName: r'keyAgreement')
  static const VerificationRelationship keyAgreement = _$keyAgreement;

  /// DID document verification relationship
  @BuiltValueEnumConst(wireName: r'capabilityInvocation')
  static const VerificationRelationship capabilityInvocation =
      _$capabilityInvocation;

  /// DID document verification relationship
  @BuiltValueEnumConst(wireName: r'capabilityDelegation')
  static const VerificationRelationship capabilityDelegation =
      _$capabilityDelegation;

  static Serializer<VerificationRelationship> get serializer =>
      _$verificationRelationshipSerializer;

  const VerificationRelationship._(String name) : super(name);

  static BuiltSet<VerificationRelationship> get values => _$values;
  static VerificationRelationship valueOf(String name) => _$valueOf(name);
}

/// Optionally, enum_class can generate a mixin to go with your enum for use
/// with Angular. It exposes your enum constants as getters. So, if you mix it
/// in to your Dart component class, the values become available to the
/// corresponding Angular template.
///
/// Trigger mixin generation by writing a line like this one next to your enum.
abstract class VerificationRelationshipMixin = Object
    with _$VerificationRelationshipMixin;
