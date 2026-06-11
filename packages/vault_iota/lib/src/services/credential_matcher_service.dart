import 'package:ssi/ssi.dart';

import '../models/matched_credentials_result.dart';
import '../models/share_requirements.dart';
import 'credential_matcher_service_interface.dart';
import 'dcql_share_requirements_matcher_service.dart';
import 'pd_classifier_service.dart';
import 'share_requirements_matcher_service.dart';

/// Routes credential matching to the correct PEX or DCQL implementation based
/// on the concrete type of [Oid4vpShareRequest].
///
/// Consumers always call the same [match] method regardless of which query
/// protocol the verifier used.
class CredentialMatcherService implements CredentialMatcherServiceInterface {
  final PDClassifier _pdClassifier;
  final ShareRequirementsMatcher _pexMatcher;
  final DcqlShareRequirementsMatcher _dcqlMatcher;

  /// Creates a [CredentialMatcherService].
  ///
  /// Parameters:
  /// * [pdClassifier] - optional PEX classifier; defaults to one with no
  ///   trusted IDV issuers.
  /// * [pexMatcher] - optional PEX matcher; defaults to one with no
  ///   revocation checking.
  /// * [dcqlMatcher] - optional DCQL matcher; defaults to one with no
  ///   revocation checking.
  CredentialMatcherService({
    PDClassifier? pdClassifier,
    ShareRequirementsMatcher? pexMatcher,
    DcqlShareRequirementsMatcher? dcqlMatcher,
  }) : _pdClassifier = pdClassifier ?? PDClassifier(validIdvIssuers: const []),
       _pexMatcher = pexMatcher ?? ShareRequirementsMatcher(),
       _dcqlMatcher = dcqlMatcher ?? DcqlShareRequirementsMatcher();

  @override
  Future<MatchedCredentialsResult> match(
    Oid4vpShareRequest shareRequest,
    List<VerifiableCredential> allVCs,
  ) async {
    switch (shareRequest) {
      case PexShareRequest pex:
        final requirements = _pdClassifier.classify(pex.presentationDefinition);
        return _pexMatcher.match(requirements, allVCs);
      case DcqlShareRequest dcql:
        return _dcqlMatcher.match(dcql.dcqlQuery, allVCs);
    }
  }
}
