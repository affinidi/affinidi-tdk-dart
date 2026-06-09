import 'package:affinidi_tdk_common/affinidi_tdk_common.dart';
import 'package:dcql/dcql.dart';
import 'package:ssi/ssi.dart';

import '../models/credential_set_options.dart';
import '../models/matched_credential_group.dart';
import '../models/matched_credentials_result.dart';
import '../models/vc_availability.dart';
import '../models/vc_unavailability_reason.dart';
import '../models/vcs_group_by_type.dart';

/// The result of matching vault credentials against a DCQL query.
///
/// Each entry in [vcsGroups] maps one credential-query ID to the
/// credentials found in the vault — available, expired, or missing.
///
/// When the query's `credential_sets` is non-empty, satisfaction follows the
/// DCQL `credential_sets` rules: each required set is satisfied when at least
/// one of its options (a list of credential-query IDs) is fully available.
/// When `credential_sets` is absent, every credential query is required.
class DcqlMatchedCredentialsResult implements MatchedCredentialsResult {
  /// Creates a [DcqlMatchedCredentialsResult].
  const DcqlMatchedCredentialsResult({
    required this.vcsGroups,
    required this.dcqlQuery,
  });

  /// Maps each credential-query ID to its matched credential group.
  final Map<String, VCsGroupByType> vcsGroups;

  /// The full DCQL query (includes `credential_sets` requirements if any).
  final DcqlCredentialQuery dcqlQuery;

  @override
  bool get hasEnoughVCsAvailableToShare {
    final sets = dcqlQuery.credentialSets;
    if (sets == null || sets.isEmpty) {
      return vcsGroups.values.every((group) => group.hasEnoughVCsToShare);
    }
    return sets.where((set) => set.required).every(_isSetSatisfied);
  }

  @override
  List<VerifiableCredential> get recommendedMaximumVCs {
    final sets = dcqlQuery.credentialSets;
    if (sets == null || sets.isEmpty) {
      return vcsGroups.values
          .expand((group) => group.recommendedMaximumVCs)
          .map((a) => a.vc)
          .toList();
    }

    final recommended = <VerifiableCredential>[];
    for (final set in sets) {
      final option = _firstSatisfiedOption(set);
      if (option == null) continue;
      for (final id in option) {
        for (final available
            in vcsGroups[id]?.recommendedMaximumVCs ?? const <VcAvailable>[]) {
          if (!recommended.contains(available.vc)) {
            recommended.add(available.vc);
          }
        }
      }
    }
    return recommended;
  }

  @override
  List<VerifiableCredential> get availableCredentials => vcsGroups.values
      .expand((group) => group.allAvailableVCs)
      .map((a) => a.vc)
      .toList();

  @override
  List<CredentialSetOptions>? get credentialSetOptions {
    final sets = dcqlQuery.credentialSets;
    if (sets == null || sets.isEmpty) return null;
    return sets
        .map(
          (set) => CredentialSetOptions(
            isRequired: set.required,
            alternatives: set.options,
          ),
        )
        .toList();
  }

  @override
  List<MatchedCredentialGroup> get groups => vcsGroups.entries
      .map(
        (entry) => MatchedCredentialGroup(
          id: entry.key,
          minimumVCsCountToShare: entry.value.minimumVCsCountToShare,
          maximumVCsCountToShare: entry.value.maximumVCsCountToShare,
          availableCredentials: entry.value.allAvailableVCs
              .map((a) => a.vc)
              .toList(),
          recommendedCredentials: entry.value.recommendedMaximumVCs
              .map((a) => a.vc)
              .toList(),
        ),
      )
      .toList();

  bool _isSetSatisfied(DcqlCredentialSet set) =>
      set.options.any(_isOptionSatisfied);

  bool _isOptionSatisfied(List<String> option) =>
      option.every((id) => vcsGroups[id]?.hasEnoughVCsToShare ?? false);

  List<String>? _firstSatisfiedOption(DcqlCredentialSet set) {
    for (final option in set.options) {
      if (_isOptionSatisfied(option)) return option;
    }
    return null;
  }
}

/// Matches a user's vault credentials against a DCQL query.
///
/// For each [DcqlCredential] in the query, the matcher runs the DCQL
/// evaluation using the `dcql` package, then classifies each result as
/// available, expired, or missing. The overall result is returned as a
/// [DcqlMatchedCredentialsResult].
class DcqlShareRequirementsMatcher {
  final Logger _logger;
  final RevocationList2020Verifier? _revocationVerifier;
  static const _componentName = 'DcqlShareRequirementsMatcher';

  /// Creates a [DcqlShareRequirementsMatcher].
  ///
  /// Parameters:
  /// * [revocationVerifier] - optional verifier used to check revocation status.
  ///   When omitted, revocation is not checked and credentials are assumed valid.
  /// * [logger] - optional [Logger] instance; defaults to [Logger.instance].
  DcqlShareRequirementsMatcher({
    RevocationList2020Verifier? revocationVerifier,
    Logger? logger,
  }) : _revocationVerifier = revocationVerifier,
       _logger = logger ?? Logger.instance;

