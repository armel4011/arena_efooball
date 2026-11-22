// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'payout.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Payout {

 String get id; String get userId; String get competitionId; String? get prizeId; double get amountUsd; double get amountLocal; String get currency; double get exchangeRate; String get status; String? get validatedByAdminId; DateTime? get validatedAt; String? get validationJustification; Map<String, dynamic> get autoChecks; String? get payoutProvider; String? get payoutMethod; Map<String, dynamic> get payoutDestination; String? get providerTransactionId; Map<String, dynamic> get providerResponse; DateTime? get scheduledFor; DateTime? get completedAt; DateTime? get createdAt; DateTime? get updatedAt;
/// Create a copy of Payout
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PayoutCopyWith<Payout> get copyWith => _$PayoutCopyWithImpl<Payout>(this as Payout, _$identity);

  /// Serializes this Payout to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as Payout;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Payout&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.userId, _this.userId) || other.userId == _this.userId)&&(identical(other.competitionId, _this.competitionId) || other.competitionId == _this.competitionId)&&(identical(other.prizeId, _this.prizeId) || other.prizeId == _this.prizeId)&&(identical(other.amountUsd, _this.amountUsd) || other.amountUsd == _this.amountUsd)&&(identical(other.amountLocal, _this.amountLocal) || other.amountLocal == _this.amountLocal)&&(identical(other.currency, _this.currency) || other.currency == _this.currency)&&(identical(other.exchangeRate, _this.exchangeRate) || other.exchangeRate == _this.exchangeRate)&&(identical(other.status, _this.status) || other.status == _this.status)&&(identical(other.validatedByAdminId, _this.validatedByAdminId) || other.validatedByAdminId == _this.validatedByAdminId)&&(identical(other.validatedAt, _this.validatedAt) || other.validatedAt == _this.validatedAt)&&(identical(other.validationJustification, _this.validationJustification) || other.validationJustification == _this.validationJustification)&&const DeepCollectionEquality().equals(other.autoChecks, _this.autoChecks)&&(identical(other.payoutProvider, _this.payoutProvider) || other.payoutProvider == _this.payoutProvider)&&(identical(other.payoutMethod, _this.payoutMethod) || other.payoutMethod == _this.payoutMethod)&&const DeepCollectionEquality().equals(other.payoutDestination, _this.payoutDestination)&&(identical(other.providerTransactionId, _this.providerTransactionId) || other.providerTransactionId == _this.providerTransactionId)&&const DeepCollectionEquality().equals(other.providerResponse, _this.providerResponse)&&(identical(other.scheduledFor, _this.scheduledFor) || other.scheduledFor == _this.scheduledFor)&&(identical(other.completedAt, _this.completedAt) || other.completedAt == _this.completedAt)&&(identical(other.createdAt, _this.createdAt) || other.createdAt == _this.createdAt)&&(identical(other.updatedAt, _this.updatedAt) || other.updatedAt == _this.updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as Payout;
  return Object.hashAll([runtimeType,_this.id,_this.userId,_this.competitionId,_this.prizeId,_this.amountUsd,_this.amountLocal,_this.currency,_this.exchangeRate,_this.status,_this.validatedByAdminId,_this.validatedAt,_this.validationJustification,const DeepCollectionEquality().hash(_this.autoChecks),_this.payoutProvider,_this.payoutMethod,const DeepCollectionEquality().hash(_this.payoutDestination),_this.providerTransactionId,const DeepCollectionEquality().hash(_this.providerResponse),_this.scheduledFor,_this.completedAt,_this.createdAt,_this.updatedAt]);
}

