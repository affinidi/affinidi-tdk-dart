// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'upstream_unavailable_error.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const UpstreamUnavailableErrorNameEnum
_$upstreamUnavailableErrorNameEnum_upstreamUnavailableError =
    const UpstreamUnavailableErrorNameEnum._('upstreamUnavailableError');

UpstreamUnavailableErrorNameEnum _$upstreamUnavailableErrorNameEnumValueOf(
  String name,
) {
  switch (name) {
    case 'upstreamUnavailableError':
      return _$upstreamUnavailableErrorNameEnum_upstreamUnavailableError;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<UpstreamUnavailableErrorNameEnum>
_$upstreamUnavailableErrorNameEnumValues =
    BuiltSet<UpstreamUnavailableErrorNameEnum>(
      const <UpstreamUnavailableErrorNameEnum>[
        _$upstreamUnavailableErrorNameEnum_upstreamUnavailableError,
      ],
    );

const UpstreamUnavailableErrorMessageEnum
_$upstreamUnavailableErrorMessageEnum_theUpstreamIdentityServiceIsUnavailablePeriod =
    const UpstreamUnavailableErrorMessageEnum._(
      'theUpstreamIdentityServiceIsUnavailablePeriod',
    );

UpstreamUnavailableErrorMessageEnum
_$upstreamUnavailableErrorMessageEnumValueOf(String name) {
  switch (name) {
    case 'theUpstreamIdentityServiceIsUnavailablePeriod':
      return _$upstreamUnavailableErrorMessageEnum_theUpstreamIdentityServiceIsUnavailablePeriod;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<UpstreamUnavailableErrorMessageEnum>
_$upstreamUnavailableErrorMessageEnumValues =
    BuiltSet<UpstreamUnavailableErrorMessageEnum>(const <
      UpstreamUnavailableErrorMessageEnum
    >[
      _$upstreamUnavailableErrorMessageEnum_theUpstreamIdentityServiceIsUnavailablePeriod,
    ]);

const UpstreamUnavailableErrorHttpStatusCodeEnum
_$upstreamUnavailableErrorHttpStatusCodeEnum_number424 =
    const UpstreamUnavailableErrorHttpStatusCodeEnum._('number424');

UpstreamUnavailableErrorHttpStatusCodeEnum
_$upstreamUnavailableErrorHttpStatusCodeEnumValueOf(String name) {
  switch (name) {
    case 'number424':
      return _$upstreamUnavailableErrorHttpStatusCodeEnum_number424;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<UpstreamUnavailableErrorHttpStatusCodeEnum>
_$upstreamUnavailableErrorHttpStatusCodeEnumValues =
    BuiltSet<UpstreamUnavailableErrorHttpStatusCodeEnum>(
      const <UpstreamUnavailableErrorHttpStatusCodeEnum>[
        _$upstreamUnavailableErrorHttpStatusCodeEnum_number424,
      ],
    );

Serializer<UpstreamUnavailableErrorNameEnum>
_$upstreamUnavailableErrorNameEnumSerializer =
    _$UpstreamUnavailableErrorNameEnumSerializer();
Serializer<UpstreamUnavailableErrorMessageEnum>
_$upstreamUnavailableErrorMessageEnumSerializer =
    _$UpstreamUnavailableErrorMessageEnumSerializer();
Serializer<UpstreamUnavailableErrorHttpStatusCodeEnum>
_$upstreamUnavailableErrorHttpStatusCodeEnumSerializer =
    _$UpstreamUnavailableErrorHttpStatusCodeEnumSerializer();

class _$UpstreamUnavailableErrorNameEnumSerializer
    implements PrimitiveSerializer<UpstreamUnavailableErrorNameEnum> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'upstreamUnavailableError': 'UpstreamUnavailableError',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'UpstreamUnavailableError': 'upstreamUnavailableError',
  };

  @override
  final Iterable<Type> types = const <Type>[UpstreamUnavailableErrorNameEnum];
  @override
  final String wireName = 'UpstreamUnavailableErrorNameEnum';

  @override
  Object serialize(
    Serializers serializers,
    UpstreamUnavailableErrorNameEnum object, {
    FullType specifiedType = FullType.unspecified,
  }) => _toWire[object.name] ?? object.name;

  @override
  UpstreamUnavailableErrorNameEnum deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => UpstreamUnavailableErrorNameEnum.valueOf(
    _fromWire[serialized] ?? (serialized is String ? serialized : ''),
  );
}

class _$UpstreamUnavailableErrorMessageEnumSerializer
    implements PrimitiveSerializer<UpstreamUnavailableErrorMessageEnum> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'theUpstreamIdentityServiceIsUnavailablePeriod':
        'The upstream identity service is unavailable.',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'The upstream identity service is unavailable.':
        'theUpstreamIdentityServiceIsUnavailablePeriod',
  };

  @override
  final Iterable<Type> types = const <Type>[
    UpstreamUnavailableErrorMessageEnum,
  ];
  @override
  final String wireName = 'UpstreamUnavailableErrorMessageEnum';

  @override
  Object serialize(
    Serializers serializers,
    UpstreamUnavailableErrorMessageEnum object, {
    FullType specifiedType = FullType.unspecified,
  }) => _toWire[object.name] ?? object.name;

  @override
  UpstreamUnavailableErrorMessageEnum deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => UpstreamUnavailableErrorMessageEnum.valueOf(
    _fromWire[serialized] ?? (serialized is String ? serialized : ''),
  );
}

class _$UpstreamUnavailableErrorHttpStatusCodeEnumSerializer
    implements PrimitiveSerializer<UpstreamUnavailableErrorHttpStatusCodeEnum> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'number424': 424,
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    424: 'number424',
  };

  @override
  final Iterable<Type> types = const <Type>[
    UpstreamUnavailableErrorHttpStatusCodeEnum,
  ];
  @override
  final String wireName = 'UpstreamUnavailableErrorHttpStatusCodeEnum';

  @override
  Object serialize(
    Serializers serializers,
    UpstreamUnavailableErrorHttpStatusCodeEnum object, {
    FullType specifiedType = FullType.unspecified,
  }) => _toWire[object.name] ?? object.name;

  @override
  UpstreamUnavailableErrorHttpStatusCodeEnum deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => UpstreamUnavailableErrorHttpStatusCodeEnum.valueOf(
    _fromWire[serialized] ?? (serialized is String ? serialized : ''),
  );
}