  /// Matches [allVCs] against each credential query in [dcqlQuery].
  ///
  /// Parameters:
  /// * [dcqlQuery] - the DCQL query describing requested credentials.
  /// * [allVCs] - the full list of credentials from the vault.
  ///
  /// Returns a [DcqlMatchedCredentialsResult] mapping each query ID to its
  /// [VCsGroupByType]. If the underlying DCQL evaluation throws, all groups
  /// are marked [VcUnavailabilityReason.unknown] and the error is logged.
  /// Per-credential classification errors within the loop are also caught
  /// individually and recorded as [VcUnavailabilityReason.unknown]; other
  /// queries continue normally.
  Future<DcqlMatchedCredentialsResult> match(
    DcqlCredentialQuery dcqlQuery,
    List<VerifiableCredential> allVCs,
  ) async {
    // Build a mapping from dcql-package DigitalCredential wrappers back to the
    // original VerifiableCredential so we can classify them after evaluation.
    final digitalToVc = <DigitalCredential, VerifiableCredential>{};
    for (final vc in allVCs) {
      final digital = _toDigitalCredential(vc);
      if (digital != null) digitalToVc[digital] = vc;
    }

    final DcqlQueryResult queryResult;
    try {
      queryResult = dcqlQuery.query(digitalToVc.keys);
    } catch (e) {
      _logger.error(
        'DCQL evaluation failed — all credential groups marked unknown: $e',
        component: _componentName,
      );
      final vcsGroups = <String, VCsGroupByType>{
        for (final credential in dcqlQuery.credentials)
          credential.id: VCsGroupByType(
            maximumVCsCountToShare: credential.multiple ? null : 1,
            matchedVCs: const [
              VcUnavailable(reason: VcUnavailabilityReason.unknown),
            ],
          ),
      };
      return DcqlMatchedCredentialsResult(
        vcsGroups: vcsGroups,
        dcqlQuery: dcqlQuery,
      );
    }

    final vcsGroups = <String, VCsGroupByType>{};

    for (final credential in dcqlQuery.credentials) {
      // `multiple: true` imposes no upper bound; `false` (the default) means
      // the user must pick exactly one.
      final maxCount = credential.multiple ? null : 1;
      try {
        final matchedDigital =
            queryResult.verifiableCredentials[credential.id] ?? const [];

        if (matchedDigital.isEmpty) {
          vcsGroups[credential.id] = VCsGroupByType(
            maximumVCsCountToShare: maxCount,
            matchedVCs: const [
              VcUnavailable(reason: VcUnavailabilityReason.missing),
            ],
          );
          continue;
        }

        final matched = matchedDigital
            .map((d) => digitalToVc[d])
            .whereType<VerifiableCredential>()
            .toList();

        final available = <VcAvailability>[];
        final expired = <VcAvailability>[];
        final revoked = <VcAvailability>[];
        final now = DateTime.now();

        for (final vc in matched) {
          if (vc.validUntil != null && vc.validUntil!.isBefore(now)) {
            expired.add(
              VcUnavailable(
                reason: VcUnavailabilityReason.expired,
                bestMatchVc: vc,
              ),
            );
            continue;
          }

          final verifier = _revocationVerifier;
          if (verifier != null) {
            if (vc is! ParsedVerifiableCredential) {
              _logger.warning(
                'Revocation check skipped: VC is ${vc.runtimeType}, '
                'not a ParsedVerifiableCredential. Treating as available.',
                component: _componentName,
              );
            } else {
              try {
                final result = await verifier.verify(vc);
                if (result.errors.isNotEmpty) {
                  revoked.add(
                    VcUnavailable(
                      reason: VcUnavailabilityReason.revoked,
                      bestMatchVc: vc,
                    ),
                  );
                  continue;
                }
              } catch (e, stack) {
                _logger.warning(
                  'Revocation check failed for VC — treating as available: $e',
                  component: _componentName,
                );
                _logger.warning(stack.toString(), component: _componentName);
              }
            }
          }

          available.add(VcAvailable(vc: vc));
        }

        vcsGroups[credential.id] = VCsGroupByType(
          maximumVCsCountToShare: maxCount,
          matchedVCs: [...available, ...revoked, ...expired],
        );
      } catch (e, stackTrace) {
        _logger.error(
          '$_componentName: error evaluating credential query '
          '"${credential.id}": $e',
          component: _componentName,
        );
        _logger.warning(stackTrace.toString(), component: _componentName);
        vcsGroups[credential.id] = VCsGroupByType(
          maximumVCsCountToShare: maxCount,
          matchedVCs: const [
            VcUnavailable(reason: VcUnavailabilityReason.unknown),
          ],
        );
      }
    }

    return DcqlMatchedCredentialsResult(
      vcsGroups: vcsGroups,
      dcqlQuery: dcqlQuery,
    );
  }

  /// Wraps a [VerifiableCredential] in the dcql package's [DigitalCredential]
  /// interface for evaluation. Returns `null` for unsupported VC formats.
  static DigitalCredential? _toDigitalCredential(VerifiableCredential vc) {
    final contextUri = vc.context.firstUri?.toString();
    try {
      if (contextUri == dmV1ContextUrl) {
        return W3CDigitalCredential.fromLdVcDataModelV1(vc.toJson());
      }
      if (contextUri == dmV2ContextUrl) {
        return W3CDigitalCredential.fromLdVcDataModelV2(vc.toJson());
      }
      return null;
    } on Exception {
      return null;
    }
  }
}
