import '../models/pd_requirements.dart';

/// Static mapping from zero-party VC type to the set of profile data paths
/// it covers.
///
/// Each HIT* and UserProfile VC type maps to the profile data paths it
/// provides. When an input descriptor requests one of these types, the paths
/// are added to [PDRequirements.dataPoints] and the type is added to
/// [PDRequirements.zeroPartyVCs].
abstract final class ZeroPartyVcDataPoints {
  // Profile path constants — resolved from
  // `packages/domain/lib/model/profile/profile.dart`
  static const _givenName = r'$.person.properties.givenName';
  static const _familyName = r'$.person.properties.familyName';
  static const _middleName = r'$.person.properties.middleName';
  static const _nickname = r'$.person.properties.nickname';
  static const _birthdate = r'$.person.properties.birthdate';
  static const _gender = r'$.person.properties.gender';
  static const _pictureUrl = r'$.person.properties.picture.properties.url';
  static const _phoneNumber = r'$.person.properties.phoneNumber';
  static const _email = r'$.person.properties.email';
  static const _streetAddress =
      r'$.person.properties.addresses.items[0].properties.streetAddress';
  static const _postalCode =
      r'$.person.properties.addresses.items[0].properties.postalCode';
  static const _addressLocality =
      r'$.person.properties.addresses.items[0].properties.addressLocality';
  static const _addressCountry =
      r'$.person.properties.addresses.items[0].properties.addressCountry';

  /// Maps a zero-party VC type to the profile paths it covers.
  static const Map<String, Set<String>> byType = {
    'UserProfile': {
      _givenName,
      _familyName,
      _middleName,
      _nickname,
      _birthdate,
      _gender,
      _pictureUrl,
      _phoneNumber,
      _streetAddress,
      _postalCode,
      _addressLocality,
      _addressCountry,
    },
    'HITGivenName': {_givenName},
    'HITFamilyName': {_familyName},
    'HITMiddleName': {_middleName},
    'HITNickname': {_nickname},
    'HITBirthdate': {_birthdate},
    'HITGender': {_gender},
    'HITPicture': {_pictureUrl},
    'HITPhoneNumber': {_phoneNumber},
    'HITStreetAddress': {_streetAddress},
    'HITPostalCode': {_postalCode},
    'HITLocality': {_addressLocality},
    'HITCountry': {_addressCountry},
    'HITFullName': {_givenName, _familyName, _middleName},
    'HITAddress': {
      _streetAddress,
      _postalCode,
      _addressLocality,
      _addressCountry,
    },
    'HITContacts': {_phoneNumber, _email},
    'HITIdentity': {_nickname, _gender, _birthdate},
  };
}
