// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'bracket_node.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$BracketNode {

 String get id; String get phaseId; String get competitionId; int get roundNumber; int get positionInRound; int get totalRounds; String? get matchId; String? get nextNodeId; String? get parentNodeId; String? get nextPosition; bool get isGrandFinal; bool get isThirdPlaceMatch; bool get isBye; String? get byePlayerId; DateTime? get createdAt;
/// Create a copy of BracketNode
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BracketNodeCopyWith<BracketNode> get copyWith => _$BracketNodeCopyWithImpl<BracketNode>(this as BracketNode, _$identity);

  /// Serializes this BracketNode to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as BracketNode;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BracketNode&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.phaseId, _this.phaseId) || other.phaseId == _this.phaseId)&&(identical(other.competitionId, _this.competitionId) || other.competitionId == _this.competitionId)&&(identical(other.roundNumber, _this.roundNumber) || other.roundNumber == _this.roundNumber)&&(identical(other.positionInRound, _this.positionInRound) || other.positionInRound == _this.positionInRound)&&(identical(other.totalRounds, _this.totalRounds) || other.totalRounds == _this.totalRounds)&&(identical(other.matchId, _this.matchId) || other.matchId == _this.matchId)&&(identical(other.nextNodeId, _this.nextNodeId) || other.nextNodeId == _this.nextNodeId)&&(identical(other.parentNodeId, _this.parentNodeId) || other.parentNodeId == _this.parentNodeId)&&(identical(other.nextPosition, _this.nextPosition) || other.nextPosition == _this.nextPosition)&&(identical(other.isGrandFinal, _this.isGrandFinal) || other.isGrandFinal == _this.isGrandFinal)&&(identical(other.isThirdPlaceMatch, _this.isThirdPlaceMatch) || other.isThirdPlaceMatch == _this.isThirdPlaceMatch)&&(identical(other.isBye, _this.isBye) || other.isBye == _this.isBye)&&(identical(other.byePlayerId, _this.byePlayerId) || other.byePlayerId == _this.byePlayerId)&&(identical(other.createdAt, _this.createdAt) || other.createdAt == _this.createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as BracketNode;
  return Object.hash(runtimeType,_this.id,_this.phaseId,_this.competitionId,_this.roundNumber,_this.positionInRound,_this.totalRounds,_this.matchId,_this.nextNodeId,_this.parentNodeId,_this.nextPosition,_this.isGrandFinal,_this.isThirdPlaceMatch,_this.isBye,_this.byePlayerId,_this.createdAt);
}

@override
String toString() {
  final _this = this as BracketNode;
  return 'BracketNode(id: ${_this.id}, phaseId: ${_this.phaseId}, competitionId: ${_this.competitionId}, roundNumber: ${_this.roundNumber}, positionInRound: ${_this.positionInRound}, totalRounds: ${_this.totalRounds}, matchId: ${_this.matchId}, nextNodeId: ${_this.nextNodeId}, parentNodeId: ${_this.parentNodeId}, nextPosition: ${_this.nextPosition}, isGrandFinal: ${_this.isGrandFinal}, isThirdPlaceMatch: ${_this.isThirdPlaceMatch}, isBye: ${_this.isBye}, byePlayerId: ${_this.byePlayerId}, createdAt: ${_this.createdAt})';
}


}

