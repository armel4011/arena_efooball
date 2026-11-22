// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'standings.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$CompetitionGroup {

 String get id; String get competitionId; String get name; int get groupNumber;
/// Create a copy of CompetitionGroup
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CompetitionGroupCopyWith<CompetitionGroup> get copyWith => _$CompetitionGroupCopyWithImpl<CompetitionGroup>(this as CompetitionGroup, _$identity);

  /// Serializes this CompetitionGroup to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as CompetitionGroup;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CompetitionGroup&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.competitionId, _this.competitionId) || other.competitionId == _this.competitionId)&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.groupNumber, _this.groupNumber) || other.groupNumber == _this.groupNumber));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as CompetitionGroup;
  return Object.hash(runtimeType,_this.id,_this.competitionId,_this.name,_this.groupNumber);
}

@override
String toString() {
  final _this = this as CompetitionGroup;
  return 'CompetitionGroup(id: ${_this.id}, competitionId: ${_this.competitionId}, name: ${_this.name}, groupNumber: ${_this.groupNumber})';
}


}

/// @nodoc
abstract mixin class $CompetitionGroupCopyWith<$Res>  {
  factory $CompetitionGroupCopyWith(CompetitionGroup value, $Res Function(CompetitionGroup) _then) = _$CompetitionGroupCopyWithImpl;
@useResult
$Res call({
 String id, String competitionId, String name, int groupNumber
});




}
/// @nodoc
class _$CompetitionGroupCopyWithImpl<$Res>
    implements $CompetitionGroupCopyWith<$Res> {
  _$CompetitionGroupCopyWithImpl(this._self, this._then);

  final CompetitionGroup _self;
  final $Res Function(CompetitionGroup) _then;

/// Create a copy of CompetitionGroup
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? competitionId = null,Object? name = null,Object? groupNumber = null,}) {
  return _then(CompetitionGroup(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,competitionId: null == competitionId ? _self.competitionId : competitionId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,groupNumber: null == groupNumber ? _self.groupNumber : groupNumber // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [CompetitionGroup].
extension CompetitionGroupPatterns on CompetitionGroup {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CompetitionGroup value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CompetitionGroup() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CompetitionGroup value)  $default,){
final _that = this;
switch (_that) {
case _CompetitionGroup():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CompetitionGroup value)?  $default,){
final _that = this;
switch (_that) {
case _CompetitionGroup() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String competitionId,  String name,  int groupNumber)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CompetitionGroup() when $default != null:
return $default(_that.id,_that.competitionId,_that.name,_that.groupNumber);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String competitionId,  String name,  int groupNumber)  $default,) {final _that = this;
switch (_that) {
case _CompetitionGroup():
return $default(_that.id,_that.competitionId,_that.name,_that.groupNumber);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String competitionId,  String name,  int groupNumber)?  $default,) {final _that = this;
switch (_that) {
case _CompetitionGroup() when $default != null:
return $default(_that.id,_that.competitionId,_that.name,_that.groupNumber);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CompetitionGroup implements CompetitionGroup {
  const _CompetitionGroup({required this.id, required this.competitionId, required this.name, required this.groupNumber});
  factory _CompetitionGroup.fromJson(Map<String, dynamic> json) => _$CompetitionGroupFromJson(json);

@override final  String id;
@override final  String competitionId;
@override final  String name;
@override final  int groupNumber;

/// Create a copy of CompetitionGroup
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CompetitionGroupCopyWith<_CompetitionGroup> get copyWith => __$CompetitionGroupCopyWithImpl<_CompetitionGroup>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CompetitionGroupToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _CompetitionGroup&&(identical(other.id, id) || other.id == id)&&(identical(other.competitionId, competitionId) || other.competitionId == competitionId)&&(identical(other.name, name) || other.name == name)&&(identical(other.groupNumber, groupNumber) || other.groupNumber == groupNumber));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,competitionId,name,groupNumber);
}

@override
String toString() {
    return 'CompetitionGroup(id: $id, competitionId: $competitionId, name: $name, groupNumber: $groupNumber)';
}


}

