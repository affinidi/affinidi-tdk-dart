import 'package:ssi/ssi.dart' show ParsedVerifiableCredential;

import '../models/share_requirements.dart';

/// Defines the contract for building and submitting an OID4VP share response.
///
/// Works transparently for both PEX and DCQL share requests — the caller
/// never needs to know which query protocol the verifier used.
abstract interface class IotaShareResponseServiceInterface {
  /// Builds and submits a Verifiable Presentation to the verifier callback endpoint.
  ///
  /// Parameters:
  /// * [shareRequest] - the parsed OID4VP request returned by
  ///   `ShareFlowService.validateOid4vpRequest`.
  /// * [selectedCredentials] - the credentials to include in the VP.
  /// * [acceptResponseUri] - the URI from the OID4VP request JWT to POST the VP to.
  ///
  /// Returns the redirect [Uri] provided by the endpoint, or `null`.
  /// Throws `TdkException` with code `submission_failed` if the call fails.
  Future<Uri?> submitShareResponse({
    required Oid4vpShareRequest shareRequest,
    required List<ParsedVerifiableCredential<dynamic>> selectedCredentials,
    required String acceptResponseUri,
  });

  /// Sends a rejection to the verifier callback endpoint.
  ///
  /// Parameters:
  /// * [shareRequest] - the parsed OID4VP request to reject.
  /// * [rejectResponseUri] - the URI from the OID4VP request JWT to POST the rejection to.
  ///
  /// Returns the redirect [Uri] provided by the endpoint, or `null`.
  /// Throws `TdkException` with code `submission_failed` if the call fails.
  Future<Uri?> rejectShareResponse({
    required Oid4vpShareRequest shareRequest,
    required String rejectResponseUri,
  });
}
