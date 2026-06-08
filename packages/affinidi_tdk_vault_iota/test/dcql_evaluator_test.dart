import 'dart:convert';

import 'package:affinidi_tdk_vault_iota/src/models/dcql_query.dart';
import 'package:affinidi_tdk_vault_iota/src/services/dcql_evaluator.dart';
import 'package:ssi/ssi.dart';
import 'package:test/test.dart';

VerifiableCredential _vc(
  Map<String, dynamic> credentialSubject, {
  List<String> extraTypes = const ['UniversityDegree'],
}) {
  return UniversalParser.parse(
    jsonEncode({
      '@context': ['https://www.w3.org/2018/credentials/v1'],
      'id': 'urn:test:vc',
      'type': ['VerifiableCredential', ...extraTypes],
      'issuer': 'did:key:z6MkTestIssuer',
      'issuanceDate': '2024-01-01T00:00:00Z',
      'credentialSubject': credentialSubject,
      'proof': {
        'type': 'DataIntegrityProof',
        'created': '2024-01-01T00:00:00Z',
        'proofPurpose': 'assertionMethod',
        'verificationMethod': 'did:key:z6MkTestIssuer#key-1',
        'proofValue': 'test_proof_value',
      },
    }),
  );
}

DcqlCredentialQuery _query({
  String? format,
  List<List<String>>? typeValues,
  List<DcqlClaimDescriptor>? claims,
  List<List<String>>? claimSets,
}) {
  return DcqlCredentialQuery(
    id: 'query-1',
    format: format,
    meta: typeValues != null
        ? DcqlCredentialMeta(typeValues: typeValues)
        : null,
    claims: claims,
    claimSets: claimSets,
  );
}

