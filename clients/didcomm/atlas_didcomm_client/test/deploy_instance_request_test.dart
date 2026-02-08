import 'package:affinidi_tdk_atlas_didcomm_client/affinidi_tdk_atlas_didcomm_client.dart';
import 'package:test/test.dart';

void main() {
  group('DeployMediatorInstanceOptions', () {
    test('should create options with required fields only', () {
      const options = DeployMediatorInstanceOptions(
        serviceSize: ServiceSize.small,
        mediatorAclMode: MediatorAclMode.explicitDeny,
      );

      expect(options.serviceSize, ServiceSize.small);
      expect(options.mediatorAclMode, MediatorAclMode.explicitDeny);
      expect(options.administratorDids, isNull);
      expect(options.name, isNull);
      expect(options.description, isNull);
    });

    test('should create options with all fields', () {
      const options = DeployMediatorInstanceOptions(
        serviceSize: ServiceSize.medium,
        mediatorAclMode: MediatorAclMode.explicitAllow,
        administratorDids: 'did:example:admin',
        name: 'Test Instance',
        description: 'Test description',
      );

      expect(options.serviceSize, ServiceSize.medium);
      expect(options.mediatorAclMode, MediatorAclMode.explicitAllow);
      expect(options.administratorDids, 'did:example:admin');
      expect(options.name, 'Test Instance');
      expect(options.description, 'Test description');
    });

    test('should serialize to JSON with all fields', () {
      const options = DeployMediatorInstanceOptions(
        serviceSize: ServiceSize.large,
        mediatorAclMode: MediatorAclMode.explicitDeny,
        administratorDids: 'did:example:admin',
        name: 'Test Instance',
        description: 'Test description',
      );

      final json = options.toJson();

      expect(json['serviceSize'], 'large');
      expect(json['mediatorAclMode'], 'explicit_deny');
      expect(json['administratorDids'], 'did:example:admin');
      expect(json['name'], 'Test Instance');
      expect(json['description'], 'Test description');
    });

    test('should serialize to JSON without null fields', () {
      const options = DeployMediatorInstanceOptions(
        serviceSize: ServiceSize.tiny,
        mediatorAclMode: MediatorAclMode.explicitAllow,
      );

      final json = options.toJson();

      expect(json['serviceSize'], 'tiny');
      expect(json['mediatorAclMode'], 'explicit_allow');
      expect(json.containsKey('administratorDids'), isFalse);
      expect(json.containsKey('name'), isFalse);
      expect(json.containsKey('description'), isFalse);
    });

    test('should deserialize from JSON with all fields', () {
      final json = {
        'serviceSize': 'medium',
        'mediatorAclMode': 'explicit_deny',
        'administratorDids': 'did:example:admin',
        'name': 'Test Instance',
        'description': 'Test description',
      };

      final options = DeployMediatorInstanceOptions.fromJson(json);

      expect(options.serviceSize, ServiceSize.medium);
      expect(options.mediatorAclMode, MediatorAclMode.explicitDeny);
      expect(options.administratorDids, 'did:example:admin');
      expect(options.name, 'Test Instance');
      expect(options.description, 'Test description');
    });

    test('should deserialize from JSON with only required fields', () {
      final json = {
        'serviceSize': 'small',
        'mediatorAclMode': 'explicit_allow',
      };

      final options = DeployMediatorInstanceOptions.fromJson(json);

      expect(options.serviceSize, ServiceSize.small);
      expect(options.mediatorAclMode, MediatorAclMode.explicitAllow);
      expect(options.administratorDids, isNull);
      expect(options.name, isNull);
      expect(options.description, isNull);
    });

    test('should handle extra fields in JSON', () {
      final json = {
        'serviceSize': 'tiny',
        'mediatorAclMode': 'explicit_deny',
        'extraField': 'should be ignored',
      };

      final options = DeployMediatorInstanceOptions.fromJson(json);

      expect(options.serviceSize, ServiceSize.tiny);
      expect(options.mediatorAclMode, MediatorAclMode.explicitDeny);
    });
  });

  group('DeployInstanceRequestMessage', () {
    test('should create mediator message with options in body', () {
      final message = DeployInstanceRequestMessage.mediator(
        id: 'test-id',
        to: ['did:example:alice'],
        options: const DeployMediatorInstanceOptions(
          serviceSize: ServiceSize.small,
          mediatorAclMode: MediatorAclMode.explicitDeny,
          administratorDids: 'did:example:admin',
          name: 'Test Instance',
          description: 'Test description',
        ),
      );

      expect(message.body!['serviceSize'], 'small');
      expect(message.body!['mediatorAclMode'], 'explicit_deny');
      expect(message.body!['administratorDids'], 'did:example:admin');
      expect(message.body!['name'], 'Test Instance');
      expect(message.body!['description'], 'Test description');
    });

    test('should create meeting place message with options in body', () {
      final message = DeployInstanceRequestMessage.meetingPlace(
        id: 'test-id',
        to: ['did:example:alice'],
        options: const DeployMpxInstanceOptions(
          serviceSize: ServiceSize.medium,
          name: 'MPX Instance',
          description: 'Meeting place description',
        ),
      );

      expect(message.body!['serviceSize'], 'medium');
      expect(message.body!['name'], 'MPX Instance');
      expect(message.body!['description'], 'Meeting place description');
    });

    test('should create trust registry message with options in body', () {
      final message = DeployInstanceRequestMessage.trustRegistry(
        id: 'test-id',
        to: ['did:example:alice'],
        options: const DeployTrInstanceOptions(
          serviceSize: ServiceSize.large,
          defaultMediatorDid: 'did:example:mediator',
          administratorDids: 'did:example:admin',
          corsAllowedOrigins: 'https://example.com',
          name: 'TR Instance',
          description: 'Trust registry description',
        ),
      );

      expect(message.body!['serviceSize'], 'large');
      expect(message.body!['defaultMediatorDid'], 'did:example:mediator');
      expect(message.body!['administratorDids'], 'did:example:admin');
      expect(message.body!['corsAllowedOrigins'], 'https://example.com');
      expect(message.body!['name'], 'TR Instance');
      expect(message.body!['description'], 'Trust registry description');
    });
  });
}
