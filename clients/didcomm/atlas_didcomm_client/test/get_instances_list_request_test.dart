import 'package:affinidi_tdk_atlas_didcomm_client/affinidi_tdk_atlas_didcomm_client.dart';
import 'package:test/test.dart';

void main() {
  group('GetMediatorInstancesListRequestOptions', () {
    test('should create request with no fields', () {
      final request = GetMediatorInstancesListRequestOptions();

      expect(request.serviceType, 'mediator');
      expect(request.limit, isNull);
      expect(request.exclusiveStartKey, isNull);
    });

    test('should create request with limit', () {
      final request = GetMediatorInstancesListRequestOptions(limit: 10);

      expect(request.serviceType, 'mediator');
      expect(request.limit, 10);
      expect(request.exclusiveStartKey, isNull);
    });

    test('should create request with all parameters', () {
      final request = GetMediatorInstancesListRequestOptions(
        limit: 20,
        exclusiveStartKey: 'key-456',
      );

      expect(request.serviceType, 'mediator');
      expect(request.limit, 20);
      expect(request.exclusiveStartKey, 'key-456');
    });

    test('should serialize to JSON with all fields', () {
      final request = GetMediatorInstancesListRequestOptions(
        limit: 15,
        exclusiveStartKey: 'key-789',
      );

      final json = request.toJson();

      expect(json['serviceType'], 'mediator');
      expect(json['limit'], 15);
      expect(json['exclusiveStartKey'], 'key-789');
    });

    test('should serialize to JSON with only serviceType', () {
      final request = GetMediatorInstancesListRequestOptions();

      final json = request.toJson();

      expect(json['serviceType'], 'mediator');
      expect(json.containsKey('limit'), isFalse);
      expect(json.containsKey('exclusiveStartKey'), isFalse);
    });

    test('should deserialize from JSON with all fields', () {
      final json = {
        'serviceType': 'mediator',
        'limit': 25,
        'exclusiveStartKey': 'key-xyz',
      };

      final request = GetMediatorInstancesListRequestOptions.fromJson(json);

      expect(request.serviceType, 'mediator');
      expect(request.limit, 25);
      expect(request.exclusiveStartKey, 'key-xyz');
    });
  });

  group('GetMpxInstancesListRequestOptions', () {
    test('should create request with no fields', () {
      final request = GetMpxInstancesListRequestOptions();

      expect(request.serviceType, 'mpx');
      expect(request.limit, isNull);
      expect(request.exclusiveStartKey, isNull);
    });

    test('should create request with all parameters', () {
      final request = GetMpxInstancesListRequestOptions(
        limit: 30,
        exclusiveStartKey: 'mpx-key',
      );

      expect(request.serviceType, 'mpx');
      expect(request.limit, 30);
      expect(request.exclusiveStartKey, 'mpx-key');
    });

    test('should serialize to JSON with all fields', () {
      final request = GetMpxInstancesListRequestOptions(
        limit: 35,
        exclusiveStartKey: 'mpx-key-2',
      );

      final json = request.toJson();

      expect(json['serviceType'], 'mpx');
      expect(json['limit'], 35);
      expect(json['exclusiveStartKey'], 'mpx-key-2');
    });
  });

  group('GetTrInstancesListRequestOptions', () {
    test('should create request with no fields', () {
      final request = GetTrInstancesListRequestOptions();

      expect(request.serviceType, 'tr');
      expect(request.limit, isNull);
      expect(request.exclusiveStartKey, isNull);
    });

    test('should create request with all parameters', () {
      final request = GetTrInstancesListRequestOptions(
        limit: 40,
        exclusiveStartKey: 'tr-key',
      );

      expect(request.serviceType, 'tr');
      expect(request.limit, 40);
      expect(request.exclusiveStartKey, 'tr-key');
    });

    test('should serialize to JSON with all fields', () {
      final request = GetTrInstancesListRequestOptions(
        limit: 45,
        exclusiveStartKey: 'tr-key-2',
      );

      final json = request.toJson();

      expect(json['serviceType'], 'tr');
      expect(json['limit'], 45);
      expect(json['exclusiveStartKey'], 'tr-key-2');
    });
  });
}
