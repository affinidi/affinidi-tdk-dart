// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'update_wallet_key_input.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$UpdateWalletKeyInput extends UpdateWalletKeyInput {
  @override
  final BuiltList<VerificationRelationship>? relationships;

  factory _$UpdateWalletKeyInput([
    void Function(UpdateWalletKeyInputBuilder)? updates,
  ]) => (UpdateWalletKeyInputBuilder()..update(updates))._build();

  _$UpdateWalletKeyInput._({this.relationships}) : super._();
  @override
  UpdateWalletKeyInput rebuild(
    void Function(UpdateWalletKeyInputBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  UpdateWalletKeyInputBuilder toBuilder() =>
      UpdateWalletKeyInputBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is UpdateWalletKeyInput &&
        relationships == other.relationships;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, relationships.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(
      r'UpdateWalletKeyInput',
    )..add('relationships', relationships)).toString();
  }
}

class UpdateWalletKeyInputBuilder
    implements Builder<UpdateWalletKeyInput, UpdateWalletKeyInputBuilder> {
  _$UpdateWalletKeyInput? _$v;

  ListBuilder<VerificationRelationship>? _relationships;
  ListBuilder<VerificationRelationship> get relationships =>
      _$this._relationships ??= ListBuilder<VerificationRelationship>();
  set relationships(ListBuilder<VerificationRelationship>? relationships) =>
      _$this._relationships = relationships;

  UpdateWalletKeyInputBuilder() {
    UpdateWalletKeyInput._defaults(this);
  }

  UpdateWalletKeyInputBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _relationships = $v.relationships?.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(UpdateWalletKeyInput other) {
    _$v = other as _$UpdateWalletKeyInput;
  }

  @override
  void update(void Function(UpdateWalletKeyInputBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  UpdateWalletKeyInput build() => _build();

  _$UpdateWalletKeyInput _build() {
    _$UpdateWalletKeyInput _$result;
    try {
      _$result =
          _$v ??
          _$UpdateWalletKeyInput._(relationships: _relationships?.build());
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'relationships';
        _relationships?.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
          r'UpdateWalletKeyInput',
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
