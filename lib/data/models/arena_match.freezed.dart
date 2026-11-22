// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'arena_match.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ArenaMatch {

 String get id; String get competitionId; String? get phaseId; String? get groupId; int? get round; int? get matchNumber; String? get player1Id; String? get player2Id; int? get score1; int? get score2; String? get winnerId;@MatchStatusConverter() MatchStatus get status; String? get homePlayerId; String? get roomCode; String? get player1TeamName; String? get player2TeamName; bool get player1Ready; bool get player2Ready; String? get nextMatchId; bool get isThirdPlace; bool get isStreamed; DateTime? get scheduledAt; DateTime? get startedAt; DateTime? get finishedAt; DateTime? get createdAt; DateTime? get updatedAt;
/// Create a copy of ArenaMatch
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ArenaMatchCopyWith<ArenaMatch> get copyWith => _$ArenaMatchCopyWithImpl<ArenaMatch>(this as ArenaMatch, _$identity);

  /// Serializes this ArenaMatch to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as ArenaMatch;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ArenaMatch&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.competitionId, _this.competitionId) || other.competitionId == _this.competitionId)&&(identical(other.phaseId, _this.phaseId) || other.phaseId == _this.phaseId)&&(identical(other.groupId, _this.groupId) || other.groupId == _this.groupId)&&(identical(other.round, _this.round) || other.round == _this.round)&&(identical(other.matchNumber, _this.matchNumber) || other.matchNumber == _this.matchNumber)&&(identical(other.player1Id, _this.player1Id) || other.player1Id == _this.player1Id)&&(identical(other.player2Id, _this.player2Id) || other.player2Id == _this.player2Id)&&(identical(other.score1, _this.score1) || other.score1 == _this.score1)&&(identical(other.score2, _this.score2) || other.score2 == _this.score2)&&(identical(other.winnerId, _this.winnerId) || other.winnerId == _this.winnerId)&&(identical(other.status, _this.status) || other.status == _this.status)&&(identical(other.homePlayerId, _this.homePlayerId) || other.homePlayerId == _this.homePlayerId)&&(identical(other.roomCode, _this.roomCode) || other.roomCode == _this.roomCode)&&(identical(other.player1TeamName, _this.player1TeamName) || other.player1TeamName == _this.player1TeamName)&&(identical(other.player2TeamName, _this.player2TeamName) || other.player2TeamName == _this.player2TeamName)&&(identical(other.player1Ready, _this.player1Ready) || other.player1Ready == _this.player1Ready)&&(identical(other.player2Ready, _this.player2Ready) || other.player2Ready == _this.player2Ready)&&(identical(other.nextMatchId, _this.nextMatchId) || other.nextMatchId == _this.nextMatchId)&&(identical(other.isThirdPlace, _this.isThirdPlace) || other.isThirdPlace == _this.isThirdPlace)&&(identical(other.isStreamed, _this.isStreamed) || other.isStreamed == _this.isStreamed)&&(identical(other.scheduledAt, _this.scheduledAt) || other.scheduledAt == _this.scheduledAt)&&(identical(other.startedAt, _this.startedAt) || other.startedAt == _this.startedAt)&&(identical(other.finishedAt, _this.finishedAt) || other.finishedAt == _this.finishedAt)&&(identical(other.createdAt, _this.createdAt) || other.createdAt == _this.createdAt)&&(identical(other.updatedAt, _this.updatedAt) || other.updatedAt == _this.updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as ArenaMatch;
  return Object.hashAll([runtimeType,_this.id,_this.competitionId,_this.phaseId,_this.groupId,_this.round,_this.matchNumber,_this.player1Id,_this.player2Id,_this.score1,_this.score2,_this.winnerId,_this.status,_this.homePlayerId,_this.roomCode,_this.player1TeamName,_this.player2TeamName,_this.player1Ready,_this.player2Ready,_this.nextMatchId,_this.isThirdPlace,_this.isStreamed,_this.scheduledAt,_this.startedAt,_this.finishedAt,_this.createdAt,_this.updatedAt]);
}

