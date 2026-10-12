/// The recommended PEX `path` list for an issuer filter.
///
/// Matches both the string form (`"issuer": "did:..."`) and the object form
/// (`"issuer": {"id": "did:..."}`) of a W3C VC issuer. `$.issuer.id` comes
/// first because some verifiers take the first path that resolves to a node.
const recommendedIssuerPaths = [
  r'$.issuer.id',
  r'$.issuer',
  r'$.vc.issuer.id',
  r'$.vc.issuer',
];

/// Builds a minimal raw input descriptor map with a `$.type` filter.
///
/// Optionally includes `$.@context`, issuer filters and a `group` field.
/// Set [usePattern] to produce regex filters instead of const filters.
/// [issuerPaths] sets the `path` list of the issuer field; defaults to
/// `[r'$.issuer']`. Pass [recommendedIssuerPaths] to match both issuer forms.
Map<String, dynamic> buildDescriptor({
  required String id,
  required String type,
  String? context,
  String? issuer,
  List<String> issuerPaths = const [r'$.issuer'],
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
      'path': issuerPaths,
      'filter': {'type': 'string', 'const': issuer},
    });
  }

  return {
    'id': id,
    'constraints': {'fields': fields},
    if (group != null) 'group': group,
  };
}
