/// The recommended PEX `path` list for an issuer filter.
///
/// Matches both the string form (`"issuer": "did:..."`) and the object form
/// (`"issuer": {"id": "did:..."}`) of a W3C VC issuer. `$.issuer.id` comes
/// first because DIF Presentation Exchange evaluates `path` from index 0 and
/// stops at the first path that resolves; for an object-form issuer,
/// `$.issuer` resolves to the object and fails the string filter.
const recommendedIssuerPaths = [
  r'$.issuer.id',
  r'$.issuer',
  r'$.vc.issuer.id',
  r'$.vc.issuer',
];

/// Builds a minimal raw input descriptor map with a `$.type` filter.
///
/// Optionally includes `$.@context`, issuer filters and a `group` field.
/// Set [usePattern] to produce anchored regex filters instead of const filters.
/// The type and issuer values are regex-escaped, so a DID with dots stays an
/// exact match for the matcher. The context value is not: `PDClassifier` strips
/// the anchors but does not unescape, and its ProfileTemplate check compares the
/// result with the literal URL. Type and issuer are read the same way, so a
/// dotted issuer with [usePattern] will not route to IDV; use `const` (the
/// default) for an IDV test with a did:web issuer.
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
      'contains': usePattern
          ? {'pattern': '^${RegExp.escape(type)}\$'}
          : {'const': type},
    },
  });

  if (issuer != null) {
    fields.add({
      'path': issuerPaths,
      'filter': usePattern
          ? {'type': 'string', 'pattern': '^${RegExp.escape(issuer)}\$'}
          : {'type': 'string', 'const': issuer},
    });
  }

  return {
    'id': id,
    'constraints': {'fields': fields},
    if (group != null) 'group': group,
  };
}
