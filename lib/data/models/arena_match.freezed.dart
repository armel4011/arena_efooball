// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'arena_match.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

ArenaMatch _$ArenaMatchFromJson(Map<String, dynamic> json) {
  return _ArenaMatch.fromJson(json);
}

/// @nodoc
mixin _$ArenaMatch {
  String get id => throw _privateConstructorUsedError;
  String get competitionId => throw _privateConstructorUsedError;
  String? get phaseId => throw _privateConstructorUsedError;
  String? get groupId => throw _privateConstructorUsedError;
  int? get round => throw _privateConstructorUsedError;
  int? get matchNumber => throw _privateConstructorUsedError;
  String? get player1Id => throw _privateConstructorUsedError;
  String? get player2Id => throw _privateConstructorUsedError;
  int? get score1 => throw _privateConstructorUsedError;
  int? get score2 => throw _privateConstructorUsedError;
  String? get winnerId => throw _privateConstructorUsedError;
  @MatchStatusConverter()
  MatchStatus get status => throw _privateConstructorUsedError;
  String? get homePlayerId => throw _privateConstructorUsedError;
  String? get roomCode => throw _privateConstructorUsedError;
  String? get player1TeamName => throw _privateConstructorUsedError;
  String? get player2TeamName => throw _privateConstructorUsedError;
  String? get nextMatchId => throw _privateConstructorUsedError;
  bool get isThirdPlace => throw _privateConstructorUsedError;
  bool get isStreamed => throw _privateConstructorUsedError;
  DateTime? get scheduledAt => throw _privateConstructorUsedError;
  DateTime? get startedAt => throw _privateConstructorUsedError;
  DateTime? get finishedAt => throw _privateConstructorUsedError;
  DateTime? get createdAt => throw _privateConstructorUsedError;
  DateTime? get updatedAt => throw _privateConstructorUsedError;

  /// Serializes this ArenaMatch to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ArenaMatch
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ArenaMatchCopyWith<ArenaMatch> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ArenaMatchCopyWith<$Res> {
  factory $ArenaMatchCopyWith(
          ArenaMatch value, $Res Function(ArenaMatch) then) =
      _$ArenaMatchCopyWithImpl<$Res, ArenaMatch>;
  @useResult
  $Res call(
      {String id,
      String competitionId,
      String? phaseId,
      String? groupId,
      int? round,
      int? matchNumber,
      String? player1Id,
      String? player2Id,
      int? score1,
      int? score2,
      String? winnerId,
      @MatchStatusConverter() MatchStatus status,
      String? homePlayerId,
      String? roomCode,
      String? player1TeamName,
      String? player2TeamName,
      String? nextMatchId,
      bool isThirdPlace,
      bool isStreamed,
      DateTime? scheduledAt,
      DateTime? startedAt,
      DateTime? finishedAt,
      DateTime? createdAt,
      DateTime? updatedAt});
}

/// @nodoc
class _$ArenaMatchCopyWithImpl<$Res, $Val extends ArenaMatch>
    implements $ArenaMatchCopyWith<$Res> {
  _$ArenaMatchCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ArenaMatch
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? competitionId = null,
    Object? phaseId = freezed,
    Object? groupId = freezed,
    Object? round = freezed,
    Object? matchNumber = freezed,
    Object? player1Id = freezed,
    Object? player2Id = freezed,
    Object? score1 = freezed,
    Object? score2 = freezed,
    Object? winnerId = freezed,
    Object? status = null,
    Object? homePlayerId = freezed,
    Object? roomCode = freezed,
    Object? player1TeamName = freezed,
    Object? player2TeamName = freezed,
    Object? nextMatchId = freezed,
    Object? isThirdPlace = null,
    Object? isStreamed = null,
    Object? scheduledAt = freezed,
    Object? startedAt = freezed,
    Object? finishedAt = freezed,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
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
      phaseId: freezed == phaseId
          ? _value.phaseId
          : phaseId // ignore: cast_nullable_to_non_nullable
              as String?,
      groupId: freezed == groupId
          ? _value.groupId
          : groupId // ignore: cast_nullable_to_non_nullable
              as String?,
      round: freezed == round
          ? _value.round
          : round // ignore: cast_nullable_to_non_nullable
              as int?,
      matchNumber: freezed == matchNumber
          ? _value.matchNumber
          : matchNumber // ignore: cast_nullable_to_non_nullable
              as int?,
      player1Id: freezed == player1Id
          ? _value.player1Id
          : player1Id // ignore: cast_nullable_to_non_nullable
              as String?,
      player2Id: freezed == player2Id
          ? _value.player2Id
          : player2Id // ignore: cast_nullable_to_non_nullable
              as String?,
      score1: freezed == score1
          ? _value.score1
          : score1 // ignore: cast_nullable_to_non_nullable
              as int?,
      score2: freezed == score2
          ? _value.score2
          : score2 // ignore: cast_nullable_to_non_nullable
              as int?,
      winnerId: freezed == winnerId
          ? _value.winnerId
          : winnerId // ignore: cast_nullable_to_non_nullable
              as String?,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as MatchStatus,
      homePlayerId: freezed == homePlayerId
          ? _value.homePlayerId
          : homePlayerId // ignore: cast_nullable_to_non_nullable
              as String?,
      roomCode: freezed == roomCode
          ? _value.roomCode
          : roomCode // ignore: cast_nullable_to_non_nullable
              as String?,
      player1TeamName: freezed == player1TeamName
          ? _value.player1TeamName
          : player1TeamName // ignore: cast_nullable_to_non_nullable
              as String?,
      player2TeamName: freezed == player2TeamName
          ? _value.player2TeamName
          : player2TeamName // ignore: cast_nullable_to_non_nullable
              as String?,
      nextMatchId: freezed == nextMatchId
          ? _value.nextMatchId
          : nextMatchId // ignore: cast_nullable_to_non_nullable
              as String?,
      isThirdPlace: null == isThirdPlace
          ? _value.isThirdPlace
          : isThirdPlace // ignore: cast_nullable_to_non_nullable
              as bool,
      isStreamed: null == isStreamed
          ? _value.isStreamed
          : isStreamed // ignore: cast_nullable_to_non_nullable
              as bool,
      scheduledAt: freezed == scheduledAt
          ? _value.scheduledAt
          : scheduledAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      startedAt: freezed == startedAt
          ? _value.startedAt
          : startedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      finishedAt: freezed == finishedAt
          ? _value.finishedAt
          : finishedAt // ignore: cast_nullable_to_non_nullable
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
abstract class _$$ArenaMatchImplCopyWith<$Res>
    implements $ArenaMatchCopyWith<$Res> {
  factory _$$ArenaMatchImplCopyWith(
          _$ArenaMatchImpl value, $Res Function(_$ArenaMatchImpl) then) =
      __$$ArenaMatchImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String competitionId,
      String? phaseId,
      String? groupId,
      int? round,
      int? matchNumber,
      String? player1Id,
      String? player2Id,
      int? score1,
      int? score2,
      String? winnerId,
      @MatchStatusConverter() MatchStatus status,
      String? homePlayerId,
      String? roomCode,
      String? player1TeamName,
      String? player2TeamName,
      String? nextMatchId,
      bool isThirdPlace,
      bool isStreamed,
      DateTime? scheduledAt,
      DateTime? startedAt,
      DateTime? finishedAt,
      DateTime? createdAt,
      DateTime? updatedAt});
}

