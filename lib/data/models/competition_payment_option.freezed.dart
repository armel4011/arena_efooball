// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'competition_payment_option.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$CompetitionPaymentOption {

 String get id; String get competitionId; String get countryCode; String get operatorLabel; String get transferCode;/// Indicatif E.164 du pays (ex. `'+237'`) — pré-remplit le champ numéro
/// côté joueur (P2). Peut être null (repli sur `dialCodeFor(countryCode)`).
 String? get dialCode;/// Numéro destinataire du paiement Mobile Money (à copier par le joueur,
/// zone CEMAC). Distinct du code USSD (`transferCode`). Optionnel.
 String? get paymentNumber;/// Collecteur de paiement rattaché à ce numéro (quota + blocage). `null` =
/// numéro libre (Cameroun historique), jamais bloqué.
 String? get collectorId; int get sortOrder; DateTime? get createdAt;/// Disponibilité calculée au CHECKOUT (RPC `competition_checkout_payment_
/// options`) : `false` = collecteur bloqué/inactif → option masquée. Non
/// persisté (défaut `true` pour les lectures admin).
 bool get available;
/// Create a copy of CompetitionPaymentOption
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CompetitionPaymentOptionCopyWith<CompetitionPaymentOption> get copyWith => _$CompetitionPaymentOptionCopyWithImpl<CompetitionPaymentOption>(this as CompetitionPaymentOption, _$identity);

  /// Serializes this CompetitionPaymentOption to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as CompetitionPaymentOption;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CompetitionPaymentOption&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.competitionId, _this.competitionId) || other.competitionId == _this.competitionId)&&(identical(other.countryCode, _this.countryCode) || other.countryCode == _this.countryCode)&&(identical(other.operatorLabel, _this.operatorLabel) || other.operatorLabel == _this.operatorLabel)&&(identical(other.transferCode, _this.transferCode) || other.transferCode == _this.transferCode)&&(identical(other.dialCode, _this.dialCode) || other.dialCode == _this.dialCode)&&(identical(other.paymentNumber, _this.paymentNumber) || other.paymentNumber == _this.paymentNumber)&&(identical(other.collectorId, _this.collectorId) || other.collectorId == _this.collectorId)&&(identical(other.sortOrder, _this.sortOrder) || other.sortOrder == _this.sortOrder)&&(identical(other.createdAt, _this.createdAt) || other.createdAt == _this.createdAt)&&(identical(other.available, _this.available) || other.available == _this.available));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as CompetitionPaymentOption;
  return Object.hash(runtimeType,_this.id,_this.competitionId,_this.countryCode,_this.operatorLabel,_this.transferCode,_this.dialCode,_this.paymentNumber,_this.collectorId,_this.sortOrder,_this.createdAt,_this.available);
}

@override
String toString() {
  final _this = this as CompetitionPaymentOption;
  return 'CompetitionPaymentOption(id: ${_this.id}, competitionId: ${_this.competitionId}, countryCode: ${_this.countryCode}, operatorLabel: ${_this.operatorLabel}, transferCode: ${_this.transferCode}, dialCode: ${_this.dialCode}, paymentNumber: ${_this.paymentNumber}, collectorId: ${_this.collectorId}, sortOrder: ${_this.sortOrder}, createdAt: ${_this.createdAt}, available: ${_this.available})';
}


}

