import 'package:ssi/ssi.dart' show DidDocument;

/// Resolves a verifier DID to its [DidDocument].
///
/// Used by `IotaShareResponseService` to extract declared HTTPS
/// `serviceEndpoint` hosts for `response_uri` binding.
typedef DidDocumentResolver = Future<DidDocument> Function(String did);
