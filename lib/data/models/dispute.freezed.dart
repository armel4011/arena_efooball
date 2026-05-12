// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'dispute.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

Dispute _$DisputeFromJson(Map<String, dynamic> json) {
  return _Dispute.fromJson(json);
}

/// @nodoc
mixin _$Dispute {
  String get id => throw _privateConstructorUsedError;
  String get matchId => throw _privateConstructorUsedError;
  String get openedBy => throw _privateConstructorUsedError;
  String get status => throw _privateConstructorUsedError;
  String? get reason => throw _privateConstructorUsedError;
  Map<String, dynamic> get evidence => throw _privateConstructorUsedError;
  int get escalationLevel => throw _privateConstructorUsedError;
  DateTime? get botAttemptedAt => throw _privateConstructorUsedError;
  DateTime? get escalatedAt => throw _privateConstructorUsedError;
  DateTime? get resolvedAt => throw _privateConstructorUsedError;
  String? get resolvedBy => throw _privateConstructorUsedError;
  String? get resolution => throw _privateConstructorUsedError;
  DateTime? get createdAt => throw _privateConstructorUsedError;
  DateTime? get updatedAt => throw _privateConstructorUsedError;

  /// Serializes this Dispute to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Dispute
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $DisputeCopyWith<Dispute> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $DisputeCopyWith<$Res> {
  factory $DisputeCopyWith(Dispute value, $Res Function(Dispute) then) =
      _$DisputeCopyWithImpl<$Res, Dispute>;
  @useResult
  $Res call(
      {String id,
      String matchId,
      String openedBy,
      String status,
      String? reason,
      Map<String, dynamic> evidence,
      int escalationLevel,
      DateTime? botAttemptedAt,
      DateTime? escalatedAt,
      DateTime? resolvedAt,
      String? resolvedBy,
      String? resolution,
      DateTime? createdAt,
      DateTime? updatedAt});
}

/// @nodoc
class _$DisputeCopyWithImpl<$Res, $Val extends Dispute>
    implements $DisputeCopyWith<$Res> {
  _$DisputeCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Dispute
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? matchId = null,
    Object? openedBy = null,
    Object? status = null,
    Object? reason = freezed,
    Object? evidence = null,
    Object? escalationLevel = null,
    Object? botAttemptedAt = freezed,
    Object? escalatedAt = freezed,
    Object? resolvedAt = freezed,
    Object? resolvedBy = freezed,
    Object? resolution = freezed,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      matchId: null == matchId
          ? _value.matchId
          : matchId // ignore: cast_nullable_to_non_nullable
              as String,
      openedBy: null == openedBy
          ? _value.openedBy
          : openedBy // ignore: cast_nullable_to_non_nullable
              as String,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      reason: freezed == reason
          ? _value.reason
          : reason // ignore: cast_nullable_to_non_nullable
              as String?,
      evidence: null == evidence
          ? _value.evidence
          : evidence // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
      escalationLevel: null == escalationLevel
          ? _value.escalationLevel
          : escalationLevel // ignore: cast_nullable_to_non_nullable
              as int,
      botAttemptedAt: freezed == botAttemptedAt
          ? _value.botAttemptedAt
          : botAttemptedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      escalatedAt: freezed == escalatedAt
          ? _value.escalatedAt
          : escalatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      resolvedAt: freezed == resolvedAt
          ? _value.resolvedAt
          : resolvedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      resolvedBy: freezed == resolvedBy
          ? _value.resolvedBy
          : resolvedBy // ignore: cast_nullable_to_non_nullable
              as String?,
      resolution: freezed == resolution
          ? _value.resolution
          : resolution // ignore: cast_nullable_to_non_nullable
              as String?,
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
abstract class _$$DisputeImplCopyWith<$Res> implements $DisputeCopyWith<$Res> {
  factory _$$DisputeImplCopyWith(
          _$DisputeImpl value, $Res Function(_$DisputeImpl) then) =
      __$$DisputeImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String matchId,
      String openedBy,
      String status,
      String? reason,
      Map<String, dynamic> evidence,
      int escalationLevel,
      DateTime? botAttemptedAt,
      DateTime? escalatedAt,
      DateTime? resolvedAt,
      String? resolvedBy,
      String? resolution,
      DateTime? createdAt,
      DateTime? updatedAt});
}