/// @nodoc
class __$$ArenaMatchImplCopyWithImpl<$Res>
    extends _$ArenaMatchCopyWithImpl<$Res, _$ArenaMatchImpl>
    implements _$$ArenaMatchImplCopyWith<$Res> {
  __$$ArenaMatchImplCopyWithImpl(
      _$ArenaMatchImpl _value, $Res Function(_$ArenaMatchImpl) _then)
      : super(_value, _then);

  /// Create a copy of ArenaMatch
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? competitionId = null,
    Object? phaseId = freezed,
    Object? groupId = freezed,
    Object? round = freezed,
    Object? matchNumber = freezed,
    Object? player1Id = freezed,
    Object? player2Id = freezed,
    Object? score1 = freezed,
    Object? score2 = freezed,
    Object? winnerId = freezed,
    Object? status = null,
    Object? homePlayerId = freezed,
    Object? roomCode = freezed,
    Object? player1TeamName = freezed,
    Object? player2TeamName = freezed,
    Object? nextMatchId = freezed,
    Object? isThirdPlace = null,
    Object? isStreamed = null,
    Object? scheduledAt = freezed,
    Object? startedAt = freezed,
    Object? finishedAt = freezed,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
  }) {
    return _then(_$ArenaMatchImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      competitionId: null == competitionId
          ? _value.competitionId
          : competitionId // ignore: cast_nullable_to_non_nullable
              as String,
      phaseId: freezed == phaseId
          ? _value.phaseId
          : phaseId // ignore: cast_nullable_to_non_nullable
              as String?,
      groupId: freezed == groupId
          ? _value.groupId
          : groupId // ignore: cast_nullable_to_non_nullable
              as String?,
      round: freezed == round
          ? _value.round
          : round // ignore: cast_nullable_to_non_nullable
              as int?,
      matchNumber: freezed == matchNumber
          ? _value.matchNumber
          : matchNumber // ignore: cast_nullable_to_non_nullable
              as int?,
      player1Id: freezed == player1Id
          ? _value.player1Id
          : player1Id // ignore: cast_nullable_to_non_nullable
              as String?,
      player2Id: freezed == player2Id
          ? _value.player2Id
          : player2Id // ignore: cast_nullable_to_non_nullable
              as String?,
      score1: freezed == score1
          ? _value.score1
          : score1 // ignore: cast_nullable_to_non_nullable
              as int?,
      score2: freezed == score2
          ? _value.score2
          : score2 // ignore: cast_nullable_to_non_nullable
              as int?,
      winnerId: freezed == winnerId
          ? _value.winnerId
          : winnerId // ignore: cast_nullable_to_non_nullable
              as String?,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as MatchStatus,
      homePlayerId: freezed == homePlayerId
          ? _value.homePlayerId
          : homePlayerId // ignore: cast_nullable_to_non_nullable
              as String?,
      roomCode: freezed == roomCode
          ? _value.roomCode
          : roomCode // ignore: cast_nullable_to_non_nullable
              as String?,
      player1TeamName: freezed == player1TeamName
          ? _value.player1TeamName
          : player1TeamName // ignore: cast_nullable_to_non_nullable
              as String?,
      player2TeamName: freezed == player2TeamName
          ? _value.player2TeamName
          : player2TeamName // ignore: cast_nullable_to_non_nullable
              as String?,
      nextMatchId: freezed == nextMatchId
          ? _value.nextMatchId
          : nextMatchId // ignore: cast_nullable_to_non_nullable
              as String?,
      isThirdPlace: null == isThirdPlace
          ? _value.isThirdPlace
          : isThirdPlace // ignore: cast_nullable_to_non_nullable
              as bool,
      isStreamed: null == isStreamed
          ? _value.isStreamed
          : isStreamed // ignore: cast_nullable_to_non_nullable
              as bool,
      scheduledAt: freezed == scheduledAt
          ? _value.scheduledAt
          : scheduledAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      startedAt: freezed == startedAt
          ? _value.startedAt
          : startedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      finishedAt: freezed == finishedAt
          ? _value.finishedAt
          : finishedAt // ignore: cast_nullable_to_non_nullable
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
class _$ArenaMatchImpl extends _ArenaMatch {
  const _$ArenaMatchImpl(
      {required this.id,
      required this.competitionId,
      this.phaseId,
      this.groupId,
      this.round,
      this.matchNumber,
      this.player1Id,
      this.player2Id,
      this.score1,
      this.score2,
      this.winnerId,
      @MatchStatusConverter() this.status = MatchStatus.pending,
      this.homePlayerId,
      this.roomCode,
      this.player1TeamName,
      this.player2TeamName,
      this.nextMatchId,
      this.isThirdPlace = false,
      this.isStreamed = false,
      this.scheduledAt,
      this.startedAt,
      this.finishedAt,
      this.createdAt,
      this.updatedAt})
      : super._();

  factory _$ArenaMatchImpl.fromJson(Map<String, dynamic> json) =>
      _$$ArenaMatchImplFromJson(json);

  @override
  final String id;
  @override
  final String competitionId;
  @override
  final String? phaseId;
  @override
  final String? groupId;
  @override
  final int? round;
  @override
  final int? matchNumber;
  @override
  final String? player1Id;
  @override
  final String? player2Id;
  @override
  final int? score1;
  @override
  final int? score2;
  @override
  final String? winnerId;
  @override
  @JsonKey()
  @MatchStatusConverter()
  final MatchStatus status;
  @override
  final String? homePlayerId;
  @override
  final String? roomCode;
  @override
  final String? player1TeamName;
  @override
  final String? player2TeamName;
  @override
  final String? nextMatchId;
  @override
  @JsonKey()
  final bool isThirdPlace;
  @override
  @JsonKey()
  final bool isStreamed;
  @override
  final DateTime? scheduledAt;
  @override
  final DateTime? startedAt;
  @override
  final DateTime? finishedAt;
  @override
  final DateTime? createdAt;
  @override
  final DateTime? updatedAt;

  @override
  String toString() {
    return 'ArenaMatch(id: $id, competitionId: $competitionId, phaseId: $phaseId, groupId: $groupId, round: $round, matchNumber: $matchNumber, player1Id: $player1Id, player2Id: $player2Id, score1: $score1, score2: $score2, winnerId: $winnerId, status: $status, homePlayerId: $homePlayerId, roomCode: $roomCode, player1TeamName: $player1TeamName, player2TeamName: $player2TeamName, nextMatchId: $nextMatchId, isThirdPlace: $isThirdPlace, isStreamed: $isStreamed, scheduledAt: $scheduledAt, startedAt: $startedAt, finishedAt: $finishedAt, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ArenaMatchImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.competitionId, competitionId) ||
                other.competitionId == competitionId) &&
            (identical(other.phaseId, phaseId) || other.phaseId == phaseId) &&
            (identical(other.groupId, groupId) || other.groupId == groupId) &&
            (identical(other.round, round) || other.round == round) &&
            (identical(other.matchNumber, matchNumber) ||
                other.matchNumber == matchNumber) &&
            (identical(other.player1Id, player1Id) ||
                other.player1Id == player1Id) &&
            (identical(other.player2Id, player2Id) ||
                other.player2Id == player2Id) &&
            (identical(other.score1, score1) || other.score1 == score1) &&
            (identical(other.score2, score2) || other.score2 == score2) &&
            (identical(other.winnerId, winnerId) ||
                other.winnerId == winnerId) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.homePlayerId, homePlayerId) ||
                other.homePlayerId == homePlayerId) &&
            (identical(other.roomCode, roomCode) ||
                other.roomCode == roomCode) &&
            (identical(other.player1TeamName, player1TeamName) ||
                other.player1TeamName == player1TeamName) &&
            (identical(other.player2TeamName, player2TeamName) ||
                other.player2TeamName == player2TeamName) &&
            (identical(other.nextMatchId, nextMatchId) ||
                other.nextMatchId == nextMatchId) &&
            (identical(other.isThirdPlace, isThirdPlace) ||
                other.isThirdPlace == isThirdPlace) &&
            (identical(other.isStreamed, isStreamed) ||
                other.isStreamed == isStreamed) &&
            (identical(other.scheduledAt, scheduledAt) ||
                other.scheduledAt == scheduledAt) &&
            (identical(other.startedAt, startedAt) ||
                other.startedAt == startedAt) &&
            (identical(other.finishedAt, finishedAt) ||
                other.finishedAt == finishedAt) &&
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
        competitionId,
        phaseId,
        groupId,
        round,
        matchNumber,
        player1Id,
        player2Id,
        score1,
        score2,
        winnerId,
        status,
        homePlayerId,
        roomCode,
        player1TeamName,
        player2TeamName,
        nextMatchId,
        isThirdPlace,
        isStreamed,
        scheduledAt,
        startedAt,
        finishedAt,
        createdAt,
        updatedAt
      ]);

  /// Create a copy of ArenaMatch
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ArenaMatchImplCopyWith<_$ArenaMatchImpl> get copyWith =>
      __$$ArenaMatchImplCopyWithImpl<_$ArenaMatchImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ArenaMatchImplToJson(
      this,
    );
  }
}

