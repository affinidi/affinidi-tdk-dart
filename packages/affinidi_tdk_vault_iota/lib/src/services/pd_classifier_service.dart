import 'package:affinidi_tdk_common/affinidi_tdk_common.dart';

import '../exceptions/tdk_exception_type.dart';
import '../models/pd_descriptor.dart';
import '../models/pd_requirements.dart';
import '../models/request_purpose.dart';
import '../models/submission_requirements.dart';
import '../models/verified_identity_document_info.dart';
import 'pd_classifier_constants.dart';
import 'zero_party_vc_data_points.dart';
import 'zpd_linked_vc_types.dart';

/// Intermediate parsing result for a single input descriptor.
///
/// Produced by [PDClassifier._extractRequestedType] and consumed by
/// [PDClassifier._computeRequiredDataPoints] and the fold classifier.
class _PdParserTmpResult {
  const _PdParserTmpResult({
    required this.inputDescriptor,
    required this.types,
    this.context,
    this.groupName,
    this.issuer,
    this.dataPoints,
  });

  final Map<String, dynamic> inputDescriptor;
  final List<String> types;
  final String? context;
  final String? groupName;
  final String? issuer;

  /// Non-null when this descriptor maps to zero-party (HIT* / ProfileTemplate)
  /// profile data paths. An empty set means the type was recognised but
  /// declares no specific paths (e.g. `ProfileTemplate`).
  final Set<String>? dataPoints;

  _PdParserTmpResult copyWith({Set<String>? dataPoints}) => _PdParserTmpResult(
    inputDescriptor: inputDescriptor,
    types: types,
    context: context,
    groupName: groupName,
    issuer: issuer,
    dataPoints: dataPoints ?? this.dataPoints,
  );
}

/// Classifies the input descriptors of a Presentation Definition into
/// requirement categories.
///
/// Produces a [PDRequirements] that tells the caller which types of data a
/// verifier is requesting — claimed VCs, ZPD-linked VCs, profile data, or
/// identity verification.
class PDClassifier {
  /// Creates a [PDClassifier].
  ///
  /// [validIdvIssuers] is the list of DID strings that are trusted IDV
  /// issuers. A descriptor is routed to [PDRequirements.idvDescriptors] only
  /// when its extracted issuer appears in this list.
  const PDClassifier({required this.validIdvIssuers});

  /// Trusted IDV issuer DIDs.
  final List<String> validIdvIssuers;

