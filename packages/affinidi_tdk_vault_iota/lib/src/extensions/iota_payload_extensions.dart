import '../models/iota_payload.dart';
import '../models/iota_request.dart';
import '../models/request_purpose.dart';

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
    clientMetadata: clientMetadata,
  );

  /// Extracts and validates the [RequestPurpose] from the presentation
  /// definition's `purpose` field.
  ///
  /// Returns `null` if the field is absent or does not contain a valid
  /// [RequestPurpose.dataCollectionPurpose].
  RequestPurpose? get purpose {
    final rawPurpose = presentationDefinition['purpose'];
    if (rawPurpose == null) return null;
    final parsed = RequestPurpose.fromJson(rawPurpose);
    return parsed.isValid ? parsed : null;
  }
}
