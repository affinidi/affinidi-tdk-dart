import 'package:affinidi_tdk_atlas_didcomm_client/affinidi_tdk_atlas_didcomm_client.dart';
import 'package:test/test.dart';

void main() {
  const testServiceId = 'test-service-id';

  group('UpdateMpxInstanceDeploymentOptions', () {
    test('should create options with only required serviceId', () {
      final options = const UpdateMpxInstanceDeploymentOptions(
        serviceId: testServiceId,
      );

      expect(options.serviceId, testServiceId);
      expect(options.serviceSize, isNull);
      expect(options.name, isNull);
      expect(options.description, isNull);
    });

    test('should create options with only serviceSize', () {
      final options = const UpdateMpxInstanceDeploymentOptions(
        serviceId: testServiceId,
        serviceSize: ServiceSize.medium,
      );

      expect(options.serviceId, testServiceId);
      expect(options.serviceSize, ServiceSize.medium);
      expect(options.name, isNull);
      expect(options.description, isNull);
    });

    test('should create options with all fields', () {
      final options = const UpdateMpxInstanceDeploymentOptions(
        serviceId: testServiceId,
        serviceSize: ServiceSize.large,
        name: 'Updated MPX',
        description: 'Updated MPX description',
      );

      expect(options.serviceId, testServiceId);
      expect(options.serviceSize, ServiceSize.large);
      expect(options.name, 'Updated MPX');
      expect(options.description, 'Updated MPX description');
    });

    test('should serialize to JSON with only non-null fields', () {
      final options = const UpdateMpxInstanceDeploymentOptions(
        serviceId: testServiceId,
        name: 'Updated Name',
      );

      final json = options.toJson();

      expect(json['serviceId'], testServiceId);
      expect(json['name'], 'Updated Name');
      expect(json.containsKey('serviceSize'), isFalse);
      expect(json.containsKey('description'), isFalse);
    });

    test('should serialize to JSON with all fields', () {
      final options = const UpdateMpxInstanceDeploymentOptions(
        serviceId: testServiceId,
        serviceSize: ServiceSize.small,
        name: 'Test MPX',
        description: 'Test description',
      );

      final json = options.toJson();

      expect(json['serviceId'], testServiceId);
      expect(json['serviceSize'], 'small');
      expect(json['name'], 'Test MPX');
      expect(json['description'], 'Test description');
    });

    test('should deserialize from JSON correctly', () {
      final json = {
        'serviceId': testServiceId,
        'serviceSize': 'tiny',
        'name': 'Test MPX',
        'description': 'Test description',
      };

      final options = UpdateMpxInstanceDeploymentOptions.fromJson(json);

      expect(options.serviceId, testServiceId);
      expect(options.serviceSize, ServiceSize.tiny);
      expect(options.name, 'Test MPX');
      expect(options.description, 'Test description');
    });

    test('should handle partial updates - only description', () {
      final json = {
        'serviceId': testServiceId,
        'description': 'New description only',
      };

      final options = UpdateMpxInstanceDeploymentOptions.fromJson(json);

      expect(options.serviceId, testServiceId);
      expect(options.serviceSize, isNull);
      expect(options.name, isNull);
      expect(options.description, 'New description only');
    });

    test('should round-trip through JSON', () {
      final original = const UpdateMpxInstanceDeploymentOptions(
        serviceId: testServiceId,
        serviceSize: ServiceSize.dev,
        name: 'Round-trip MPX',
        description: 'Round-trip description',
      );

      final json = original.toJson();
      final deserialized = UpdateMpxInstanceDeploymentOptions.fromJson(json);

      expect(deserialized.serviceId, original.serviceId);
      expect(deserialized.serviceSize, original.serviceSize);
      expect(deserialized.name, original.name);
      expect(deserialized.description, original.description);
    });

    test('should support partial updates scenario - size only', () {
      final updateOptions = const UpdateMpxInstanceDeploymentOptions(
        serviceId: testServiceId,
        serviceSize: ServiceSize.large,
      );

      final json = updateOptions.toJson();

      expect(json['serviceId'], testServiceId);
      expect(json['serviceSize'], 'large');
      expect(json.containsKey('name'), isFalse);
      expect(json.containsKey('description'), isFalse);
    });

    test('should support updating name and description together', () {
      final updateOptions = const UpdateMpxInstanceDeploymentOptions(
        serviceId: testServiceId,
        name: 'New MPX Name',
        description: 'New MPX Description',
      );

      final json = updateOptions.toJson();

      expect(json['serviceId'], testServiceId);
      expect(json['name'], 'New MPX Name');
      expect(json['description'], 'New MPX Description');
      expect(json.containsKey('serviceSize'), isFalse);
    });
  });
}
