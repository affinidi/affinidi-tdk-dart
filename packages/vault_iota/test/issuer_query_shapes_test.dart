import 'package:affinidi_tdk_vault_iota/affinidi_tdk_vault_iota.dart';
import 'package:affinidi_tdk_vault_iota/src/helpers/dcql_vc_adapter.dart';
import 'package:affinidi_tdk_vault_iota/src/services/dcql_share_requirements_matcher_service.dart';
import 'package:dcql/dcql.dart';
import 'package:test/test.dart';

import 'fixtures/pd_descriptor_fixtures.dart';
import 'fixtures/verifiable_credential_fixtures.dart';

// Regression tests for the recommended issuer query shapes.
//
// W3C VCDM allows `issuer` as a string or as an object `{"id": "did:..."}`.
// Credentials signed with the Dart `ssi` library use the object form. Each
// group below runs the recommended PEX or DCQL issuer filter against both
// forms, plus a credential from a different DID that must not match.

// ── Shared test constants ─────────────────────────────────────────────────────

const _trustedIssuer = 'did:key:z6MkIdvIssuer';
const _otherIssuer = 'did:key:z6MkOtherIssuer';

const _issuerAsObjectValues = [false, true];

// ── Helper builders ───────────────────────────────────────────────────────────

String _formName(bool issuerAsObject) =>
    issuerAsObject ? 'an object-form' : 'a string-form';

Map<String, dynamic> _pd(List<Map<String, dynamic>> descriptors) => {
  'input_descriptors': descriptors,
};

/// DCQL query with one claim per issuer form, either of which satisfies it.
DcqlCredential _claimSetsIssuerQuery(String issuer) => DcqlCredential(
  id: 'degree',
  format: CredentialFormat.ldpVc,
  meta: DcqlMeta(
    typeValues: [
      ['UniversityDegree'],
    ],
  ),
  claims: [
    DcqlClaim(id: 'iss_str', path: ['issuer'], values: [issuer]),
    DcqlClaim(id: 'iss_obj', path: ['issuer', 'id'], values: [issuer]),
  ],
  claimSets: [
    ['iss_str'],
    ['iss_obj'],
  ],
);

/// DCQL query with a single `["issuer", "id"]` claim.
DcqlCredential _issuerIdQuery(String issuer) => DcqlCredential(
  id: 'degree',
  format: CredentialFormat.ldpVc,
  meta: DcqlMeta(
    typeValues: [
      ['UniversityDegree'],
    ],
  ),
  claims: [
    DcqlClaim(path: ['issuer', 'id'], values: [issuer]),
  ],
);

