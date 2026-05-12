// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'payout.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

Payout _$PayoutFromJson(Map<String, dynamic> json) {
  return _Payout.fromJson(json);
}

/// @nodoc
mixin _$Payout {
  String get id => throw _privateConstructorUsedError;
  String get userId => throw _privateConstructorUsedError;
  String get competitionId => throw _privateConstructorUsedError;
  String? get prizeId => throw _privateConstructorUsedError;
  double get amountUsd => throw _privateConstructorUsedError;
  double get amountLocal => throw _privateConstructorUsedError;
  String get currency => throw _privateConstructorUsedError;
  double get exchangeRate => throw _privateConstructorUsedError;
  String get status => throw _privateConstructorUsedError;
  String? get validatedByAdminId => throw _privateConstructorUsedError;
  DateTime? get validatedAt => throw _privateConstructorUsedError;
  String? get validationJustification => throw _privateConstructorUsedError;
  Map<String, dynamic> get autoChecks => throw _privateConstructorUsedError;
  String? get payoutProvider => throw _privateConstructorUsedError;
  String? get payoutMethod => throw _privateConstructorUsedError;
  Map<String, dynamic> get payoutDestination =>
      throw _privateConstructorUsedError;
  String? get providerTransactionId => throw _privateConstructorUsedError;
  Map<String, dynamic> get providerResponse =>
      throw _privateConstructorUsedError;
  DateTime? get scheduledFor => throw _privateConstructorUsedError;
  DateTime? get completedAt => throw _privateConstructorUsedError;
  DateTime? get createdAt => throw _privateConstructorUsedError;
  DateTime? get updatedAt => throw _privateConstructorUsedError;

  /// Serializes this Payout to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Payout
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PayoutCopyWith<Payout> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PayoutCopyWith<$Res> {
  factory $PayoutCopyWith(Payout value, $Res Function(Payout) then) =
      _$PayoutCopyWithImpl<$Res, Payout>;
  @useResult
  $Res call(
      {String id,
      String userId,
      String competitionId,
      String? prizeId,
      double amountUsd,
      double amountLocal,
      String currency,
      double exchangeRate,
      String status,
      String? validatedByAdminId,
      DateTime? validatedAt,
      String? validationJustification,
      Map<String, dynamic> autoChecks,
      String? payoutProvider,
      String? payoutMethod,
      Map<String, dynamic> payoutDestination,
      String? providerTransactionId,
      Map<String, dynamic> providerResponse,
      DateTime? scheduledFor,
      DateTime? completedAt,
      DateTime? createdAt,
      DateTime? updatedAt});
}

/// @nodoc
class _$PayoutCopyWithImpl<$Res, $Val extends Payout>
    implements $PayoutCopyWith<$Res> {
  _$PayoutCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Payout
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? competitionId = null,
    Object? prizeId = freezed,
    Object? amountUsd = null,
    Object? amountLocal = null,
    Object? currency = null,
    Object? exchangeRate = null,
    Object? status = null,
    Object? validatedByAdminId = freezed,
    Object? validatedAt = freezed,
    Object? validationJustification = freezed,
    Object? autoChecks = null,
    Object? payoutProvider = freezed,
    Object? payoutMethod = freezed,
    Object? payoutDestination = null,
    Object? providerTransactionId = freezed,
    Object? providerResponse = null,
    Object? scheduledFor = freezed,
    Object? completedAt = freezed,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      competitionId: null == competitionId
          ? _value.competitionId
          : competitionId // ignore: cast_nullable_to_non_nullable
              as String,
      prizeId: freezed == prizeId
          ? _value.prizeId
          : prizeId // ignore: cast_nullable_to_non_nullable
              as String?,
      amountUsd: null == amountUsd
          ? _value.amountUsd
          : amountUsd // ignore: cast_nullable_to_non_nullable
              as double,
      amountLocal: null == amountLocal
          ? _value.amountLocal
          : amountLocal // ignore: cast_nullable_to_non_nullable
              as double,
      currency: null == currency
          ? _value.currency
          : currency // ignore: cast_nullable_to_non_nullable
              as String,
      exchangeRate: null == exchangeRate
          ? _value.exchangeRate
          : exchangeRate // ignore: cast_nullable_to_non_nullable
              as double,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      validatedByAdminId: freezed == validatedByAdminId
          ? _value.validatedByAdminId
          : validatedByAdminId // ignore: cast_nullable_to_non_nullable
              as String?,
      validatedAt: freezed == validatedAt
          ? _value.validatedAt
          : validatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      validationJustification: freezed == validationJustification
          ? _value.validationJustification
          : validationJustification // ignore: cast_nullable_to_non_nullable
              as String?,
      autoChecks: null == autoChecks
          ? _value.autoChecks
          : autoChecks // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
      payoutProvider: freezed == payoutProvider
          ? _value.payoutProvider
          : payoutProvider // ignore: cast_nullable_to_non_nullable
              as String?,
      payoutMethod: freezed == payoutMethod
          ? _value.payoutMethod
          : payoutMethod // ignore: cast_nullable_to_non_nullable
              as String?,
      payoutDestination: null == payoutDestination
          ? _value.payoutDestination
          : payoutDestination // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
      providerTransactionId: freezed == providerTransactionId
          ? _value.providerTransactionId
          : providerTransactionId // ignore: cast_nullable_to_non_nullable
              as String?,
      providerResponse: null == providerResponse
          ? _value.providerResponse
          : providerResponse // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
      scheduledFor: freezed == scheduledFor
          ? _value.scheduledFor
          : scheduledFor // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      completedAt: freezed == completedAt
          ? _value.completedAt
          : completedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      updatedAt: freezed == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$PayoutImplCopyWith<$Res> implements $PayoutCopyWith<$Res> {
  factory _$$PayoutImplCopyWith(
          _$PayoutImpl value, $Res Function(_$PayoutImpl) then) =
      __$$PayoutImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String userId,
      String competitionId,
      String? prizeId,
      double amountUsd,
      double amountLocal,
      String currency,
      double exchangeRate,
      String status,
      String? validatedByAdminId,
      DateTime? validatedAt,
      String? validationJustification,
      Map<String, dynamic> autoChecks,
      String? payoutProvider,
      String? payoutMethod,
      Map<String, dynamic> payoutDestination,
      String? providerTransactionId,
      Map<String, dynamic> providerResponse,
      DateTime? scheduledFor,
      DateTime? completedAt,
      DateTime? createdAt,
      DateTime? updatedAt});
}