  /// Classifies [pd] and returns a [PDRequirements] breakdown.
  ///
  /// [pd] must be a `Map<String, dynamic>` containing at least an
  /// `input_descriptors` key. Throws a [TdkException] with code
  /// [TdkExceptionType.invalidPresentationDefinition] if the PD is
  /// structurally invalid, or
  /// [TdkExceptionType.unsupportedMultipleIdvTypes] if a single descriptor
  /// requests more than one IDV document type.
  PDRequirements classify(Map<String, dynamic> pd) {
    final rawValue = pd[PdClassifierConstants.inputDescriptorsKey];

    if (rawValue is! List) {
      Error.throwWithStackTrace(
        TdkException(
          message: rawValue == null
              ? 'Presentation Definition is missing input_descriptors.'
              : 'Presentation Definition input_descriptors must be a list.',
          code: TdkExceptionType.invalidPresentationDefinition.code,
        ),
        StackTrace.current,
      );
    }

    final rawDescriptors = rawValue;

    final purpose = _extractPurpose(pd[PdClassifierConstants.purposeKey]);

    final submissionRequirementsByGroup = _extractSubmissionRequirements(pd);

    var requirements = PDRequirements(
      claimedDescriptors: [],
      zpdLinkedDescriptors: [],
      idvDescriptors: [],
      dataPoints: {},
      zeroPartyVCs: {},
      submissionRequirementsByGroup: submissionRequirementsByGroup,
      purpose: purpose,
    );

    var hasInvalidIdvPd = false;

    requirements = rawDescriptors
        .map((d) {
          if (d is! Map<String, dynamic>) {
            Error.throwWithStackTrace(
              TdkException(
                message: 'Each input_descriptors entry must be a JSON object.',
                code: TdkExceptionType.invalidPresentationDefinition.code,
              ),
              StackTrace.current,
            );
          }
          if (d['id'] is! String) {
            Error.throwWithStackTrace(
              TdkException(
                message:
                    'Each input_descriptors entry must have a string "id" field.',
                code: TdkExceptionType.invalidPresentationDefinition.code,
              ),
              StackTrace.current,
            );
          }
          return _extractRequestedType(d);
        })
        .map(_computeRequiredDataPoints)
        .fold(requirements, (result, requiredDataPoints) {
          final isZeroPartyVC = requiredDataPoints.dataPoints != null;
          final linkedZpdPaths = _getLinkedZpdPaths(requiredDataPoints);
          final isIdv =
              validIdvIssuers.contains(requiredDataPoints.issuer) &&
              requiredDataPoints.types.contains(
                PdClassifierConstants.verifiedIdentityDocumentType,
              );

          if (isZeroPartyVC) {
            result.dataPoints.addAll(requiredDataPoints.dataPoints!);
            if (requiredDataPoints.types.isNotEmpty) {
              result.zeroPartyVCs.add(requiredDataPoints.types.first);
            }
          } else if (linkedZpdPaths.isNotEmpty) {
            result.zpdLinkedDescriptors.add(
              PDDescriptor(data: requiredDataPoints.inputDescriptor),
            );
            result.dataPoints.addAll(linkedZpdPaths);
          } else if (isIdv) {
            if (requiredDataPoints.types.length > 2) {
              hasInvalidIdvPd = true;
            }

            result.idvDescriptors.add(
              PDDescriptor(data: requiredDataPoints.inputDescriptor),
            );

            VerifiedIdentityDocumentInfo? idvInfo;
            if (requiredDataPoints.context != null) {
              idvInfo = VerifiedIdentityDocumentInfo(
                schemaContextUrl: requiredDataPoints.context,
              );
            }

            if (requiredDataPoints.types.length > 1) {
              final specificType = requiredDataPoints.types.firstWhere(
                (t) => t != PdClassifierConstants.verifiedIdentityDocumentType,
              );
              idvInfo =
                  idvInfo?.copyWith(type: specificType) ??
                  VerifiedIdentityDocumentInfo(type: specificType);
            }

            if (idvInfo != null) {
              result = result.copyWith(idvInfo: idvInfo);
            }
          } else {
            // Standard claimed VC
            result.claimedDescriptors.add(
              PDDescriptor(data: requiredDataPoints.inputDescriptor),
            );
          }

          return result;
        });

    if (hasInvalidIdvPd) {
      Error.throwWithStackTrace(
        TdkException(
          message:
              'Multiple IDV types in a single descriptor are not supported.',
          code: TdkExceptionType.unsupportedMultipleIdvTypes.code,
        ),
        StackTrace.current,
      );
    }

    return PDRequirements(
      claimedDescriptors: List.unmodifiable(requirements.claimedDescriptors),
      zpdLinkedDescriptors: List.unmodifiable(
        requirements.zpdLinkedDescriptors,
      ),
      idvDescriptors: List.unmodifiable(requirements.idvDescriptors),
      dataPoints: Set.unmodifiable(requirements.dataPoints),
      zeroPartyVCs: Set.unmodifiable(requirements.zeroPartyVCs),
      idvInfo: requirements.idvInfo,
      submissionRequirementsByGroup: Map.unmodifiable(
        requirements.submissionRequirementsByGroup,
      ),
      purpose: requirements.purpose,
    );
  }

  // ── Private helpers ──────────────────────────────────────────────────────

