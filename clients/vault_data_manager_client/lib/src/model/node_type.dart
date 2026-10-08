//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'node_type.g.dart';

/// type of the Node
class NodeType extends EnumClass {
  @BuiltValueEnumConst(wireName: r'VC_ROOT')
  static const NodeType VC_ROOT = _$VC_ROOT;
  @BuiltValueEnumConst(wireName: r'VC')
  static const NodeType VC = _$VC;
  @BuiltValueEnumConst(wireName: r'FILE')
  static const NodeType FILE = _$FILE;
  @BuiltValueEnumConst(wireName: r'FOLDER')
  static const NodeType FOLDER = _$FOLDER;
  @BuiltValueEnumConst(wireName: r'PROFILE')
  static const NodeType PROFILE = _$PROFILE;
  @BuiltValueEnumConst(wireName: r'ROOT_ELEMENT')
  static const NodeType ROOT_ELEMENT = _$ROOT_ELEMENT;
  @BuiltValueEnumConst(wireName: r'TRASH_BIN')
  static const NodeType TRASH_BIN = _$TRASH_BIN;

  static Serializer<NodeType> get serializer => _$nodeTypeSerializer;

  const NodeType._(String name) : super(name);

  static BuiltSet<NodeType> get values => _$values;
  static NodeType valueOf(String name) => _$valueOf(name);
}

/// Optionally, enum_class can generate a mixin to go with your enum for use
/// with Angular. It exposes your enum constants as getters. So, if you mix it
/// in to your Dart component class, the values become available to the
/// corresponding Angular template.
///
/// Trigger mixin generation by writing a line like this one next to your enum.
abstract class NodeTypeMixin = Object with _$NodeTypeMixin;
