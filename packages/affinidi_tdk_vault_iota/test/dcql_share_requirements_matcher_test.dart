import 'package:affinidi_tdk_vault_iota/src/services/dcql_share_requirements_matcher_service.dart';
import 'package:dcql/dcql.dart';
import 'package:test/test.dart';

import 'fixtures/verifiable_credential_fixtures.dart';

DcqlCredential _query(String id, String type) => DcqlCredential(
  id: id,
  format: CredentialFormat.ldpVc,
  meta: DcqlMeta(
    typeValues: [
      [type],
    ],
  ),
);

void main() {
  final matcher = DcqlShareRequirementsMatcher();

  group('without credential_sets', () {
    test('is satisfied when every credential query matches', () async {
      final query = DcqlCredentialQuery(
        credentials: [
          _query('degree', 'UniversityDegree'),
          _query('employment', 'EmploymentCredential'),
        ],
      );

      final result = await matcher.match(query, [
        buildTestVc(type: 'UniversityDegree'),
        buildTestVc(type: 'EmploymentCredential'),
      ]);

      expect(result.hasEnoughVCsAvailableToShare, isTrue);
    });

    test('is not satisfied when one credential query is missing', () async {
      final query = DcqlCredentialQuery(
        credentials: [
          _query('degree', 'UniversityDegree'),
          _query('employment', 'EmploymentCredential'),
        ],
      );

      final result = await matcher.match(query, [
        buildTestVc(type: 'UniversityDegree'),
      ]);

      expect(result.hasEnoughVCsAvailableToShare, isFalse);
    });
  });

  group('with credential_sets options (OR)', () {
    final query = DcqlCredentialQuery(
      credentials: [
        _query('degree', 'UniversityDegree'),
        _query('employment', 'EmploymentCredential'),
      ],
      credentialSets: [
        DcqlCredentialSet(
          options: [
            ['degree'],
            ['employment'],
          ],
        ),
      ],
    );

    test('is satisfied when the first option is available', () async {
      final result = await matcher.match(query, [
        buildTestVc(type: 'UniversityDegree'),
      ]);

      expect(result.hasEnoughVCsAvailableToShare, isTrue);
    });

    test('is satisfied when only the second option is available', () async {
      final result = await matcher.match(query, [
        buildTestVc(type: 'EmploymentCredential'),
      ]);

      expect(result.hasEnoughVCsAvailableToShare, isTrue);
    });

    test('is not satisfied when no option is available', () async {
      final result = await matcher.match(query, [
        buildTestVc(type: 'PassportCredential'),
      ]);

      expect(result.hasEnoughVCsAvailableToShare, isFalse);
    });
  });

  group('with an AND option', () {
    final query = DcqlCredentialQuery(
      credentials: [
        _query('degree', 'UniversityDegree'),
        _query('employment', 'EmploymentCredential'),
      ],
      credentialSets: [
        DcqlCredentialSet(
          options: [
            ['degree', 'employment'],
          ],
        ),
      ],
    );

    test('is satisfied only when both ids in the option match', () async {
      final result = await matcher.match(query, [
        buildTestVc(type: 'UniversityDegree'),
        buildTestVc(type: 'EmploymentCredential'),
      ]);

      expect(result.hasEnoughVCsAvailableToShare, isTrue);
    });

    test('is not satisfied when only one id in the option matches', () async {
      final result = await matcher.match(query, [
        buildTestVc(type: 'UniversityDegree'),
      ]);

      expect(result.hasEnoughVCsAvailableToShare, isFalse);
    });
  });

  group('with an optional credential set', () {
    test('ignores an unsatisfied optional set', () async {
      final query = DcqlCredentialQuery(
        credentials: [
          _query('degree', 'UniversityDegree'),
          _query('employment', 'EmploymentCredential'),
        ],
        credentialSets: [
          DcqlCredentialSet(
            options: [
              ['degree'],
            ],
          ),
          DcqlCredentialSet(
            required: false,
            options: [
              ['employment'],
            ],
          ),
        ],
      );

      final result = await matcher.match(query, [
        buildTestVc(type: 'UniversityDegree'),
      ]);

      expect(result.hasEnoughVCsAvailableToShare, isTrue);
    });

    test('still fails when a required set is unsatisfied', () async {
      final query = DcqlCredentialQuery(
        credentials: [
          _query('degree', 'UniversityDegree'),
          _query('employment', 'EmploymentCredential'),
        ],
        credentialSets: [
          DcqlCredentialSet(
            options: [
              ['degree'],
            ],
          ),
          DcqlCredentialSet(
            required: false,
            options: [
              ['employment'],
            ],
          ),
        ],
      );

      final result = await matcher.match(query, [
        buildTestVc(type: 'EmploymentCredential'),
      ]);

      expect(result.hasEnoughVCsAvailableToShare, isFalse);
    });
  });

  group('recommendedMaximumVCs with credential_sets', () {
    final query = DcqlCredentialQuery(
      credentials: [
        _query('degree', 'UniversityDegree'),
        _query('employment', 'EmploymentCredential'),
      ],
      credentialSets: [
        DcqlCredentialSet(
          options: [
            ['degree'],
            ['employment'],
          ],
        ),
      ],
    );

    test('only recommends VCs from the satisfied option', () async {
      final degree = buildTestVc(type: 'UniversityDegree');
      final employment = buildTestVc(type: 'EmploymentCredential');

      final result = await matcher.match(query, [degree, employment]);

      expect(result.recommendedMaximumVCs, hasLength(1));
      expect(result.recommendedMaximumVCs, contains(degree));
      expect(result.recommendedMaximumVCs, isNot(contains(employment)));
    });

    test('is empty when no option is satisfied', () async {
      final result = await matcher.match(query, [
        buildTestVc(type: 'PassportCredential'),
      ]);

      expect(result.recommendedMaximumVCs, isEmpty);
    });

    test('availableCredentials still lists every matching VC', () async {
      final degree = buildTestVc(type: 'UniversityDegree');
      final employment = buildTestVc(type: 'EmploymentCredential');

      final result = await matcher.match(query, [degree, employment]);

      expect(result.availableCredentials, containsAll([degree, employment]));
    });
  });

  group('groups view and multiple flag', () {
    DcqlCredential queryWithMultiple({required bool multiple}) =>
        DcqlCredential(
          id: 'degree',
          format: CredentialFormat.ldpVc,
          multiple: multiple,
          meta: DcqlMeta(
            typeValues: [
              ['UniversityDegree'],
            ],
          ),
        );

    test('caps the group at one and recommends one when multiple is '
        'false', () async {
      final query = DcqlCredentialQuery(
        credentials: [queryWithMultiple(multiple: false)],
      );

      final result = await matcher.match(query, [
        buildTestVc(type: 'UniversityDegree'),
        buildTestVc(type: 'UniversityDegree'),
      ]);

      final group = result.groups.single;
      expect(group.id, equals('degree'));
      expect(group.maximumVCsCountToShare, equals(1));
      expect(group.allowsMultiple, isFalse);
      expect(group.availableCredentials, hasLength(2));
      expect(group.recommendedCredentials, hasLength(1));
    });

    test('leaves the group unbounded and recommends all when multiple is '
        'true', () async {
      final query = DcqlCredentialQuery(
        credentials: [queryWithMultiple(multiple: true)],
      );

      final result = await matcher.match(query, [
        buildTestVc(type: 'UniversityDegree'),
        buildTestVc(type: 'UniversityDegree'),
      ]);

      final group = result.groups.single;
      expect(group.maximumVCsCountToShare, isNull);
      expect(group.allowsMultiple, isTrue);
      expect(group.recommendedCredentials, hasLength(2));
    });
  });

  group('credentialSetOptions', () {
    test('is null when no credential_sets are present', () async {
      final query = DcqlCredentialQuery(
        credentials: [_query('degree', 'UniversityDegree')],
      );

      final result = await matcher.match(query, [
        buildTestVc(type: 'UniversityDegree'),
      ]);

      expect(result.credentialSetOptions, isNull);
    });

    test('returns one required set with the correct alternatives', () async {
      final query = DcqlCredentialQuery(
        credentials: [
          _query('degree', 'UniversityDegree'),
          _query('employment', 'EmploymentCredential'),
        ],
        credentialSets: [
          DcqlCredentialSet(
            options: [
              ['degree'],
              ['employment'],
            ],
          ),
        ],
      );

      final result = await matcher.match(query, [
        buildTestVc(type: 'UniversityDegree'),
      ]);

      expect(result.credentialSetOptions, hasLength(1));
      final set = result.credentialSetOptions!.single;
      expect(set.isRequired, isTrue);
      expect(
        set.alternatives,
        equals([
          ['degree'],
          ['employment'],
        ]),
      );
    });

    test('reflects isRequired: false for optional sets', () async {
      final query = DcqlCredentialQuery(
        credentials: [
          _query('degree', 'UniversityDegree'),
          _query('employment', 'EmploymentCredential'),
        ],
        credentialSets: [
          DcqlCredentialSet(
            options: [
              ['degree'],
            ],
          ),
          DcqlCredentialSet(
            required: false,
            options: [
              ['employment'],
            ],
          ),
        ],
      );

      final result = await matcher.match(query, [
        buildTestVc(type: 'UniversityDegree'),
      ]);

      expect(result.credentialSetOptions, hasLength(2));
      expect(result.credentialSetOptions![0].isRequired, isTrue);
      expect(result.credentialSetOptions![1].isRequired, isFalse);
    });

    test('preserves multiple credential_sets in order', () async {
      final query = DcqlCredentialQuery(
        credentials: [
          _query('a', 'TypeA'),
          _query('b', 'TypeB'),
          _query('c', 'TypeC'),
        ],
        credentialSets: [
          DcqlCredentialSet(
            options: [
              ['a', 'b'],
              ['c'],
            ],
          ),
          DcqlCredentialSet(
            required: false,
            options: [
              ['b'],
            ],
          ),
        ],
      );

      final result = await matcher.match(query, [
        buildTestVc(type: 'TypeA'),
        buildTestVc(type: 'TypeB'),
      ]);

      final sets = result.credentialSetOptions!;
      expect(sets, hasLength(2));
      expect(
        sets[0].alternatives,
        equals([
          ['a', 'b'],
          ['c'],
        ]),
      );
      expect(
        sets[1].alternatives,
        equals([
          ['b'],
        ]),
      );
    });
  });
}