  /// Extracts context, type(s), issuer, and group from a single input
  /// descriptor by inspecting its `constraints.fields[]`.
  _PdParserTmpResult _extractRequestedType(
    Map<String, dynamic> inputDescriptor,
  ) {
    String? context;
    final types = <String>[];
    String? issuer;
    String? groupName;

    final rawGroup = inputDescriptor[PdClassifierConstants.groupNameKey];
    if (rawGroup is List && rawGroup.isNotEmpty) {
      groupName = rawGroup.first.toString();
    } else if (rawGroup is String && rawGroup.isNotEmpty) {
      groupName = rawGroup;
    } else if (rawGroup != null) {
      Error.throwWithStackTrace(
        TdkException(
          message: 'input_descriptor "group" field must be a list or string.',
          code: TdkExceptionType.invalidPresentationDefinition.code,
        ),
        StackTrace.current,
      );
    }

    final rawConstraints =
        inputDescriptor[PdClassifierConstants.constraintsKey];
    if (rawConstraints is! Map<String, dynamic>) {
      return _PdParserTmpResult(
        inputDescriptor: inputDescriptor,
        types: types,
        context: context,
        groupName: groupName,
        issuer: issuer,
      );
    }

    final fields =
        rawConstraints[PdClassifierConstants.fieldsKey] as List<dynamic>?;
    if (fields == null) {
      return _PdParserTmpResult(
        inputDescriptor: inputDescriptor,
        types: types,
        context: context,
        groupName: groupName,
        issuer: issuer,
      );
    }

    var contextPathCount = 0;

    for (final field in fields) {
      if (field is! Map<String, dynamic>) continue;

      final rawPaths = field[PdClassifierConstants.pathKey] as List<dynamic>?;
      if (rawPaths == null) continue;

      final paths = rawPaths.map((e) => e.toString()).toList();
      final rawFilter = field[PdClassifierConstants.filterKey];
      final filter = rawFilter is Map<String, dynamic> ? rawFilter : null;

      contextPathCount += paths
          .where((p) => p == PdClassifierConstants.contextPath)
          .length;
      if (contextPathCount > 1) {
        Error.throwWithStackTrace(
          TdkException(
            message:
                'Multiple \$.@context fields in a single descriptor are not supported.',
            code: TdkExceptionType.invalidPresentationDefinition.code,
          ),
          StackTrace.current,
        );
      }

      if (filter == null) continue;

      if (paths.contains(PdClassifierConstants.contextPath) &&
          filter[PdClassifierConstants.containsKey] is Map) {
        context = _extractConstraint(filter);
      }

      if (paths.contains(PdClassifierConstants.typePath) &&
          filter[PdClassifierConstants.containsKey] is Map) {
        types.add(_extractConstraint(filter));
      }

      final isIssuerPath =
          paths.contains(r'$.issuer') ||
          paths.contains(r'$.vc.issuer') ||
          paths.contains(r'$.iss');
      if (isIssuerPath &&
          filter[PdClassifierConstants.typeKey] == 'string' &&
          (filter.containsKey(PdClassifierConstants.patternKey) ||
              filter.containsKey(PdClassifierConstants.constKey))) {
        issuer = _extractConstraint(filter);
      }
    }

    return _PdParserTmpResult(
      inputDescriptor: inputDescriptor,
      types: types,
      context: context,
      groupName: groupName,
      issuer: issuer,
    );
  }

  /// Maps recognised zero-party VC types to their profile data paths.
  _PdParserTmpResult _computeRequiredDataPoints(_PdParserTmpResult tmp) {
    if (tmp.types.isEmpty) return tmp;

    // ProfileTemplate: must match both type and context
    if (tmp.types.contains(PdClassifierConstants.profileType) &&
        tmp.context == PdClassifierConstants.profileContext) {
      return tmp.copyWith(dataPoints: const <String>{});
    }

    final dataPoints = ZeroPartyVcDataPoints.byType[tmp.types.first];
    if (dataPoints == null) return tmp;

    return tmp.copyWith(dataPoints: dataPoints);
  }

  /// Returns the ZPD data paths linked to a ZPD-linked VC type (e.g. Email,
  /// PhoneNumber), or an empty list if the type is not ZPD-linked.
  List<String> _getLinkedZpdPaths(_PdParserTmpResult requiredDataPoints) {
    if (requiredDataPoints.types.isEmpty) return const [];
    if (requiredDataPoints.types.length > 1) {
      Logger.instance.warning(
        'ZPD-linked VC lookup called with multiple types — skipping.',
        component: 'PDClassifier',
      );
      return const [];
    }
    return ZpdLinkedVcTypes.byType[requiredDataPoints.types.first] ?? const [];
  }