@override
String toString() {
  final _this = this as ArenaMatch;
  return 'ArenaMatch(id: ${_this.id}, competitionId: ${_this.competitionId}, phaseId: ${_this.phaseId}, groupId: ${_this.groupId}, round: ${_this.round}, matchNumber: ${_this.matchNumber}, player1Id: ${_this.player1Id}, player2Id: ${_this.player2Id}, score1: ${_this.score1}, score2: ${_this.score2}, winnerId: ${_this.winnerId}, status: ${_this.status}, homePlayerId: ${_this.homePlayerId}, roomCode: ${_this.roomCode}, player1TeamName: ${_this.player1TeamName}, player2TeamName: ${_this.player2TeamName}, player1Ready: ${_this.player1Ready}, player2Ready: ${_this.player2Ready}, nextMatchId: ${_this.nextMatchId}, isThirdPlace: ${_this.isThirdPlace}, isStreamed: ${_this.isStreamed}, scheduledAt: ${_this.scheduledAt}, startedAt: ${_this.startedAt}, finishedAt: ${_this.finishedAt}, createdAt: ${_this.createdAt}, updatedAt: ${_this.updatedAt})';
}


}

/// @nodoc
abstract mixin class $ArenaMatchCopyWith<$Res>  {
  factory $ArenaMatchCopyWith(ArenaMatch value, $Res Function(ArenaMatch) _then) = _$ArenaMatchCopyWithImpl;
@useResult
$Res call({
 String id, String competitionId, String? phaseId, String? groupId, int? round, int? matchNumber, String? player1Id, String? player2Id, int? score1, int? score2, String? winnerId,@MatchStatusConverter() MatchStatus status, String? homePlayerId, String? roomCode, String? player1TeamName, String? player2TeamName, bool player1Ready, bool player2Ready, String? nextMatchId, bool isThirdPlace, bool isStreamed, DateTime? scheduledAt, DateTime? startedAt, DateTime? finishedAt, DateTime? createdAt, DateTime? updatedAt
});




}
/// @nodoc
class _$ArenaMatchCopyWithImpl<$Res>
    implements $ArenaMatchCopyWith<$Res> {
  _$ArenaMatchCopyWithImpl(this._self, this._then);

  final ArenaMatch _self;
  final $Res Function(ArenaMatch) _then;

/// Create a copy of ArenaMatch
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? competitionId = null,Object? phaseId = freezed,Object? groupId = freezed,Object? round = freezed,Object? matchNumber = freezed,Object? player1Id = freezed,Object? player2Id = freezed,Object? score1 = freezed,Object? score2 = freezed,Object? winnerId = freezed,Object? status = null,Object? homePlayerId = freezed,Object? roomCode = freezed,Object? player1TeamName = freezed,Object? player2TeamName = freezed,Object? player1Ready = null,Object? player2Ready = null,Object? nextMatchId = freezed,Object? isThirdPlace = null,Object? isStreamed = null,Object? scheduledAt = freezed,Object? startedAt = freezed,Object? finishedAt = freezed,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(ArenaMatch(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,competitionId: null == competitionId ? _self.competitionId : competitionId // ignore: cast_nullable_to_non_nullable
as String,phaseId: freezed == phaseId ? _self.phaseId : phaseId // ignore: cast_nullable_to_non_nullable
as String?,groupId: freezed == groupId ? _self.groupId : groupId // ignore: cast_nullable_to_non_nullable
as String?,round: freezed == round ? _self.round : round // ignore: cast_nullable_to_non_nullable
as int?,matchNumber: freezed == matchNumber ? _self.matchNumber : matchNumber // ignore: cast_nullable_to_non_nullable
as int?,player1Id: freezed == player1Id ? _self.player1Id : player1Id // ignore: cast_nullable_to_non_nullable
as String?,player2Id: freezed == player2Id ? _self.player2Id : player2Id // ignore: cast_nullable_to_non_nullable
as String?,score1: freezed == score1 ? _self.score1 : score1 // ignore: cast_nullable_to_non_nullable
as int?,score2: freezed == score2 ? _self.score2 : score2 // ignore: cast_nullable_to_non_nullable
as int?,winnerId: freezed == winnerId ? _self.winnerId : winnerId // ignore: cast_nullable_to_non_nullable
as String?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as MatchStatus,homePlayerId: freezed == homePlayerId ? _self.homePlayerId : homePlayerId // ignore: cast_nullable_to_non_nullable
as String?,roomCode: freezed == roomCode ? _self.roomCode : roomCode // ignore: cast_nullable_to_non_nullable
as String?,player1TeamName: freezed == player1TeamName ? _self.player1TeamName : player1TeamName // ignore: cast_nullable_to_non_nullable
as String?,player2TeamName: freezed == player2TeamName ? _self.player2TeamName : player2TeamName // ignore: cast_nullable_to_non_nullable
as String?,player1Ready: null == player1Ready ? _self.player1Ready : player1Ready // ignore: cast_nullable_to_non_nullable
as bool,player2Ready: null == player2Ready ? _self.player2Ready : player2Ready // ignore: cast_nullable_to_non_nullable
as bool,nextMatchId: freezed == nextMatchId ? _self.nextMatchId : nextMatchId // ignore: cast_nullable_to_non_nullable
as String?,isThirdPlace: null == isThirdPlace ? _self.isThirdPlace : isThirdPlace // ignore: cast_nullable_to_non_nullable
as bool,isStreamed: null == isStreamed ? _self.isStreamed : isStreamed // ignore: cast_nullable_to_non_nullable
as bool,scheduledAt: freezed == scheduledAt ? _self.scheduledAt : scheduledAt // ignore: cast_nullable_to_non_nullable
as DateTime?,startedAt: freezed == startedAt ? _self.startedAt : startedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,finishedAt: freezed == finishedAt ? _self.finishedAt : finishedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [ArenaMatch].
extension ArenaMatchPatterns on ArenaMatch {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ArenaMatch value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ArenaMatch() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ArenaMatch value)  $default,){
final _that = this;
switch (_that) {
case _ArenaMatch():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ArenaMatch value)?  $default,){
final _that = this;
switch (_that) {
case _ArenaMatch() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String competitionId,  String? phaseId,  String? groupId,  int? round,  int? matchNumber,  String? player1Id,  String? player2Id,  int? score1,  int? score2,  String? winnerId, @MatchStatusConverter()  MatchStatus status,  String? homePlayerId,  String? roomCode,  String? player1TeamName,  String? player2TeamName,  bool player1Ready,  bool player2Ready,  String? nextMatchId,  bool isThirdPlace,  bool isStreamed,  DateTime? scheduledAt,  DateTime? startedAt,  DateTime? finishedAt,  DateTime? createdAt,  DateTime? updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ArenaMatch() when $default != null:
return $default(_that.id,_that.competitionId,_that.phaseId,_that.groupId,_that.round,_that.matchNumber,_that.player1Id,_that.player2Id,_that.score1,_that.score2,_that.winnerId,_that.status,_that.homePlayerId,_that.roomCode,_that.player1TeamName,_that.player2TeamName,_that.player1Ready,_that.player2Ready,_that.nextMatchId,_that.isThirdPlace,_that.isStreamed,_that.scheduledAt,_that.startedAt,_that.finishedAt,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String competitionId,  String? phaseId,  String? groupId,  int? round,  int? matchNumber,  String? player1Id,  String? player2Id,  int? score1,  int? score2,  String? winnerId, @MatchStatusConverter()  MatchStatus status,  String? homePlayerId,  String? roomCode,  String? player1TeamName,  String? player2TeamName,  bool player1Ready,  bool player2Ready,  String? nextMatchId,  bool isThirdPlace,  bool isStreamed,  DateTime? scheduledAt,  DateTime? startedAt,  DateTime? finishedAt,  DateTime? createdAt,  DateTime? updatedAt)  $default,) {final _that = this;
switch (_that) {
case _ArenaMatch():
return $default(_that.id,_that.competitionId,_that.phaseId,_that.groupId,_that.round,_that.matchNumber,_that.player1Id,_that.player2Id,_that.score1,_that.score2,_that.winnerId,_that.status,_that.homePlayerId,_that.roomCode,_that.player1TeamName,_that.player2TeamName,_that.player1Ready,_that.player2Ready,_that.nextMatchId,_that.isThirdPlace,_that.isStreamed,_that.scheduledAt,_that.startedAt,_that.finishedAt,_that.createdAt,_that.updatedAt);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String competitionId,  String? phaseId,  String? groupId,  int? round,  int? matchNumber,  String? player1Id,  String? player2Id,  int? score1,  int? score2,  String? winnerId, @MatchStatusConverter()  MatchStatus status,  String? homePlayerId,  String? roomCode,  String? player1TeamName,  String? player2TeamName,  bool player1Ready,  bool player2Ready,  String? nextMatchId,  bool isThirdPlace,  bool isStreamed,  DateTime? scheduledAt,  DateTime? startedAt,  DateTime? finishedAt,  DateTime? createdAt,  DateTime? updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _ArenaMatch() when $default != null:
return $default(_that.id,_that.competitionId,_that.phaseId,_that.groupId,_that.round,_that.matchNumber,_that.player1Id,_that.player2Id,_that.score1,_that.score2,_that.winnerId,_that.status,_that.homePlayerId,_that.roomCode,_that.player1TeamName,_that.player2TeamName,_that.player1Ready,_that.player2Ready,_that.nextMatchId,_that.isThirdPlace,_that.isStreamed,_that.scheduledAt,_that.startedAt,_that.finishedAt,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ArenaMatch extends ArenaMatch {
  const _ArenaMatch({required this.id, required this.competitionId, this.phaseId, this.groupId, this.round, this.matchNumber, this.player1Id, this.player2Id, this.score1, this.score2, this.winnerId, @MatchStatusConverter() this.status = MatchStatus.pending, this.homePlayerId, this.roomCode, this.player1TeamName, this.player2TeamName, this.player1Ready = false, this.player2Ready = false, this.nextMatchId, this.isThirdPlace = false, this.isStreamed = false, this.scheduledAt, this.startedAt, this.finishedAt, this.createdAt, this.updatedAt}): super._();
  factory _ArenaMatch.fromJson(Map<String, dynamic> json) => _$ArenaMatchFromJson(json);

@override final  String id;
@override final  String competitionId;
@override final  String? phaseId;
@override final  String? groupId;
@override final  int? round;
@override final  int? matchNumber;
@override final  String? player1Id;
@override final  String? player2Id;
@override final  int? score1;
@override final  int? score2;
@override final  String? winnerId;
@override@JsonKey()@MatchStatusConverter() final  MatchStatus status;
@override final  String? homePlayerId;
@override final  String? roomCode;
@override final  String? player1TeamName;
@override final  String? player2TeamName;
@override@JsonKey() final  bool player1Ready;
@override@JsonKey() final  bool player2Ready;
@override final  String? nextMatchId;
@override@JsonKey() final  bool isThirdPlace;
@override@JsonKey() final  bool isStreamed;
@override final  DateTime? scheduledAt;
@override final  DateTime? startedAt;
@override final  DateTime? finishedAt;
@override final  DateTime? createdAt;
@override final  DateTime? updatedAt;

/// Create a copy of ArenaMatch
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ArenaMatchCopyWith<_ArenaMatch> get copyWith => __$ArenaMatchCopyWithImpl<_ArenaMatch>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ArenaMatchToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ArenaMatch&&(identical(other.id, id) || other.id == id)&&(identical(other.competitionId, competitionId) || other.competitionId == competitionId)&&(identical(other.phaseId, phaseId) || other.phaseId == phaseId)&&(identical(other.groupId, groupId) || other.groupId == groupId)&&(identical(other.round, round) || other.round == round)&&(identical(other.matchNumber, matchNumber) || other.matchNumber == matchNumber)&&(identical(other.player1Id, player1Id) || other.player1Id == player1Id)&&(identical(other.player2Id, player2Id) || other.player2Id == player2Id)&&(identical(other.score1, score1) || other.score1 == score1)&&(identical(other.score2, score2) || other.score2 == score2)&&(identical(other.winnerId, winnerId) || other.winnerId == winnerId)&&(identical(other.status, status) || other.status == status)&&(identical(other.homePlayerId, homePlayerId) || other.homePlayerId == homePlayerId)&&(identical(other.roomCode, roomCode) || other.roomCode == roomCode)&&(identical(other.player1TeamName, player1TeamName) || other.player1TeamName == player1TeamName)&&(identical(other.player2TeamName, player2TeamName) || other.player2TeamName == player2TeamName)&&(identical(other.player1Ready, player1Ready) || other.player1Ready == player1Ready)&&(identical(other.player2Ready, player2Ready) || other.player2Ready == player2Ready)&&(identical(other.nextMatchId, nextMatchId) || other.nextMatchId == nextMatchId)&&(identical(other.isThirdPlace, isThirdPlace) || other.isThirdPlace == isThirdPlace)&&(identical(other.isStreamed, isStreamed) || other.isStreamed == isStreamed)&&(identical(other.scheduledAt, scheduledAt) || other.scheduledAt == scheduledAt)&&(identical(other.startedAt, startedAt) || other.startedAt == startedAt)&&(identical(other.finishedAt, finishedAt) || other.finishedAt == finishedAt)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hashAll([runtimeType,id,competitionId,phaseId,groupId,round,matchNumber,player1Id,player2Id,score1,score2,winnerId,status,homePlayerId,roomCode,player1TeamName,player2TeamName,player1Ready,player2Ready,nextMatchId,isThirdPlace,isStreamed,scheduledAt,startedAt,finishedAt,createdAt,updatedAt]);
}

@override
String toString() {
    return 'ArenaMatch(id: $id, competitionId: $competitionId, phaseId: $phaseId, groupId: $groupId, round: $round, matchNumber: $matchNumber, player1Id: $player1Id, player2Id: $player2Id, score1: $score1, score2: $score2, winnerId: $winnerId, status: $status, homePlayerId: $homePlayerId, roomCode: $roomCode, player1TeamName: $player1TeamName, player2TeamName: $player2TeamName, player1Ready: $player1Ready, player2Ready: $player2Ready, nextMatchId: $nextMatchId, isThirdPlace: $isThirdPlace, isStreamed: $isStreamed, scheduledAt: $scheduledAt, startedAt: $startedAt, finishedAt: $finishedAt, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$ArenaMatchCopyWith<$Res> implements $ArenaMatchCopyWith<$Res> {
  factory _$ArenaMatchCopyWith(_ArenaMatch value, $Res Function(_ArenaMatch) _then) = __$ArenaMatchCopyWithImpl;
@override @useResult
$Res call({
 String id, String competitionId, String? phaseId, String? groupId, int? round, int? matchNumber, String? player1Id, String? player2Id, int? score1, int? score2, String? winnerId,@MatchStatusConverter() MatchStatus status, String? homePlayerId, String? roomCode, String? player1TeamName, String? player2TeamName, bool player1Ready, bool player2Ready, String? nextMatchId, bool isThirdPlace, bool isStreamed, DateTime? scheduledAt, DateTime? startedAt, DateTime? finishedAt, DateTime? createdAt, DateTime? updatedAt
});




}
/// @nodoc
class __$ArenaMatchCopyWithImpl<$Res>
    implements _$ArenaMatchCopyWith<$Res> {
  __$ArenaMatchCopyWithImpl(this._self, this._then);

  final _ArenaMatch _self;
  final $Res Function(_ArenaMatch) _then;

/// Create a copy of ArenaMatch
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? competitionId = null,Object? phaseId = freezed,Object? groupId = freezed,Object? round = freezed,Object? matchNumber = freezed,Object? player1Id = freezed,Object? player2Id = freezed,Object? score1 = freezed,Object? score2 = freezed,Object? winnerId = freezed,Object? status = null,Object? homePlayerId = freezed,Object? roomCode = freezed,Object? player1TeamName = freezed,Object? player2TeamName = freezed,Object? player1Ready = null,Object? player2Ready = null,Object? nextMatchId = freezed,Object? isThirdPlace = null,Object? isStreamed = null,Object? scheduledAt = freezed,Object? startedAt = freezed,Object? finishedAt = freezed,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_ArenaMatch(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,competitionId: null == competitionId ? _self.competitionId : competitionId // ignore: cast_nullable_to_non_nullable
as String,phaseId: freezed == phaseId ? _self.phaseId : phaseId // ignore: cast_nullable_to_non_nullable
as String?,groupId: freezed == groupId ? _self.groupId : groupId // ignore: cast_nullable_to_non_nullable
as String?,round: freezed == round ? _self.round : round // ignore: cast_nullable_to_non_nullable
as int?,matchNumber: freezed == matchNumber ? _self.matchNumber : matchNumber // ignore: cast_nullable_to_non_nullable
as int?,player1Id: freezed == player1Id ? _self.player1Id : player1Id // ignore: cast_nullable_to_non_nullable
as String?,player2Id: freezed == player2Id ? _self.player2Id : player2Id // ignore: cast_nullable_to_non_nullable
as String?,score1: freezed == score1 ? _self.score1 : score1 // ignore: cast_nullable_to_non_nullable
as int?,score2: freezed == score2 ? _self.score2 : score2 // ignore: cast_nullable_to_non_nullable
as int?,winnerId: freezed == winnerId ? _self.winnerId : winnerId // ignore: cast_nullable_to_non_nullable
as String?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as MatchStatus,homePlayerId: freezed == homePlayerId ? _self.homePlayerId : homePlayerId // ignore: cast_nullable_to_non_nullable
as String?,roomCode: freezed == roomCode ? _self.roomCode : roomCode // ignore: cast_nullable_to_non_nullable
as String?,player1TeamName: freezed == player1TeamName ? _self.player1TeamName : player1TeamName // ignore: cast_nullable_to_non_nullable
as String?,player2TeamName: freezed == player2TeamName ? _self.player2TeamName : player2TeamName // ignore: cast_nullable_to_non_nullable
as String?,player1Ready: null == player1Ready ? _self.player1Ready : player1Ready // ignore: cast_nullable_to_non_nullable
as bool,player2Ready: null == player2Ready ? _self.player2Ready : player2Ready // ignore: cast_nullable_to_non_nullable
as bool,nextMatchId: freezed == nextMatchId ? _self.nextMatchId : nextMatchId // ignore: cast_nullable_to_non_nullable
as String?,isThirdPlace: null == isThirdPlace ? _self.isThirdPlace : isThirdPlace // ignore: cast_nullable_to_non_nullable
as bool,isStreamed: null == isStreamed ? _self.isStreamed : isStreamed // ignore: cast_nullable_to_non_nullable
as bool,scheduledAt: freezed == scheduledAt ? _self.scheduledAt : scheduledAt // ignore: cast_nullable_to_non_nullable
as DateTime?,startedAt: freezed == startedAt ? _self.startedAt : startedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,finishedAt: freezed == finishedAt ? _self.finishedAt : finishedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
