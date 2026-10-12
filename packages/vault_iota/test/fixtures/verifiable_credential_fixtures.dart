// ignore_for_file: inference_failure_on_collection_literal

import 'dart:convert';

import 'package:ssi/ssi.dart';

/// Builds a [VerifiableCredential] for use in unit tests.
///
/// [type] — the specific VC type (e.g. `'UniversityDegree'`); always combined
/// with `'VerifiableCredential'`.
/// [validUntil] — ISO-8601 string for the expiry date; omit for no expiry.
/// [validFrom] — ISO-8601 string for the issuance date; defaults to
/// `'2024-01-01T00:00:00Z'`.
/// [issuer] — the issuer DID; defaults to `'did:key:z6MkTestIssuer'`.
/// [issuerAsObject] — when `true`, emits the W3C VCDM object form
/// `"issuer": {"id": "<issuer>"}` (as produced by credentials signed with the
/// Dart `ssi` library) instead of the plain string form. Defaults to `false`.
/// The proof's `verificationMethod` always uses the DID string.
VerifiableCredential buildTestVc({
  required String type,
  String? validUntil,
  String validFrom = '2024-01-01T00:00:00Z',
  String issuer = 'did:key:z6MkTestIssuer',
  bool issuerAsObject = false,
}) {
  return UniversalParser.parse(
    jsonEncode({
      '@context': ['https://www.w3.org/2018/credentials/v1'],
      'id': 'urn:test:vc:$type',
      'type': ['VerifiableCredential', type],
      'issuer': issuerAsObject ? {'id': issuer} : issuer,
      'issuanceDate': validFrom,
      if (validUntil != null) 'expirationDate': validUntil,
      'credentialSubject': {'id': 'did:key:z6MkSubject'},
      'proof': {
        'type': 'DataIntegrityProof',
        'created': validFrom,
        'proofPurpose': 'assertionMethod',
        'verificationMethod': '$issuer#key-1',
        'proofValue': 'test_proof_value',
      },
    }),
  );
}
