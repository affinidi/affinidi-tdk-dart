import 'package:affinidi_tdk_vault_iota/affinidi_tdk_vault_iota.dart';
import 'package:test/test.dart';

void main() {
  group('PresentationSubmissionBuilder', () {
    final descriptorA = PDDescriptor.fromJson({'id': 'desc_a', 'name': 'A'});
    final descriptorB = PDDescriptor.fromJson({'id': 'desc_b', 'name': 'B'});

    group('when build is called', () {
      group('and a single descriptor is provided', () {
        test('should produce a valid UUID id', () {
          final result = PresentationSubmissionBuilder.build(
            definitionId: 'pd_123',
            descriptors: [descriptorA],
          );

          expect(result.id, matches(RegExp(r'^[0-9a-f\-]{36}$')));
        });

        test('should set definitionId correctly', () {
          final result = PresentationSubmissionBuilder.build(
            definitionId: 'pd_test_42',
            descriptors: [descriptorA],
          );

          expect(result.definitionId, equals('pd_test_42'));
        });

        test('should map the descriptor to \$.verifiableCredential[0]', () {
          final result = PresentationSubmissionBuilder.build(
            definitionId: 'pd_1',
            descriptors: [descriptorA],
          );

          expect(result.descriptorMap, hasLength(1));
          expect(result.descriptorMap.first.id, equals('desc_a'));
          expect(result.descriptorMap.first.format, equals('ldp_vc'));
          expect(
            result.descriptorMap.first.path,
            equals(r'$.verifiableCredential[0]'),
          );
        });

        test('should produce a different id on each call', () {
          final a = PresentationSubmissionBuilder.build(
            definitionId: 'pd_1',
            descriptors: [descriptorA],
          );
          final b = PresentationSubmissionBuilder.build(
            definitionId: 'pd_1',
            descriptors: [descriptorA],
          );

          expect(a.id, isNot(equals(b.id)));
        });
      });

      group('and multiple descriptors are provided', () {
        test('should assign sequential verifiableCredential paths', () {
          final result = PresentationSubmissionBuilder.build(
            definitionId: 'pd_2',
            descriptors: [descriptorA, descriptorB],
          );

          expect(result.descriptorMap, hasLength(2));
          expect(
            result.descriptorMap[0].path,
            equals(r'$.verifiableCredential[0]'),
          );
          expect(
            result.descriptorMap[1].path,
            equals(r'$.verifiableCredential[1]'),
          );
          expect(result.descriptorMap[0].id, equals('desc_a'));
          expect(result.descriptorMap[1].id, equals('desc_b'));
        });
      });

      group('and an empty descriptor list is provided', () {
        test('should produce an empty descriptorMap', () {
          final result = PresentationSubmissionBuilder.build(
            definitionId: 'pd_empty',
            descriptors: [],
          );

          expect(result.descriptorMap, isEmpty);
        });
      });
    });

    group('when PresentationSubmission.toJson is called', () {
      test('should include id, definition_id, and descriptor_map keys', () {
        final result = PresentationSubmissionBuilder.build(
          definitionId: 'pd_json',
          descriptors: [descriptorA],
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