/// @nodoc
abstract mixin class $CompetitionPaymentOptionCopyWith<$Res>  {
  factory $CompetitionPaymentOptionCopyWith(CompetitionPaymentOption value, $Res Function(CompetitionPaymentOption) _then) = _$CompetitionPaymentOptionCopyWithImpl;
@useResult
$Res call({
 String id, String competitionId, String countryCode, String operatorLabel, String transferCode, String? dialCode, String? paymentNumber, String? collectorId, int sortOrder, DateTime? createdAt, bool available
});




}
/// @nodoc
class _$CompetitionPaymentOptionCopyWithImpl<$Res>
    implements $CompetitionPaymentOptionCopyWith<$Res> {
  _$CompetitionPaymentOptionCopyWithImpl(this._self, this._then);

  final CompetitionPaymentOption _self;
  final $Res Function(CompetitionPaymentOption) _then;

/// Create a copy of CompetitionPaymentOption
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? competitionId = null,Object? countryCode = null,Object? operatorLabel = null,Object? transferCode = null,Object? dialCode = freezed,Object? paymentNumber = freezed,Object? collectorId = freezed,Object? sortOrder = null,Object? createdAt = freezed,Object? available = null,}) {
  return _then(CompetitionPaymentOption(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,competitionId: null == competitionId ? _self.competitionId : competitionId // ignore: cast_nullable_to_non_nullable
as String,countryCode: null == countryCode ? _self.countryCode : countryCode // ignore: cast_nullable_to_non_nullable
as String,operatorLabel: null == operatorLabel ? _self.operatorLabel : operatorLabel // ignore: cast_nullable_to_non_nullable
as String,transferCode: null == transferCode ? _self.transferCode : transferCode // ignore: cast_nullable_to_non_nullable
as String,dialCode: freezed == dialCode ? _self.dialCode : dialCode // ignore: cast_nullable_to_non_nullable
as String?,paymentNumber: freezed == paymentNumber ? _self.paymentNumber : paymentNumber // ignore: cast_nullable_to_non_nullable
as String?,collectorId: freezed == collectorId ? _self.collectorId : collectorId // ignore: cast_nullable_to_non_nullable
as String?,sortOrder: null == sortOrder ? _self.sortOrder : sortOrder // ignore: cast_nullable_to_non_nullable
as int,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,available: null == available ? _self.available : available // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [CompetitionPaymentOption].
extension CompetitionPaymentOptionPatterns on CompetitionPaymentOption {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CompetitionPaymentOption value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CompetitionPaymentOption() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CompetitionPaymentOption value)  $default,){
final _that = this;
switch (_that) {
case _CompetitionPaymentOption():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CompetitionPaymentOption value)?  $default,){
final _that = this;
switch (_that) {
case _CompetitionPaymentOption() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String competitionId,  String countryCode,  String operatorLabel,  String transferCode,  String? dialCode,  String? paymentNumber,  String? collectorId,  int sortOrder,  DateTime? createdAt,  bool available)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CompetitionPaymentOption() when $default != null:
return $default(_that.id,_that.competitionId,_that.countryCode,_that.operatorLabel,_that.transferCode,_that.dialCode,_that.paymentNumber,_that.collectorId,_that.sortOrder,_that.createdAt,_that.available);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String competitionId,  String countryCode,  String operatorLabel,  String transferCode,  String? dialCode,  String? paymentNumber,  String? collectorId,  int sortOrder,  DateTime? createdAt,  bool available)  $default,) {final _that = this;
switch (_that) {
case _CompetitionPaymentOption():
return $default(_that.id,_that.competitionId,_that.countryCode,_that.operatorLabel,_that.transferCode,_that.dialCode,_that.paymentNumber,_that.collectorId,_that.sortOrder,_that.createdAt,_that.available);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String competitionId,  String countryCode,  String operatorLabel,  String transferCode,  String? dialCode,  String? paymentNumber,  String? collectorId,  int sortOrder,  DateTime? createdAt,  bool available)?  $default,) {final _that = this;
switch (_that) {
case _CompetitionPaymentOption() when $default != null:
return $default(_that.id,_that.competitionId,_that.countryCode,_that.operatorLabel,_that.transferCode,_that.dialCode,_that.paymentNumber,_that.collectorId,_that.sortOrder,_that.createdAt,_that.available);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CompetitionPaymentOption extends CompetitionPaymentOption {
  const _CompetitionPaymentOption({required this.id, required this.competitionId, required this.countryCode, required this.operatorLabel, required this.transferCode, this.dialCode, this.paymentNumber, this.collectorId, this.sortOrder = 0, this.createdAt, this.available = true}): super._();
  factory _CompetitionPaymentOption.fromJson(Map<String, dynamic> json) => _$CompetitionPaymentOptionFromJson(json);

@override final  String id;
@override final  String competitionId;
@override final  String countryCode;
@override final  String operatorLabel;
@override final  String transferCode;
/// Indicatif E.164 du pays (ex. `'+237'`) — pré-remplit le champ numéro
/// côté joueur (P2). Peut être null (repli sur `dialCodeFor(countryCode)`).
@override final  String? dialCode;
/// Numéro destinataire du paiement Mobile Money (à copier par le joueur,
/// zone CEMAC). Distinct du code USSD (`transferCode`). Optionnel.
@override final  String? paymentNumber;
/// Collecteur de paiement rattaché à ce numéro (quota + blocage). `null` =
/// numéro libre (Cameroun historique), jamais bloqué.
@override final  String? collectorId;
@override@JsonKey() final  int sortOrder;
@override final  DateTime? createdAt;
/// Disponibilité calculée au CHECKOUT (RPC `competition_checkout_payment_
/// options`) : `false` = collecteur bloqué/inactif → option masquée. Non
/// persisté (défaut `true` pour les lectures admin).
@override@JsonKey() final  bool available;

/// Create a copy of CompetitionPaymentOption
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CompetitionPaymentOptionCopyWith<_CompetitionPaymentOption> get copyWith => __$CompetitionPaymentOptionCopyWithImpl<_CompetitionPaymentOption>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CompetitionPaymentOptionToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _CompetitionPaymentOption&&(identical(other.id, id) || other.id == id)&&(identical(other.competitionId, competitionId) || other.competitionId == competitionId)&&(identical(other.countryCode, countryCode) || other.countryCode == countryCode)&&(identical(other.operatorLabel, operatorLabel) || other.operatorLabel == operatorLabel)&&(identical(other.transferCode, transferCode) || other.transferCode == transferCode)&&(identical(other.dialCode, dialCode) || other.dialCode == dialCode)&&(identical(other.paymentNumber, paymentNumber) || other.paymentNumber == paymentNumber)&&(identical(other.collectorId, collectorId) || other.collectorId == collectorId)&&(identical(other.sortOrder, sortOrder) || other.sortOrder == sortOrder)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.available, available) || other.available == available));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,competitionId,countryCode,operatorLabel,transferCode,dialCode,paymentNumber,collectorId,sortOrder,createdAt,available);
}

