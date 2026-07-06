// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'competition_payment_option.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

CompetitionPaymentOption _$CompetitionPaymentOptionFromJson(
    Map<String, dynamic> json) {
  return _CompetitionPaymentOption.fromJson(json);
}

/// @nodoc
mixin _$CompetitionPaymentOption {
  String get id => throw _privateConstructorUsedError;
  String get competitionId => throw _privateConstructorUsedError;
  String get countryCode => throw _privateConstructorUsedError;
  String get operatorLabel => throw _privateConstructorUsedError;
  String get transferCode => throw _privateConstructorUsedError;

  /// Indicatif E.164 du pays (ex. `'+237'`) — pré-remplit le champ numéro
  /// côté joueur (P2). Peut être null (repli sur `dialCodeFor(countryCode)`).
  String? get dialCode => throw _privateConstructorUsedError;
  int get sortOrder => throw _privateConstructorUsedError;
  DateTime? get createdAt => throw _privateConstructorUsedError;

  /// Serializes this CompetitionPaymentOption to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of CompetitionPaymentOption
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CompetitionPaymentOptionCopyWith<CompetitionPaymentOption> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CompetitionPaymentOptionCopyWith<$Res> {
  factory $CompetitionPaymentOptionCopyWith(CompetitionPaymentOption value,
          $Res Function(CompetitionPaymentOption) then) =
      _$CompetitionPaymentOptionCopyWithImpl<$Res, CompetitionPaymentOption>;
  @useResult
  $Res call(
      {String id,
      String competitionId,
      String countryCode,
      String operatorLabel,
      String transferCode,
      String? dialCode,
      int sortOrder,
      DateTime? createdAt});
}

/// @nodoc
class _$CompetitionPaymentOptionCopyWithImpl<$Res,
        $Val extends CompetitionPaymentOption>
    implements $CompetitionPaymentOptionCopyWith<$Res> {
  _$CompetitionPaymentOptionCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of CompetitionPaymentOption
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? competitionId = null,
    Object? countryCode = null,
    Object? operatorLabel = null,
    Object? transferCode = null,
    Object? dialCode = freezed,
    Object? sortOrder = null,
    Object? createdAt = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      competitionId: null == competitionId
          ? _value.competitionId
          : competitionId // ignore: cast_nullable_to_non_nullable
              as String,
      countryCode: null == countryCode
          ? _value.countryCode
          : countryCode // ignore: cast_nullable_to_non_nullable
              as String,
      operatorLabel: null == operatorLabel
          ? _value.operatorLabel
          : operatorLabel // ignore: cast_nullable_to_non_nullable
              as String,
      transferCode: null == transferCode
          ? _value.transferCode
          : transferCode // ignore: cast_nullable_to_non_nullable
              as String,
      dialCode: freezed == dialCode
          ? _value.dialCode
          : dialCode // ignore: cast_nullable_to_non_nullable
              as String?,
      sortOrder: null == sortOrder
          ? _value.sortOrder
          : sortOrder // ignore: cast_nullable_to_non_nullable
              as int,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$CompetitionPaymentOptionImplCopyWith<$Res>
    implements $CompetitionPaymentOptionCopyWith<$Res> {
  factory _$$CompetitionPaymentOptionImplCopyWith(
          _$CompetitionPaymentOptionImpl value,
          $Res Function(_$CompetitionPaymentOptionImpl) then) =
      __$$CompetitionPaymentOptionImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String competitionId,
      String countryCode,
      String operatorLabel,
      String transferCode,
      String? dialCode,
      int sortOrder,
      DateTime? createdAt});
}

