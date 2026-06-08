/// This library provides OID4VP share flow support — parsing Iota request URIs,
/// classifying what a verifier is requesting, and resolving verifier identity.
library;

export 'package:affinidi_tdk_common/affinidi_tdk_common.dart' show TdkException;

export 'src/exceptions/tdk_exception_type.dart';
export 'src/models/auto_consent_result.dart';
export 'src/models/claimed_credentials_result.dart';
export 'src/models/iota_consent_record.dart';
export 'src/models/iota_request.dart';
export 'src/models/matched_credential_group.dart';
export 'src/models/matched_credentials_result.dart';
export 'src/models/pd_descriptor.dart';
export 'src/models/pd_requirements.dart';
export 'src/models/presentation_submission.dart';
export 'src/models/request_purpose.dart';
export 'src/models/share_requirements.dart' show Oid4vpShareRequest;
export 'src/models/submission_requirements.dart';
export 'src/models/vc_availability.dart';
export 'src/models/vc_unavailability_reason.dart';
export 'src/models/vcs_group_by_type.dart';
export 'src/models/verified_identity_document_info.dart';
export 'src/models/verifier_client_metadata.dart';
export 'src/models/vp_data_model.dart';
export 'src/services/consent_storage.dart';
export 'src/services/credential_matcher_service.dart';
export 'src/services/credential_matcher_service_interface.dart';
export 'src/services/iota_consent_record_service.dart';
export 'src/services/iota_consent_record_service_interface.dart';
export 'src/services/iota_share_response_service.dart';
export 'src/services/iota_share_response_service_interface.dart';
export 'src/services/pd_classifier_service.dart';
export 'src/services/presentation_submission_builder.dart';
export 'src/services/share_requirements_matcher_service.dart';
export 'src/services/verifier_metadata_service.dart';
export 'src/services/verifier_metadata_service_interface.dart';
export 'src/services/vp_builder.dart';
export 'src/share_flow_service.dart';
export 'src/share_flow_service_interface.dart';