class _$UpstreamUnavailableError extends UpstreamUnavailableError {
  @override
  final UpstreamUnavailableErrorNameEnum name;
  @override
  final UpstreamUnavailableErrorMessageEnum message;
  @override
  final UpstreamUnavailableErrorHttpStatusCodeEnum httpStatusCode;
  @override
  final String traceId;
  @override
  final BuiltList<UnexpectedErrorDetailsInner>? details;

  factory _$UpstreamUnavailableError([
    void Function(UpstreamUnavailableErrorBuilder)? updates,
  ]) => (UpstreamUnavailableErrorBuilder()..update(updates))._build();

  _$UpstreamUnavailableError._({
    required this.name,
    required this.message,
    required this.httpStatusCode,
    required this.traceId,
    this.details,
  }) : super._();
  @override
  UpstreamUnavailableError rebuild(
    void Function(UpstreamUnavailableErrorBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  UpstreamUnavailableErrorBuilder toBuilder() =>
      UpstreamUnavailableErrorBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is UpstreamUnavailableError &&
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
    return (newBuiltValueToStringHelper(r'UpstreamUnavailableError')
          ..add('name', name)
          ..add('message', message)
          ..add('httpStatusCode', httpStatusCode)
          ..add('traceId', traceId)
          ..add('details', details))
        .toString();
  }
}

class UpstreamUnavailableErrorBuilder
    implements
        Builder<UpstreamUnavailableError, UpstreamUnavailableErrorBuilder> {
  _$UpstreamUnavailableError? _$v;

  UpstreamUnavailableErrorNameEnum? _name;
  UpstreamUnavailableErrorNameEnum? get name => _$this._name;
  set name(UpstreamUnavailableErrorNameEnum? name) => _$this._name = name;

  UpstreamUnavailableErrorMessageEnum? _message;
  UpstreamUnavailableErrorMessageEnum? get message => _$this._message;
  set message(UpstreamUnavailableErrorMessageEnum? message) =>
      _$this._message = message;

  UpstreamUnavailableErrorHttpStatusCodeEnum? _httpStatusCode;
  UpstreamUnavailableErrorHttpStatusCodeEnum? get httpStatusCode =>
      _$this._httpStatusCode;
  set httpStatusCode(
    UpstreamUnavailableErrorHttpStatusCodeEnum? httpStatusCode,
  ) => _$this._httpStatusCode = httpStatusCode;

  String? _traceId;
  String? get traceId => _$this._traceId;
  set traceId(String? traceId) => _$this._traceId = traceId;

  ListBuilder<UnexpectedErrorDetailsInner>? _details;
  ListBuilder<UnexpectedErrorDetailsInner> get details =>
      _$this._details ??= ListBuilder<UnexpectedErrorDetailsInner>();
  set details(ListBuilder<UnexpectedErrorDetailsInner>? details) =>
      _$this._details = details;

  UpstreamUnavailableErrorBuilder() {
    UpstreamUnavailableError._defaults(this);
  }

  UpstreamUnavailableErrorBuilder get _$this {
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
  void replace(UpstreamUnavailableError other) {
    _$v = other as _$UpstreamUnavailableError;
  }

  @override
  void update(void Function(UpstreamUnavailableErrorBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  UpstreamUnavailableError build() => _build();

  _$UpstreamUnavailableError _build() {
    _$UpstreamUnavailableError _$result;
    try {
      _$result =
          _$v ??
          _$UpstreamUnavailableError._(
            name: BuiltValueNullFieldError.checkNotNull(
              name,
              r'UpstreamUnavailableError',
              'name',
            ),
            message: BuiltValueNullFieldError.checkNotNull(
              message,
              r'UpstreamUnavailableError',
              'message',
            ),
            httpStatusCode: BuiltValueNullFieldError.checkNotNull(
              httpStatusCode,
              r'UpstreamUnavailableError',
              'httpStatusCode',
            ),
            traceId: BuiltValueNullFieldError.checkNotNull(
              traceId,
              r'UpstreamUnavailableError',
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
          r'UpstreamUnavailableError',
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
