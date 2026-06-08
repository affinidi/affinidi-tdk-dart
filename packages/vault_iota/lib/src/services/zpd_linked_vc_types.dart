import '../models/pd_requirements.dart';

/// VC types that attest ZPD data and the profile data paths they cover.
abstract final class ZpdLinkedVcTypes {
  /// Maps a VC type to the profile data paths it attests.
  ///
  /// An input descriptor whose extracted type appears here is routed to
  /// [PDRequirements.zpdLinkedDescriptors] and the corresponding paths are
  /// added to [PDRequirements.dataPoints].
  static const Map<String, List<String>> byType = {
    'Email': [r'$.person.properties.email'],
    'PhoneNumber': [r'$.person.properties.phoneNumber'],
  };
}