/// @nodoc
abstract mixin class $BracketNodeCopyWith<$Res>  {
  factory $BracketNodeCopyWith(BracketNode value, $Res Function(BracketNode) _then) = _$BracketNodeCopyWithImpl;
@useResult
$Res call({
 String id, String phaseId, String competitionId, int roundNumber, int positionInRound, int totalRounds, String? matchId, String? nextNodeId, String? parentNodeId, String? nextPosition, bool isGrandFinal, bool isThirdPlaceMatch, bool isBye, String? byePlayerId, DateTime? createdAt
});




}
/// @nodoc
class _$BracketNodeCopyWithImpl<$Res>
    implements $BracketNodeCopyWith<$Res> {
  _$BracketNodeCopyWithImpl(this._self, this._then);

  final BracketNode _self;
  final $Res Function(BracketNode) _then;

/// Create a copy of BracketNode
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? phaseId = null,Object? competitionId = null,Object? roundNumber = null,Object? positionInRound = null,Object? totalRounds = null,Object? matchId = freezed,Object? nextNodeId = freezed,Object? parentNodeId = freezed,Object? nextPosition = freezed,Object? isGrandFinal = null,Object? isThirdPlaceMatch = null,Object? isBye = null,Object? byePlayerId = freezed,Object? createdAt = freezed,}) {
  return _then(BracketNode(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,phaseId: null == phaseId ? _self.phaseId : phaseId // ignore: cast_nullable_to_non_nullable
as String,competitionId: null == competitionId ? _self.competitionId : competitionId // ignore: cast_nullable_to_non_nullable
as String,roundNumber: null == roundNumber ? _self.roundNumber : roundNumber // ignore: cast_nullable_to_non_nullable
as int,positionInRound: null == positionInRound ? _self.positionInRound : positionInRound // ignore: cast_nullable_to_non_nullable
as int,totalRounds: null == totalRounds ? _self.totalRounds : totalRounds // ignore: cast_nullable_to_non_nullable
as int,matchId: freezed == matchId ? _self.matchId : matchId // ignore: cast_nullable_to_non_nullable
as String?,nextNodeId: freezed == nextNodeId ? _self.nextNodeId : nextNodeId // ignore: cast_nullable_to_non_nullable
as String?,parentNodeId: freezed == parentNodeId ? _self.parentNodeId : parentNodeId // ignore: cast_nullable_to_non_nullable
as String?,nextPosition: freezed == nextPosition ? _self.nextPosition : nextPosition // ignore: cast_nullable_to_non_nullable
as String?,isGrandFinal: null == isGrandFinal ? _self.isGrandFinal : isGrandFinal // ignore: cast_nullable_to_non_nullable
as bool,isThirdPlaceMatch: null == isThirdPlaceMatch ? _self.isThirdPlaceMatch : isThirdPlaceMatch // ignore: cast_nullable_to_non_nullable
as bool,isBye: null == isBye ? _self.isBye : isBye // ignore: cast_nullable_to_non_nullable
as bool,byePlayerId: freezed == byePlayerId ? _self.byePlayerId : byePlayerId // ignore: cast_nullable_to_non_nullable
as String?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [BracketNode].
extension BracketNodePatterns on BracketNode {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BracketNode value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BracketNode() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BracketNode value)  $default,){
final _that = this;
switch (_that) {
case _BracketNode():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BracketNode value)?  $default,){
final _that = this;
switch (_that) {
case _BracketNode() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String phaseId,  String competitionId,  int roundNumber,  int positionInRound,  int totalRounds,  String? matchId,  String? nextNodeId,  String? parentNodeId,  String? nextPosition,  bool isGrandFinal,  bool isThirdPlaceMatch,  bool isBye,  String? byePlayerId,  DateTime? createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BracketNode() when $default != null:
return $default(_that.id,_that.phaseId,_that.competitionId,_that.roundNumber,_that.positionInRound,_that.totalRounds,_that.matchId,_that.nextNodeId,_that.parentNodeId,_that.nextPosition,_that.isGrandFinal,_that.isThirdPlaceMatch,_that.isBye,_that.byePlayerId,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String phaseId,  String competitionId,  int roundNumber,  int positionInRound,  int totalRounds,  String? matchId,  String? nextNodeId,  String? parentNodeId,  String? nextPosition,  bool isGrandFinal,  bool isThirdPlaceMatch,  bool isBye,  String? byePlayerId,  DateTime? createdAt)  $default,) {final _that = this;
switch (_that) {
case _BracketNode():
return $default(_that.id,_that.phaseId,_that.competitionId,_that.roundNumber,_that.positionInRound,_that.totalRounds,_that.matchId,_that.nextNodeId,_that.parentNodeId,_that.nextPosition,_that.isGrandFinal,_that.isThirdPlaceMatch,_that.isBye,_that.byePlayerId,_that.createdAt);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String phaseId,  String competitionId,  int roundNumber,  int positionInRound,  int totalRounds,  String? matchId,  String? nextNodeId,  String? parentNodeId,  String? nextPosition,  bool isGrandFinal,  bool isThirdPlaceMatch,  bool isBye,  String? byePlayerId,  DateTime? createdAt)?  $default,) {final _that = this;
switch (_that) {
case _BracketNode() when $default != null:
return $default(_that.id,_that.phaseId,_that.competitionId,_that.roundNumber,_that.positionInRound,_that.totalRounds,_that.matchId,_that.nextNodeId,_that.parentNodeId,_that.nextPosition,_that.isGrandFinal,_that.isThirdPlaceMatch,_that.isBye,_that.byePlayerId,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BracketNode implements BracketNode {
  const _BracketNode({required this.id, required this.phaseId, required this.competitionId, required this.roundNumber, required this.positionInRound, required this.totalRounds, this.matchId, this.nextNodeId, this.parentNodeId, this.nextPosition, this.isGrandFinal = false, this.isThirdPlaceMatch = false, this.isBye = false, this.byePlayerId, this.createdAt});
  factory _BracketNode.fromJson(Map<String, dynamic> json) => _$BracketNodeFromJson(json);

@override final  String id;
@override final  String phaseId;
@override final  String competitionId;
@override final  int roundNumber;
@override final  int positionInRound;
@override final  int totalRounds;
@override final  String? matchId;
@override final  String? nextNodeId;
@override final  String? parentNodeId;
@override final  String? nextPosition;
@override@JsonKey() final  bool isGrandFinal;
@override@JsonKey() final  bool isThirdPlaceMatch;
@override@JsonKey() final  bool isBye;
@override final  String? byePlayerId;
@override final  DateTime? createdAt;

/// Create a copy of BracketNode
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BracketNodeCopyWith<_BracketNode> get copyWith => __$BracketNodeCopyWithImpl<_BracketNode>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BracketNodeToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _BracketNode&&(identical(other.id, id) || other.id == id)&&(identical(other.phaseId, phaseId) || other.phaseId == phaseId)&&(identical(other.competitionId, competitionId) || other.competitionId == competitionId)&&(identical(other.roundNumber, roundNumber) || other.roundNumber == roundNumber)&&(identical(other.positionInRound, positionInRound) || other.positionInRound == positionInRound)&&(identical(other.totalRounds, totalRounds) || other.totalRounds == totalRounds)&&(identical(other.matchId, matchId) || other.matchId == matchId)&&(identical(other.nextNodeId, nextNodeId) || other.nextNodeId == nextNodeId)&&(identical(other.parentNodeId, parentNodeId) || other.parentNodeId == parentNodeId)&&(identical(other.nextPosition, nextPosition) || other.nextPosition == nextPosition)&&(identical(other.isGrandFinal, isGrandFinal) || other.isGrandFinal == isGrandFinal)&&(identical(other.isThirdPlaceMatch, isThirdPlaceMatch) || other.isThirdPlaceMatch == isThirdPlaceMatch)&&(identical(other.isBye, isBye) || other.isBye == isBye)&&(identical(other.byePlayerId, byePlayerId) || other.byePlayerId == byePlayerId)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,phaseId,competitionId,roundNumber,positionInRound,totalRounds,matchId,nextNodeId,parentNodeId,nextPosition,isGrandFinal,isThirdPlaceMatch,isBye,byePlayerId,createdAt);
}

@override
String toString() {
    return 'BracketNode(id: $id, phaseId: $phaseId, competitionId: $competitionId, roundNumber: $roundNumber, positionInRound: $positionInRound, totalRounds: $totalRounds, matchId: $matchId, nextNodeId: $nextNodeId, parentNodeId: $parentNodeId, nextPosition: $nextPosition, isGrandFinal: $isGrandFinal, isThirdPlaceMatch: $isThirdPlaceMatch, isBye: $isBye, byePlayerId: $byePlayerId, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$BracketNodeCopyWith<$Res> implements $BracketNodeCopyWith<$Res> {
  factory _$BracketNodeCopyWith(_BracketNode value, $Res Function(_BracketNode) _then) = __$BracketNodeCopyWithImpl;
@override @useResult
$Res call({
 String id, String phaseId, String competitionId, int roundNumber, int positionInRound, int totalRounds, String? matchId, String? nextNodeId, String? parentNodeId, String? nextPosition, bool isGrandFinal, bool isThirdPlaceMatch, bool isBye, String? byePlayerId, DateTime? createdAt
});




}
/// @nodoc
class __$BracketNodeCopyWithImpl<$Res>
    implements _$BracketNodeCopyWith<$Res> {
  __$BracketNodeCopyWithImpl(this._self, this._then);

  final _BracketNode _self;
  final $Res Function(_BracketNode) _then;

/// Create a copy of BracketNode
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? phaseId = null,Object? competitionId = null,Object? roundNumber = null,Object? positionInRound = null,Object? totalRounds = null,Object? matchId = freezed,Object? nextNodeId = freezed,Object? parentNodeId = freezed,Object? nextPosition = freezed,Object? isGrandFinal = null,Object? isThirdPlaceMatch = null,Object? isBye = null,Object? byePlayerId = freezed,Object? createdAt = freezed,}) {
  return _then(_BracketNode(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,phaseId: null == phaseId ? _self.phaseId : phaseId // ignore: cast_nullable_to_non_nullable
as String,competitionId: null == competitionId ? _self.competitionId : competitionId // ignore: cast_nullable_to_non_nullable
as String,roundNumber: null == roundNumber ? _self.roundNumber : roundNumber // ignore: cast_nullable_to_non_nullable
as int,positionInRound: null == positionInRound ? _self.positionInRound : positionInRound // ignore: cast_nullable_to_non_nullable
as int,totalRounds: null == totalRounds ? _self.totalRounds : totalRounds // ignore: cast_nullable_to_non_nullable
as int,matchId: freezed == matchId ? _self.matchId : matchId // ignore: cast_nullable_to_non_nullable
as String?,nextNodeId: freezed == nextNodeId ? _self.nextNodeId : nextNodeId // ignore: cast_nullable_to_non_nullable
as String?,parentNodeId: freezed == parentNodeId ? _self.parentNodeId : parentNodeId // ignore: cast_nullable_to_non_nullable
as String?,nextPosition: freezed == nextPosition ? _self.nextPosition : nextPosition // ignore: cast_nullable_to_non_nullable
as String?,isGrandFinal: null == isGrandFinal ? _self.isGrandFinal : isGrandFinal // ignore: cast_nullable_to_non_nullable
as bool,isThirdPlaceMatch: null == isThirdPlaceMatch ? _self.isThirdPlaceMatch : isThirdPlaceMatch // ignore: cast_nullable_to_non_nullable
as bool,isBye: null == isBye ? _self.isBye : isBye // ignore: cast_nullable_to_non_nullable
as bool,byePlayerId: freezed == byePlayerId ? _self.byePlayerId : byePlayerId // ignore: cast_nullable_to_non_nullable
as String?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
