import 'package:affinidi_tdk_vault_iota/affinidi_tdk_vault_iota.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ssi/ssi.dart';
import 'package:test/test.dart';

import 'fixtures/verifiable_credential_fixtures.dart';
import 'mocks/mock_verifiable_credential.dart';

// ── Shared test constants ─────────────────────────────────────────────────────

const _trustedIssuer = 'did:key:z6MkIdvIssuer';
const _otherIssuer = 'did:key:z6MkOtherIssuer';

// ── Helper builders ───────────────────────────────────────────────────────────

/// Builds a descriptor that matches on [type] and optionally [issuer].
Map<String, dynamic> _descriptor({
  required String id,
  required String type,
  String? issuer,
  List<String>? group,
}) {
  final fields = <Map<String, dynamic>>[
    {
      'path': [r'$.type'],
      'filter': {
        'contains': {'const': type},
      },
    },
  ];

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

PDRequirements _requirements(
  List<Map<String, dynamic>> claimedDescriptors, {
  List<Map<String, dynamic>> idvDescriptors = const [],
  Map<String, SubmissionRequirements> submissionRequirementsByGroup = const {},
}) {
  return PDRequirements(
    claimedDescriptors:
        claimedDescriptors.map((d) => PDDescriptor(data: d)).toList(),
    zpdLinkedDescriptors: const [],
    idvDescriptors:
        idvDescriptors.map((d) => PDDescriptor(data: d)).toList(),
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
      final req =
          _requirements([_descriptor(id: 'd1', type: 'UniversityDegree')]);
      final result = await matcher.match(req, [vc]);

      expect(result.vcsGroups, hasLength(1));
      expect(result.vcsGroups.values.first.allAvailableVCs, hasLength(1));
      expect(
        result.vcsGroups.values.first.matchedVCs.first,
        isA<VcAvailable>(),
      );
    });

    test('should report isEnoughVCsAvailableToShare as true', () async {
      final req =
          _requirements([_descriptor(id: 'd1', type: 'UniversityDegree')]);
      final result = await matcher.match(req, [vc]);

      expect(result.isEnoughVCsAvailableToShare, isTrue);
    });

    test('should include the VC in availableCredentials', () async {
      final req =
          _requirements([_descriptor(id: 'd1', type: 'UniversityDegree')]);
      final result = await matcher.match(req, [vc]);

      expect(result.availableCredentials, contains(vc));
    });
  });

  // ── Type mismatch ─────────────────────────────────────────────────────────

  group('when no VC matches the descriptor type', () {
    test('should mark the descriptor as missing', () async {
      final vc = buildTestVc(type: 'UniversityDegree');
      final req = _requirements(
        [_descriptor(id: 'd1', type: 'EmploymentCredential')],
      );
      final result = await matcher.match(req, [vc]);

      final first = result.vcsGroups.values.first.matchedVCs.first;
      expect(first, isA<VcUnavailable>());
      expect(
        (first as VcUnavailable).reason,
        VcUnavailabilityReason.missing,
      );
    });

    test('should report isEnoughVCsAvailableToShare as false', () async {
      final req = _requirements(
        [_descriptor(id: 'd1', type: 'EmploymentCredential')],
      );
      final result = await matcher.match(req, []);

      expect(result.isEnoughVCsAvailableToShare, isFalse);
    });
  });

  // ── Issuer filter ─────────────────────────────────────────────────────────

  group('when the descriptor includes an issuer constraint', () {
    test('should match a VC whose issuer equals the filter', () async {
      final vc = buildTestVc(
        type: 'UniversityDegree',
        issuer: _trustedIssuer,
      );
      final req = _requirements([
        _descriptor(
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

    test('should not match a VC whose issuer differs from the filter',
        () async {
      final vc = buildTestVc(
        type: 'UniversityDegree',
        issuer: _otherIssuer,
      );
      final req = _requirements([
        _descriptor(
          id: 'd1',
          type: 'UniversityDegree',
          issuer: _trustedIssuer,
        ),
      ]);
      final result = await matcher.match(req, [vc]);

      final first = result.vcsGroups.values.first.matchedVCs.first;
      expect(first, isA<VcUnavailable>());
      expect(
        (first as VcUnavailable).reason,
        VcUnavailabilityReason.missing,
      );
    });
  });

  // ── Expired credentials ───────────────────────────────────────────────────

  group('when the matched credential is expired', () {
    test('should mark it as unavailable with reason expired', () async {
      final expiredVc = buildTestVc(
        type: 'UniversityDegree',
        validUntil: '2000-01-01T00:00:00Z',
      );
      final req =
          _requirements([_descriptor(id: 'd1', type: 'UniversityDegree')]);
      final result = await matcher.match(req, [expiredVc]);

      final first = result.vcsGroups.values.first.matchedVCs.first;
      expect(first, isA<VcUnavailable>());
      expect(
        (first as VcUnavailable).reason,
        VcUnavailabilityReason.expired,
      );
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
      final req =
          _requirements([_descriptor(id: 'd1', type: 'UniversityDegree')]);
      final result = await matcher.match(req, [expiredVc, validVc]);

      final matchedVCs = result.vcsGroups.values.first.matchedVCs;
      expect(matchedVCs[0], isA<VcAvailable>());
      expect(matchedVCs[1], isA<VcUnavailable>());
    });
  });

  // ── VC evaluation throws ──────────────────────────────────────────────────

  group('when evaluating a VC throws', () {
    test('should record the descriptor as unknown rather than propagating',
        () async {
      final badVc = MockVerifiableCredential();
      when(() => badVc.toJson()).thenThrow(Exception('VC evaluation failed'));

      final req =
          _requirements([_descriptor(id: 'd1', type: 'UniversityDegree')]);
      final result = await matcher.match(req, [badVc]);

      final first = result.vcsGroups.values.first.matchedVCs.first;
      expect(first, isA<VcUnavailable>());
      expect(
        (first as VcUnavailable).reason,
        VcUnavailabilityReason.unknown,
      );
    });
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
        [_descriptor(id: 'degree', type: 'UniversityDegree')],
        idvDescriptors: [
          _descriptor(
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
        [_descriptor(id: 'd1', type: 'UniversityDegree', group: ['A'])],
        submissionRequirementsByGroup: {
          'A': const SubmissionRequirements(count: 2, groupName: 'A'),
        },
      );
      final result = await matcher.match(req, [vc]);

      final group = result.vcsGroups.values.first;
      expect(group.minimumVCsCountToShare, 2);
      expect(group.maximumVCsCountToShare, 2);
    });

    test(
        'should default to 1 when no submission requirement exists for the '
        'descriptor', () async {
      final vc = buildTestVc(type: 'UniversityDegree');
      final req =
          _requirements([_descriptor(id: 'd1', type: 'UniversityDegree')]);
      final result = await matcher.match(req, [vc]);

      final group = result.vcsGroups.values.first;
      expect(group.minimumVCsCountToShare, 1);
      expect(group.maximumVCsCountToShare, 1);
    });
  });

  // ── Multiple descriptors ──────────────────────────────────────────────────

  group('when there are multiple descriptors', () {
    test('should produce one vcsGroups entry per descriptor', () async {
      final degreeVc = buildTestVc(type: 'UniversityDegree');
      final employVc = buildTestVc(type: 'EmploymentCredential');

      final req = _requirements([
        _descriptor(id: 'd1', type: 'UniversityDegree'),
        _descriptor(id: 'd2', type: 'EmploymentCredential'),
      ]);
      final result = await matcher.match(req, [degreeVc, employVc]);

      expect(result.vcsGroups, hasLength(2));
      expect(result.isEnoughVCsAvailableToShare, isTrue);
    });

    test('should only match each VC to its respective descriptor', () async {
      final degreeVc = buildTestVc(type: 'UniversityDegree');

      final req = _requirements([
        _descriptor(id: 'd1', type: 'UniversityDegree'),
        _descriptor(id: 'd2', type: 'EmploymentCredential'),
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

  // ── maximumRecommendedVCs ─────────────────────────────────────────────────

  group('maximumRecommendedVCs', () {
    test('should return up to maximumVCsCountToShare from each group',
        () async {
      final vc1 = buildTestVc(
        type: 'UniversityDegree',
        validFrom: '2025-06-01T00:00:00Z',
      );
      final vc2 = buildTestVc(
        type: 'UniversityDegree',
        validFrom: '2024-01-01T00:00:00Z',
      );

      final req = _requirements([
        _descriptor(id: 'd1', type: 'UniversityDegree', group: ['A']),
      ], submissionRequirementsByGroup: {
        'A': const SubmissionRequirements(count: 1, groupName: 'A'),
      });
      final result = await matcher.match(req, [vc1, vc2]);

      expect(result.maximumRecommendedVCs, hasLength(1));
    });
  });
}