void main() {
  final classifier = PDClassifier(validIdvIssuers: [_trustedIssuer]);

  // ── Fixture precondition ──────────────────────────────────────────────────

  // The PEX matchers resolve paths against `vc.toJson()`, so the object-form
  // PEX tests below are only meaningful if the fixture keeps that form there.
  group('when buildTestVc builds the issuer', () {
    test('should serialise the default as a string', () {
      final vc = buildTestVc(type: 'UniversityDegree', issuer: _trustedIssuer);

      expect(vc.toJson()['issuer'], _trustedIssuer);
    });

    test('should serialise issuerAsObject as an object with an id', () {
      final vc = buildTestVc(
        type: 'UniversityDegree',
        issuer: _trustedIssuer,
        issuerAsObject: true,
      );

      expect(vc.toJson()['issuer'], {'id': _trustedIssuer});
      expect(vc.issuer.id.toString(), _trustedIssuer);
    });
  });

  // ── PEX: PDClassifier → ShareRequirementsMatcher ──────────────────────────

  group(
    'when a claimed descriptor filters by the recommended issuer paths',
    () {
      final matcher = ShareRequirementsMatcher();
      late PDRequirements requirements;

      setUp(() {
        requirements = classifier.classify(
          _pd([
            buildDescriptor(
              id: 'degree',
              type: 'UniversityDegree',
              issuer: _trustedIssuer,
              issuerPaths: recommendedIssuerPaths,
            ),
          ]),
        );
      });

      test('should route the descriptor to claimedDescriptors', () {
        expect(requirements.claimedDescriptors, hasLength(1));
        expect(requirements.idvDescriptors, isEmpty);
      });

      for (final issuerAsObject in _issuerAsObjectValues) {
        final form = _formName(issuerAsObject);

        test(
          'should mark a VC with $form issuer from that DID as available',
          () async {
            final vc = buildTestVc(
              type: 'UniversityDegree',
              issuer: _trustedIssuer,
              issuerAsObject: issuerAsObject,
            );
            final result = await matcher.match(requirements, [vc]);

            final first = result.vcsGroups.values.single.matchedVCs.single;
            expect(first, isA<VcAvailable>());
            expect((first as VcAvailable).vc, same(vc));
            expect(result.hasEnoughVCsAvailableToShare, isTrue);
          },
        );

        test(
          'should mark a VC with $form issuer from a different DID as missing',
          () async {
            final vc = buildTestVc(
              type: 'UniversityDegree',
              issuer: _otherIssuer,
              issuerAsObject: issuerAsObject,
            );
            final result = await matcher.match(requirements, [vc]);

            final first = result.vcsGroups.values.single.matchedVCs.single;
            expect(first, isA<VcUnavailable>());
            expect(
              (first as VcUnavailable).reason,
              VcUnavailabilityReason.missing,
            );
            expect(result.hasEnoughVCsAvailableToShare, isFalse);
          },
        );
      }
    },
  );

  // ── PEX: IDV routing ──────────────────────────────────────────────────────

  group(
    'when a claimed descriptor filters the recommended issuer paths by pattern',
    () {
      final matcher = ShareRequirementsMatcher();

      PDRequirements requirementsFor(String issuer) => classifier.classify(
        _pd([
          buildDescriptor(
            id: 'degree',
            type: 'UniversityDegree',
            issuer: issuer,
            issuerPaths: recommendedIssuerPaths,
            usePattern: true,
          ),
        ]),
      );

      for (final issuerAsObject in _issuerAsObjectValues) {
        final form = _formName(issuerAsObject);

        test('should match a VC with $form issuer from that DID', () async {
          final vc = buildTestVc(
            type: 'UniversityDegree',
            issuer: _trustedIssuer,
            issuerAsObject: issuerAsObject,
          );
          final result = await matcher.match(requirementsFor(_trustedIssuer), [
            vc,
          ]);

          expect(result.hasEnoughVCsAvailableToShare, isTrue);
        });

        test(
          'should not match a VC with $form issuer from a different DID',
          () async {
            final vc = buildTestVc(
              type: 'UniversityDegree',
              issuer: _otherIssuer,
              issuerAsObject: issuerAsObject,
            );
            final result = await matcher.match(
              requirementsFor(_trustedIssuer),
              [vc],
            );

            expect(result.hasEnoughVCsAvailableToShare, isFalse);
          },
        );
      }
    },
  );

  group('when an IDV descriptor filters by the recommended issuer paths', () {
    final matcher = ShareRequirementsMatcher();
    late PDRequirements requirements;

    setUp(() {
      requirements = classifier.classify(
        _pd([
          buildDescriptor(
            id: 'idv',
            type: 'VerifiedIdentityDocument',
            issuer: _trustedIssuer,
            issuerPaths: recommendedIssuerPaths,
          ),
        ]),
      );
    });

    test('should route the descriptor to idvDescriptors', () {
      expect(requirements.idvDescriptors, hasLength(1));
      expect(requirements.idvDescriptors.single.id, 'idv');
      expect(requirements.claimedDescriptors, isEmpty);
    });

    for (final issuerAsObject in _issuerAsObjectValues) {
      final form = _formName(issuerAsObject);

      test(
        'should mark an IDV VC with $form issuer from the trusted DID as available',
        () async {
          final vc = buildTestVc(
            type: 'VerifiedIdentityDocument',
            issuer: _trustedIssuer,
            issuerAsObject: issuerAsObject,
          );
          final result = await matcher.match(requirements, [vc]);

          final first = result.vcsGroups.values.single.matchedVCs.single;
          expect(first, isA<VcAvailable>());
          expect((first as VcAvailable).vc, same(vc));
        },
      );

      test(
        'should mark an IDV VC with $form issuer from a different DID as missing',
        () async {
          final vc = buildTestVc(
            type: 'VerifiedIdentityDocument',
            issuer: _otherIssuer,
            issuerAsObject: issuerAsObject,
          );
          final result = await matcher.match(requirements, [vc]);

          final first = result.vcsGroups.values.single.matchedVCs.single;
          expect(first, isA<VcUnavailable>());
          expect(
            (first as VcUnavailable).reason,
            VcUnavailabilityReason.missing,
          );
        },
      );
    }
  });

  // ── PEX: PresentationSubmissionBuilder ────────────────────────────────────

  group(
    'when PresentationSubmissionBuilder.build uses the recommended issuer paths',
    () {
      final descriptor = PDDescriptor.fromJson(
        buildDescriptor(
          id: 'desc_degree',
          type: 'UniversityDegree',
          issuer: _trustedIssuer,
          issuerPaths: recommendedIssuerPaths,
        ),
      );

      for (final issuerAsObject in _issuerAsObjectValues) {
        final form = _formName(issuerAsObject);

        test(
          'should map the descriptor to the VC with $form issuer from that DID',
          () {
            final result = PresentationSubmissionBuilder.build(
              definitionId: 'pd_issuer',
              descriptors: [descriptor],
              credentials: [
                buildTestVc(
                  type: 'UniversityDegree',
                  issuer: _otherIssuer,
                  issuerAsObject: issuerAsObject,
                ), // index 0
                buildTestVc(
                  type: 'UniversityDegree',
                  issuer: _trustedIssuer,
                  issuerAsObject: issuerAsObject,
                ), // index 1
              ],
            );

            expect(result.descriptorMap, hasLength(1));
            expect(result.descriptorMap.single.id, equals('desc_degree'));
            expect(
              result.descriptorMap.single.path,
              equals(r'$.verifiableCredential[1]'),
            );
          },
        );

        test(
          'should omit the descriptor when only a VC with $form issuer from a different DID is present',
          () {
            final result = PresentationSubmissionBuilder.build(
              definitionId: 'pd_issuer',
              descriptors: [descriptor],
              credentials: [
                buildTestVc(
                  type: 'UniversityDegree',
                  issuer: _otherIssuer,
                  issuerAsObject: issuerAsObject,
                ),
              ],
            );

            expect(result.descriptorMap, isEmpty);
          },
        );
      }
    },
  );

  // ── DCQL: DcqlShareRequirementsMatcher ────────────────────────────────────

  // DCQL sees the issuer through the dcql package, which re-serializes it as
  // {"id": ...} whichever form the VC used. So only ["issuer", "id"] can match
  // in vault_iota; the string-form cases below check that this still holds.
  group('when a DCQL credential query filters by issuer', () {
    final matcher = DcqlShareRequirementsMatcher();

    for (final issuerAsObject in _issuerAsObjectValues) {
      test(
        'should expose ${_formName(issuerAsObject)} issuer to DCQL as an object',
        () {
          final vc = buildTestVc(
            type: 'UniversityDegree',
            issuer: _trustedIssuer,
            issuerAsObject: issuerAsObject,
          );

          expect(
            DcqlVcAdapter().toDigitalCredential(vc)!.getValueByPath(['issuer']),
            {'id': _trustedIssuer},
          );
        },
      );
    }

    final shapes = {
      'with claim_sets over ["issuer"] and ["issuer", "id"]':
          _claimSetsIssuerQuery(_trustedIssuer),
      'with a single ["issuer", "id"] claim': _issuerIdQuery(_trustedIssuer),
    };

    for (final MapEntry(key: shape, value: credential) in shapes.entries) {
      group(shape, () {
        final query = DcqlCredentialQuery(credentials: [credential]);

        for (final issuerAsObject in _issuerAsObjectValues) {
          final form = _formName(issuerAsObject);

          test('should match a VC with $form issuer from that DID', () async {
            final vc = buildTestVc(
              type: 'UniversityDegree',
              issuer: _trustedIssuer,
              issuerAsObject: issuerAsObject,
            );
            final result = await matcher.match(query, [vc]);

            expect(result.hasEnoughVCsAvailableToShare, isTrue);
            expect(result.availableCredentials, [same(vc)]);
          });

          test(
            'should not match a VC with $form issuer from a different DID',
            () async {
              final result = await matcher.match(query, [
                buildTestVc(
                  type: 'UniversityDegree',
                  issuer: _otherIssuer,
                  issuerAsObject: issuerAsObject,
                ),
              ]);

              expect(result.hasEnoughVCsAvailableToShare, isFalse);
              expect(result.availableCredentials, isEmpty);
            },
          );
        }
      });
    }
  });
}
