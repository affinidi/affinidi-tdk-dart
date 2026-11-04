// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'identity_mapping_error.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const IdentityMappingErrorNameEnum
_$identityMappingErrorNameEnum_identityMappingError =
    const IdentityMappingErrorNameEnum._('identityMappingError');

IdentityMappingErrorNameEnum _$identityMappingErrorNameEnumValueOf(
  String name,
) {
  switch (name) {
    case 'identityMappingError':
      return _$identityMappingErrorNameEnum_identityMappingError;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<IdentityMappingErrorNameEnum>
_$identityMappingErrorNameEnumValues = BuiltSet<IdentityMappingErrorNameEnum>(
  const <IdentityMappingErrorNameEnum>[
    _$identityMappingErrorNameEnum_identityMappingError,
  ],
);

const IdentityMappingErrorMessageEnum
_$identityMappingErrorMessageEnum_unableToMapTheAuthenticatedPrincipalToAnIdentityPeriod =
    const IdentityMappingErrorMessageEnum._(
      'unableToMapTheAuthenticatedPrincipalToAnIdentityPeriod',
    );

IdentityMappingErrorMessageEnum _$identityMappingErrorMessageEnumValueOf(
  String name,
) {
  switch (name) {
    case 'unableToMapTheAuthenticatedPrincipalToAnIdentityPeriod':
      return _$identityMappingErrorMessageEnum_unableToMapTheAuthenticatedPrincipalToAnIdentityPeriod;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<IdentityMappingErrorMessageEnum>
_$identityMappingErrorMessageEnumValues =
    BuiltSet<IdentityMappingErrorMessageEnum>(const <
      IdentityMappingErrorMessageEnum
    >[
      _$identityMappingErrorMessageEnum_unableToMapTheAuthenticatedPrincipalToAnIdentityPeriod,
    ]);

const IdentityMappingErrorHttpStatusCodeEnum
_$identityMappingErrorHttpStatusCodeEnum_number404 =
    const IdentityMappingErrorHttpStatusCodeEnum._('number404');

IdentityMappingErrorHttpStatusCodeEnum
_$identityMappingErrorHttpStatusCodeEnumValueOf(String name) {
  switch (name) {
    case 'number404':
      return _$identityMappingErrorHttpStatusCodeEnum_number404;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<IdentityMappingErrorHttpStatusCodeEnum>
_$identityMappingErrorHttpStatusCodeEnumValues =
    BuiltSet<IdentityMappingErrorHttpStatusCodeEnum>(
      const <IdentityMappingErrorHttpStatusCodeEnum>[
        _$identityMappingErrorHttpStatusCodeEnum_number404,
      ],
    );

Serializer<IdentityMappingErrorNameEnum>
_$identityMappingErrorNameEnumSerializer =
    _$IdentityMappingErrorNameEnumSerializer();
Serializer<IdentityMappingErrorMessageEnum>
_$identityMappingErrorMessageEnumSerializer =
    _$IdentityMappingErrorMessageEnumSerializer();
Serializer<IdentityMappingErrorHttpStatusCodeEnum>
_$identityMappingErrorHttpStatusCodeEnumSerializer =
    _$IdentityMappingErrorHttpStatusCodeEnumSerializer();

class _$IdentityMappingErrorNameEnumSerializer
    implements PrimitiveSerializer<IdentityMappingErrorNameEnum> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'identityMappingError': 'IdentityMappingError',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'IdentityMappingError': 'identityMappingError',
  };

  @override
  final Iterable<Type> types = const <Type>[IdentityMappingErrorNameEnum];
  @override
  final String wireName = 'IdentityMappingErrorNameEnum';

  @override
  Object serialize(
    Serializers serializers,
    IdentityMappingErrorNameEnum object, {
    FullType specifiedType = FullType.unspecified,
  }) => _toWire[object.name] ?? object.name;

  @override
  IdentityMappingErrorNameEnum deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => IdentityMappingErrorNameEnum.valueOf(
    _fromWire[serialized] ?? (serialized is String ? serialized : ''),
  );
}

class _$IdentityMappingErrorMessageEnumSerializer
    implements PrimitiveSerializer<IdentityMappingErrorMessageEnum> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'unableToMapTheAuthenticatedPrincipalToAnIdentityPeriod':
        'Unable to map the authenticated principal to an identity.',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'Unable to map the authenticated principal to an identity.':
        'unableToMapTheAuthenticatedPrincipalToAnIdentityPeriod',
  };

  @override
  final Iterable<Type> types = const <Type>[IdentityMappingErrorMessageEnum];
  @override
  final String wireName = 'IdentityMappingErrorMessageEnum';

  @override
  Object serialize(
    Serializers serializers,
    IdentityMappingErrorMessageEnum object, {
    FullType specifiedType = FullType.unspecified,
  }) => _toWire[object.name] ?? object.name;

  @override
  IdentityMappingErrorMessageEnum deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => IdentityMappingErrorMessageEnum.valueOf(
    _fromWire[serialized] ?? (serialized is String ? serialized : ''),
  );
}

class _$IdentityMappingErrorHttpStatusCodeEnumSerializer
    implements PrimitiveSerializer<IdentityMappingErrorHttpStatusCodeEnum> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'number404': 404,
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    404: 'number404',
  };

  @override
  final Iterable<Type> types = const <Type>[
    IdentityMappingErrorHttpStatusCodeEnum,
  ];
  @override
  final String wireName = 'IdentityMappingErrorHttpStatusCodeEnum';

  @override
  Object serialize(
    Serializers serializers,
    IdentityMappingErrorHttpStatusCodeEnum object, {
    FullType specifiedType = FullType.unspecified,
  }) => _toWire[object.name] ?? object.name;

  @override
  IdentityMappingErrorHttpStatusCodeEnum deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => IdentityMappingErrorHttpStatusCodeEnum.valueOf(
    _fromWire[serialized] ?? (serialized is String ? serialized : ''),
  );
}

