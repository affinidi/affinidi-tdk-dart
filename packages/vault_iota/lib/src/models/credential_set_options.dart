/// Describes one DCQL `credential_set` entry and its selectable alternatives.
///
/// The Wallet satisfies this set by meeting any single entry in
/// [alternatives]. Each alternative is a list of credential-query IDs
/// (matching `MatchedCredentialGroup.id` values) that must ALL be presented
/// together.
///
/// When [isRequired] is `true` (the default per the spec), the Wallet MUST
/// satisfy at least one alternative. When `false`, the set is optional and
/// the Wallet MAY skip it.
class CredentialSetOptions {
  /// Creates a [CredentialSetOptions].
  const CredentialSetOptions({
    required this.isRequired,
    required this.alternatives,
  });

  /// Whether the Wallet must satisfy at least one entry in [alternatives].
  final bool isRequired;

  /// The selectable alternatives. Each alternative is a list of
  /// credential-query IDs (matching `MatchedCredentialGroup.id`) that must
  /// ALL be presented together to fulfil that option.
  final List<List<String>> alternatives;
}
