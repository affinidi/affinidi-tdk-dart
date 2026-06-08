import 'package:ssi/ssi.dart';

import '../models/matched_credentials_result.dart';
import '../models/share_requirements.dart';

/// Defines the contract for matching vault credentials against an OID4VP
/// share request — works transparently for both PEX and DCQL requests.
abstract interface class CredentialMatcherServiceInterface {
  /// Matches [allVCs] against the credential requirements described in
  /// [shareRequest] and returns a unified availability result.
  ///
  /// Parameters:
  /// * [shareRequest] - the parsed OID4VP request (PEX or DCQL).
  /// * [allVCs] - all credentials from the user's vault.
  ///
  /// Returns a [Future] containing a [MatchedCredentialsResult].
  Future<MatchedCredentialsResult> match(
    Oid4vpShareRequest shareRequest,
    List<VerifiableCredential> allVCs,
  );
}
