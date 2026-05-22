import 'package:affinidi_tdk_vault_edge_provider/affinidi_tdk_vault_edge_provider.dart';
import 'package:test/test.dart';

void main() {
  const profile = EdgeProfile(
    id: 'profile-id',
    accountIndex: 7,
    name: 'Original',
    description: 'Initial description',
  );

  group('EdgeProfile.copyWith', () {
    test('updates the name while preserving immutable fields', () {
      final updated = profile.copyWith(name: 'Updated');

      expect(updated.id, profile.id);
      expect(updated.accountIndex, profile.accountIndex);
      expect(updated.name, 'Updated');
      expect(updated.description, profile.description);
    });

    test('updates the description through the field helper', () {
      final updated = profile.copyWith.description('Updated description');

      expect(updated.id, profile.id);
      expect(updated.accountIndex, profile.accountIndex);
      expect(updated.description, 'Updated description');
      expect(updated.name, profile.name);
    });

    test('supports nulling description through copyWith', () {
      final updated = profile.copyWith(description: null);

      expect(updated.id, profile.id);
      expect(updated.accountIndex, profile.accountIndex);
      expect(updated.description, isNull);
      expect(updated.name, profile.name);
    });
  });

  group('EdgeProfile.copyWithNull', () {
    test('nulls only the requested nullable fields', () {
      final updated = profile.copyWithNull(description: true);

      expect(updated.id, profile.id);
      expect(updated.accountIndex, profile.accountIndex);
      expect(updated.name, profile.name);
      expect(updated.description, isNull);
    });

    test('leaves description unchanged when false', () {
      final updated = profile.copyWithNull();

      expect(updated.id, profile.id);
      expect(updated.accountIndex, profile.accountIndex);
      expect(updated.description, profile.description);
    });
  });
}