/// @nodoc
class __$$PayoutImplCopyWithImpl<$Res>
    extends _$PayoutCopyWithImpl<$Res, _$PayoutImpl>
    implements _$$PayoutImplCopyWith<$Res> {
  __$$PayoutImplCopyWithImpl(
      _$PayoutImpl _value, $Res Function(_$PayoutImpl) _then)
      : super(_value, _then);

  /// Create a copy of Payout
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? competitionId = null,
    Object? prizeId = freezed,
    Object? amountUsd = null,
    Object? amountLocal = null,
    Object? currency = null,
    Object? exchangeRate = null,
    Object? status = null,
    Object? validatedByAdminId = freezed,
    Object? validatedAt = freezed,
    Object? validationJustification = freezed,
    Object? autoChecks = null,
    Object? payoutProvider = freezed,
    Object? payoutMethod = freezed,
    Object? payoutDestination = null,
    Object? providerTransactionId = freezed,
    Object? providerResponse = null,
    Object? scheduledFor = freezed,
    Object? completedAt = freezed,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
  }) {
    return _then(_$PayoutImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      competitionId: null == competitionId
          ? _value.competitionId
          : competitionId // ignore: cast_nullable_to_non_nullable
              as String,
      prizeId: freezed == prizeId
          ? _value.prizeId
          : prizeId // ignore: cast_nullable_to_non_nullable
              as String?,
      amountUsd: null == amountUsd
          ? _value.amountUsd
          : amountUsd // ignore: cast_nullable_to_non_nullable
              as double,
      amountLocal: null == amountLocal
          ? _value.amountLocal
          : amountLocal // ignore: cast_nullable_to_non_nullable
              as double,
      currency: null == currency
          ? _value.currency
          : currency // ignore: cast_nullable_to_non_nullable
              as String,
      exchangeRate: null == exchangeRate
          ? _value.exchangeRate
          : exchangeRate // ignore: cast_nullable_to_non_nullable
              as double,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      validatedByAdminId: freezed == validatedByAdminId
          ? _value.validatedByAdminId
          : validatedByAdminId // ignore: cast_nullable_to_non_nullable
              as String?,
      validatedAt: freezed == validatedAt
          ? _value.validatedAt
          : validatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      validationJustification: freezed == validationJustification
          ? _value.validationJustification
          : validationJustification // ignore: cast_nullable_to_non_nullable
              as String?,
      autoChecks: null == autoChecks
          ? _value._autoChecks
          : autoChecks // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
      payoutProvider: freezed == payoutProvider
          ? _value.payoutProvider
          : payoutProvider // ignore: cast_nullable_to_non_nullable
              as String?,
      payoutMethod: freezed == payoutMethod
          ? _value.payoutMethod
          : payoutMethod // ignore: cast_nullable_to_non_nullable
              as String?,
      payoutDestination: null == payoutDestination
          ? _value._payoutDestination
          : payoutDestination // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
      providerTransactionId: freezed == providerTransactionId
          ? _value.providerTransactionId
          : providerTransactionId // ignore: cast_nullable_to_non_nullable
              as String?,
      providerResponse: null == providerResponse
          ? _value._providerResponse
          : providerResponse // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
      scheduledFor: freezed == scheduledFor
          ? _value.scheduledFor
          : scheduledFor // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      completedAt: freezed == completedAt
          ? _value.completedAt
          : completedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      updatedAt: freezed == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$PayoutImpl extends _Payout {
  const _$PayoutImpl(
      {required this.id,
      required this.userId,
      required this.competitionId,
      this.prizeId,
      this.amountUsd = 0,
      this.amountLocal = 0,
      this.currency = 'XAF',
      this.exchangeRate = 1.0,
      this.status = 'pending',
      this.validatedByAdminId,
      this.validatedAt,
      this.validationJustification,
      final Map<String, dynamic> autoChecks = const <String, dynamic>{},
      this.payoutProvider,
      this.payoutMethod,
      final Map<String, dynamic> payoutDestination = const <String, dynamic>{},
      this.providerTransactionId,
      final Map<String, dynamic> providerResponse = const <String, dynamic>{},
      this.scheduledFor,
      this.completedAt,
      this.createdAt,
      this.updatedAt})
      : _autoChecks = autoChecks,
        _payoutDestination = payoutDestination,
        _providerResponse = providerResponse,
        super._();

  factory _$PayoutImpl.fromJson(Map<String, dynamic> json) =>
      _$$PayoutImplFromJson(json);

  @override
  final String id;
  @override
  final String userId;
  @override
  final String competitionId;
  @override
  final String? prizeId;
  @override
  @JsonKey()
  final double amountUsd;
  @override
  @JsonKey()
  final double amountLocal;
  @override
  @JsonKey()
  final String currency;
  @override
  @JsonKey()
  final double exchangeRate;
  @override
  @JsonKey()
  final String status;
  @override
  final String? validatedByAdminId;
  @override
  final DateTime? validatedAt;
  @override
  final String? validationJustification;
  final Map<String, dynamic> _autoChecks;
  @override
  @JsonKey()
  Map<String, dynamic> get autoChecks {
    if (_autoChecks is EqualUnmodifiableMapView) return _autoChecks;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_autoChecks);
  }

  @override
  final String? payoutProvider;
  @override
  final String? payoutMethod;
  final Map<String, dynamic> _payoutDestination;
  @override
  @JsonKey()
  Map<String, dynamic> get payoutDestination {
    if (_payoutDestination is EqualUnmodifiableMapView)
      return _payoutDestination;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_payoutDestination);
  }

  @override
  final String? providerTransactionId;
  final Map<String, dynamic> _providerResponse;
  @override
  @JsonKey()
  Map<String, dynamic> get providerResponse {
    if (_providerResponse is EqualUnmodifiableMapView) return _providerResponse;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_providerResponse);
  }

  @override
  final DateTime? scheduledFor;
  @override
  final DateTime? completedAt;
  @override
  final DateTime? createdAt;
  @override
  final DateTime? updatedAt;

  @override
  String toString() {
    return 'Payout(id: $id, userId: $userId, competitionId: $competitionId, prizeId: $prizeId, amountUsd: $amountUsd, amountLocal: $amountLocal, currency: $currency, exchangeRate: $exchangeRate, status: $status, validatedByAdminId: $validatedByAdminId, validatedAt: $validatedAt, validationJustification: $validationJustification, autoChecks: $autoChecks, payoutProvider: $payoutProvider, payoutMethod: $payoutMethod, payoutDestination: $payoutDestination, providerTransactionId: $providerTransactionId, providerResponse: $providerResponse, scheduledFor: $scheduledFor, completedAt: $completedAt, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PayoutImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.competitionId, competitionId) ||
                other.competitionId == competitionId) &&
            (identical(other.prizeId, prizeId) || other.prizeId == prizeId) &&
            (identical(other.amountUsd, amountUsd) ||
                other.amountUsd == amountUsd) &&
            (identical(other.amountLocal, amountLocal) ||
                other.amountLocal == amountLocal) &&
            (identical(other.currency, currency) ||
                other.currency == currency) &&
            (identical(other.exchangeRate, exchangeRate) ||
                other.exchangeRate == exchangeRate) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.validatedByAdminId, validatedByAdminId) ||
                other.validatedByAdminId == validatedByAdminId) &&
            (identical(other.validatedAt, validatedAt) ||
                other.validatedAt == validatedAt) &&
            (identical(
                    other.validationJustification, validationJustification) ||
                other.validationJustification == validationJustification) &&
            const DeepCollectionEquality()
                .equals(other._autoChecks, _autoChecks) &&
            (identical(other.payoutProvider, payoutProvider) ||
                other.payoutProvider == payoutProvider) &&
            (identical(other.payoutMethod, payoutMethod) ||
                other.payoutMethod == payoutMethod) &&
            const DeepCollectionEquality()
                .equals(other._payoutDestination, _payoutDestination) &&
            (identical(other.providerTransactionId, providerTransactionId) ||
                other.providerTransactionId == providerTransactionId) &&
            const DeepCollectionEquality()
                .equals(other._providerResponse, _providerResponse) &&
            (identical(other.scheduledFor, scheduledFor) ||
                other.scheduledFor == scheduledFor) &&
            (identical(other.completedAt, completedAt) ||
                other.completedAt == completedAt) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hashAll([
        runtimeType,
        id,
        userId,
        competitionId,
        prizeId,
        amountUsd,
        amountLocal,
        currency,
        exchangeRate,
        status,
        validatedByAdminId,
        validatedAt,
        validationJustification,
        const DeepCollectionEquality().hash(_autoChecks),
        payoutProvider,
        payoutMethod,
        const DeepCollectionEquality().hash(_payoutDestination),
        providerTransactionId,
        const DeepCollectionEquality().hash(_providerResponse),
        scheduledFor,
        completedAt,
        createdAt,
        updatedAt
      ]);

  /// Create a copy of Payout
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PayoutImplCopyWith<_$PayoutImpl> get copyWith =>
      __$$PayoutImplCopyWithImpl<_$PayoutImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$PayoutImplToJson(
      this,
    );
  }
}

