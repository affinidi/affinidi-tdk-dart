import 'package:affinidi_tdk_vault_iota/affinidi_tdk_vault_iota.dart';
import 'package:test/test.dart';

void main() {
  final validJson = <String, dynamic>{
    'hash': 'abc123',
    'requestHash': 'req456',
    'sharedAt': '2024-01-01T00:00:00.000Z',
    'isAutoShareEnabled': false,
    'sharedVcIds': <String>[],
    'claimedVcTypesCsv': '',
  };

  group('IotaConsentRecord.fromJson', () {
    test('parses a valid JSON map correctly', () {
      final record = IotaConsentRecord.fromJson({
        ...validJson,
        'logo': 'https://example.com/logo.png',
        'siteUrl': 'https://example.com',
        'profileName': 'My Profile',
        'profileId': 'profile-1',
        'clientId': 'did:key:verifier',
        'isAutoShareEnabled': true,
        'sharedVcIds': ['vc-1', 'vc-2'],
        'claimedVcTypesCsv': 'EmailV1,PhoneV1',
        'historySharedData': {'Email': 'alice@example.com'},
        'isConsentManagementEnabled': true,
      });

      expect(record.hash, 'abc123');
      expect(record.requestHash, 'req456');
      expect(record.logo, 'https://example.com/logo.png');
      expect(record.siteUrl, 'https://example.com');
      expect(record.sharedAt, '2024-01-01T00:00:00.000Z');
      expect(record.profileName, 'My Profile');
      expect(record.profileId, 'profile-1');
      expect(record.clientId, 'did:key:verifier');
      expect(record.isAutoShareEnabled, isTrue);
      expect(record.sharedVcIds, ['vc-1', 'vc-2']);
      expect(record.claimedVcTypesCsv, 'EmailV1,PhoneV1');
      expect(record.historySharedData, {'Email': 'alice@example.com'});
      expect(record.isConsentManagementEnabled, isTrue);
    });

    test('applies defaults for optional fields', () {
      final record = IotaConsentRecord.fromJson(validJson);

      expect(record.logo, isNull);
      expect(record.siteUrl, isNull);
      expect(record.profileName, '');
      expect(record.profileId, '');
      expect(record.clientId, '');
      expect(record.historySharedData, isEmpty);
      expect(record.isConsentManagementEnabled, isFalse);
    });

    group('throws TdkException for missing required fields', () {
      test('when hash is null', () {
        expect(
          () => IotaConsentRecord.fromJson({...validJson, 'hash': null}),
          throwsA(
            isA<TdkException>().having(
              (e) => e.code,
              'code',
              TdkExceptionType.parseFailure.code,
            ),
          ),
        );
      });

      test('when hash is absent', () {
        final json = Map<String, dynamic>.from(validJson)..remove('hash');
        expect(
          () => IotaConsentRecord.fromJson(json),
          throwsA(
            isA<TdkException>().having(
              (e) => e.code,
              'code',
              TdkExceptionType.parseFailure.code,
            ),
          ),
        );
      });

      test('when hash is empty', () {
        expect(
          () => IotaConsentRecord.fromJson({...validJson, 'hash': ''}),
          throwsA(
            isA<TdkException>().having(
              (e) => e.code,
              'code',
              TdkExceptionType.parseFailure.code,
            ),
          ),
        );
      });

      test('when requestHash is null', () {
        expect(
          () => IotaConsentRecord.fromJson({...validJson, 'requestHash': null}),
          throwsA(
            isA<TdkException>().having(
              (e) => e.code,
              'code',
              TdkExceptionType.parseFailure.code,
            ),
          ),
        );
      });

      test('when requestHash is empty', () {
        expect(
          () => IotaConsentRecord.fromJson({...validJson, 'requestHash': ''}),
          throwsA(
            isA<TdkException>().having(
              (e) => e.code,
              'code',
              TdkExceptionType.parseFailure.code,
            ),
          ),
        );
      });

      test('when sharedAt is null', () {
        expect(
          () => IotaConsentRecord.fromJson({...validJson, 'sharedAt': null}),
          throwsA(
            isA<TdkException>().having(
              (e) => e.code,
              'code',
              TdkExceptionType.parseFailure.code,
            ),
          ),
        );
      });

      test('when sharedAt is empty', () {
        expect(
          () => IotaConsentRecord.fromJson({...validJson, 'sharedAt': ''}),
          throwsA(
            isA<TdkException>().having(
              (e) => e.code,
              'code',
              TdkExceptionType.parseFailure.code,
            ),
          ),
        );
      });

      test('when isAutoShareEnabled is null', () {
        expect(
          () => IotaConsentRecord.fromJson({
            ...validJson,
            'isAutoShareEnabled': null,
          }),
          throwsA(
            isA<TdkException>().having(
              (e) => e.code,
              'code',
              TdkExceptionType.parseFailure.code,
            ),
          ),
        );
      });
    });
  });
}
