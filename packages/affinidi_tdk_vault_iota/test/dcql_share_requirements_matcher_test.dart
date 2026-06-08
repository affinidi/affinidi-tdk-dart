import 'package:affinidi_tdk_vault_iota/src/models/dcql_query.dart';
import 'package:affinidi_tdk_vault_iota/src/services/dcql_share_requirements_matcher_service.dart';
import 'package:test/test.dart';

import 'fixtures/verifiable_credential_fixtures.dart';

DcqlCredentialQuery _query(String id, String type) => DcqlCredentialQuery(
  id: id,
  meta: DcqlCredentialMeta(
    typeValues: [
      [type],
    ],
  ),
);

void main() {
  final matcher = DcqlShareRequirementsMatcher();

  group('without credential_sets', () {
    test('is satisfied when every credential query matches', () async {
      final query = DcqlQuery(
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
      final query = DcqlQuery(
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
    final query = DcqlQuery(
      credentials: [
        _query('degree', 'UniversityDegree'),
        _query('employment', 'EmploymentCredential'),
      ],
      credentialSets: [
        const DcqlCredentialSetQuery(
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
    final query = DcqlQuery(
      credentials: [
        _query('degree', 'UniversityDegree'),
        _query('employment', 'EmploymentCredential'),
      ],
      credentialSets: [
        const DcqlCredentialSetQuery(
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
      final query = DcqlQuery(
        credentials: [
          _query('degree', 'UniversityDegree'),
          _query('employment', 'EmploymentCredential'),
        ],
        credentialSets: [
          const DcqlCredentialSetQuery(
            options: [
              ['degree'],
            ],
          ),
          const DcqlCredentialSetQuery(
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
      final query = DcqlQuery(
        credentials: [
          _query('degree', 'UniversityDegree'),
          _query('employment', 'EmploymentCredential'),
        ],
        credentialSets: [
          const DcqlCredentialSetQuery(
            options: [
              ['degree'],
            ],
          ),
          const DcqlCredentialSetQuery(
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
    final query = DcqlQuery(
      credentials: [
        _query('degree', 'UniversityDegree'),
        _query('employment', 'EmploymentCredential'),
      ],
      credentialSets: [
        const DcqlCredentialSetQuery(
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
    DcqlCredentialQuery queryWithMultiple({required bool multiple}) =>
        DcqlCredentialQuery(
          id: 'degree',
          multiple: multiple,
          meta: DcqlCredentialMeta(
            typeValues: [
              ['UniversityDegree'],
            ],
          ),
        );

    test('caps the group at one and recommends one when multiple is '
        'false', () async {
      final query = DcqlQuery(
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
      final query = DcqlQuery(credentials: [queryWithMultiple(multiple: true)]);

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
}