abstract class _Payout extends Payout {
  const factory _Payout(
      {required final String id,
      required final String userId,
      required final String competitionId,
      final String? prizeId,
      final double amountUsd,
      final double amountLocal,
      final String currency,
      final double exchangeRate,
      final String status,
      final String? validatedByAdminId,
      final DateTime? validatedAt,
      final String? validationJustification,
      final Map<String, dynamic> autoChecks,
      final String? payoutProvider,
      final String? payoutMethod,
      final Map<String, dynamic> payoutDestination,
      final String? providerTransactionId,
      final Map<String, dynamic> providerResponse,
      final DateTime? scheduledFor,
      final DateTime? completedAt,
      final DateTime? createdAt,
      final DateTime? updatedAt}) = _$PayoutImpl;
  const _Payout._() : super._();

  factory _Payout.fromJson(Map<String, dynamic> json) = _$PayoutImpl.fromJson;

  @override
  String get id;
  @override
  String get userId;
  @override
  String get competitionId;
  @override
  String? get prizeId;
  @override
  double get amountUsd;
  @override
  double get amountLocal;
  @override
  String get currency;
  @override
  double get exchangeRate;
  @override
  String get status;
  @override
  String? get validatedByAdminId;
  @override
  DateTime? get validatedAt;
  @override
  String? get validationJustification;
  @override
  Map<String, dynamic> get autoChecks;
  @override
  String? get payoutProvider;
  @override
  String? get payoutMethod;
  @override
  Map<String, dynamic> get payoutDestination;
  @override
  String? get providerTransactionId;
  @override
  Map<String, dynamic> get providerResponse;
  @override
  DateTime? get scheduledFor;
  @override
  DateTime? get completedAt;
  @override
  DateTime? get createdAt;
  @override
  DateTime? get updatedAt;

  /// Create a copy of Payout
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PayoutImplCopyWith<_$PayoutImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