abstract class _ArenaMatch extends ArenaMatch {
  const factory _ArenaMatch(
      {required final String id,
      required final String competitionId,
      final String? phaseId,
      final String? groupId,
      final int? round,
      final int? matchNumber,
      final String? player1Id,
      final String? player2Id,
      final int? score1,
      final int? score2,
      final String? winnerId,
      @MatchStatusConverter() final MatchStatus status,
      final String? homePlayerId,
      final String? roomCode,
      final String? player1TeamName,
      final String? player2TeamName,
      final String? nextMatchId,
      final bool isThirdPlace,
      final bool isStreamed,
      final DateTime? scheduledAt,
      final DateTime? startedAt,
      final DateTime? finishedAt,
      final DateTime? createdAt,
      final DateTime? updatedAt}) = _$ArenaMatchImpl;
  const _ArenaMatch._() : super._();

  factory _ArenaMatch.fromJson(Map<String, dynamic> json) =
      _$ArenaMatchImpl.fromJson;

  @override
  String get id;
  @override
  String get competitionId;
  @override
  String? get phaseId;
  @override
  String? get groupId;
  @override
  int? get round;
  @override
  int? get matchNumber;
  @override
  String? get player1Id;
  @override
  String? get player2Id;
  @override
  int? get score1;
  @override
  int? get score2;
  @override
  String? get winnerId;
  @override
  @MatchStatusConverter()
  MatchStatus get status;
  @override
  String? get homePlayerId;
  @override
  String? get roomCode;
  @override
  String? get player1TeamName;
  @override
  String? get player2TeamName;
  @override
  String? get nextMatchId;
  @override
  bool get isThirdPlace;
  @override
  bool get isStreamed;
  @override
  DateTime? get scheduledAt;
  @override
  DateTime? get startedAt;
  @override
  DateTime? get finishedAt;
  @override
  DateTime? get createdAt;
  @override
  DateTime? get updatedAt;

  /// Create a copy of ArenaMatch
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ArenaMatchImplCopyWith<_$ArenaMatchImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
