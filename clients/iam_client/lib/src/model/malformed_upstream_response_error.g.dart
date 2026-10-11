// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'malformed_upstream_response_error.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const MalformedUpstreamResponseErrorNameEnum
_$malformedUpstreamResponseErrorNameEnum_malformedUpstreamResponseError =
    const MalformedUpstreamResponseErrorNameEnum._(
      'malformedUpstreamResponseError',
    );

MalformedUpstreamResponseErrorNameEnum
_$malformedUpstreamResponseErrorNameEnumValueOf(String name) {
  switch (name) {
    case 'malformedUpstreamResponseError':
      return _$malformedUpstreamResponseErrorNameEnum_malformedUpstreamResponseError;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<MalformedUpstreamResponseErrorNameEnum>
_$malformedUpstreamResponseErrorNameEnumValues =
    BuiltSet<MalformedUpstreamResponseErrorNameEnum>(
      const <MalformedUpstreamResponseErrorNameEnum>[
        _$malformedUpstreamResponseErrorNameEnum_malformedUpstreamResponseError,
      ],
    );

const MalformedUpstreamResponseErrorMessageEnum
_$malformedUpstreamResponseErrorMessageEnum_theUpstreamIdentityServiceReturnedAnUnexpectedResponsePeriod =
    const MalformedUpstreamResponseErrorMessageEnum._(
      'theUpstreamIdentityServiceReturnedAnUnexpectedResponsePeriod',
    );

MalformedUpstreamResponseErrorMessageEnum
_$malformedUpstreamResponseErrorMessageEnumValueOf(String name) {
  switch (name) {
    case 'theUpstreamIdentityServiceReturnedAnUnexpectedResponsePeriod':
      return _$malformedUpstreamResponseErrorMessageEnum_theUpstreamIdentityServiceReturnedAnUnexpectedResponsePeriod;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<MalformedUpstreamResponseErrorMessageEnum>
_$malformedUpstreamResponseErrorMessageEnumValues =
    BuiltSet<MalformedUpstreamResponseErrorMessageEnum>(const <
      MalformedUpstreamResponseErrorMessageEnum
    >[
      _$malformedUpstreamResponseErrorMessageEnum_theUpstreamIdentityServiceReturnedAnUnexpectedResponsePeriod,
    ]);

const MalformedUpstreamResponseErrorHttpStatusCodeEnum
_$malformedUpstreamResponseErrorHttpStatusCodeEnum_number422 =
    const MalformedUpstreamResponseErrorHttpStatusCodeEnum._('number422');

MalformedUpstreamResponseErrorHttpStatusCodeEnum
_$malformedUpstreamResponseErrorHttpStatusCodeEnumValueOf(String name) {
  switch (name) {
    case 'number422':
      return _$malformedUpstreamResponseErrorHttpStatusCodeEnum_number422;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<MalformedUpstreamResponseErrorHttpStatusCodeEnum>
_$malformedUpstreamResponseErrorHttpStatusCodeEnumValues =
    BuiltSet<MalformedUpstreamResponseErrorHttpStatusCodeEnum>(
      const <MalformedUpstreamResponseErrorHttpStatusCodeEnum>[
        _$malformedUpstreamResponseErrorHttpStatusCodeEnum_number422,
      ],
    );

Serializer<MalformedUpstreamResponseErrorNameEnum>
_$malformedUpstreamResponseErrorNameEnumSerializer =
    _$MalformedUpstreamResponseErrorNameEnumSerializer();
Serializer<MalformedUpstreamResponseErrorMessageEnum>
_$malformedUpstreamResponseErrorMessageEnumSerializer =
    _$MalformedUpstreamResponseErrorMessageEnumSerializer();
Serializer<MalformedUpstreamResponseErrorHttpStatusCodeEnum>
_$malformedUpstreamResponseErrorHttpStatusCodeEnumSerializer =
    _$MalformedUpstreamResponseErrorHttpStatusCodeEnumSerializer();

class _$MalformedUpstreamResponseErrorNameEnumSerializer
    implements PrimitiveSerializer<MalformedUpstreamResponseErrorNameEnum> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'malformedUpstreamResponseError': 'MalformedUpstreamResponseError',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'MalformedUpstreamResponseError': 'malformedUpstreamResponseError',
  };

  @override
  final Iterable<Type> types = const <Type>[
    MalformedUpstreamResponseErrorNameEnum,
  ];
  @override
  final String wireName = 'MalformedUpstreamResponseErrorNameEnum';

  @override
  Object serialize(
    Serializers serializers,
    MalformedUpstreamResponseErrorNameEnum object, {
    FullType specifiedType = FullType.unspecified,
  }) => _toWire[object.name] ?? object.name;

  @override
  MalformedUpstreamResponseErrorNameEnum deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => MalformedUpstreamResponseErrorNameEnum.valueOf(
    _fromWire[serialized] ?? (serialized is String ? serialized : ''),
  );
}

class _$MalformedUpstreamResponseErrorMessageEnumSerializer
    implements PrimitiveSerializer<MalformedUpstreamResponseErrorMessageEnum> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'theUpstreamIdentityServiceReturnedAnUnexpectedResponsePeriod':
        'The upstream identity service returned an unexpected response.',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'The upstream identity service returned an unexpected response.':
        'theUpstreamIdentityServiceReturnedAnUnexpectedResponsePeriod',
  };

  @override
  final Iterable<Type> types = const <Type>[
    MalformedUpstreamResponseErrorMessageEnum,
  ];
  @override
  final String wireName = 'MalformedUpstreamResponseErrorMessageEnum';

  @override
  Object serialize(
    Serializers serializers,
    MalformedUpstreamResponseErrorMessageEnum object, {
    FullType specifiedType = FullType.unspecified,
  }) => _toWire[object.name] ?? object.name;

  @override
  MalformedUpstreamResponseErrorMessageEnum deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => MalformedUpstreamResponseErrorMessageEnum.valueOf(
    _fromWire[serialized] ?? (serialized is String ? serialized : ''),
  );
}

class _$MalformedUpstreamResponseErrorHttpStatusCodeEnumSerializer
    implements
        PrimitiveSerializer<MalformedUpstreamResponseErrorHttpStatusCodeEnum> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'number422': 422,
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    422: 'number422',
  };

  @override
  final Iterable<Type> types = const <Type>[
    MalformedUpstreamResponseErrorHttpStatusCodeEnum,
  ];
  @override
  final String wireName = 'MalformedUpstreamResponseErrorHttpStatusCodeEnum';

  @override
  Object serialize(
    Serializers serializers,
    MalformedUpstreamResponseErrorHttpStatusCodeEnum object, {
    FullType specifiedType = FullType.unspecified,
  }) => _toWire[object.name] ?? object.name;

  @override
  MalformedUpstreamResponseErrorHttpStatusCodeEnum deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => MalformedUpstreamResponseErrorHttpStatusCodeEnum.valueOf(
    _fromWire[serialized] ?? (serialized is String ? serialized : ''),
  );
}