/// @nodoc
class __$$DisputeImplCopyWithImpl<$Res>
    extends _$DisputeCopyWithImpl<$Res, _$DisputeImpl>
    implements _$$DisputeImplCopyWith<$Res> {
  __$$DisputeImplCopyWithImpl(
      _$DisputeImpl _value, $Res Function(_$DisputeImpl) _then)
      : super(_value, _then);

  /// Create a copy of Dispute
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? matchId = null,
    Object? openedBy = null,
    Object? status = null,
    Object? reason = freezed,
    Object? evidence = null,
    Object? escalationLevel = null,
    Object? botAttemptedAt = freezed,
    Object? escalatedAt = freezed,
    Object? resolvedAt = freezed,
    Object? resolvedBy = freezed,
    Object? resolution = freezed,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
  }) {
    return _then(_$DisputeImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      matchId: null == matchId
          ? _value.matchId
          : matchId // ignore: cast_nullable_to_non_nullable
              as String,
      openedBy: null == openedBy
          ? _value.openedBy
          : openedBy // ignore: cast_nullable_to_non_nullable
              as String,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      reason: freezed == reason
          ? _value.reason
          : reason // ignore: cast_nullable_to_non_nullable
              as String?,
      evidence: null == evidence
          ? _value._evidence
          : evidence // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
      escalationLevel: null == escalationLevel
          ? _value.escalationLevel
          : escalationLevel // ignore: cast_nullable_to_non_nullable
              as int,
      botAttemptedAt: freezed == botAttemptedAt
          ? _value.botAttemptedAt
          : botAttemptedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      escalatedAt: freezed == escalatedAt
          ? _value.escalatedAt
          : escalatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      resolvedAt: freezed == resolvedAt
          ? _value.resolvedAt
          : resolvedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      resolvedBy: freezed == resolvedBy
          ? _value.resolvedBy
          : resolvedBy // ignore: cast_nullable_to_non_nullable
              as String?,
      resolution: freezed == resolution
          ? _value.resolution
          : resolution // ignore: cast_nullable_to_non_nullable
              as String?,
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
class _$DisputeImpl extends _Dispute {
  const _$DisputeImpl(
      {required this.id,
      required this.matchId,
      required this.openedBy,
      this.status = 'open',
      this.reason,
      final Map<String, dynamic> evidence = const <String, dynamic>{},
      this.escalationLevel = 0,
      this.botAttemptedAt,
      this.escalatedAt,
      this.resolvedAt,
      this.resolvedBy,
      this.resolution,
      this.createdAt,
      this.updatedAt})
      : _evidence = evidence,
        super._();

  factory _$DisputeImpl.fromJson(Map<String, dynamic> json) =>
      _$$DisputeImplFromJson(json);

  @override
  final String id;
  @override
  final String matchId;
  @override
  final String openedBy;
  @override
  @JsonKey()
  final String status;
  @override
  final String? reason;
  final Map<String, dynamic> _evidence;
  @override
  @JsonKey()
  Map<String, dynamic> get evidence {
    if (_evidence is EqualUnmodifiableMapView) return _evidence;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_evidence);
  }

  @override
  @JsonKey()
  final int escalationLevel;
  @override
  final DateTime? botAttemptedAt;
  @override
  final DateTime? escalatedAt;
  @override
  final DateTime? resolvedAt;
  @override
  final String? resolvedBy;
  @override
  final String? resolution;
  @override
  final DateTime? createdAt;
  @override
  final DateTime? updatedAt;

  @override
  String toString() {
    return 'Dispute(id: $id, matchId: $matchId, openedBy: $openedBy, status: $status, reason: $reason, evidence: $evidence, escalationLevel: $escalationLevel, botAttemptedAt: $botAttemptedAt, escalatedAt: $escalatedAt, resolvedAt: $resolvedAt, resolvedBy: $resolvedBy, resolution: $resolution, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DisputeImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.matchId, matchId) || other.matchId == matchId) &&
            (identical(other.openedBy, openedBy) ||
                other.openedBy == openedBy) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.reason, reason) || other.reason == reason) &&
            const DeepCollectionEquality().equals(other._evidence, _evidence) &&
            (identical(other.escalationLevel, escalationLevel) ||
                other.escalationLevel == escalationLevel) &&
            (identical(other.botAttemptedAt, botAttemptedAt) ||
                other.botAttemptedAt == botAttemptedAt) &&
            (identical(other.escalatedAt, escalatedAt) ||
                other.escalatedAt == escalatedAt) &&
            (identical(other.resolvedAt, resolvedAt) ||
                other.resolvedAt == resolvedAt) &&
            (identical(other.resolvedBy, resolvedBy) ||
                other.resolvedBy == resolvedBy) &&
            (identical(other.resolution, resolution) ||
                other.resolution == resolution) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      matchId,
      openedBy,
      status,
      reason,
      const DeepCollectionEquality().hash(_evidence),
      escalationLevel,
      botAttemptedAt,
      escalatedAt,
      resolvedAt,
      resolvedBy,
      resolution,
      createdAt,
      updatedAt);

  /// Create a copy of Dispute
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$DisputeImplCopyWith<_$DisputeImpl> get copyWith =>
      __$$DisputeImplCopyWithImpl<_$DisputeImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$DisputeImplToJson(
      this,
    );
  }
}

abstract class _Dispute extends Dispute {
  const factory _Dispute(
      {required final String id,
      required final String matchId,
      required final String openedBy,
      final String status,
      final String? reason,
      final Map<String, dynamic> evidence,
      final int escalationLevel,
      final DateTime? botAttemptedAt,
      final DateTime? escalatedAt,
      final DateTime? resolvedAt,
      final String? resolvedBy,
      final String? resolution,
      final DateTime? createdAt,
      final DateTime? updatedAt}) = _$DisputeImpl;
  const _Dispute._() : super._();

  factory _Dispute.fromJson(Map<String, dynamic> json) = _$DisputeImpl.fromJson;

  @override
  String get id;
  @override
  String get matchId;
  @override
  String get openedBy;
  @override
  String get status;
  @override
  String? get reason;
  @override
  Map<String, dynamic> get evidence;
  @override
  int get escalationLevel;
  @override
  DateTime? get botAttemptedAt;
  @override
  DateTime? get escalatedAt;
  @override
  DateTime? get resolvedAt;
  @override
  String? get resolvedBy;
  @override
  String? get resolution;
  @override
  DateTime? get createdAt;
  @override
  DateTime? get updatedAt;

  /// Create a copy of Dispute
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$DisputeImplCopyWith<_$DisputeImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
