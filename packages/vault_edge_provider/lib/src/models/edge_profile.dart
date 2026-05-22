import 'package:affinidi_tdk_vault/affinidi_tdk_vault.dart';

/// Class representing a profile
class EdgeProfile {
  /// Constructor
  ///
  /// The [id] of profile
  /// The [accountIndex] of profile
  /// The [name] of profile
  /// The [description] of profile
  const EdgeProfile({
    required this.id,
    required this.accountIndex,
    required this.name,
    required this.description,
  });

  /// The profile identifier
  final String id;

  /// The profile name
  final String name;

  /// The profile description
  final String? description;

  /// The profile accountIndex
  final int accountIndex;

  /// Constructs an [EdgeProfile] from a [Profile]
  factory EdgeProfile.from(Profile profile) {
    return EdgeProfile(
      id: profile.id,
      accountIndex: profile.accountIndex,
      name: profile.name,
      description: profile.description,
    );
  }

  /// Copies the object with the specific fields set to `null`.
  /// If you pass `false` as a parameter, nothing will be done and it will be ignored.
  /// Don't do it. Prefer `copyWith(field: null)` or `EdgeProfile(...).copyWith.fieldName(...)`
  /// to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// EdgeProfile(...).copyWithNull(firstField: true, secondField: true)
  /// ```
  EdgeProfile copyWithNull({bool description = false}) {
    return EdgeProfile(
      id: id,
      accountIndex: accountIndex,
      name: name,
      description: description ? null : this.description,
    );
  }
}

class _CopyWithPlaceholder {
  const _CopyWithPlaceholder();
}

abstract class _EdgeProfileCWProxy {
  EdgeProfile name(String name);

  EdgeProfile description(String? description);

  EdgeProfile call({String? name, String? description});
}

class _EdgeProfileCWProxyImpl implements _EdgeProfileCWProxy {
  const _EdgeProfileCWProxyImpl(this._value);

  final EdgeProfile _value;

  @override
  EdgeProfile name(String name) => this(name: name);

  @override
  EdgeProfile description(String? description) =>
      this(description: description);

  @override
  EdgeProfile call({
    Object? name = const _CopyWithPlaceholder(),
    Object? description = const _CopyWithPlaceholder(),
  }) {
    return EdgeProfile(
      id: _value.id,
      accountIndex: _value.accountIndex,
      name: name == const _CopyWithPlaceholder() ? _value.name : name as String,
      description: description == const _CopyWithPlaceholder()
          ? _value.description
          : description as String?,
    );
  }
}

/// Extension to add the copyWith functionality to [EdgeProfile]
extension EdgeProfileCopyWith on EdgeProfile {
  /// Returns a callable class that can be used as follows: `instanceOfEdgeProfile.copyWith(...)` or like so:`instanceOfEdgeProfile.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _EdgeProfileCWProxy get copyWith => _EdgeProfileCWProxyImpl(this);
}