void main() {
  group('DcqlEvaluator.selectMatching format filtering', () {
    test('returns empty list when format is unsupported', () {
      final vc = _vc({'name': 'Alice'});
      final result = DcqlEvaluator.selectMatching(_query(format: 'mso_mdoc'), [
        vc,
      ]);

      expect(result, isEmpty);
    });

    test('keeps all VCs when no type or claim filter is defined', () {
      final vc = _vc({'name': 'Alice'});
      final result = DcqlEvaluator.selectMatching(_query(), [vc]);

      expect(result, [vc]);
    });

    test('proceeds when format is a supported value', () {
      final vc = _vc({'name': 'Alice'});
      final result = DcqlEvaluator.selectMatching(_query(format: 'ldp_vc'), [
        vc,
      ]);

      expect(result, [vc]);
    });
  });

  group('DcqlEvaluator.selectMatching type_values', () {
    test('matches when any OR group is satisfied', () {
      final vc = _vc({'name': 'A'}, extraTypes: ['UniversityDegree']);
      final result = DcqlEvaluator.selectMatching(
        _query(
          typeValues: const [
            ['DriversLicense'],
            ['UniversityDegree'],
          ],
        ),
        [vc],
      );

      expect(result, [vc]);
    });

    test('requires every type in an AND group to be present', () {
      final vc = _vc({'name': 'A'}, extraTypes: ['UniversityDegree']);

      final match = DcqlEvaluator.selectMatching(
        _query(
          typeValues: const [
            ['VerifiableCredential', 'UniversityDegree'],
          ],
        ),
        [vc],
      );
      expect(match, [vc]);

      final noMatch = DcqlEvaluator.selectMatching(
        _query(
          typeValues: const [
            ['VerifiableCredential', 'DriversLicense'],
          ],
        ),
        [vc],
      );
      expect(noMatch, isEmpty);
    });
  });

  group('DcqlEvaluator.selectMatching claims (no claim_sets)', () {
    test('keeps a VC when the claims list is empty', () {
      final vc = _vc({'name': 'Alice'});
      final result = DcqlEvaluator.selectMatching(_query(claims: const []), [
        vc,
      ]);

      expect(result, [vc]);
    });
    test('keeps a VC when all claim paths resolve (presence only)', () {
      final vc = _vc({'degree': 'BSc', 'gpa': 3.8});
      final result = DcqlEvaluator.selectMatching(
        _query(
          claims: const [
            DcqlClaimDescriptor(path: ['credentialSubject', 'degree']),
            DcqlClaimDescriptor(path: ['credentialSubject', 'gpa']),
          ],
        ),
        [vc],
      );

      expect(result, [vc]);
    });

    test('drops a VC when any claim path is absent', () {
      final vc = _vc({'degree': 'BSc'});
      final result = DcqlEvaluator.selectMatching(
        _query(
          claims: const [
            DcqlClaimDescriptor(path: ['credentialSubject', 'degree']),
            DcqlClaimDescriptor(path: ['credentialSubject', 'missing']),
          ],
        ),
        [vc],
      );

      expect(result, isEmpty);
    });

    test('matches a scalar claim value', () {
      final vc = _vc({'degree': 'BSc'});
      final result = DcqlEvaluator.selectMatching(
        _query(
          claims: const [
            DcqlClaimDescriptor(
              path: ['credentialSubject', 'degree'],
              values: ['BSc', 'MSc'],
            ),
          ],
        ),
        [vc],
      );

      expect(result, [vc]);
    });

    test('drops a VC when the scalar claim value does not match', () {
      final vc = _vc({'degree': 'PhD'});
      final result = DcqlEvaluator.selectMatching(
        _query(
          claims: const [
            DcqlClaimDescriptor(
              path: ['credentialSubject', 'degree'],
              values: ['BSc', 'MSc'],
            ),
          ],
        ),
        [vc],
      );

      expect(result, isEmpty);
    });

    test('matches when an accepted value is in a resolved list', () {
      final vc = _vc({
        'roles': ['student', 'alumni'],
      });
      final result = DcqlEvaluator.selectMatching(
        _query(
          claims: const [
            DcqlClaimDescriptor(
              path: ['credentialSubject', 'roles'],
              values: ['alumni'],
            ),
          ],
        ),
        [vc],
      );

      expect(result, [vc]);
    });

    test('drops a VC when no list element is an accepted value', () {
      final vc = _vc({
        'roles': ['student'],
      });
      final result = DcqlEvaluator.selectMatching(
        _query(
          claims: const [
            DcqlClaimDescriptor(
              path: ['credentialSubject', 'roles'],
              values: ['alumni'],
            ),
          ],
        ),
        [vc],
      );

      expect(result, isEmpty);
    });

    test('treats an empty values list as presence-only', () {
      final vc = _vc({'degree': 'BSc'});
      final result = DcqlEvaluator.selectMatching(
        _query(
          claims: const [
            DcqlClaimDescriptor(
              path: ['credentialSubject', 'degree'],
              values: [],
            ),
          ],
        ),
        [vc],
      );

      expect(result, [vc]);
    });

    test('matches a non-string scalar value', () {
      final vc = _vc({'level': 3});
      final result = DcqlEvaluator.selectMatching(
        _query(
          claims: const [
            DcqlClaimDescriptor(
              path: ['credentialSubject', 'level'],
              values: [3],
            ),
          ],
        ),
        [vc],
      );

      expect(result, [vc]);
    });

    test('resolves an integer index path segment', () {
      final vc = _vc({
        'grades': ['A', 'B', 'C'],
      });
      final result = DcqlEvaluator.selectMatching(
        _query(
          claims: const [
            DcqlClaimDescriptor(
              path: ['credentialSubject', 'grades', 0],
              values: ['A'],
            ),
          ],
        ),
        [vc],
      );

      expect(result, [vc]);
    });

    test('drops a VC when an integer index is out of range', () {
      final vc = _vc({
        'grades': ['A'],
      });
      final result = DcqlEvaluator.selectMatching(
        _query(
          claims: const [
            DcqlClaimDescriptor(path: ['credentialSubject', 'grades', 5]),
          ],
        ),
        [vc],
      );

      expect(result, isEmpty);
    });

    test('drops a VC when a path traverses past a scalar', () {
      final vc = _vc({'degree': 'BSc'});
      final result = DcqlEvaluator.selectMatching(
        _query(
          claims: const [
            DcqlClaimDescriptor(path: ['credentialSubject', 'degree', 'level']),
          ],
        ),
        [vc],
      );

      expect(result, isEmpty);
    });

    test('resolves a null wildcard over an array of objects', () {
      final vc = _vc({
        'courses': [
          {'name': 'Math'},
          {'name': 'Physics'},
        ],
      });
      final result = DcqlEvaluator.selectMatching(
        _query(
          claims: const [
            DcqlClaimDescriptor(
              path: ['credentialSubject', 'courses', null, 'name'],
              values: ['Physics'],
            ),
          ],
        ),
        [vc],
      );

      expect(result, [vc]);
    });
  });

  group('DcqlEvaluator.selectMatching with claim_sets', () {
    final vc = _vc({'email': 'a@b.com', 'phone': '+100'});

    test('keeps a VC when every claim id in a set matches', () {
      final result = DcqlEvaluator.selectMatching(
        _query(
          claims: const [
            DcqlClaimDescriptor(
              id: 'email',
              path: ['credentialSubject', 'email'],
            ),
            DcqlClaimDescriptor(
              id: 'phone',
              path: ['credentialSubject', 'phone'],
            ),
          ],
          claimSets: const [
            ['email', 'phone'],
          ],
        ),
        [vc],
      );

      expect(result, [vc]);
    });

    test('drops a VC when a set is only partially satisfied', () {
      final partialVc = _vc({'email': 'a@b.com'});
      final result = DcqlEvaluator.selectMatching(
        _query(
          claims: const [
            DcqlClaimDescriptor(
              id: 'email',
              path: ['credentialSubject', 'email'],
            ),
            DcqlClaimDescriptor(
              id: 'phone',
              path: ['credentialSubject', 'phone'],
            ),
          ],
          claimSets: const [
            ['email', 'phone'],
          ],
        ),
        [partialVc],
      );

      expect(result, isEmpty);
    });

    test('keeps a VC when one claim set is fully satisfied', () {
      final result = DcqlEvaluator.selectMatching(
        _query(
          claims: const [
            DcqlClaimDescriptor(
              id: 'email',
              path: ['credentialSubject', 'email'],
            ),
            DcqlClaimDescriptor(id: 'ssn', path: ['credentialSubject', 'ssn']),
          ],
          claimSets: const [
            ['ssn'],
            ['email'],
          ],
        ),
        [vc],
      );

      expect(result, [vc]);
    });

    test('drops a VC when no claim set is satisfied', () {
      final result = DcqlEvaluator.selectMatching(
        _query(
          claims: const [
            DcqlClaimDescriptor(id: 'ssn', path: ['credentialSubject', 'ssn']),
            DcqlClaimDescriptor(
              id: 'passport',
              path: ['credentialSubject', 'passport'],
            ),
          ],
          claimSets: const [
            ['ssn'],
            ['passport'],
          ],
        ),
        [vc],
      );

      expect(result, isEmpty);
    });

    test('uses generated effective ids when claim ids are absent', () {
      final result = DcqlEvaluator.selectMatching(
        _query(
          claims: const [
            DcqlClaimDescriptor(path: ['credentialSubject', 'email']),
            DcqlClaimDescriptor(path: ['credentialSubject', 'ssn']),
          ],
          claimSets: const [
            ['CLAIM_0'],
          ],
        ),
        [vc],
      );

      expect(result, [vc]);
    });
  });

  group('DcqlEvaluator.selectMatching type and claims combined', () {
    test('requires both type_values and claims to match', () {
      final vc = _vc({'degree': 'BSc'}, extraTypes: ['UniversityDegree']);

      final matching = DcqlEvaluator.selectMatching(
        _query(
          typeValues: const [
            ['UniversityDegree'],
          ],
          claims: const [
            DcqlClaimDescriptor(
              path: ['credentialSubject', 'degree'],
              values: ['BSc'],
            ),
          ],
        ),
        [vc],
      );
      expect(matching, [vc]);

      final typeMismatch = DcqlEvaluator.selectMatching(
        _query(
          typeValues: const [
            ['DriversLicense'],
          ],
          claims: const [
            DcqlClaimDescriptor(
              path: ['credentialSubject', 'degree'],
              values: ['BSc'],
            ),
          ],
        ),
        [vc],
      );
      expect(typeMismatch, isEmpty);
    });
  });

  group('DcqlEvaluator.selectMatching collection handling', () {
    test('returns an empty list for empty input', () {
      final result = DcqlEvaluator.selectMatching(_query(), const []);

      expect(result, isEmpty);
    });

    test('returns only the matching subset of multiple VCs', () {
      final match = _vc({'degree': 'BSc'});
      final noMatch = _vc({'degree': 'PhD'});
      final result = DcqlEvaluator.selectMatching(
        _query(
          claims: const [
            DcqlClaimDescriptor(
              path: ['credentialSubject', 'degree'],
              values: ['BSc'],
            ),
          ],
        ),
        [match, noMatch],
      );

      expect(result, [match]);
    });
  });

  group('DcqlClaimDescriptor JSON round-trip', () {
    test('parses id, path and values from JSON', () {
      final claim = DcqlClaimDescriptor.fromJson({
        'id': 'email',
        'path': ['credentialSubject', 'email'],
        'values': ['a@b.com'],
      });

      expect(claim.id, 'email');
      expect(claim.path, ['credentialSubject', 'email']);
      expect(claim.values, ['a@b.com']);
      expect(claim.toJson(), {
        'id': 'email',
        'path': ['credentialSubject', 'email'],
        'values': ['a@b.com'],
      });
    });

    test('derives effective id from index when id is absent', () {
      const claim = DcqlClaimDescriptor(path: ['credentialSubject', 'email']);

      expect(claim.getEffectiveId(2), 'CLAIM_2');
      expect(claim.toJson().containsKey('id'), isFalse);
    });
  });

  group('DcqlCredentialQuery claim_sets JSON round-trip', () {
    test('parses and serialises claim_sets', () {
      final query = DcqlCredentialQuery.fromJson({
        'id': 'query-1',
        'claims': [
          {
            'id': 'email',
            'path': ['credentialSubject', 'email'],
          },
        ],
        'claim_sets': [
          ['email'],
        ],
      });

      expect(query.claimSets, [
        ['email'],
      ]);
      expect(query.toJson()['claim_sets'], [
        ['email'],
      ]);
    });
  });

  group('DcqlQuery credential_sets JSON round-trip', () {
    test('parses options, required and purpose', () {
      final query = DcqlQuery.fromJson({
        'credentials': [
          {'id': 'pid', 'format': 'ldp_vc'},
          {'id': 'license', 'format': 'ldp_vc'},
        ],
        'credential_sets': [
          {
            'options': [
              ['pid'],
              ['license'],
            ],
            'required': false,
            'purpose': 'Identity verification',
          },
        ],
      });

      expect(query.credentialSets, hasLength(1));
      final set = query.credentialSets!.first;
      expect(set.options, [
        ['pid'],
        ['license'],
      ]);
      expect(set.required, isFalse);
      expect(set.purpose, 'Identity verification');
    });

    test('defaults required to true and purpose to null when omitted', () {
      final query = DcqlQuery.fromJson({
        'credentials': [
          {'id': 'pid', 'format': 'ldp_vc'},
        ],
        'credential_sets': [
          {
            'options': [
              ['pid'],
            ],
          },
        ],
      });

      expect(query.credentialSets!.first.required, isTrue);
      expect(query.credentialSets!.first.purpose, isNull);
    });

    test('leaves credentialSets null when credential_sets is absent', () {
      final query = DcqlQuery.fromJson({
        'credentials': [
          {'id': 'pid', 'format': 'ldp_vc'},
        ],
      });

      expect(query.credentialSets, isNull);
      expect(query.toJson().containsKey('credential_sets'), isFalse);
    });

    test('serialises credential_sets', () {
      const query = DcqlQuery(
        credentials: [DcqlCredentialQuery(id: 'pid')],
        credentialSets: [
          DcqlCredentialSetQuery(
            options: [
              ['pid'],
            ],
            purpose: 'KYC',
          ),
        ],
      );

      expect(query.toJson()['credential_sets'], [
        {
          'options': [
            ['pid'],
          ],
          'required': true,
          'purpose': 'KYC',
        },
      ]);
    });
  });
}
