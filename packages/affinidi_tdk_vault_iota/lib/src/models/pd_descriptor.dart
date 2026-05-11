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

  /// Creates an empty [PDDescriptor] with a placeholder `id`.
  factory PDDescriptor.empty() => PDDescriptor(data: {'id': 'id'});

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

  @override
  String toString() => jsonEncode(_data);
}
