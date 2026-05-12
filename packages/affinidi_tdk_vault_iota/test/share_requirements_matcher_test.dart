import 'package:affinidi_tdk_vault_iota/affinidi_tdk_vault_iota.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ssi/ssi.dart';
import 'package:test/test.dart';

import 'fixtures/verifiable_credential_fixtures.dart';
import 'mocks/mock_verifiable_credential.dart';

// ── Shared test constants ─────────────────────────────────────────────────────

const _trustedIssuer = 'did:key:z6MkIdvIssuer';

// ── Helper builders ───────────────────────────────────────────────────────────

MockVerifiableCredential _mockVc({DateTime? validUntil, DateTime? validFrom}) {
  final vc = MockVerifiableCredential();
  when(() => vc.validUntil).thenReturn(validUntil);
  when(() => vc.validFrom).thenReturn(validFrom ?? DateTime(2024));
  return vc;
}

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

ShareRequirementsMatcher _matcherReturning(VcMatchResult result) {
  return ShareRequirementsMatcher(
    matcher: ({
      required Map<String, dynamic> presentationDefinition,
      required List<VerifiableCredential> allVerifiableCredentials,
    }) async =>
        result,
  );
}

void main() {
  // ── Single available credential ───────────────────────────────────────────

  group('when the matcher returns a single available credential', () {
    late ShareRequirementsMatcher matcher;
    late VerifiableCredential vc;

    setUp(() {
      vc = buildTestVc(type: 'UniversityDegree');
      matcher = _matcherReturning(
        VcMatchResult(matchedVCs: [vc], requiredCredentialsPresent: true),
      );
    });

    test('should mark the credential as available', () async {
      final req = _requirements([_descriptor(id: 'd1', type: 'UniversityDegree')]);
      final result = await matcher.match(req, [vc]);

      expect(result.vcsGroups, hasLength(1));
      expect(result.vcsGroups.values.first.allAvailableVCs, hasLength(1));
      expect(result.vcsGroups.values.first.matchedVCs.first, isA<VcAvailable>());
    });

    test('should report isEnoughVCsAvailableToShare as true', () async {
      final req = _requirements([_descriptor(id: 'd1', type: 'UniversityDegree')]);
      final result = await matcher.match(req, [vc]);

      expect(result.isEnoughVCsAvailableToShare, isTrue);
    });

    test('should include the VC in availableCredentials', () async {
      final req = _requirements([_descriptor(id: 'd1', type: 'UniversityDegree')]);
      final result = await matcher.match(req, [vc]);

      expect(result.availableCredentials, contains(vc));
    });
  });

  // ── No credentials matched ────────────────────────────────────────────────

  group('when the matcher returns no credentials', () {
    late ShareRequirementsMatcher matcher;

    setUp(() {
      matcher = _matcherReturning(
        const VcMatchResult(matchedVCs: [], requiredCredentialsPresent: false),
      );
    });

    test('should mark the descriptor as missing', () async {
      final req = _requirements([_descriptor(id: 'd1', type: 'UniversityDegree')]);
      final result = await matcher.match(req, []);

      final first = result.vcsGroups.values.first.matchedVCs.first;
      expect(first, isA<VcUnavailable>());
      expect((first as VcUnavailable).reason, VcUnavailabilityReason.missing);
    });

    test('should report isEnoughVCsAvailableToShare as false', () async {
      final req = _requirements([_descriptor(id: 'd1', type: 'UniversityDegree')]);
      final result = await matcher.match(req, []);

      expect(result.isEnoughVCsAvailableToShare, isFalse);
    });
  });

  // ── Expired credentials ───────────────────────────────────────────────────

  group('when the matched credentials are expired', () {
    test('should mark them as unavailable with reason expired', () async {
      final expiredVc = _mockVc(validUntil: DateTime(2000));
      final matcher = _matcherReturning(
        VcMatchResult(matchedVCs: [expiredVc], requiredCredentialsPresent: true),
      );

      final req = _requirements([_descriptor(id: 'd1', type: 'UniversityDegree')]);
      final result = await matcher.match(req, [expiredVc]);

      final first = result.vcsGroups.values.first.matchedVCs.first;
      expect(first, isA<VcUnavailable>());
      expect((first as VcUnavailable).reason, VcUnavailabilityReason.expired);
      expect(first.bestMatchVc, expiredVc);
    });

    test('should place available credentials before expired ones', () async {
      final validVc = _mockVc(validFrom: DateTime(2025));
      final expiredVc = _mockVc(
        validUntil: DateTime(2000),
        validFrom: DateTime(2024),
      );
      final matcher = _matcherReturning(
        VcMatchResult(
          matchedVCs: [expiredVc, validVc],
          requiredCredentialsPresent: true,
        ),
      );

      final req = _requirements([_descriptor(id: 'd1', type: 'UniversityDegree')]);
      final result = await matcher.match(req, [validVc, expiredVc]);

      final matchedVCs = result.vcsGroups.values.first.matchedVCs;
      expect(matchedVCs[0], isA<VcAvailable>());
      expect(matchedVCs[1], isA<VcUnavailable>());
    });
  });

  // ── Matcher throws ────────────────────────────────────────────────────────

  group('when the matcher throws', () {
    test('should record the descriptor as unknown rather than propagating', () async {
      final matcher = ShareRequirementsMatcher(
        matcher: ({
          required Map<String, dynamic> presentationDefinition,
          required List<VerifiableCredential> allVerifiableCredentials,
        }) async =>
            throw Exception('PEX engine failed'),
      );

      final req = _requirements([_descriptor(id: 'd1', type: 'UniversityDegree')]);
      final result = await matcher.match(req, []);

      final first = result.vcsGroups.values.first.matchedVCs.first;
      expect(first, isA<VcUnavailable>());
      expect((first as VcUnavailable).reason, VcUnavailabilityReason.unknown);
    });
  });

  // ── IDV descriptors ───────────────────────────────────────────────────────

  group('when requirements include IDV descriptors', () {
    test('should match IDV descriptors alongside claimed ones', () async {
      final vc = buildTestVc(type: 'VerifiedIdentityDocument', issuer: _trustedIssuer);
      final matcher = _matcherReturning(
        VcMatchResult(matchedVCs: [vc], requiredCredentialsPresent: true),
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
      final result = await matcher.match(req, [vc]);

      expect(result.vcsGroups, hasLength(2));
      expect(result.isEnoughVCsAvailableToShare, isTrue);
    });
  });

  // ── Submission requirements ───────────────────────────────────────────────

  group('when submission_requirements define min/max counts', () {
    test('should apply count to VCsGroupByType min and max', () async {
      final vc = buildTestVc(type: 'UniversityDegree');
      final matcher = _matcherReturning(
        VcMatchResult(matchedVCs: [vc], requiredCredentialsPresent: true),
      );

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

    test('should default to 1 when no submission requirement exists for the descriptor', () async {
      final vc = buildTestVc(type: 'UniversityDegree');
      final matcher = _matcherReturning(
        VcMatchResult(matchedVCs: [vc], requiredCredentialsPresent: true),
      );

      final req = _requirements([_descriptor(id: 'd1', type: 'UniversityDegree')]);
      final result = await matcher.match(req, [vc]);

      final group = result.vcsGroups.values.first;
      expect(group.minimumVCsCountToShare, 1);
      expect(group.maximumVCsCountToShare, 1);
    });
  });

  // ── Multiple descriptors ──────────────────────────────────────────────────

  group('when there are multiple descriptors', () {
    test('should call the matcher once per descriptor', () async {
      var callCount = 0;
      final matcher = ShareRequirementsMatcher(
        matcher: ({
          required Map<String, dynamic> presentationDefinition,
          required List<VerifiableCredential> allVerifiableCredentials,
        }) async {
          callCount++;
          return const VcMatchResult(matchedVCs: [], requiredCredentialsPresent: false);
        },
      );

      final req = _requirements([
        _descriptor(id: 'd1', type: 'UniversityDegree'),
        _descriptor(id: 'd2', type: 'EmploymentCredential'),
      ]);
      await matcher.match(req, []);

      expect(callCount, 2);
    });

    test('should produce one vcsGroups entry per descriptor', () async {
      final matcher = _matcherReturning(
        const VcMatchResult(matchedVCs: [], requiredCredentialsPresent: false),
      );

      final req = _requirements([
        _descriptor(id: 'd1', type: 'UniversityDegree'),
        _descriptor(id: 'd2', type: 'EmploymentCredential'),
      ]);
      final result = await matcher.match(req, []);

      expect(result.vcsGroups, hasLength(2));
    });

    test('should return empty vcsGroups for empty requirements', () async {
      final matcher = _matcherReturning(
        const VcMatchResult(matchedVCs: [], requiredCredentialsPresent: false),
      );

      final result = await matcher.match(_requirements([]), []);

      expect(result.vcsGroups, isEmpty);
      expect(result.isEnoughVCsAvailableToShare, isTrue);
    });
  });
}