/// @nodoc
abstract mixin class _$CompetitionGroupCopyWith<$Res> implements $CompetitionGroupCopyWith<$Res> {
  factory _$CompetitionGroupCopyWith(_CompetitionGroup value, $Res Function(_CompetitionGroup) _then) = __$CompetitionGroupCopyWithImpl;
@override @useResult
$Res call({
 String id, String competitionId, String name, int groupNumber
});




}
/// @nodoc
class __$CompetitionGroupCopyWithImpl<$Res>
    implements _$CompetitionGroupCopyWith<$Res> {
  __$CompetitionGroupCopyWithImpl(this._self, this._then);

  final _CompetitionGroup _self;
  final $Res Function(_CompetitionGroup) _then;

/// Create a copy of CompetitionGroup
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? competitionId = null,Object? name = null,Object? groupNumber = null,}) {
  return _then(_CompetitionGroup(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,competitionId: null == competitionId ? _self.competitionId : competitionId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,groupNumber: null == groupNumber ? _self.groupNumber : groupNumber // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$GroupStandingRow {

 String get id; String get groupId; String get profileId; int? get position; int get points; int get played; int get wins; int get draws; int get losses; int get goalsFor; int get goalsAgainst; int get goalDiff;
/// Create a copy of GroupStandingRow
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GroupStandingRowCopyWith<GroupStandingRow> get copyWith => _$GroupStandingRowCopyWithImpl<GroupStandingRow>(this as GroupStandingRow, _$identity);

  /// Serializes this GroupStandingRow to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as GroupStandingRow;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GroupStandingRow&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.groupId, _this.groupId) || other.groupId == _this.groupId)&&(identical(other.profileId, _this.profileId) || other.profileId == _this.profileId)&&(identical(other.position, _this.position) || other.position == _this.position)&&(identical(other.points, _this.points) || other.points == _this.points)&&(identical(other.played, _this.played) || other.played == _this.played)&&(identical(other.wins, _this.wins) || other.wins == _this.wins)&&(identical(other.draws, _this.draws) || other.draws == _this.draws)&&(identical(other.losses, _this.losses) || other.losses == _this.losses)&&(identical(other.goalsFor, _this.goalsFor) || other.goalsFor == _this.goalsFor)&&(identical(other.goalsAgainst, _this.goalsAgainst) || other.goalsAgainst == _this.goalsAgainst)&&(identical(other.goalDiff, _this.goalDiff) || other.goalDiff == _this.goalDiff));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as GroupStandingRow;
  return Object.hash(runtimeType,_this.id,_this.groupId,_this.profileId,_this.position,_this.points,_this.played,_this.wins,_this.draws,_this.losses,_this.goalsFor,_this.goalsAgainst,_this.goalDiff);
}

@override
String toString() {
  final _this = this as GroupStandingRow;
  return 'GroupStandingRow(id: ${_this.id}, groupId: ${_this.groupId}, profileId: ${_this.profileId}, position: ${_this.position}, points: ${_this.points}, played: ${_this.played}, wins: ${_this.wins}, draws: ${_this.draws}, losses: ${_this.losses}, goalsFor: ${_this.goalsFor}, goalsAgainst: ${_this.goalsAgainst}, goalDiff: ${_this.goalDiff})';
}


}

/// @nodoc
abstract mixin class $GroupStandingRowCopyWith<$Res>  {
  factory $GroupStandingRowCopyWith(GroupStandingRow value, $Res Function(GroupStandingRow) _then) = _$GroupStandingRowCopyWithImpl;
@useResult
$Res call({
 String id, String groupId, String profileId, int? position, int points, int played, int wins, int draws, int losses, int goalsFor, int goalsAgainst, int goalDiff
});




}
/// @nodoc
class _$GroupStandingRowCopyWithImpl<$Res>
    implements $GroupStandingRowCopyWith<$Res> {
  _$GroupStandingRowCopyWithImpl(this._self, this._then);

  final GroupStandingRow _self;
  final $Res Function(GroupStandingRow) _then;

/// Create a copy of GroupStandingRow
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? groupId = null,Object? profileId = null,Object? position = freezed,Object? points = null,Object? played = null,Object? wins = null,Object? draws = null,Object? losses = null,Object? goalsFor = null,Object? goalsAgainst = null,Object? goalDiff = null,}) {
  return _then(GroupStandingRow(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,groupId: null == groupId ? _self.groupId : groupId // ignore: cast_nullable_to_non_nullable
as String,profileId: null == profileId ? _self.profileId : profileId // ignore: cast_nullable_to_non_nullable
as String,position: freezed == position ? _self.position : position // ignore: cast_nullable_to_non_nullable
as int?,points: null == points ? _self.points : points // ignore: cast_nullable_to_non_nullable
as int,played: null == played ? _self.played : played // ignore: cast_nullable_to_non_nullable
as int,wins: null == wins ? _self.wins : wins // ignore: cast_nullable_to_non_nullable
as int,draws: null == draws ? _self.draws : draws // ignore: cast_nullable_to_non_nullable
as int,losses: null == losses ? _self.losses : losses // ignore: cast_nullable_to_non_nullable
as int,goalsFor: null == goalsFor ? _self.goalsFor : goalsFor // ignore: cast_nullable_to_non_nullable
as int,goalsAgainst: null == goalsAgainst ? _self.goalsAgainst : goalsAgainst // ignore: cast_nullable_to_non_nullable
as int,goalDiff: null == goalDiff ? _self.goalDiff : goalDiff // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [GroupStandingRow].
extension GroupStandingRowPatterns on GroupStandingRow {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _GroupStandingRow value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _GroupStandingRow() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _GroupStandingRow value)  $default,){
final _that = this;
switch (_that) {
case _GroupStandingRow():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _GroupStandingRow value)?  $default,){
final _that = this;
switch (_that) {
case _GroupStandingRow() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String groupId,  String profileId,  int? position,  int points,  int played,  int wins,  int draws,  int losses,  int goalsFor,  int goalsAgainst,  int goalDiff)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _GroupStandingRow() when $default != null:
return $default(_that.id,_that.groupId,_that.profileId,_that.position,_that.points,_that.played,_that.wins,_that.draws,_that.losses,_that.goalsFor,_that.goalsAgainst,_that.goalDiff);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String groupId,  String profileId,  int? position,  int points,  int played,  int wins,  int draws,  int losses,  int goalsFor,  int goalsAgainst,  int goalDiff)  $default,) {final _that = this;
switch (_that) {
case _GroupStandingRow():
return $default(_that.id,_that.groupId,_that.profileId,_that.position,_that.points,_that.played,_that.wins,_that.draws,_that.losses,_that.goalsFor,_that.goalsAgainst,_that.goalDiff);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String groupId,  String profileId,  int? position,  int points,  int played,  int wins,  int draws,  int losses,  int goalsFor,  int goalsAgainst,  int goalDiff)?  $default,) {final _that = this;
switch (_that) {
case _GroupStandingRow() when $default != null:
return $default(_that.id,_that.groupId,_that.profileId,_that.position,_that.points,_that.played,_that.wins,_that.draws,_that.losses,_that.goalsFor,_that.goalsAgainst,_that.goalDiff);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _GroupStandingRow implements GroupStandingRow {
  const _GroupStandingRow({required this.id, required this.groupId, required this.profileId, this.position, this.points = 0, this.played = 0, this.wins = 0, this.draws = 0, this.losses = 0, this.goalsFor = 0, this.goalsAgainst = 0, this.goalDiff = 0});
  factory _GroupStandingRow.fromJson(Map<String, dynamic> json) => _$GroupStandingRowFromJson(json);

@override final  String id;
@override final  String groupId;
@override final  String profileId;
@override final  int? position;
@override@JsonKey() final  int points;
@override@JsonKey() final  int played;
@override@JsonKey() final  int wins;
@override@JsonKey() final  int draws;
@override@JsonKey() final  int losses;
@override@JsonKey() final  int goalsFor;
@override@JsonKey() final  int goalsAgainst;
@override@JsonKey() final  int goalDiff;

/// Create a copy of GroupStandingRow
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GroupStandingRowCopyWith<_GroupStandingRow> get copyWith => __$GroupStandingRowCopyWithImpl<_GroupStandingRow>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$GroupStandingRowToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _GroupStandingRow&&(identical(other.id, id) || other.id == id)&&(identical(other.groupId, groupId) || other.groupId == groupId)&&(identical(other.profileId, profileId) || other.profileId == profileId)&&(identical(other.position, position) || other.position == position)&&(identical(other.points, points) || other.points == points)&&(identical(other.played, played) || other.played == played)&&(identical(other.wins, wins) || other.wins == wins)&&(identical(other.draws, draws) || other.draws == draws)&&(identical(other.losses, losses) || other.losses == losses)&&(identical(other.goalsFor, goalsFor) || other.goalsFor == goalsFor)&&(identical(other.goalsAgainst, goalsAgainst) || other.goalsAgainst == goalsAgainst)&&(identical(other.goalDiff, goalDiff) || other.goalDiff == goalDiff));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,groupId,profileId,position,points,played,wins,draws,losses,goalsFor,goalsAgainst,goalDiff);
}

@override
String toString() {
    return 'GroupStandingRow(id: $id, groupId: $groupId, profileId: $profileId, position: $position, points: $points, played: $played, wins: $wins, draws: $draws, losses: $losses, goalsFor: $goalsFor, goalsAgainst: $goalsAgainst, goalDiff: $goalDiff)';
}


}

