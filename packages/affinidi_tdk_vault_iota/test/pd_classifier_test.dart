import 'package:affinidi_tdk_vault_iota/affinidi_tdk_vault_iota.dart';
import 'package:test/test.dart';

// ── Shared test constants ────────────────────────────────────────────────────

const _trustedIssuer = 'did:key:z6MkIdvIssuer';
const _untrustedIssuer = 'did:key:z6MkUntrusted';

const _profileContext =
    'https://schema.affinidi.io/profile-template/context.jsonld';

// Builds a minimal input descriptor with a $.type filter.
Map<String, dynamic> _descriptor({
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
        'contains': usePattern ? {'pattern': '^$context\$'} : {'const': context},
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

  final descriptor = <String, dynamic>{
    'id': id,
    'constraints': {'fields': fields},
  };

  if (group != null) descriptor['group'] = group;
  return descriptor;
}

// Builds a PD map with the given input descriptors.
Map<String, dynamic> _pd(
  List<Map<String, dynamic>> descriptors, {
  Map<String, dynamic>? purpose,
  List<Map<String, dynamic>>? submissionRequirements,
}) {
  return {
    'input_descriptors': descriptors,
    if (purpose != null) 'purpose': purpose,
    if (submissionRequirements != null)
      'submission_requirements': submissionRequirements,
  };
}

void main() {
  late PDClassifier classifier;

  setUp(() {
    classifier = const PDClassifier(validIdvIssuers: [_trustedIssuer]);
  });

  // ── Missing input_descriptors ─────────────────────────────────────────────

  group('when input_descriptors is missing', () {
    test('should throw TdkException with invalidPresentationDefinition', () {
      expect(
        () => classifier.classify({}),
        throwsA(
          isA<TdkException>().having(
            (e) => e.code,
            'code',
            TdkExceptionType.invalidPresentationDefinition.code,
          ),
        ),
      );
    });
  });

  // ── Claimed VCs ───────────────────────────────────────────────────────────

  group('claimed VC descriptors', () {
    test('should route a standard VC descriptor to claimedDescriptors', () {
      final pd = _pd([_descriptor(id: 'cred1', type: 'UniversityDegree')]);
      final result = classifier.classify(pd);

      expect(result.claimedDescriptors, hasLength(1));
      expect(result.claimedDescriptors.first.id, 'cred1');
      expect(result.zpdLinkedDescriptors, isEmpty);
      expect(result.idvDescriptors, isEmpty);
      expect(result.dataPoints, isEmpty);
      expect(result.zeroPartyVCs, isEmpty);
    });

    test('should route multiple standard VCs to claimedDescriptors', () {
      final pd = _pd([
        _descriptor(id: 'd1', type: 'UniversityDegree'),
        _descriptor(id: 'd2', type: 'EmploymentCredential'),
      ]);
      final result = classifier.classify(pd);

      expect(result.claimedDescriptors, hasLength(2));
      expect(result.claimedVCsRequested, isTrue);
    });

    test('claimedVCsRequested is false when no claimed or IDV descriptors', () {
      final pd = _pd([_descriptor(id: 'hit1', type: 'HITGivenName')]);
      final result = classifier.classify(pd);

      expect(result.claimedVCsRequested, isFalse);
    });

    test('descriptor without constraints goes to claimedDescriptors', () {
      final pd = _pd([
        {'id': 'bare', 'name': 'Bare descriptor'},
      ]);
      final result = classifier.classify(pd);

      expect(result.claimedDescriptors, hasLength(1));
      expect(result.claimedDescriptors.first.id, 'bare');
    });
  });

  // ── ZPD-linked VCs (Email / PhoneNumber) ──────────────────────────────────

  group('ZPD-linked VC descriptors', () {
    test('should route Email descriptor to zpdLinkedDescriptors', () {
      final pd = _pd([_descriptor(id: 'email1', type: 'Email')]);
      final result = classifier.classify(pd);

      expect(result.zpdLinkedDescriptors, hasLength(1));
      expect(result.zpdLinkedDescriptors.first.id, 'email1');
      expect(result.dataPoints, contains(r'$.person.properties.email'));
      expect(result.claimedDescriptors, isEmpty);
    });

    test('should route PhoneNumber descriptor to zpdLinkedDescriptors', () {
      final pd = _pd([_descriptor(id: 'phone1', type: 'PhoneNumber')]);
      final result = classifier.classify(pd);

      expect(result.zpdLinkedDescriptors, hasLength(1));
      expect(result.dataPoints, contains(r'$.person.properties.phoneNumber'));
    });

    test('zpdRequested is true when zpdLinkedDescriptors are present', () {
      final pd = _pd([_descriptor(id: 'e1', type: 'Email')]);
      final result = classifier.classify(pd);

      expect(result.zpdRequested, isTrue);
    });
  });

  // ── Zero-party VCs (HIT* / ProfileTemplate) ───────────────────────────────

  group('zero-party VC descriptors', () {
    test('should add HITGivenName type to zeroPartyVCs and correct dataPoint',
        () {
      final pd = _pd([_descriptor(id: 'h1', type: 'HITGivenName')]);
      final result = classifier.classify(pd);

      expect(result.zeroPartyVCs, contains('HITGivenName'));
      expect(result.dataPoints, contains(r'$.person.properties.givenName'));
      expect(result.claimedDescriptors, isEmpty);
    });

    test('should add HITContacts with both email and phone data points', () {
      final pd = _pd([_descriptor(id: 'hc', type: 'HITContacts')]);
      final result = classifier.classify(pd);

      expect(result.zeroPartyVCs, contains('HITContacts'));
      expect(result.dataPoints, contains(r'$.person.properties.phoneNumber'));
      expect(result.dataPoints, contains(r'$.person.properties.email'));
    });

    test('should add ProfileTemplate with empty dataPoints and set zeroPartyVCs',
        () {
      final pd = _pd([
        _descriptor(
          id: 'pt',
          type: 'ProfileTemplate',
          context: _profileContext,
        ),
      ]);
      final result = classifier.classify(pd);

      expect(result.zeroPartyVCs, contains('ProfileTemplate'));
      expect(result.shouldGenerateProfileVC, isTrue);
      expect(result.zpdRequested, isTrue);
    });

    test('ProfileTemplate without matching context goes to claimedDescriptors',
        () {
      // Context doesn't match profileContext — not treated as ProfileTemplate.
      final pd = _pd([
        _descriptor(
          id: 'pt2',
          type: 'ProfileTemplate',
          context: 'https://other.context/',
        ),
      ]);
      final result = classifier.classify(pd);

      expect(result.claimedDescriptors, hasLength(1));
      expect(result.zeroPartyVCs, isEmpty);
    });

    test('shouldGenerateProfileVC is false when ProfileTemplate is absent', () {
      final pd = _pd([_descriptor(id: 'd1', type: 'HITGivenName')]);
      final result = classifier.classify(pd);

      expect(result.shouldGenerateProfileVC, isFalse);
    });
  });

  // ── IDV descriptors ──────────────────────────────────────────────────────

  group('IDV descriptors', () {
    test('should route VerifiedIdentityDocument from trusted issuer to idvDescriptors',
        () {
      final pd = _pd([
        _descriptor(
          id: 'idv1',
          type: 'VerifiedIdentityDocument',
          issuer: _trustedIssuer,
        ),
      ]);
      final result = classifier.classify(pd);

      expect(result.idvDescriptors, hasLength(1));
      expect(result.idvDescriptors.first.id, 'idv1');
      expect(result.claimedDescriptors, isEmpty);
      expect(result.claimedVCsRequested, isTrue);
    });

    test('should populate idvInfo.schemaContextUrl when context is present', () {
      final pd = _pd([
        _descriptor(
          id: 'idv2',
          type: 'VerifiedIdentityDocument',
          context: 'https://schema.affinidi.io/passport/context.jsonld',
          issuer: _trustedIssuer,
        ),
      ]);
      final result = classifier.classify(pd);

      expect(result.idvInfo?.schemaContextUrl,
          'https://schema.affinidi.io/passport/context.jsonld');
    });

    test('should populate idvInfo.type from the specific sub-type', () {
      final pd = _pd([
        {
          'id': 'passport',
          'constraints': {
            'fields': [
              {
                'path': [r'$.@context'],
                'filter': {
                  'contains': {
                    'const': 'https://schema.affinidi.io/passport/context.jsonld',
                  },
                },
              },
              {
                'path': [r'$.type'],
                'filter': {
                  'contains': {'const': 'VerifiedIdentityDocument'},
                },
              },
              {
                'path': [r'$.type'],
                'filter': {
                  'contains': {'const': 'Passport'},
                },
              },
              {
                'path': [r'$.issuer'],
                'filter': {'type': 'string', 'const': _trustedIssuer},
              },
            ],
          },
        },
      ]);
      final result = classifier.classify(pd);

      expect(result.idvInfo?.type, 'Passport');
    });

    test('VerifiedIdentityDocument from untrusted issuer goes to claimedDescriptors',
        () {
      final pd = _pd([
        _descriptor(
          id: 'untrusted',
          type: 'VerifiedIdentityDocument',
          issuer: _untrustedIssuer,
        ),
      ]);
      final result = classifier.classify(pd);

      expect(result.claimedDescriptors, hasLength(1));
      expect(result.idvDescriptors, isEmpty);
    });

    test('should throw unsupportedMultipleIdvTypes when descriptor has > 2 IDV types',
        () {
      final pd = _pd([
        {
          'id': 'multi-idv',
          'constraints': {
            'fields': [
              {
                'path': [r'$.type'],
                'filter': {
                  'contains': {'const': 'VerifiedIdentityDocument'},
                },
              },
              {
                'path': [r'$.type'],
                'filter': {
                  'contains': {'const': 'Passport'},
                },
              },
              {
                'path': [r'$.type'],
                'filter': {
                  'contains': {'const': 'DriversLicense'},
                },
              },
              {
                'path': [r'$.issuer'],
                'filter': {'type': 'string', 'const': _trustedIssuer},
              },
            ],
          },
        },
      ]);

      expect(
        () => classifier.classify(pd),
        throwsA(
          isA<TdkException>().having(
            (e) => e.code,
            'code',
            TdkExceptionType.unsupportedMultipleIdvTypes.code,
          ),
        ),
      );
    });
  });

  // ── Pattern filter (regex anchors stripped) ───────────────────────────────

  group('pattern filter handling', () {
    test('should strip ^ and \$ anchors from regex type filter', () {
      final pd = _pd([
        _descriptor(id: 'p1', type: 'HITGivenName', usePattern: true),
      ]);
      final result = classifier.classify(pd);

      expect(result.zeroPartyVCs, contains('HITGivenName'));
    });

    test('should strip anchors from context pattern filter', () {
      final pd = _pd([
        _descriptor(
          id: 'pt3',
          type: 'ProfileTemplate',
          context: _profileContext,
          usePattern: true,
        ),
      ]);
      final result = classifier.classify(pd);

      expect(result.zeroPartyVCs, contains('ProfileTemplate'));
    });
  });

  // ── Multiple $.@context fields ────────────────────────────────────────────

  group(r'multiple $.@context fields', () {
    test('should throw invalidPresentationDefinition when descriptor has two @context fields',
        () {
      final pd = _pd([
        {
          'id': 'dup-ctx',
          'constraints': {
            'fields': [
              {
                'path': [r'$.@context'],
                'filter': {
                  'contains': {'const': 'https://ctx1.example/'},
                },
              },
              {
                'path': [r'$.@context'],
                'filter': {
                  'contains': {'const': 'https://ctx2.example/'},
                },
              },
            ],
          },
        },
      ]);

      expect(
        () => classifier.classify(pd),
        throwsA(
          isA<TdkException>().having(
            (e) => e.code,
            'code',
            TdkExceptionType.invalidPresentationDefinition.code,
          ),
        ),
      );
    });
  });

  // ── Purpose ───────────────────────────────────────────────────────────────

  group('purpose field', () {
    test('should parse purpose from a map in the PD', () {
      final pd = _pd(
        [_descriptor(id: 'd1', type: 'UniversityDegree')],
        purpose: {
          'data_collection_purpose': 'Identity verification',
          'request_description': 'We need to verify your identity.',
        },
      );
      final result = classifier.classify(pd);

      expect(result.purpose?.dataCollectionPurpose, 'Identity verification');
      expect(result.purpose?.requestDescription,
          'We need to verify your identity.');
    });

    test('should return null purpose when field is absent', () {
      final pd = _pd([_descriptor(id: 'd1', type: 'UniversityDegree')]);
      final result = classifier.classify(pd);

      expect(result.purpose, isNull);
    });

    test('should return null purpose when dataCollectionPurpose is null', () {
      final pd = _pd(
        [_descriptor(id: 'd1', type: 'UniversityDegree')],
        purpose: {'data_collection_purpose': null},
      );
      final result = classifier.classify(pd);

      expect(result.purpose, isNull);
    });
  });

  // ── Submission requirements ───────────────────────────────────────────────

  group('submission requirements', () {
    test('should parse submission requirements and key by group name', () {
      final pd = _pd(
        [_descriptor(id: 'd1', type: 'UniversityDegree', group: ['A'])],
        submissionRequirements: [
          {'from': 'A', 'rule': 'pick', 'count': 1},
        ],
      );
      final result = classifier.classify(pd);

      expect(result.submissionRequirementsByGroup, contains('A'));
      expect(result.submissionRequirementsByGroup['A']?.count, 1);
    });

    test('should throw invalidPresentationDefinition when count is zero', () {
      final pd = _pd(
        [_descriptor(id: 'd1', type: 'UniversityDegree')],
        submissionRequirements: [
          {'from': 'A', 'count': 0},
        ],
      );

      expect(
        () => classifier.classify(pd),
        throwsA(
          isA<TdkException>().having(
            (e) => e.code,
            'code',
            TdkExceptionType.invalidPresentationDefinition.code,
          ),
        ),
      );
    });

    test('should throw invalidPresentationDefinition when min is zero', () {
      final pd = _pd(
        [_descriptor(id: 'd1', type: 'UniversityDegree')],
        submissionRequirements: [
          {'from': 'A', 'min': 0},
        ],
      );

      expect(
        () => classifier.classify(pd),
        throwsA(isA<TdkException>()),
      );
    });

    test('should throw invalidPresentationDefinition when from field is missing',
        () {
      final pd = _pd(
        [_descriptor(id: 'd1', type: 'UniversityDegree')],
        submissionRequirements: [
          {'count': 1},
        ],
      );

      expect(
        () => classifier.classify(pd),
        throwsA(
          isA<TdkException>().having(
            (e) => e.code,
            'code',
            TdkExceptionType.invalidPresentationDefinition.code,
          ),
        ),
      );
    });
  });

  // ── Mixed descriptors ─────────────────────────────────────────────────────

  group('mixed descriptor types', () {
    test('should classify claimed, ZPD-linked, and zero-party in one PD', () {
      final pd = _pd([
        _descriptor(id: 'degree', type: 'UniversityDegree'),
        _descriptor(id: 'email', type: 'Email'),
        _descriptor(id: 'givenName', type: 'HITGivenName'),
      ]);
      final result = classifier.classify(pd);

      expect(result.claimedDescriptors, hasLength(1));
      expect(result.claimedDescriptors.first.id, 'degree');
      expect(result.zpdLinkedDescriptors, hasLength(1));
      expect(result.zpdLinkedDescriptors.first.id, 'email');
      expect(result.zeroPartyVCs, contains('HITGivenName'));
      expect(result.dataPoints,
          containsAll([r'$.person.properties.email', r'$.person.properties.givenName']));
    });

    test('empty PD produces empty requirements', () {
      final pd = _pd([]);
      final result = classifier.classify(pd);

      expect(result.claimedDescriptors, isEmpty);
      expect(result.zpdLinkedDescriptors, isEmpty);
      expect(result.idvDescriptors, isEmpty);
      expect(result.dataPoints, isEmpty);
      expect(result.zeroPartyVCs, isEmpty);
      expect(result.claimedVCsRequested, isFalse);
      expect(result.zpdRequested, isFalse);
    });
  });

  // ── Issuer filter path variants ───────────────────────────────────────────

  group('issuer filter path variants', () {
    for (final issuerPath in [r'$.issuer', r'$.vc.issuer', r'$.iss']) {
      test('should extract issuer from path $issuerPath', () {
        final pd = _pd([
          {
            'id': 'idv-$issuerPath',
            'constraints': {
              'fields': [
                {
                  'path': [r'$.type'],
                  'filter': {
                    'contains': {'const': 'VerifiedIdentityDocument'},
                  },
                },
                {
                  'path': [issuerPath],
                  'filter': {'type': 'string', 'const': _trustedIssuer},
                },
              ],
            },
          },
        ]);
        final result = classifier.classify(pd);

        expect(result.idvDescriptors, hasLength(1));
      });
    }
  });
}
