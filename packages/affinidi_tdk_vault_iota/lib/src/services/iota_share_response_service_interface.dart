import 'package:ssi/ssi.dart' show ParsedVerifiableCredential;

import '../models/pd_descriptor.dart';

/// Defines the contract for building and submitting an OID4VP share response.
abstract interface class IotaShareResponseServiceInterface {
  /// The DID of the holder whose key is used to sign Verifiable Presentations.
  String get holderDid;

  /// Builds and submits a Verifiable Presentation to the Iota callback endpoint.
  ///
  /// Parameters:
  /// * [state] - The `state` value from the OID4VP authorization request.
  /// * [nonce] - The `nonce` from the request JWT; used as the VP proof challenge.
  /// * [clientId] - The `client_id` from the request JWT; used as the VP proof domain.
  /// * [definitionId] - The ID of the Presentation Definition being satisfied.
  /// * [selectedCredentials] - Ordered list of `(descriptor, credential)` pairs.
  ///   Position `i` maps descriptor `i` to `$.verifiableCredential[i]` in the VP.
  ///
  /// Returns the redirect [Uri] provided by the endpoint, or `null`.
  /// Throws `TdkException` with code `submission_failed` if the API call fails.
  Future<Uri?> submitShareResponse({
    required String state,
    required String nonce,
    required String clientId,
    required String definitionId,
    required List<
      ({
        PDDescriptor descriptor,
        ParsedVerifiableCredential<dynamic> credential,
      })
    >
    selectedCredentials,
  });

  /// Sends a rejection to the Iota callback endpoint.
  ///
  /// Parameters:
  /// * [state] - The `state` value from the OID4VP authorization request.
  ///
  /// Returns the redirect [Uri] provided by the endpoint, or `null`.
  /// Throws `TdkException` with code `submission_failed` if the API call fails.
  Future<Uri?> rejectShareResponse({required String state});
}
