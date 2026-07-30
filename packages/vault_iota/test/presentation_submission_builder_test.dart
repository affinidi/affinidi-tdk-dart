import 'package:affinidi_tdk_vault_iota/affinidi_tdk_vault_iota.dart';
import 'package:ssi/ssi.dart';
import 'package:test/test.dart';

import 'fixtures/pd_descriptor_fixtures.dart';
import 'fixtures/verifiable_credential_fixtures.dart';

void main() {
  group('PresentationSubmissionBuilder', () {
    final degreeDescriptor = PDDescriptor.fromJson(
      buildDescriptor(id: 'desc_degree', type: 'UniversityDegree'),
    );
    final employmentDescriptor = PDDescriptor.fromJson(
      buildDescriptor(id: 'desc_employment', type: 'EmploymentCredential'),
    );

    group('when build is called', () {
      group('and a single descriptor matches a single credential', () {
        test('should produce a valid UUID id', () {
          final result = PresentationSubmissionBuilder.build(
            definitionId: 'pd_123',
            descriptors: [degreeDescriptor],
            credentials: [buildTestVc(type: 'UniversityDegree')],
          );

          expect(result.id, matches(RegExp(r'^[0-9a-f\-]{36}$')));
        });

        test('should set definitionId correctly', () {
          final result = PresentationSubmissionBuilder.build(
            definitionId: 'pd_test_42',
            descriptors: [degreeDescriptor],
            credentials: [buildTestVc(type: 'UniversityDegree')],
          );

          expect(result.definitionId, equals('pd_test_42'));
        });

        test('should map the descriptor to \$.verifiableCredential[0]', () {
          final result = PresentationSubmissionBuilder.build(
            definitionId: 'pd_1',
            descriptors: [degreeDescriptor],
            credentials: [buildTestVc(type: 'UniversityDegree')],
          );

          expect(result.descriptorMap, hasLength(1));
          expect(result.descriptorMap.first.id, equals('desc_degree'));
          expect(result.descriptorMap.first.format, equals('ldp_vc'));
          expect(
            result.descriptorMap.first.path,
            equals(r'$.verifiableCredential[0]'),
          );
        });

        test('should produce a different id on each call', () {
          final a = PresentationSubmissionBuilder.build(
            definitionId: 'pd_1',
            descriptors: [degreeDescriptor],
            credentials: [buildTestVc(type: 'UniversityDegree')],
          );
          final b = PresentationSubmissionBuilder.build(
            definitionId: 'pd_1',
            descriptors: [degreeDescriptor],
            credentials: [buildTestVc(type: 'UniversityDegree')],
          );

          expect(a.id, isNot(equals(b.id)));
        });
      });

      group('and multiple descriptors match credentials in the same order', () {
        test('should assign matching verifiableCredential paths', () {
          final result = PresentationSubmissionBuilder.build(
            definitionId: 'pd_2',
            descriptors: [degreeDescriptor, employmentDescriptor],
            credentials: [
              buildTestVc(type: 'UniversityDegree'),
              buildTestVc(type: 'EmploymentCredential'),
            ],
          );

          expect(result.descriptorMap, hasLength(2));
          expect(result.descriptorMap[0].id, equals('desc_degree'));
          expect(
            result.descriptorMap[0].path,
            equals(r'$.verifiableCredential[0]'),
          );
          expect(result.descriptorMap[1].id, equals('desc_employment'));
          expect(
            result.descriptorMap[1].path,
            equals(r'$.verifiableCredential[1]'),
          );
        });
      });

      group(
        'and credentials are provided in a different order than descriptors',
        () {
          test(
            'should point each descriptor at the credential that satisfies it',
            () {
              // Descriptors are ordered degree-then-employment, but the caller
              // supplies the credentials in the reverse order. Each descriptor
              // must still reference the credential that actually satisfies it,
              // not the one that happens to share its positional index.
              final result = PresentationSubmissionBuilder.build(
                definitionId: 'pd_reordered',
                descriptors: [degreeDescriptor, employmentDescriptor],
                credentials: [
                  buildTestVc(type: 'EmploymentCredential'), // index 0
                  buildTestVc(type: 'UniversityDegree'), // index 1
                ],
              );

              expect(result.descriptorMap, hasLength(2));

              final degreeEntry = result.descriptorMap.firstWhere(
                (e) => e.id == 'desc_degree',
              );
              final employmentEntry = result.descriptorMap.firstWhere(
                (e) => e.id == 'desc_employment',
              );

              expect(degreeEntry.path, equals(r'$.verifiableCredential[1]'));
              expect(
                employmentEntry.path,
                equals(r'$.verifiableCredential[0]'),
              );
            },
          );
        },
      );

      group('and a descriptor has no matching credential', () {
        test('should omit that descriptor from the descriptor_map', () {
          final result = PresentationSubmissionBuilder.build(
            definitionId: 'pd_partial',
            descriptors: [degreeDescriptor, employmentDescriptor],
            credentials: [buildTestVc(type: 'UniversityDegree')],
          );

          expect(result.descriptorMap, hasLength(1));
          expect(result.descriptorMap.single.id, equals('desc_degree'));
          expect(
            result.descriptorMap.single.path,
            equals(r'$.verifiableCredential[0]'),
          );
        });
      });

      group('and two descriptors share the same constraints', () {
        test(
          'should greedily assign each descriptor a distinct credential',
          () {
            final emailA = PDDescriptor.fromJson(
              buildDescriptor(id: 'desc_email_a', type: 'EmailCredential'),
            );
            final emailB = PDDescriptor.fromJson(
              buildDescriptor(id: 'desc_email_b', type: 'EmailCredential'),
            );

            final result = PresentationSubmissionBuilder.build(
              definitionId: 'pd_two_emails',
              descriptors: [emailA, emailB],
              credentials: [
                buildTestVc(type: 'EmailCredential'), // index 0
                buildTestVc(type: 'EmailCredential'), // index 1
              ],
            );

            expect(result.descriptorMap, hasLength(2));
            final paths = result.descriptorMap.map((e) => e.path).toSet();
            expect(
              paths,
              equals({
                r'$.verifiableCredential[0]',
                r'$.verifiableCredential[1]',
              }),
            );
          },
        );
      });

      group('and one credential satisfies multiple descriptors', () {
        test('should reference that credential for each descriptor', () {
          final degreeA = PDDescriptor.fromJson(
            buildDescriptor(id: 'desc_degree_a', type: 'UniversityDegree'),
          );
          final degreeB = PDDescriptor.fromJson(
            buildDescriptor(id: 'desc_degree_b', type: 'UniversityDegree'),
          );

          final result = PresentationSubmissionBuilder.build(
            definitionId: 'pd_shared_vc',
            descriptors: [degreeA, degreeB],
            credentials: [buildTestVc(type: 'UniversityDegree')],
          );

          expect(result.descriptorMap, hasLength(2));
          expect(
            result.descriptorMap.map((e) => e.id),
            containsAll(<String>['desc_degree_a', 'desc_degree_b']),
          );
          for (final entry in result.descriptorMap) {
            expect(entry.path, equals(r'$.verifiableCredential[0]'));
          }
        });
      });

      group('and an empty descriptor list is provided', () {
        test('should produce an empty descriptorMap', () {
          final result = PresentationSubmissionBuilder.build(
            definitionId: 'pd_empty',
            descriptors: const [],
            credentials: [buildTestVc(type: 'UniversityDegree')],
          );

          expect(result.descriptorMap, isEmpty);
        });
      });

      group('and an empty credential list is provided', () {
        test('should produce an empty descriptorMap', () {
          final result = PresentationSubmissionBuilder.build(
            definitionId: 'pd_no_creds',
            descriptors: [degreeDescriptor],
            credentials: const <VerifiableCredential>[],
          );

          expect(result.descriptorMap, isEmpty);
        });
      });
    });

    group('when PresentationSubmission.toJson is called', () {
      test('should include id, definition_id, and descriptor_map keys', () {
        final result = PresentationSubmissionBuilder.build(
          definitionId: 'pd_json',
          descriptors: [degreeDescriptor],
          credentials: [buildTestVc(type: 'UniversityDegree')],
        );

        final json = result.toJson();

        expect(json['id'], isNotNull);
        expect(json['definition_id'], equals('pd_json'));
        expect(json['descriptor_map'], isA<List>());
      });
    });

    group('when DescriptorMapEntry.toJson is called', () {
      test('should include id, format, and path keys', () {
        const entry = DescriptorMapEntry(
          id: 'test_id',
          format: 'ldp_vc',
          path: r'$.verifiableCredential[0]',
        );

        expect(
          entry.toJson(),
          equals({
            'id': 'test_id',
            'format': 'ldp_vc',
            'path': r'$.verifiableCredential[0]',
          }),
        );
      });
    });
  });
}
