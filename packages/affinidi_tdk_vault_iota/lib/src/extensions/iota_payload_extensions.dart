import '../models/iota_payload.dart';
import '../models/iota_request.dart';
import '../models/request_purpose.dart';
import '../models/share_requirements.dart';

/// Extensions on [IotaPayload] that derive higher-level values.
extension IotaPayloadX on IotaPayload {
  /// Converts this payload into a normalised [IotaRequest].
  IotaRequest toRequest() => IotaRequest(
    responseType: responseType,
    responseMode: responseMode,
    acceptResponseUri: responseUri,
    rejectResponseUri: responseUri,
    scope: scope,
    state: state,
    nonce: nonce,
    clientId: clientId,
    clientMetadataUri: clientMetadataUri,
    clientMetadata: clientMetadata,
  );

  /// Extracts and validates the [RequestPurpose] from the presentation
  /// definition's `purpose` field.
  ///
  /// Returns `null` if [presentationDefinition] is absent, the `purpose` field
  /// is absent, or the parsed purpose is not valid.
  RequestPurpose? get purpose {
    final rawPurpose = presentationDefinition?['purpose'];
    if (rawPurpose == null) return null;
    final parsed = RequestPurpose.fromJson(rawPurpose);
    return parsed.isValid ? parsed : null;
  }

  /// Builds the appropriate [Oid4vpShareRequest] subtype from this payload.
  ///
  /// Parameters:
  /// * [jwtAssertion] - raw JWT string from the `request` query parameter.
  ///
  /// Returns a [PexShareRequest] if [presentationDefinition] is set, or a
  /// [DcqlShareRequest] if [dcqlQuery] is set.
  Oid4vpShareRequest toShareRequest({required String jwtAssertion}) {
    final pd = presentationDefinition;
    if (pd != null) {
      return PexShareRequest(
        request: toRequest(),
        jwtAssertion: jwtAssertion,
        presentationDefinition: pd,
        purpose: purpose,
      );
    }
    return DcqlShareRequest(
      request: toRequest(),
      jwtAssertion: jwtAssertion,
      dcqlQuery: dcqlQuery!,
    );
  }
}
