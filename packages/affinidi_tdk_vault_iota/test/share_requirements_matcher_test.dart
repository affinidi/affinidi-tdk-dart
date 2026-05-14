import 'package:affinidi_tdk_vault_iota/affinidi_tdk_vault_iota.dart';
import 'package:mocktail/mocktail.dart' hide VerificationResult;
import 'package:ssi/ssi.dart';
import 'package:test/test.dart';

import 'fixtures/pd_descriptor_fixtures.dart';
import 'fixtures/verifiable_credential_fixtures.dart';
import 'mocks/mock_revocation_verifier.dart';
import 'mocks/mock_verifiable_credential.dart';

// ── Shared test constants ─────────────────────────────────────────────────────

const _trustedIssuer = 'did:key:z6MkIdvIssuer';
const _otherIssuer = 'did:key:z6MkOtherIssuer';

// ── Fakes ─────────────────────────────────────────────────────────────────────

class _FakeParsedVerifiableCredential extends Fake
    implements ParsedVerifiableCredential<dynamic> {}

// ── Helper builders ───────────────────────────────────────────────────────────

PDRequirements _requirements(
  List<Map<String, dynamic>> claimedDescriptors, {
  List<Map<String, dynamic>> idvDescriptors = const [],
  Map<String, SubmissionRequirements> submissionRequirementsByGroup = const {},
}) {
  return PDRequirements(
    claimedDescriptors: claimedDescriptors
        .map((d) => PDDescriptor(data: d))
        .toList(),
    zpdLinkedDescriptors: const [],
    idvDescriptors: idvDescriptors.map((d) => PDDescriptor(data: d)).toList(),
    dataPoints: const {},
    zeroPartyVCs: const {},
    submissionRequirementsByGroup: submissionRequirementsByGroup,
  );
}

