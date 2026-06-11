/// Builds a minimal raw input descriptor map with a `$.type` filter.
///
/// Optionally includes `$.@context`, `$.issuer` filters and a `group` field.
/// Set [usePattern] to produce regex filters instead of const filters.
Map<String, dynamic> buildDescriptor({
  required String id,
  required String type,
  String? context,
  String? issuer,
  List<String>? group,
  bool usePattern = false,
}) {
  final fields = <Map<String, dynamic>>[];

  if (context != null) {
    fields.add({
      'path': [r'$.@context'],
      'filter': {
        'contains': usePattern
            ? {'pattern': '^$context\$'}
            : {'const': context},
      },
    });
  }

  fields.add({
    'path': [r'$.type'],
    'filter': {
      'contains': usePattern ? {'pattern': '^$type\$'} : {'const': type},
    },
  });

  if (issuer != null) {
    fields.add({
      'path': [r'$.issuer'],
      'filter': {'type': 'string', 'const': issuer},
    });
  }

  return {
    'id': id,
    'constraints': {'fields': fields},
    if (group != null) 'group': group,
  };
}
