import 'package:affinidi_tdk_atlas_didcomm_client/affinidi_tdk_atlas_didcomm_client.dart';
import 'package:test/test.dart';

void main() {
  const testServiceId = 'test-service-id';

  group('UpdateMediatorInstanceDeploymentOptions', () {
    test('should create options with only required serviceId', () {
      final options = const UpdateMediatorInstanceDeploymentOptions(
        serviceId: testServiceId,
      );

      expect(options.serviceId, testServiceId);
      expect(options.serviceSize, isNull);
      expect(options.mediatorAclMode, isNull);
      expect(options.name, isNull);
      expect(options.description, isNull);
    });

    test('should create options with only serviceSize', () {
      final options = const UpdateMediatorInstanceDeploymentOptions(
        serviceId: testServiceId,
        serviceSize: ServiceSize.medium,
      );

      expect(options.serviceId, testServiceId);
      expect(options.serviceSize, ServiceSize.medium);
      expect(options.mediatorAclMode, isNull);
      expect(options.name, isNull);
      expect(options.description, isNull);
    });

    test('should create options with only mediatorAclMode', () {
      final options = const UpdateMediatorInstanceDeploymentOptions(
        serviceId: testServiceId,
        mediatorAclMode: MediatorAclMode.explicitAllow,
      );

      expect(options.serviceId, testServiceId);
      expect(options.serviceSize, isNull);
      expect(options.mediatorAclMode, MediatorAclMode.explicitAllow);
      expect(options.name, isNull);
      expect(options.description, isNull);
    });

    test('should create options with all fields', () {
      final options = const UpdateMediatorInstanceDeploymentOptions(
        serviceId: testServiceId,
        serviceSize: ServiceSize.large,
        mediatorAclMode: MediatorAclMode.explicitDeny,
        name: 'Updated Mediator',
        description: 'Updated description',
      );

      expect(options.serviceId, testServiceId);
      expect(options.serviceSize, ServiceSize.large);
      expect(options.mediatorAclMode, MediatorAclMode.explicitDeny);
      expect(options.name, 'Updated Mediator');
      expect(options.description, 'Updated description');
    });

    test('should serialize to JSON with only non-null fields', () {
      final options = const UpdateMediatorInstanceDeploymentOptions(
        serviceId: testServiceId,
        serviceSize: ServiceSize.small,
        name: 'Updated Name',
      );

      final json = options.toJson();

      expect(json['serviceId'], testServiceId);
      expect(json['serviceSize'], 'small');
      expect(json['name'], 'Updated Name');
      expect(json.containsKey('mediatorAclMode'), isFalse);
      expect(json.containsKey('description'), isFalse);
    });

    test('should serialize to JSON with all fields', () {
      final options = const UpdateMediatorInstanceDeploymentOptions(
        serviceId: testServiceId,
        serviceSize: ServiceSize.tiny,
        mediatorAclMode: MediatorAclMode.explicitAllow,
        name: 'Test',
        description: 'Description',
      );

      final json = options.toJson();

      expect(json['serviceId'], testServiceId);
      expect(json['serviceSize'], 'tiny');
      expect(json['mediatorAclMode'], 'explicit_allow');
      expect(json['name'], 'Test');
      expect(json['description'], 'Description');
    });

    test('should deserialize from JSON correctly', () {
      final json = {
        'serviceId': testServiceId,
        'serviceSize': 'medium',
        'mediatorAclMode': 'explicit_deny',
        'name': 'Test Mediator',
        'description': 'Test description',
      };

      final options = UpdateMediatorInstanceDeploymentOptions.fromJson(json);

      expect(options.serviceId, testServiceId);
      expect(options.serviceSize, ServiceSize.medium);
      expect(options.mediatorAclMode, MediatorAclMode.explicitDeny);
      expect(options.name, 'Test Mediator');
      expect(options.description, 'Test description');
    });

    test('should handle partial updates - only serviceSize', () {
      final json = {'serviceId': testServiceId, 'serviceSize': 'large'};

      final options = UpdateMediatorInstanceDeploymentOptions.fromJson(json);

      expect(options.serviceId, testServiceId);
      expect(options.serviceSize, ServiceSize.large);
      expect(options.mediatorAclMode, isNull);
      expect(options.name, isNull);
      expect(options.description, isNull);
    });

    test('should round-trip through JSON', () {
      final original = const UpdateMediatorInstanceDeploymentOptions(
        serviceId: testServiceId,
        serviceSize: ServiceSize.dev,
        mediatorAclMode: MediatorAclMode.explicitAllow,
        name: 'Round-trip test',
        description: 'Round-trip description',
      );

      final json = original.toJson();
      final deserialized = UpdateMediatorInstanceDeploymentOptions.fromJson(
        json,
      );

      expect(deserialized.serviceId, original.serviceId);
      expect(deserialized.serviceSize, original.serviceSize);
      expect(deserialized.mediatorAclMode, original.mediatorAclMode);
      expect(deserialized.name, original.name);
      expect(deserialized.description, original.description);
    });

    test('should support partial updates scenario', () {
      // Simulate updating only name and description, keeping size and ACL mode unchanged
      final updateOptions = const UpdateMediatorInstanceDeploymentOptions(
        serviceId: testServiceId,
        name: 'New Name',
        description: 'New Description',
      );

      final json = updateOptions.toJson();

      expect(json['serviceId'], testServiceId);
      expect(json['name'], 'New Name');
      expect(json['description'], 'New Description');
      expect(json.containsKey('serviceSize'), isFalse);
      expect(json.containsKey('mediatorAclMode'), isFalse);
    });
  });
}