void main() {
  final matcher = ShareRequirementsMatcher();

  // ── Single available credential ───────────────────────────────────────────

  group('when a VC matches the descriptor type', () {
    late VerifiableCredential vc;

    setUp(() {
      vc = buildTestVc(type: 'UniversityDegree');
    });

    test('should mark the credential as available', () async {
      final req = _requirements([
        buildDescriptor(id: 'd1', type: 'UniversityDegree'),
      ]);
      final result = await matcher.match(req, [vc]);

      expect(result.vcsGroups, hasLength(1));
      expect(result.vcsGroups.values.first.allAvailableVCs, hasLength(1));
      expect(
        result.vcsGroups.values.first.matchedVCs.first,
        isA<VcAvailable>(),
      );
    });

    test('should report isEnoughVCsAvailableToShare as true', () async {
      final req = _requirements([
        buildDescriptor(id: 'd1', type: 'UniversityDegree'),
      ]);
      final result = await matcher.match(req, [vc]);

      expect(result.isEnoughVCsAvailableToShare, isTrue);
    });

    test('should include the VC in availableCredentials', () async {
      final req = _requirements([
        buildDescriptor(id: 'd1', type: 'UniversityDegree'),
      ]);
      final result = await matcher.match(req, [vc]);

      expect(result.availableCredentials, contains(vc));
    });
  });

  // ── Type mismatch ─────────────────────────────────────────────────────────

  group('when no VC matches the descriptor type', () {
    test('should mark the descriptor as missing', () async {
      final vc = buildTestVc(type: 'UniversityDegree');
      final req = _requirements([
        buildDescriptor(id: 'd1', type: 'EmploymentCredential'),
      ]);
      final result = await matcher.match(req, [vc]);

      final first = result.vcsGroups.values.first.matchedVCs.first;
      expect(first, isA<VcUnavailable>());
      expect((first as VcUnavailable).reason, VcUnavailabilityReason.missing);
    });

    test('should report isEnoughVCsAvailableToShare as false', () async {
      final req = _requirements([
        buildDescriptor(id: 'd1', type: 'EmploymentCredential'),
      ]);
      final result = await matcher.match(req, []);

      expect(result.isEnoughVCsAvailableToShare, isFalse);
    });
  });

  // ── Issuer filter ─────────────────────────────────────────────────────────

  group('when the descriptor includes an issuer constraint', () {
    test('should match a VC whose issuer equals the filter', () async {
      final vc = buildTestVc(type: 'UniversityDegree', issuer: _trustedIssuer);
      final req = _requirements([
        buildDescriptor(
          id: 'd1',
          type: 'UniversityDegree',
          issuer: _trustedIssuer,
        ),
      ]);
      final result = await matcher.match(req, [vc]);

      expect(
        result.vcsGroups.values.first.matchedVCs.first,
        isA<VcAvailable>(),
      );
    });

    test(
      'should not match a VC whose issuer differs from the filter',
      () async {
        final vc = buildTestVc(type: 'UniversityDegree', issuer: _otherIssuer);
        final req = _requirements([
          buildDescriptor(
            id: 'd1',
            type: 'UniversityDegree',
            issuer: _trustedIssuer,
          ),
        ]);
        final result = await matcher.match(req, [vc]);

        final first = result.vcsGroups.values.first.matchedVCs.first;
        expect(first, isA<VcUnavailable>());
        expect((first as VcUnavailable).reason, VcUnavailabilityReason.missing);
      },
    );
  });

  // ── Expired credentials ───────────────────────────────────────────────────

  group('when the matched credential is expired', () {
    test('should mark it as unavailable with reason expired', () async {
      final expiredVc = buildTestVc(
        type: 'UniversityDegree',
        validUntil: '2000-01-01T00:00:00Z',
      );
      final req = _requirements([
        buildDescriptor(id: 'd1', type: 'UniversityDegree'),
      ]);
      final result = await matcher.match(req, [expiredVc]);

      final first = result.vcsGroups.values.first.matchedVCs.first;
      expect(first, isA<VcUnavailable>());
      expect((first as VcUnavailable).reason, VcUnavailabilityReason.expired);
      expect(first.bestMatchVc, expiredVc);
    });

    test('should place available credentials before expired ones', () async {
      final validVc = buildTestVc(
        type: 'UniversityDegree',
        validFrom: '2025-01-01T00:00:00Z',
      );
      final expiredVc = buildTestVc(
        type: 'UniversityDegree',
        validFrom: '2024-01-01T00:00:00Z',
        validUntil: '2000-01-01T00:00:00Z',
      );
      final req = _requirements([
        buildDescriptor(id: 'd1', type: 'UniversityDegree'),
      ]);
      final result = await matcher.match(req, [expiredVc, validVc]);

      final matchedVCs = result.vcsGroups.values.first.matchedVCs;
      expect(matchedVCs[0], isA<VcAvailable>());
      expect(matchedVCs[1], isA<VcUnavailable>());
    });
  });

  // ── VC evaluation throws ──────────────────────────────────────────────────

  group('when evaluating a VC throws', () {
    test(
      'should skip the bad VC and record the descriptor as missing',
      () async {
        final badVc = MockVerifiableCredential();
        when(badVc.toJson).thenThrow(Exception('VC evaluation failed'));

        final req = _requirements([
          buildDescriptor(id: 'd1', type: 'UniversityDegree'),
        ]);
        final result = await matcher.match(req, [badVc]);

        final first = result.vcsGroups.values.first.matchedVCs.first;
        expect(first, isA<VcUnavailable>());
        expect((first as VcUnavailable).reason, VcUnavailabilityReason.missing);
      },
    );

    test(
      'should apply submission requirement counts even when evaluation throws',
      () async {
        final badVc = MockVerifiableCredential();
        when(badVc.toJson).thenThrow(Exception('VC evaluation failed'));

        final req = _requirements(
          [
            buildDescriptor(id: 'd1', type: 'UniversityDegree', group: ['A']),
          ],
          submissionRequirementsByGroup: {
            'A': const SubmissionRequirements(count: 2, groupName: 'A'),
          },
        );
        final result = await matcher.match(req, [badVc]);

        final group = result.vcsGroups.values.first;
        expect(group.minimumVCsCountToShare, 2);
        expect(group.maximumVCsCountToShare, 2);
        expect(group.matchedVCs.first, isA<VcUnavailable>());
      },
    );
  });

  // ── IDV descriptors ───────────────────────────────────────────────────────

  group('when requirements include IDV descriptors', () {
    test('should match IDV descriptors alongside claimed ones', () async {
      final degreeVc = buildTestVc(type: 'UniversityDegree');
      final idvVc = buildTestVc(
        type: 'VerifiedIdentityDocument',
        issuer: _trustedIssuer,
      );

      final req = _requirements(
        [buildDescriptor(id: 'degree', type: 'UniversityDegree')],
        idvDescriptors: [
          buildDescriptor(
            id: 'passport',
            type: 'VerifiedIdentityDocument',
            issuer: _trustedIssuer,
          ),
        ],
      );
      final result = await matcher.match(req, [degreeVc, idvVc]);

      expect(result.vcsGroups, hasLength(2));
      expect(result.isEnoughVCsAvailableToShare, isTrue);
    });
  });

  // ── Submission requirements ───────────────────────────────────────────────

  group('when submission_requirements define min/max counts', () {
    test('should apply count to VCsGroupByType min and max', () async {
      final vc = buildTestVc(type: 'UniversityDegree');
      final req = _requirements(
        [
          buildDescriptor(id: 'd1', type: 'UniversityDegree', group: ['A']),
        ],
        submissionRequirementsByGroup: {
          'A': const SubmissionRequirements(count: 2, groupName: 'A'),
        },
      );
      final result = await matcher.match(req, [vc]);

      final group = result.vcsGroups.values.first;
      expect(group.minimumVCsCountToShare, 2);
      expect(group.maximumVCsCountToShare, 2);
    });

    test('should default to 1 when no submission requirement exists for the '
        'descriptor', () async {
      final vc = buildTestVc(type: 'UniversityDegree');
      final req = _requirements([
        buildDescriptor(id: 'd1', type: 'UniversityDegree'),
      ]);
      final result = await matcher.match(req, [vc]);

      final group = result.vcsGroups.values.first;
      expect(group.minimumVCsCountToShare, 1);
      expect(group.maximumVCsCountToShare, 1);
    });

    test(
      'should apply submission requirement counts even when no VCs match',
      () async {
        final req = _requirements(
          [
            buildDescriptor(
              id: 'd1',
              type: 'EmploymentCredential',
              group: ['A'],
            ),
          ],
          submissionRequirementsByGroup: {
            'A': const SubmissionRequirements(count: 3, groupName: 'A'),
          },
        );
        final result = await matcher.match(req, []);

        final group = result.vcsGroups.values.first;
        expect(group.minimumVCsCountToShare, 3);
        expect(group.maximumVCsCountToShare, 3);
        expect(group.matchedVCs.first, isA<VcUnavailable>());
      },
    );
  });

  // ── Multiple descriptors ──────────────────────────────────────────────────

  group('when there are multiple descriptors', () {
    test('should produce one vcsGroups entry per descriptor', () async {
      final degreeVc = buildTestVc(type: 'UniversityDegree');
      final employVc = buildTestVc(type: 'EmploymentCredential');

      final req = _requirements([
        buildDescriptor(id: 'd1', type: 'UniversityDegree'),
        buildDescriptor(id: 'd2', type: 'EmploymentCredential'),
      ]);
      final result = await matcher.match(req, [degreeVc, employVc]);

      expect(result.vcsGroups, hasLength(2));
      expect(result.isEnoughVCsAvailableToShare, isTrue);
    });

    test('should only match each VC to its respective descriptor', () async {
      final degreeVc = buildTestVc(type: 'UniversityDegree');

      final req = _requirements([
        buildDescriptor(id: 'd1', type: 'UniversityDegree'),
        buildDescriptor(id: 'd2', type: 'EmploymentCredential'),
      ]);
      final result = await matcher.match(req, [degreeVc]);

      final groups = result.vcsGroups.values.toList();
      expect(groups[0].allAvailableVCs, hasLength(1));

      final second = groups[1].matchedVCs.first;
      expect(second, isA<VcUnavailable>());
      expect((second as VcUnavailable).reason, VcUnavailabilityReason.missing);
    });

    test('should return empty vcsGroups for empty requirements', () async {
      final result = await matcher.match(_requirements([]), []);

      expect(result.vcsGroups, isEmpty);
      expect(result.isEnoughVCsAvailableToShare, isTrue);
    });
  });

  // ── recommendedMaximumVCs ─────────────────────────────────────────────────

  group('recommendedMaximumVCs', () {
    test(
      'should return up to maximumVCsCountToShare from each group',
      () async {
        final vc1 = buildTestVc(
          type: 'UniversityDegree',
          validFrom: '2025-06-01T00:00:00Z',
        );
        final vc2 = buildTestVc(
          type: 'UniversityDegree',
          validFrom: '2024-01-01T00:00:00Z',
        );

        final req = _requirements(
          [
            buildDescriptor(id: 'd1', type: 'UniversityDegree', group: ['A']),
          ],
          submissionRequirementsByGroup: {
            'A': const SubmissionRequirements(count: 1, groupName: 'A'),
          },
        );
        final result = await matcher.match(req, [vc1, vc2]);
        expect(result.recommendedMaximumVCs, hasLength(1));
      },
    );
  });

  // ── Revoked credentials ───────────────────────────────────────────────────

  group('when a revocation verifier is provided', () {
    late MockRevocationVerifier verifier;
    late ShareRequirementsMatcher matcherWithVerifier;

    setUpAll(() {
      registerFallbackValue(_FakeParsedVerifiableCredential());
    });

    setUp(() {
      verifier = MockRevocationVerifier();
      matcherWithVerifier = ShareRequirementsMatcher(
        revocationVerifier: verifier,
      );
    });

    test(
      'should mark a VC as revoked when the verifier returns errors',
      () async {
        final vc = buildTestVc(type: 'UniversityDegree');
        when(() => verifier.verify(any())).thenAnswer(
          (_) async =>
              VerificationResult.invalid(errors: ['credential is revoked']),
        );

        final req = _requirements([
          buildDescriptor(id: 'd1', type: 'UniversityDegree'),
        ]);
        final result = await matcherWithVerifier.match(req, [vc]);

        final first = result.vcsGroups.values.first.matchedVCs.first;
        expect(first, isA<VcUnavailable>());
        expect((first as VcUnavailable).reason, VcUnavailabilityReason.revoked);
        expect(first.bestMatchVc, vc);
      },
    );

    test(
      'should mark a VC as available when the verifier returns ok',
      () async {
        final vc = buildTestVc(type: 'UniversityDegree');
        when(
          () => verifier.verify(any()),
        ).thenAnswer((_) async => VerificationResult.ok());

        final req = _requirements([
          buildDescriptor(id: 'd1', type: 'UniversityDegree'),
        ]);
        final result = await matcherWithVerifier.match(req, [vc]);

        expect(
          result.vcsGroups.values.first.matchedVCs.first,
          isA<VcAvailable>(),
        );
      },
    );

    test('should place revoked credentials after available ones', () async {
      final validVc = buildTestVc(
        type: 'UniversityDegree',
        validFrom: '2025-01-01T00:00:00Z',
      );
      final revokedVc = buildTestVc(
        type: 'UniversityDegree',
        validFrom: '2024-01-01T00:00:00Z',
      );

      when(() => verifier.verify(any())).thenAnswer((invocation) async {
        final arg = invocation.positionalArguments.first;
        if (arg == revokedVc) {
          return VerificationResult.invalid(errors: ['revoked']);
        }
        return VerificationResult.ok();
      });

      final req = _requirements([
        buildDescriptor(id: 'd1', type: 'UniversityDegree'),
      ]);
      final result = await matcherWithVerifier.match(req, [revokedVc, validVc]);

      final matchedVCs = result.vcsGroups.values.first.matchedVCs;
      expect(matchedVCs[0], isA<VcAvailable>());
      expect(matchedVCs[1], isA<VcUnavailable>());
      expect(
        (matchedVCs[1] as VcUnavailable).reason,
        VcUnavailabilityReason.revoked,
      );
    });

    test('should treat a VC as available when the verifier throws', () async {
      final vc = buildTestVc(type: 'UniversityDegree');
      when(() => verifier.verify(any())).thenThrow(Exception('network error'));

      final req = _requirements([
        buildDescriptor(id: 'd1', type: 'UniversityDegree'),
      ]);
      final result = await matcherWithVerifier.match(req, [vc]);

      expect(
        result.vcsGroups.values.first.matchedVCs.first,
        isA<VcAvailable>(),
      );
    });
  });

  group('when no revocation verifier is provided', () {
    test(
      'should not check revocation and treat matched VCs as available',
      () async {
        final vc = buildTestVc(type: 'UniversityDegree');
        final req = _requirements([
          buildDescriptor(id: 'd1', type: 'UniversityDegree'),
        ]);
        // matcher has no verifier — uses default ShareRequirementsMatcher()
        final result = await matcher.match(req, [vc]);

        expect(
          result.vcsGroups.values.first.matchedVCs.first,
          isA<VcAvailable>(),
        );
      },
    );
  });

  // ── JSON Schema filter evaluation ──────────────────────────────────────────

  group('JSON Schema filter evaluation', () {
    Map<String, dynamic> descriptorWithFilter(
      String id,
      Map<String, dynamic> filter, {
      String path = r'$.type',
    }) => {
      'id': id,
      'constraints': {
        'fields': [
          {
            'path': [path],
            'filter': filter,
          },
        ],
      },
    };

    test(
      'should not match when the value type does not match the schema type',
      () async {
        // $.type resolves to a List; {type: 'string'} rejects non-strings.
        final vc = buildTestVc(type: 'UniversityDegree');
        final req = _requirements([
          descriptorWithFilter('d1', {
            'type': 'string',
            'enum': ['UniversityDegree', 'EmploymentCredential'],
          }),
        ]);
        final result = await matcher.match(req, [vc]);

        expect(
          result.vcsGroups.values.first.matchedVCs.first,
          isA<VcUnavailable>(),
        );
      },
    );

    test('should match when enum contains the resolved string value', () async {
      final vc = buildTestVc(type: 'UniversityDegree', issuer: _trustedIssuer);
      final req = _requirements([
        descriptorWithFilter('d1', {
          'type': 'string',
          'enum': [_trustedIssuer, _otherIssuer],
        }, path: r'$.issuer'),
      ]);
      final result = await matcher.match(req, [vc]);

      expect(
        result.vcsGroups.values.first.matchedVCs.first,
        isA<VcAvailable>(),
      );
    });

    test('should match when the filter has only a type annotation', () async {
      final vc = buildTestVc(type: 'UniversityDegree');
      final req = _requirements([
        descriptorWithFilter('d1', {'type': 'array'}),
      ]);
      final result = await matcher.match(req, [vc]);

      expect(
        result.vcsGroups.values.first.matchedVCs.first,
        isA<VcAvailable>(),
      );
    });

    test('should match when contains+enum is used on an array value', () async {
      final vc = buildTestVc(type: 'UniversityDegree');
      final req = _requirements([
        descriptorWithFilter('d1', {
          'type': 'array',
          'contains': {
            'enum': ['UniversityDegree'],
          },
        }),
      ]);
      final result = await matcher.match(req, [vc]);

      expect(
        result.vcsGroups.values.first.matchedVCs.first,
        isA<VcAvailable>(),
      );
    });
  });
}
