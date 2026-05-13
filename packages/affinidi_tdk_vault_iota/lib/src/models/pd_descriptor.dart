import 'dart:convert';

/// A thin wrapper around a raw Presentation Definition input descriptor JSON
/// map.
///
/// Each [PDDescriptor] corresponds to one entry from the
/// `input_descriptors` array of a Presentation Definition, preserving the
/// original JSON so it can be used verbatim when building a VP submission.
class PDDescriptor {
  final Map<String, dynamic> _data;

  /// Creates a [PDDescriptor] from the raw input descriptor [data] map.
  PDDescriptor({required Map<String, dynamic> data})
    : _data = Map.unmodifiable(data);

  /// Creates a [PDDescriptor] from a JSON [data] map.
  factory PDDescriptor.fromJson(Map<String, dynamic> data) =>
      PDDescriptor(data: data);

  /// Converts this [PDDescriptor] back to its original JSON map.
  Map<String, dynamic> toJson() => _data;

  /// The unique identifier of this input descriptor.
  String get id => _data['id'] as String;

  /// The human-readable name of this input descriptor, if present.
  String? get name => _data['name'] as String?;

  /// A description of this input descriptor, if present.
  String? get description => _data['description'] as String?;

  /// The group this descriptor belongs to, if any.
  ///
  /// The PEX `group` field may be a [List] or a plain [String]. Returns the
  /// first (or only) value, or `null` when absent.
  String? get groupName {
    final raw = _data['group'];
    if (raw is List && raw.isNotEmpty) return raw.first.toString();
    if (raw is String && raw.isNotEmpty) return raw;
    return null;
  }

  /// Two [PDDescriptor]s are equal when their [id]s match.
  ///
  /// The `id` field is required and unique per the PEX spec, making it the
  /// canonical identity of a descriptor. This allows [PDDescriptor] to be
  /// used safely as a [Map] key even when reconstructed from JSON.
  @override
  bool operator ==(Object other) => other is PDDescriptor && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => jsonEncode(_data);
}
