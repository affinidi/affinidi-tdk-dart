import '../models/iota_request.dart';

/// A consumer-provided policy hook that decides whether the TDK is allowed to
/// POST credentials to a response URI that cannot be verified from the verifier
/// DID document alone (e.g. `did:key` verifiers that declare no HTTPS service
/// endpoint).
///
/// The TDK calls this after all built-in checks (HTTPS-only, no userinfo, no
/// fragment) have passed but the callback host is not declared in the verifier
/// DID's `serviceEndpoint` list.
///
/// Parameters:
/// * [request] - the full parsed OID4VP authorisation request, including
///   `clientId`, `state`, `nonce`, and `acceptResponseUri`. Use this to
///   look up the verifier in a trusted registry.
/// * [uri] - the fully parsed callback [Uri] that the TDK is about to POST to.
///   Inspect `uri.host` to match against your trusted verifier allowlist.
/// * [parameterName] - which URI parameter is being validated: `'response_uri'`
///   (the outgoing VP callback) or `'redirect_uri'` (the page the app is
///   redirected to after submission). Distinguish these if your policy treats
///   them differently.
///
/// Returns `true` to allow the POST, `false` to block it.
///
/// **Security note:** never return `true` based solely on values from the
/// OID4VP request itself — a malicious verifier controls those values. Always
/// verify against an external, app-controlled trust source such as a
/// backend-managed verifier registry, tenant configuration, or a hardcoded
/// allowlist.
typedef ResponseUriTrustValidator =
    Future<bool> Function({
      required IotaRequest request,
      required Uri uri,
      required String parameterName,
    });
