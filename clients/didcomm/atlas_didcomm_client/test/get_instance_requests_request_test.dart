import 'package:affinidi_tdk_atlas_didcomm_client/affinidi_tdk_atlas_didcomm_client.dart';
import 'package:test/test.dart';

void main() {
  group('GetMediatorInstanceRequestsRequestOptions', () {
    test('should create request with no fields', () {
      final request = GetMediatorInstanceRequestsRequestOptions();

      expect(request.serviceType, 'mediator');
      expect(request.serviceId, isNull);
      expect(request.limit, isNull);
      expect(request.exclusiveStartKey, isNull);
    });

    test('should create request with all fields', () {
      final request = GetMediatorInstanceRequestsRequestOptions(
        serviceId: 'mediator-123',
        limit: 10,
        exclusiveStartKey: 'key-456',
      );

      expect(request.serviceType, 'mediator');
      expect(request.serviceId, 'mediator-123');
      expect(request.limit, 10);
      expect(request.exclusiveStartKey, 'key-456');
    });

    test('should serialize to JSON with all fields', () {
      final request = GetMediatorInstanceRequestsRequestOptions(
        serviceId: 'mediator-123',
        limit: 20,
        exclusiveStartKey: 'key-abc',
      );

      final json = request.toJson();

      expect(json['serviceType'], 'mediator');
      expect(json['serviceId'], 'mediator-123');
      expect(json['limit'], 20);
      expect(json['exclusiveStartKey'], 'key-abc');
    });

    test('should serialize to JSON with only serviceType', () {
      final request = GetMediatorInstanceRequestsRequestOptions();

      final json = request.toJson();

      expect(json['serviceType'], 'mediator');
      expect(json.containsKey('serviceId'), isFalse);
      expect(json.containsKey('limit'), isFalse);
      expect(json.containsKey('exclusiveStartKey'), isFalse);
    });

    test('should deserialize from JSON with all fields', () {
      final json = {
        'serviceType': 'mediator',
        'serviceId': 'mediator-123',
        'limit': 25,
        'exclusiveStartKey': 'key-def',
      };

      final request = GetMediatorInstanceRequestsRequestOptions.fromJson(json);

      expect(request.serviceType, 'mediator');
      expect(request.serviceId, 'mediator-123');
      expect(request.limit, 25);
      expect(request.exclusiveStartKey, 'key-def');
    });
  });

  group('GetMpxInstanceRequestsRequestOptions', () {
    test('should create request with no fields', () {
      final request = GetMpxInstanceRequestsRequestOptions();

      expect(request.serviceType, 'mpx');
      expect(request.serviceId, isNull);
      expect(request.limit, isNull);
      expect(request.exclusiveStartKey, isNull);
    });

    test('should create request with all fields', () {
      final request = GetMpxInstanceRequestsRequestOptions(
        serviceId: 'mpx-789',
        limit: 15,
        exclusiveStartKey: 'key-xyz',
      );

      expect(request.serviceType, 'mpx');
      expect(request.serviceId, 'mpx-789');
      expect(request.limit, 15);
      expect(request.exclusiveStartKey, 'key-xyz');
    });

    test('should serialize to JSON with all fields', () {
      final request = GetMpxInstanceRequestsRequestOptions(
        serviceId: 'mpx-789',
        limit: 30,
        exclusiveStartKey: 'key-ghi',
      );

      final json = request.toJson();

      expect(json['serviceType'], 'mpx');
      expect(json['serviceId'], 'mpx-789');
      expect(json['limit'], 30);
      expect(json['exclusiveStartKey'], 'key-ghi');
    });
  });

  group('GetTrInstanceRequestsRequestOptions', () {
    test('should create request with no fields', () {
      final request = GetTrInstanceRequestsRequestOptions();

      expect(request.serviceType, 'tr');
      expect(request.serviceId, isNull);
      expect(request.limit, isNull);
      expect(request.exclusiveStartKey, isNull);
    });

    test('should create request with all fields', () {
      final request = GetTrInstanceRequestsRequestOptions(
        serviceId: 'tr-456',
        limit: 5,
        exclusiveStartKey: 'key-jkl',
      );

      expect(request.serviceType, 'tr');
      expect(request.serviceId, 'tr-456');
      expect(request.limit, 5);
      expect(request.exclusiveStartKey, 'key-jkl');
    });

    test('should serialize to JSON with all fields', () {
      final request = GetTrInstanceRequestsRequestOptions(
        serviceId: 'tr-456',
        limit: 40,
        exclusiveStartKey: 'key-mno',
      );

      final json = request.toJson();

      expect(json['serviceType'], 'tr');
      expect(json['serviceId'], 'tr-456');
      expect(json['limit'], 40);
      expect(json['exclusiveStartKey'], 'key-mno');
    });
  });
}