/// @nodoc
class __$$CompetitionPaymentOptionImplCopyWithImpl<$Res>
    extends _$CompetitionPaymentOptionCopyWithImpl<$Res,
        _$CompetitionPaymentOptionImpl>
    implements _$$CompetitionPaymentOptionImplCopyWith<$Res> {
  __$$CompetitionPaymentOptionImplCopyWithImpl(
      _$CompetitionPaymentOptionImpl _value,
      $Res Function(_$CompetitionPaymentOptionImpl) _then)
      : super(_value, _then);

  /// Create a copy of CompetitionPaymentOption
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? competitionId = null,
    Object? countryCode = null,
    Object? operatorLabel = null,
    Object? transferCode = null,
    Object? dialCode = freezed,
    Object? sortOrder = null,
    Object? createdAt = freezed,
  }) {
    return _then(_$CompetitionPaymentOptionImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      competitionId: null == competitionId
          ? _value.competitionId
          : competitionId // ignore: cast_nullable_to_non_nullable
              as String,
      countryCode: null == countryCode
          ? _value.countryCode
          : countryCode // ignore: cast_nullable_to_non_nullable
              as String,
      operatorLabel: null == operatorLabel
          ? _value.operatorLabel
          : operatorLabel // ignore: cast_nullable_to_non_nullable
              as String,
      transferCode: null == transferCode
          ? _value.transferCode
          : transferCode // ignore: cast_nullable_to_non_nullable
              as String,
      dialCode: freezed == dialCode
          ? _value.dialCode
          : dialCode // ignore: cast_nullable_to_non_nullable
              as String?,
      sortOrder: null == sortOrder
          ? _value.sortOrder
          : sortOrder // ignore: cast_nullable_to_non_nullable
              as int,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$CompetitionPaymentOptionImpl extends _CompetitionPaymentOption {
  const _$CompetitionPaymentOptionImpl(
      {required this.id,
      required this.competitionId,
      required this.countryCode,
      required this.operatorLabel,
      required this.transferCode,
      this.dialCode,
      this.sortOrder = 0,
      this.createdAt})
      : super._();

  factory _$CompetitionPaymentOptionImpl.fromJson(Map<String, dynamic> json) =>
      _$$CompetitionPaymentOptionImplFromJson(json);

  @override
  final String id;
  @override
  final String competitionId;
  @override
  final String countryCode;
  @override
  final String operatorLabel;
  @override
  final String transferCode;

  /// Indicatif E.164 du pays (ex. `'+237'`) — pré-remplit le champ numéro
  /// côté joueur (P2). Peut être null (repli sur `dialCodeFor(countryCode)`).
  @override
  final String? dialCode;
  @override
  @JsonKey()
  final int sortOrder;
  @override
  final DateTime? createdAt;

  @override
  String toString() {
    return 'CompetitionPaymentOption(id: $id, competitionId: $competitionId, countryCode: $countryCode, operatorLabel: $operatorLabel, transferCode: $transferCode, dialCode: $dialCode, sortOrder: $sortOrder, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CompetitionPaymentOptionImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.competitionId, competitionId) ||
                other.competitionId == competitionId) &&
            (identical(other.countryCode, countryCode) ||
                other.countryCode == countryCode) &&
            (identical(other.operatorLabel, operatorLabel) ||
                other.operatorLabel == operatorLabel) &&
            (identical(other.transferCode, transferCode) ||
                other.transferCode == transferCode) &&
            (identical(other.dialCode, dialCode) ||
                other.dialCode == dialCode) &&
            (identical(other.sortOrder, sortOrder) ||
                other.sortOrder == sortOrder) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, competitionId, countryCode,
      operatorLabel, transferCode, dialCode, sortOrder, createdAt);

  /// Create a copy of CompetitionPaymentOption
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CompetitionPaymentOptionImplCopyWith<_$CompetitionPaymentOptionImpl>
      get copyWith => __$$CompetitionPaymentOptionImplCopyWithImpl<
          _$CompetitionPaymentOptionImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$CompetitionPaymentOptionImplToJson(
      this,
    );
  }
}

abstract class _CompetitionPaymentOption extends CompetitionPaymentOption {
  const factory _CompetitionPaymentOption(
      {required final String id,
      required final String competitionId,
      required final String countryCode,
      required final String operatorLabel,
      required final String transferCode,
      final String? dialCode,
      final int sortOrder,
      final DateTime? createdAt}) = _$CompetitionPaymentOptionImpl;
  const _CompetitionPaymentOption._() : super._();

  factory _CompetitionPaymentOption.fromJson(Map<String, dynamic> json) =
      _$CompetitionPaymentOptionImpl.fromJson;

  @override
  String get id;
  @override
  String get competitionId;
  @override
  String get countryCode;
  @override
  String get operatorLabel;
  @override
  String get transferCode;

  /// Indicatif E.164 du pays (ex. `'+237'`) — pré-remplit le champ numéro
  /// côté joueur (P2). Peut être null (repli sur `dialCodeFor(countryCode)`).
  @override
  String? get dialCode;
  @override
  int get sortOrder;
  @override
  DateTime? get createdAt;

  /// Create a copy of CompetitionPaymentOption
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CompetitionPaymentOptionImplCopyWith<_$CompetitionPaymentOptionImpl>
      get copyWith => throw _privateConstructorUsedError;
}