  /// Extracts a string value from a PD filter map.
  ///
  /// Looks for `contains.pattern`, `contains.const`, `pattern`, or `const`
  /// in that priority order. Strips `^` / `$` anchors from regex patterns.
  String _extractConstraint(Map<String, dynamic> filter) {
    final rawContains = filter[PdClassifierConstants.containsKey];

    if (rawContains != null) {
      if (rawContains is! Map<String, dynamic>) {
        Error.throwWithStackTrace(
          TdkException(
            message: 'PD filter "contains" must be a JSON object.',
            code: TdkExceptionType.invalidPresentationDefinition.code,
          ),
          StackTrace.current,
        );
      }
      if (rawContains.containsKey(PdClassifierConstants.patternKey)) {
        final value = rawContains[PdClassifierConstants.patternKey];
        if (value is! String) {
          Error.throwWithStackTrace(
            TdkException(
              message: 'PD filter "contains.pattern" must be a string.',
              code: TdkExceptionType.invalidPresentationDefinition.code,
            ),
            StackTrace.current,
          );
        }
        return _stripAnchors(value);
      }
      if (rawContains.containsKey(PdClassifierConstants.constKey)) {
        final value = rawContains[PdClassifierConstants.constKey];
        if (value is! String) {
          Error.throwWithStackTrace(
            TdkException(
              message: 'PD filter "contains.const" must be a string.',
              code: TdkExceptionType.invalidPresentationDefinition.code,
            ),
            StackTrace.current,
          );
        }
        return value;
      }
    } else {
      if (filter.containsKey(PdClassifierConstants.patternKey)) {
        final value = filter[PdClassifierConstants.patternKey];
        if (value is! String) {
          Error.throwWithStackTrace(
            TdkException(
              message: 'PD filter "pattern" must be a string.',
              code: TdkExceptionType.invalidPresentationDefinition.code,
            ),
            StackTrace.current,
          );
        }
        return _stripAnchors(value);
      }
      if (filter.containsKey(PdClassifierConstants.constKey)) {
        final value = filter[PdClassifierConstants.constKey];
        if (value is! String) {
          Error.throwWithStackTrace(
            TdkException(
              message: 'PD filter "const" must be a string.',
              code: TdkExceptionType.invalidPresentationDefinition.code,
            ),
            StackTrace.current,
          );
        }
        return value;
      }
    }

    Error.throwWithStackTrace(
      TdkException(
        message: 'Could not extract constraint value from PD filter.',
        code: TdkExceptionType.invalidPresentationDefinition.code,
      ),
      StackTrace.current,
    );
  }

  /// Removes leading `^` and trailing `$` from a regex pattern string.
  String _stripAnchors(String pattern) {
    var result = pattern;
    if (result.startsWith('^')) result = result.substring(1);
    if (result.endsWith(r'$')) result = result.substring(0, result.length - 1);
    return result;
  }

  /// Parses the `purpose` field of a PD (may be a JSON string or a map).
  RequestPurpose? _extractPurpose(dynamic rawPurpose) {
    if (rawPurpose == null) return null;
    try {
      final parsed = RequestPurpose.fromJson(rawPurpose);
      return parsed.isValid ? parsed : null;
    } catch (e) {
      Logger.instance.warning(
        'Failed to parse PD purpose: $e',
        component: 'PDClassifier',
      );
      return null;
    }
  }

  /// Parses `submission_requirements` from [pd] into a group-keyed map.
  ///
  /// Throws [TdkException] with [TdkExceptionType.invalidPresentationDefinition]
  /// if any requirement has a zero or negative count/min/max.
  Map<String, SubmissionRequirements> _extractSubmissionRequirements(
    Map<String, dynamic> pd,
  ) {
    final rawValue = pd[PdClassifierConstants.submissionRequirementsKey];
    if (rawValue == null) return const {};

    if (rawValue is! List) {
      Error.throwWithStackTrace(
        TdkException(
          message: 'submission_requirements must be a list.',
          code: TdkExceptionType.invalidPresentationDefinition.code,
        ),
        StackTrace.current,
      );
    }

    final requirements = rawValue.map((e) {
      if (e is! Map<String, dynamic>) {
        Error.throwWithStackTrace(
          TdkException(
            message:
                'Each submission_requirements entry must be a JSON object.',
            code: TdkExceptionType.invalidPresentationDefinition.code,
          ),
          StackTrace.current,
        );
      }
      return SubmissionRequirements.fromJson(e);
    }).toList();

    for (final req in requirements) {
      if ((req.min != null && req.min! < 1) ||
          (req.max != null && req.max! < 1) ||
          (req.count != null && req.count! < 1)) {
        Error.throwWithStackTrace(
          TdkException(
            message:
                'submission_requirements contains an invalid count/min/max value.',
            code: TdkExceptionType.invalidPresentationDefinition.code,
          ),
          StackTrace.current,
        );
      }
    }

    return {for (final req in requirements) req.groupName: req};
  }
}
