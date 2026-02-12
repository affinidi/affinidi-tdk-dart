import 'package:affinidi_tdk_atlas_didcomm_client/affinidi_tdk_atlas_didcomm_client.dart';
import 'package:test/test.dart';

void main() {
  group('DestroyInstanceRequest', () {
    test('should create request with serviceId', () {
      final request = DestroyInstanceRequestMessage.mediator(
        id: 'test-id',
        to: ['did:example:alice'],
        options: DestroyMediatorInstanceOptions(serviceId: 'mediator-123'),
      );

      expect(request.body!['serviceId'], 'mediator-123');
    });

    test('should serialize to JSON with correct field name for mediator', () {
      final request = DestroyInstanceRequestMessage.mediator(
        id: 'test-id',
        to: ['did:example:alice'],
        options: DestroyMediatorInstanceOptions(serviceId: 'mediator-123'),
      );

      expect(request.body!['serviceId'], 'mediator-123');
    });

    test('should include serviceId in body', () {
      final request = DestroyInstanceRequestMessage.mediator(
        id: 'test-id',
        to: ['did:example:alice'],
        options: DestroyMediatorInstanceOptions(serviceId: 'mediator-123'),
      );

      expect(request.body!['serviceId'], 'mediator-123');
    });

    test('should create MPX destroy request with serviceId', () {
      final request = DestroyInstanceRequestMessage.meetingPlace(
        id: 'test-id',
        to: ['did:example:alice'],
        options: DestroyMpxInstanceOptions(serviceId: 'mpx-123'),
      );

      expect(request.body!['serviceId'], 'mpx-123');
    });

    test('should create TR destroy request with serviceId', () {
      final request = DestroyInstanceRequestMessage.trustRegistry(
        id: 'test-id',
        to: ['did:example:alice'],
        options: DestroyTrInstanceOptions(serviceId: 'tr-123'),
      );

      expect(request.body!['serviceId'], 'tr-123');
    });
  });
}
