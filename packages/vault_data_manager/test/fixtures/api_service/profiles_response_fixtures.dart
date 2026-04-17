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
          'dekekInfo': {'encryptedDekek': 'dGVzdF9rZXk='},
          'sharedStorageData': <Object?>[],
        }),
      },
    ],
  };

  static final emptyList = {'nodes': <Object?>[]};
}