class _$MalformedUpstreamResponseError extends MalformedUpstreamResponseError {
  @override
  final MalformedUpstreamResponseErrorNameEnum name;
  @override
  final MalformedUpstreamResponseErrorMessageEnum message;
  @override
  final MalformedUpstreamResponseErrorHttpStatusCodeEnum httpStatusCode;
  @override
  final String traceId;
  @override
  final BuiltList<UnexpectedErrorDetailsInner>? details;

  factory _$MalformedUpstreamResponseError([
    void Function(MalformedUpstreamResponseErrorBuilder)? updates,
  ]) => (MalformedUpstreamResponseErrorBuilder()..update(updates))._build();

  _$MalformedUpstreamResponseError._({
    required this.name,
    required this.message,
    required this.httpStatusCode,
    required this.traceId,
    this.details,
  }) : super._();
  @override
  MalformedUpstreamResponseError rebuild(
    void Function(MalformedUpstreamResponseErrorBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  MalformedUpstreamResponseErrorBuilder toBuilder() =>
      MalformedUpstreamResponseErrorBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is MalformedUpstreamResponseError &&
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
    return (newBuiltValueToStringHelper(r'MalformedUpstreamResponseError')
          ..add('name', name)
          ..add('message', message)
          ..add('httpStatusCode', httpStatusCode)
          ..add('traceId', traceId)
          ..add('details', details))
        .toString();
  }
}

class MalformedUpstreamResponseErrorBuilder
    implements
        Builder<
          MalformedUpstreamResponseError,
          MalformedUpstreamResponseErrorBuilder
        > {
  _$MalformedUpstreamResponseError? _$v;

  MalformedUpstreamResponseErrorNameEnum? _name;
  MalformedUpstreamResponseErrorNameEnum? get name => _$this._name;
  set name(MalformedUpstreamResponseErrorNameEnum? name) => _$this._name = name;

  MalformedUpstreamResponseErrorMessageEnum? _message;
  MalformedUpstreamResponseErrorMessageEnum? get message => _$this._message;
  set message(MalformedUpstreamResponseErrorMessageEnum? message) =>
      _$this._message = message;

  MalformedUpstreamResponseErrorHttpStatusCodeEnum? _httpStatusCode;
  MalformedUpstreamResponseErrorHttpStatusCodeEnum? get httpStatusCode =>
      _$this._httpStatusCode;
  set httpStatusCode(
    MalformedUpstreamResponseErrorHttpStatusCodeEnum? httpStatusCode,
  ) => _$this._httpStatusCode = httpStatusCode;

  String? _traceId;
  String? get traceId => _$this._traceId;
  set traceId(String? traceId) => _$this._traceId = traceId;

  ListBuilder<UnexpectedErrorDetailsInner>? _details;
  ListBuilder<UnexpectedErrorDetailsInner> get details =>
      _$this._details ??= ListBuilder<UnexpectedErrorDetailsInner>();
  set details(ListBuilder<UnexpectedErrorDetailsInner>? details) =>
      _$this._details = details;

  MalformedUpstreamResponseErrorBuilder() {
    MalformedUpstreamResponseError._defaults(this);
  }

  MalformedUpstreamResponseErrorBuilder get _$this {
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
  void replace(MalformedUpstreamResponseError other) {
    _$v = other as _$MalformedUpstreamResponseError;
  }

  @override
  void update(void Function(MalformedUpstreamResponseErrorBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  MalformedUpstreamResponseError build() => _build();

  _$MalformedUpstreamResponseError _build() {
    _$MalformedUpstreamResponseError _$result;
    try {
      _$result =
          _$v ??
          _$MalformedUpstreamResponseError._(
            name: BuiltValueNullFieldError.checkNotNull(
              name,
              r'MalformedUpstreamResponseError',
              'name',
            ),
            message: BuiltValueNullFieldError.checkNotNull(
              message,
              r'MalformedUpstreamResponseError',
              'message',
            ),
            httpStatusCode: BuiltValueNullFieldError.checkNotNull(
              httpStatusCode,
              r'MalformedUpstreamResponseError',
              'httpStatusCode',
            ),
            traceId: BuiltValueNullFieldError.checkNotNull(
              traceId,
              r'MalformedUpstreamResponseError',
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
          r'MalformedUpstreamResponseError',
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