class _$IdentityMappingError extends IdentityMappingError {
  @override
  final IdentityMappingErrorNameEnum name;
  @override
  final IdentityMappingErrorMessageEnum message;
  @override
  final IdentityMappingErrorHttpStatusCodeEnum httpStatusCode;
  @override
  final String traceId;
  @override
  final BuiltList<UnexpectedErrorDetailsInner>? details;

  factory _$IdentityMappingError([
    void Function(IdentityMappingErrorBuilder)? updates,
  ]) => (IdentityMappingErrorBuilder()..update(updates))._build();

  _$IdentityMappingError._({
    required this.name,
    required this.message,
    required this.httpStatusCode,
    required this.traceId,
    this.details,
  }) : super._();
  @override
  IdentityMappingError rebuild(
    void Function(IdentityMappingErrorBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  IdentityMappingErrorBuilder toBuilder() =>
      IdentityMappingErrorBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is IdentityMappingError &&
        name == other.name &&
        message == other.message &&
        httpStatusCode == other.httpStatusCode &&
        traceId == other.traceId &&
        details == other.details;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, name.hashCode);
    _$hash = $jc(_$hash, message.hashCode);
    _$hash = $jc(_$hash, httpStatusCode.hashCode);
    _$hash = $jc(_$hash, traceId.hashCode);
    _$hash = $jc(_$hash, details.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'IdentityMappingError')
          ..add('name', name)
          ..add('message', message)
          ..add('httpStatusCode', httpStatusCode)
          ..add('traceId', traceId)
          ..add('details', details))
        .toString();
  }
}

class IdentityMappingErrorBuilder
    implements Builder<IdentityMappingError, IdentityMappingErrorBuilder> {
  _$IdentityMappingError? _$v;

  IdentityMappingErrorNameEnum? _name;
  IdentityMappingErrorNameEnum? get name => _$this._name;
  set name(IdentityMappingErrorNameEnum? name) => _$this._name = name;

  IdentityMappingErrorMessageEnum? _message;
  IdentityMappingErrorMessageEnum? get message => _$this._message;
  set message(IdentityMappingErrorMessageEnum? message) =>
      _$this._message = message;

  IdentityMappingErrorHttpStatusCodeEnum? _httpStatusCode;
  IdentityMappingErrorHttpStatusCodeEnum? get httpStatusCode =>
      _$this._httpStatusCode;
  set httpStatusCode(IdentityMappingErrorHttpStatusCodeEnum? httpStatusCode) =>
      _$this._httpStatusCode = httpStatusCode;

  String? _traceId;
  String? get traceId => _$this._traceId;
  set traceId(String? traceId) => _$this._traceId = traceId;

  ListBuilder<UnexpectedErrorDetailsInner>? _details;
  ListBuilder<UnexpectedErrorDetailsInner> get details =>
      _$this._details ??= ListBuilder<UnexpectedErrorDetailsInner>();
  set details(ListBuilder<UnexpectedErrorDetailsInner>? details) =>
      _$this._details = details;

  IdentityMappingErrorBuilder() {
    IdentityMappingError._defaults(this);
  }

  IdentityMappingErrorBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _name = $v.name;
      _message = $v.message;
      _httpStatusCode = $v.httpStatusCode;
      _traceId = $v.traceId;
      _details = $v.details?.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(IdentityMappingError other) {
    _$v = other as _$IdentityMappingError;
  }

  @override
  void update(void Function(IdentityMappingErrorBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  IdentityMappingError build() => _build();

  _$IdentityMappingError _build() {
    _$IdentityMappingError _$result;
    try {
      _$result =
          _$v ??
          _$IdentityMappingError._(
            name: BuiltValueNullFieldError.checkNotNull(
              name,
              r'IdentityMappingError',
              'name',
            ),
            message: BuiltValueNullFieldError.checkNotNull(
              message,
              r'IdentityMappingError',
              'message',
            ),
            httpStatusCode: BuiltValueNullFieldError.checkNotNull(
              httpStatusCode,
              r'IdentityMappingError',
              'httpStatusCode',
            ),
            traceId: BuiltValueNullFieldError.checkNotNull(
              traceId,
              r'IdentityMappingError',
              'traceId',
            ),
            details: _details?.build(),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'details';
        _details?.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
          r'IdentityMappingError',
          _$failedField,
          e.toString(),
        );
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
