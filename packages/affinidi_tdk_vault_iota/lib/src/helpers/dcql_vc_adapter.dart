import 'package:affinidi_tdk_common/affinidi_tdk_common.dart' show Logger;
import 'package:dcql/dcql.dart'
    show
        DcqlCredential,
        DcqlCredentialQuery,
        DigitalCredential,
        W3CDigitalCredential;
import 'package:ssi/ssi.dart'
    show VerifiableCredential, dmV1ContextUrl, dmV2ContextUrl;

/// Bridges the `ssi` [VerifiableCredential] type to the `dcql` package's
/// [DigitalCredential] interface for DCQL credential query evaluation.
class DcqlVcAdapter {
  final Logger _logger;

  /// Creates a [DcqlVcAdapter].
  ///
  /// Parameters:
  /// * [logger] - optional logger; defaults to [Logger.instance].
  DcqlVcAdapter({Logger? logger}) : _logger = logger ?? Logger.instance;

  /// Wraps [vc] in the `dcql` package's [DigitalCredential] interface for
  /// query evaluation.
  ///
  /// Parameters:
  /// * [vc] - the credential to wrap.
  ///
  /// Returns `null` when [vc] uses an unsupported JSON-LD context or the
  /// conversion throws.
  DigitalCredential? toDigitalCredential(VerifiableCredential vc) {
    final contextUri = vc.context.firstUri?.toString();
    try {
      if (contextUri == dmV1ContextUrl) {
        return W3CDigitalCredential.fromLdVcDataModelV1(vc.toJson());
      }
      if (contextUri == dmV2ContextUrl) {
        return W3CDigitalCredential.fromLdVcDataModelV2(vc.toJson());
      }
      return null;
    } on Exception catch (e) {
      _logger.warning('Failed to wrap VC as DigitalCredential: $e');
      return null;
    }
  }

  /// Returns `true` if [vc] satisfies the given DCQL [credential] query.
  ///
  /// Parameters:
  /// * [credential] - a single DCQL credential query to evaluate.
  /// * [vc] - the candidate credential to test.
  bool vcMatchesDcqlCredential(
    DcqlCredential credential,
    VerifiableCredential vc,
  ) {
    final wrapped = toDigitalCredential(vc);
    if (wrapped == null) return false;
    final query = DcqlCredentialQuery(credentials: [credential]);
    final result = query.query([wrapped]);
    return result.verifiableCredentials[credential.id]?.isNotEmpty == true;
  }
}