@override
String toString() {
  final _this = this as Payout;
  return 'Payout(id: ${_this.id}, userId: ${_this.userId}, competitionId: ${_this.competitionId}, prizeId: ${_this.prizeId}, amountUsd: ${_this.amountUsd}, amountLocal: ${_this.amountLocal}, currency: ${_this.currency}, exchangeRate: ${_this.exchangeRate}, status: ${_this.status}, validatedByAdminId: ${_this.validatedByAdminId}, validatedAt: ${_this.validatedAt}, validationJustification: ${_this.validationJustification}, autoChecks: ${_this.autoChecks}, payoutProvider: ${_this.payoutProvider}, payoutMethod: ${_this.payoutMethod}, payoutDestination: ${_this.payoutDestination}, providerTransactionId: ${_this.providerTransactionId}, providerResponse: ${_this.providerResponse}, scheduledFor: ${_this.scheduledFor}, completedAt: ${_this.completedAt}, createdAt: ${_this.createdAt}, updatedAt: ${_this.updatedAt})';
}


}

/// @nodoc
abstract mixin class $PayoutCopyWith<$Res>  {
  factory $PayoutCopyWith(Payout value, $Res Function(Payout) _then) = _$PayoutCopyWithImpl;
@useResult
$Res call({
 String id, String userId, String competitionId, String? prizeId, double amountUsd, double amountLocal, String currency, double exchangeRate, String status, String? validatedByAdminId, DateTime? validatedAt, String? validationJustification, Map<String, dynamic> autoChecks, String? payoutProvider, String? payoutMethod, Map<String, dynamic> payoutDestination, String? providerTransactionId, Map<String, dynamic> providerResponse, DateTime? scheduledFor, DateTime? completedAt, DateTime? createdAt, DateTime? updatedAt
});




}
/// @nodoc
class _$PayoutCopyWithImpl<$Res>
    implements $PayoutCopyWith<$Res> {
  _$PayoutCopyWithImpl(this._self, this._then);

  final Payout _self;
  final $Res Function(Payout) _then;

/// Create a copy of Payout
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? userId = null,Object? competitionId = null,Object? prizeId = freezed,Object? amountUsd = null,Object? amountLocal = null,Object? currency = null,Object? exchangeRate = null,Object? status = null,Object? validatedByAdminId = freezed,Object? validatedAt = freezed,Object? validationJustification = freezed,Object? autoChecks = null,Object? payoutProvider = freezed,Object? payoutMethod = freezed,Object? payoutDestination = null,Object? providerTransactionId = freezed,Object? providerResponse = null,Object? scheduledFor = freezed,Object? completedAt = freezed,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(Payout(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,competitionId: null == competitionId ? _self.competitionId : competitionId // ignore: cast_nullable_to_non_nullable
as String,prizeId: freezed == prizeId ? _self.prizeId : prizeId // ignore: cast_nullable_to_non_nullable
as String?,amountUsd: null == amountUsd ? _self.amountUsd : amountUsd // ignore: cast_nullable_to_non_nullable
as double,amountLocal: null == amountLocal ? _self.amountLocal : amountLocal // ignore: cast_nullable_to_non_nullable
as double,currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String,exchangeRate: null == exchangeRate ? _self.exchangeRate : exchangeRate // ignore: cast_nullable_to_non_nullable
as double,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,validatedByAdminId: freezed == validatedByAdminId ? _self.validatedByAdminId : validatedByAdminId // ignore: cast_nullable_to_non_nullable
as String?,validatedAt: freezed == validatedAt ? _self.validatedAt : validatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,validationJustification: freezed == validationJustification ? _self.validationJustification : validationJustification // ignore: cast_nullable_to_non_nullable
as String?,autoChecks: null == autoChecks ? _self.autoChecks : autoChecks // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,payoutProvider: freezed == payoutProvider ? _self.payoutProvider : payoutProvider // ignore: cast_nullable_to_non_nullable
as String?,payoutMethod: freezed == payoutMethod ? _self.payoutMethod : payoutMethod // ignore: cast_nullable_to_non_nullable
as String?,payoutDestination: null == payoutDestination ? _self.payoutDestination : payoutDestination // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,providerTransactionId: freezed == providerTransactionId ? _self.providerTransactionId : providerTransactionId // ignore: cast_nullable_to_non_nullable
as String?,providerResponse: null == providerResponse ? _self.providerResponse : providerResponse // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,scheduledFor: freezed == scheduledFor ? _self.scheduledFor : scheduledFor // ignore: cast_nullable_to_non_nullable
as DateTime?,completedAt: freezed == completedAt ? _self.completedAt : completedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [Payout].
extension PayoutPatterns on Payout {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Payout value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Payout() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Payout value)  $default,){
final _that = this;
switch (_that) {
case _Payout():
return $default(_that);}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Payout value)?  $default,){
final _that = this;
switch (_that) {
case _Payout() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String userId,  String competitionId,  String? prizeId,  double amountUsd,  double amountLocal,  String currency,  double exchangeRate,  String status,  String? validatedByAdminId,  DateTime? validatedAt,  String? validationJustification,  Map<String, dynamic> autoChecks,  String? payoutProvider,  String? payoutMethod,  Map<String, dynamic> payoutDestination,  String? providerTransactionId,  Map<String, dynamic> providerResponse,  DateTime? scheduledFor,  DateTime? completedAt,  DateTime? createdAt,  DateTime? updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Payout() when $default != null:
return $default(_that.id,_that.userId,_that.competitionId,_that.prizeId,_that.amountUsd,_that.amountLocal,_that.currency,_that.exchangeRate,_that.status,_that.validatedByAdminId,_that.validatedAt,_that.validationJustification,_that.autoChecks,_that.payoutProvider,_that.payoutMethod,_that.payoutDestination,_that.providerTransactionId,_that.providerResponse,_that.scheduledFor,_that.completedAt,_that.createdAt,_that.updatedAt);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String userId,  String competitionId,  String? prizeId,  double amountUsd,  double amountLocal,  String currency,  double exchangeRate,  String status,  String? validatedByAdminId,  DateTime? validatedAt,  String? validationJustification,  Map<String, dynamic> autoChecks,  String? payoutProvider,  String? payoutMethod,  Map<String, dynamic> payoutDestination,  String? providerTransactionId,  Map<String, dynamic> providerResponse,  DateTime? scheduledFor,  DateTime? completedAt,  DateTime? createdAt,  DateTime? updatedAt)  $default,) {final _that = this;
switch (_that) {
case _Payout():
return $default(_that.id,_that.userId,_that.competitionId,_that.prizeId,_that.amountUsd,_that.amountLocal,_that.currency,_that.exchangeRate,_that.status,_that.validatedByAdminId,_that.validatedAt,_that.validationJustification,_that.autoChecks,_that.payoutProvider,_that.payoutMethod,_that.payoutDestination,_that.providerTransactionId,_that.providerResponse,_that.scheduledFor,_that.completedAt,_that.createdAt,_that.updatedAt);}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String userId,  String competitionId,  String? prizeId,  double amountUsd,  double amountLocal,  String currency,  double exchangeRate,  String status,  String? validatedByAdminId,  DateTime? validatedAt,  String? validationJustification,  Map<String, dynamic> autoChecks,  String? payoutProvider,  String? payoutMethod,  Map<String, dynamic> payoutDestination,  String? providerTransactionId,  Map<String, dynamic> providerResponse,  DateTime? scheduledFor,  DateTime? completedAt,  DateTime? createdAt,  DateTime? updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _Payout() when $default != null:
return $default(_that.id,_that.userId,_that.competitionId,_that.prizeId,_that.amountUsd,_that.amountLocal,_that.currency,_that.exchangeRate,_that.status,_that.validatedByAdminId,_that.validatedAt,_that.validationJustification,_that.autoChecks,_that.payoutProvider,_that.payoutMethod,_that.payoutDestination,_that.providerTransactionId,_that.providerResponse,_that.scheduledFor,_that.completedAt,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Payout extends Payout {
  const _Payout({required this.id, required this.userId, required this.competitionId, this.prizeId, this.amountUsd = 0, this.amountLocal = 0, this.currency = 'XAF', this.exchangeRate = 1.0, this.status = 'pending', this.validatedByAdminId, this.validatedAt, this.validationJustification,  Map<String, dynamic> autoChecks = const <String, dynamic>{}, this.payoutProvider, this.payoutMethod,  Map<String, dynamic> payoutDestination = const <String, dynamic>{}, this.providerTransactionId,  Map<String, dynamic> providerResponse = const <String, dynamic>{}, this.scheduledFor, this.completedAt, this.createdAt, this.updatedAt}): _autoChecks = autoChecks,_payoutDestination = payoutDestination,_providerResponse = providerResponse,super._();
  factory _Payout.fromJson(Map<String, dynamic> json) => _$PayoutFromJson(json);

@override final  String id;
@override final  String userId;
@override final  String competitionId;
@override final  String? prizeId;
@override@JsonKey() final  double amountUsd;
@override@JsonKey() final  double amountLocal;
@override@JsonKey() final  String currency;
@override@JsonKey() final  double exchangeRate;
@override@JsonKey() final  String status;
@override final  String? validatedByAdminId;
@override final  DateTime? validatedAt;
@override final  String? validationJustification;
 final  Map<String, dynamic> _autoChecks;
@override@JsonKey() Map<String, dynamic> get autoChecks {
  if (_autoChecks is EqualUnmodifiableMapView) return _autoChecks;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_autoChecks);
}

@override final  String? payoutProvider;
@override final  String? payoutMethod;
 final  Map<String, dynamic> _payoutDestination;
@override@JsonKey() Map<String, dynamic> get payoutDestination {
  if (_payoutDestination is EqualUnmodifiableMapView) return _payoutDestination;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_payoutDestination);
}

@override final  String? providerTransactionId;
 final  Map<String, dynamic> _providerResponse;
@override@JsonKey() Map<String, dynamic> get providerResponse {
  if (_providerResponse is EqualUnmodifiableMapView) return _providerResponse;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_providerResponse);
}

@override final  DateTime? scheduledFor;
@override final  DateTime? completedAt;
@override final  DateTime? createdAt;
@override final  DateTime? updatedAt;

/// Create a copy of Payout
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PayoutCopyWith<_Payout> get copyWith => __$PayoutCopyWithImpl<_Payout>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PayoutToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Payout&&(identical(other.id, id) || other.id == id)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.competitionId, competitionId) || other.competitionId == competitionId)&&(identical(other.prizeId, prizeId) || other.prizeId == prizeId)&&(identical(other.amountUsd, amountUsd) || other.amountUsd == amountUsd)&&(identical(other.amountLocal, amountLocal) || other.amountLocal == amountLocal)&&(identical(other.currency, currency) || other.currency == currency)&&(identical(other.exchangeRate, exchangeRate) || other.exchangeRate == exchangeRate)&&(identical(other.status, status) || other.status == status)&&(identical(other.validatedByAdminId, validatedByAdminId) || other.validatedByAdminId == validatedByAdminId)&&(identical(other.validatedAt, validatedAt) || other.validatedAt == validatedAt)&&(identical(other.validationJustification, validationJustification) || other.validationJustification == validationJustification)&&const DeepCollectionEquality().equals(other.autoChecks, _autoChecks)&&(identical(other.payoutProvider, payoutProvider) || other.payoutProvider == payoutProvider)&&(identical(other.payoutMethod, payoutMethod) || other.payoutMethod == payoutMethod)&&const DeepCollectionEquality().equals(other.payoutDestination, _payoutDestination)&&(identical(other.providerTransactionId, providerTransactionId) || other.providerTransactionId == providerTransactionId)&&const DeepCollectionEquality().equals(other.providerResponse, _providerResponse)&&(identical(other.scheduledFor, scheduledFor) || other.scheduledFor == scheduledFor)&&(identical(other.completedAt, completedAt) || other.completedAt == completedAt)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hashAll([runtimeType,id,userId,competitionId,prizeId,amountUsd,amountLocal,currency,exchangeRate,status,validatedByAdminId,validatedAt,validationJustification,const DeepCollectionEquality().hash(_autoChecks),payoutProvider,payoutMethod,const DeepCollectionEquality().hash(_payoutDestination),providerTransactionId,const DeepCollectionEquality().hash(_providerResponse),scheduledFor,completedAt,createdAt,updatedAt]);
}