/// @nodoc
abstract mixin class _$GroupStandingRowCopyWith<$Res> implements $GroupStandingRowCopyWith<$Res> {
  factory _$GroupStandingRowCopyWith(_GroupStandingRow value, $Res Function(_GroupStandingRow) _then) = __$GroupStandingRowCopyWithImpl;
@override @useResult
$Res call({
 String id, String groupId, String profileId, int? position, int points, int played, int wins, int draws, int losses, int goalsFor, int goalsAgainst, int goalDiff
});




}
/// @nodoc
class __$GroupStandingRowCopyWithImpl<$Res>
    implements _$GroupStandingRowCopyWith<$Res> {
  __$GroupStandingRowCopyWithImpl(this._self, this._then);

  final _GroupStandingRow _self;
  final $Res Function(_GroupStandingRow) _then;

/// Create a copy of GroupStandingRow
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? groupId = null,Object? profileId = null,Object? position = freezed,Object? points = null,Object? played = null,Object? wins = null,Object? draws = null,Object? losses = null,Object? goalsFor = null,Object? goalsAgainst = null,Object? goalDiff = null,}) {
  return _then(_GroupStandingRow(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,groupId: null == groupId ? _self.groupId : groupId // ignore: cast_nullable_to_non_nullable
as String,profileId: null == profileId ? _self.profileId : profileId // ignore: cast_nullable_to_non_nullable
as String,position: freezed == position ? _self.position : position // ignore: cast_nullable_to_non_nullable
as int?,points: null == points ? _self.points : points // ignore: cast_nullable_to_non_nullable
as int,played: null == played ? _self.played : played // ignore: cast_nullable_to_non_nullable
as int,wins: null == wins ? _self.wins : wins // ignore: cast_nullable_to_non_nullable
as int,draws: null == draws ? _self.draws : draws // ignore: cast_nullable_to_non_nullable
as int,losses: null == losses ? _self.losses : losses // ignore: cast_nullable_to_non_nullable
as int,goalsFor: null == goalsFor ? _self.goalsFor : goalsFor // ignore: cast_nullable_to_non_nullable
as int,goalsAgainst: null == goalsAgainst ? _self.goalsAgainst : goalsAgainst // ignore: cast_nullable_to_non_nullable
as int,goalDiff: null == goalDiff ? _self.goalDiff : goalDiff // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
