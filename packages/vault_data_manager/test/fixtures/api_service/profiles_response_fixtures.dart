import 'dart:convert';

class ProfilesResponseFixtures {
  static const String profileId = 'NzY3ZjYjV2dFR2U=';

  static final profileList = {
    'nodes': [
      {
        'id': profileId,
        'name': 'My profile',
        'description': 'Test profile',
        'accountIndex': 1,
        'profileMetadata': jsonEncode({'pictureURI': ''}),
        'accountMetadata': jsonEncode({
          'dekekInfo': {
            'encryptedDekek': base64.encode([1, 2, 3]),
          },
          'sharedStorageData': <Object?>[],
        }),
      },
    ],
  };

  static final emptyList = {'nodes': <Object?>[]};
}
