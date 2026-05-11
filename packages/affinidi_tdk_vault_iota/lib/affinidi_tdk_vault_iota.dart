/// This library provides OID4VP share flow support — parsing Iota request URIs,
/// classifying what a verifier is requesting, and resolving verifier identity.
library;

export 'package:affinidi_tdk_common/affinidi_tdk_common.dart' show TdkException;

export 'src/exceptions/tdk_exception_type.dart';
export 'src/extensions/submission_requirements_extensions.dart';
export 'src/models/pd_descriptor.dart';
export 'src/models/pd_requirements.dart';
export 'src/models/request_purpose.dart';
export 'src/models/submission_requirements.dart';
export 'src/models/verified_identity_document_info.dart';
export 'src/services/pd_classifier_service.dart';
