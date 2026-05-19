import 'dart:convert';

import 'package:affinidi_tdk_vault_data_manager_client/affinidi_tdk_vault_data_manager_client.dart';
import 'package:built_collection/built_collection.dart';

import 'profile_fixtures.dart';

final partialProfileNodeDtoBuilder = PartialProfileNodeDtoBuilder()
  ..id = ProfileFixtures.testProfileId
  ..name = ProfileFixtures.testProfileName
  ..description = ProfileFixtures.testProfileDescription
  ..accountIndex = ProfileFixtures.testAccountIndex
  ..profileMetadata = jsonEncode({'pictureURI': ''})
  ..accountMetadata = jsonEncode(
    ProfileFixtures.testAccount.accountMetadata?.toJson(),
  );

final partialProfileNodeDto = partialProfileNodeDtoBuilder.build();

final listProfileOkBuilder = ListProfilesOKBuilder()
  ..nodes = ListBuilder([partialProfileNodeDto]);

final listProfileOk = listProfileOkBuilder.build();

final listProfilesOK = listProfileOk;
