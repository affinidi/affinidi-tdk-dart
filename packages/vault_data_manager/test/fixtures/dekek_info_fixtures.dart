import 'dart:convert';
import 'dart:typed_data';

import 'package:affinidi_tdk_vault_data_manager/src/model/account.dart';

class DeekekInfoFixtures {
  static final general = DekekInfo(
    encryptedDekek: base64.encode(Uint8List.fromList([9, 8, 7])),
  );
}