@override
String toString() {
    return 'Payout(id: $id, userId: $userId, competitionId: $competitionId, prizeId: $prizeId, amountUsd: $amountUsd, amountLocal: $amountLocal, currency: $currency, exchangeRate: $exchangeRate, status: $status, validatedByAdminId: $validatedByAdminId, validatedAt: $validatedAt, validationJustification: $validationJustification, autoChecks: $autoChecks, payoutProvider: $payoutProvider, payoutMethod: $payoutMethod, payoutDestination: $payoutDestination, providerTransactionId: $providerTransactionId, providerResponse: $providerResponse, scheduledFor: $scheduledFor, completedAt: $completedAt, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$PayoutCopyWith<$Res> implements $PayoutCopyWith<$Res> {
  factory _$PayoutCopyWith(_Payout value, $Res Function(_Payout) _then) = __$PayoutCopyWithImpl;
@override @useResult
$Res call({
 String id, String userId, String competitionId, String? prizeId, double amountUsd, double amountLocal, String currency, double exchangeRate, String status, String? validatedByAdminId, DateTime? validatedAt, String? validationJustification, Map<String, dynamic> autoChecks, String? payoutProvider, String? payoutMethod, Map<String, dynamic> payoutDestination, String? providerTransactionId, Map<String, dynamic> providerResponse, DateTime? scheduledFor, DateTime? completedAt, DateTime? createdAt, DateTime? updatedAt
});




}
/// @nodoc
class __$PayoutCopyWithImpl<$Res>
    implements _$PayoutCopyWith<$Res> {
  __$PayoutCopyWithImpl(this._self, this._then);

  final _Payout _self;
  final $Res Function(_Payout) _then;

/// Create a copy of Payout
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? userId = null,Object? competitionId = null,Object? prizeId = freezed,Object? amountUsd = null,Object? amountLocal = null,Object? currency = null,Object? exchangeRate = null,Object? status = null,Object? validatedByAdminId = freezed,Object? validatedAt = freezed,Object? validationJustification = freezed,Object? autoChecks = null,Object? payoutProvider = freezed,Object? payoutMethod = freezed,Object? payoutDestination = null,Object? providerTransactionId = freezed,Object? providerResponse = null,Object? scheduledFor = freezed,Object? completedAt = freezed,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_Payout(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,competitionId: null == competitionId ? _self.competitionId : competitionId // ignore: cast_nullable_to_non_nullable
as String,prizeId: freezed == prizeId ? _self.prizeId : prizeId // ignore: cast_nullable_to_non_nullable
as String?,amountUsd: null == amountUsd ? _self.amountUsd : amountUsd // ignore: cast_nullable_to_non_nullable
as double,amountLocal: null == amountLocal ? _self.amountLocal : amountLocal // ignore: cast_nullable_to_non_nullable
as double,currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String,exchangeRate: null == exchangeRate ? _self.exchangeRate : exchangeRate // ignore: cast_nullable_to_non_nullable
as double,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,validatedByAdminId: freezed == validatedByAdminId ? _self.validatedByAdminId : validatedByAdminId // ignore: cast_nullable_to_non_nullable
as String?,validatedAt: freezed == validatedAt ? _self.validatedAt : validatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,validationJustification: freezed == validationJustification ? _self.validationJustification : validationJustification // ignore: cast_nullable_to_non_nullable
as String?,autoChecks: null == autoChecks ? _self._autoChecks : autoChecks // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,payoutProvider: freezed == payoutProvider ? _self.payoutProvider : payoutProvider // ignore: cast_nullable_to_non_nullable
as String?,payoutMethod: freezed == payoutMethod ? _self.payoutMethod : payoutMethod // ignore: cast_nullable_to_non_nullable
as String?,payoutDestination: null == payoutDestination ? _self._payoutDestination : payoutDestination // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,providerTransactionId: freezed == providerTransactionId ? _self.providerTransactionId : providerTransactionId // ignore: cast_nullable_to_non_nullable
as String?,providerResponse: null == providerResponse ? _self._providerResponse : providerResponse // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,scheduledFor: freezed == scheduledFor ? _self.scheduledFor : scheduledFor // ignore: cast_nullable_to_non_nullable
as DateTime?,completedAt: freezed == completedAt ? _self.completedAt : completedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
