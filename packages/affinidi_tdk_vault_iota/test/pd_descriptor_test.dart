import 'package:affinidi_tdk_vault_iota/affinidi_tdk_vault_iota.dart';
import 'package:test/test.dart';

void main() {
  group('PDDescriptor.groupName', () {
    test('returns the value when group is a non-empty string', () {
      final descriptor = PDDescriptor.fromJson({'id': 'd1', 'group': 'A'});
      expect(descriptor.groupName, equals('A'));
    });

    test('returns null when group is an empty string', () {
      final descriptor = PDDescriptor.fromJson({'id': 'd1', 'group': ''});
      expect(descriptor.groupName, isNull);
    });

    test('returns the first value when group is a non-empty list', () {
      final descriptor = PDDescriptor.fromJson({
        'id': 'd1',
        'group': ['A', 'B'],
      });
      expect(descriptor.groupName, equals('A'));
    });

    test('returns null when group is a list whose first element is empty', () {
      final descriptor = PDDescriptor.fromJson({
        'id': 'd1',
        'group': ['', 'B'],
      });
      expect(descriptor.groupName, isNull);
    });

    test('returns null when group is an empty list', () {
      final descriptor = PDDescriptor.fromJson({'id': 'd1', 'group': []});
      expect(descriptor.groupName, isNull);
    });

    test('returns null when group is absent', () {
      final descriptor = PDDescriptor.fromJson({'id': 'd1'});
      expect(descriptor.groupName, isNull);
    });
  });
}