@override
String toString() {
    return 'CompetitionPaymentOption(id: $id, competitionId: $competitionId, countryCode: $countryCode, operatorLabel: $operatorLabel, transferCode: $transferCode, dialCode: $dialCode, paymentNumber: $paymentNumber, collectorId: $collectorId, sortOrder: $sortOrder, createdAt: $createdAt, available: $available)';
}


}

/// @nodoc
abstract mixin class _$CompetitionPaymentOptionCopyWith<$Res> implements $CompetitionPaymentOptionCopyWith<$Res> {
  factory _$CompetitionPaymentOptionCopyWith(_CompetitionPaymentOption value, $Res Function(_CompetitionPaymentOption) _then) = __$CompetitionPaymentOptionCopyWithImpl;
@override @useResult
$Res call({
 String id, String competitionId, String countryCode, String operatorLabel, String transferCode, String? dialCode, String? paymentNumber, String? collectorId, int sortOrder, DateTime? createdAt, bool available
});




}
/// @nodoc
class __$CompetitionPaymentOptionCopyWithImpl<$Res>
    implements _$CompetitionPaymentOptionCopyWith<$Res> {
  __$CompetitionPaymentOptionCopyWithImpl(this._self, this._then);

  final _CompetitionPaymentOption _self;
  final $Res Function(_CompetitionPaymentOption) _then;

/// Create a copy of CompetitionPaymentOption
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? competitionId = null,Object? countryCode = null,Object? operatorLabel = null,Object? transferCode = null,Object? dialCode = freezed,Object? paymentNumber = freezed,Object? collectorId = freezed,Object? sortOrder = null,Object? createdAt = freezed,Object? available = null,}) {
  return _then(_CompetitionPaymentOption(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,competitionId: null == competitionId ? _self.competitionId : competitionId // ignore: cast_nullable_to_non_nullable
as String,countryCode: null == countryCode ? _self.countryCode : countryCode // ignore: cast_nullable_to_non_nullable
as String,operatorLabel: null == operatorLabel ? _self.operatorLabel : operatorLabel // ignore: cast_nullable_to_non_nullable
as String,transferCode: null == transferCode ? _self.transferCode : transferCode // ignore: cast_nullable_to_non_nullable
as String,dialCode: freezed == dialCode ? _self.dialCode : dialCode // ignore: cast_nullable_to_non_nullable
as String?,paymentNumber: freezed == paymentNumber ? _self.paymentNumber : paymentNumber // ignore: cast_nullable_to_non_nullable
as String?,collectorId: freezed == collectorId ? _self.collectorId : collectorId // ignore: cast_nullable_to_non_nullable
as String?,sortOrder: null == sortOrder ? _self.sortOrder : sortOrder // ignore: cast_nullable_to_non_nullable
as int,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,available: null == available ? _self.available : available // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
