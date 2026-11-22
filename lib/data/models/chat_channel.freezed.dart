// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'chat_channel.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ChatChannel {

 String get id; String get type; String? get matchId; String? get competitionId; String? get friendshipId; String? get name; bool get isArchived; DateTime? get createdAt; DateTime? get deletedAt;
/// Create a copy of ChatChannel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChatChannelCopyWith<ChatChannel> get copyWith => _$ChatChannelCopyWithImpl<ChatChannel>(this as ChatChannel, _$identity);

  /// Serializes this ChatChannel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as ChatChannel;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChatChannel&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.type, _this.type) || other.type == _this.type)&&(identical(other.matchId, _this.matchId) || other.matchId == _this.matchId)&&(identical(other.competitionId, _this.competitionId) || other.competitionId == _this.competitionId)&&(identical(other.friendshipId, _this.friendshipId) || other.friendshipId == _this.friendshipId)&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.isArchived, _this.isArchived) || other.isArchived == _this.isArchived)&&(identical(other.createdAt, _this.createdAt) || other.createdAt == _this.createdAt)&&(identical(other.deletedAt, _this.deletedAt) || other.deletedAt == _this.deletedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as ChatChannel;
  return Object.hash(runtimeType,_this.id,_this.type,_this.matchId,_this.competitionId,_this.friendshipId,_this.name,_this.isArchived,_this.createdAt,_this.deletedAt);
}

@override
String toString() {
  final _this = this as ChatChannel;
  return 'ChatChannel(id: ${_this.id}, type: ${_this.type}, matchId: ${_this.matchId}, competitionId: ${_this.competitionId}, friendshipId: ${_this.friendshipId}, name: ${_this.name}, isArchived: ${_this.isArchived}, createdAt: ${_this.createdAt}, deletedAt: ${_this.deletedAt})';
}


}

/// @nodoc
abstract mixin class $ChatChannelCopyWith<$Res>  {
  factory $ChatChannelCopyWith(ChatChannel value, $Res Function(ChatChannel) _then) = _$ChatChannelCopyWithImpl;
@useResult
$Res call({
 String id, String type, String? matchId, String? competitionId, String? friendshipId, String? name, bool isArchived, DateTime? createdAt, DateTime? deletedAt
});




}
/// @nodoc
class _$ChatChannelCopyWithImpl<$Res>
    implements $ChatChannelCopyWith<$Res> {
  _$ChatChannelCopyWithImpl(this._self, this._then);

  final ChatChannel _self;
  final $Res Function(ChatChannel) _then;

/// Create a copy of ChatChannel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? type = null,Object? matchId = freezed,Object? competitionId = freezed,Object? friendshipId = freezed,Object? name = freezed,Object? isArchived = null,Object? createdAt = freezed,Object? deletedAt = freezed,}) {
  return _then(ChatChannel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,matchId: freezed == matchId ? _self.matchId : matchId // ignore: cast_nullable_to_non_nullable
as String?,competitionId: freezed == competitionId ? _self.competitionId : competitionId // ignore: cast_nullable_to_non_nullable
as String?,friendshipId: freezed == friendshipId ? _self.friendshipId : friendshipId // ignore: cast_nullable_to_non_nullable
as String?,name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,isArchived: null == isArchived ? _self.isArchived : isArchived // ignore: cast_nullable_to_non_nullable
as bool,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,deletedAt: freezed == deletedAt ? _self.deletedAt : deletedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [ChatChannel].
extension ChatChannelPatterns on ChatChannel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ChatChannel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ChatChannel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ChatChannel value)  $default,){
final _that = this;
switch (_that) {
case _ChatChannel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ChatChannel value)?  $default,){
final _that = this;
switch (_that) {
case _ChatChannel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String type,  String? matchId,  String? competitionId,  String? friendshipId,  String? name,  bool isArchived,  DateTime? createdAt,  DateTime? deletedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ChatChannel() when $default != null:
return $default(_that.id,_that.type,_that.matchId,_that.competitionId,_that.friendshipId,_that.name,_that.isArchived,_that.createdAt,_that.deletedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String type,  String? matchId,  String? competitionId,  String? friendshipId,  String? name,  bool isArchived,  DateTime? createdAt,  DateTime? deletedAt)  $default,) {final _that = this;
switch (_that) {
case _ChatChannel():
return $default(_that.id,_that.type,_that.matchId,_that.competitionId,_that.friendshipId,_that.name,_that.isArchived,_that.createdAt,_that.deletedAt);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String type,  String? matchId,  String? competitionId,  String? friendshipId,  String? name,  bool isArchived,  DateTime? createdAt,  DateTime? deletedAt)?  $default,) {final _that = this;
switch (_that) {
case _ChatChannel() when $default != null:
return $default(_that.id,_that.type,_that.matchId,_that.competitionId,_that.friendshipId,_that.name,_that.isArchived,_that.createdAt,_that.deletedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ChatChannel implements ChatChannel {
  const _ChatChannel({required this.id, required this.type, this.matchId, this.competitionId, this.friendshipId, this.name, this.isArchived = false, this.createdAt, this.deletedAt});
  factory _ChatChannel.fromJson(Map<String, dynamic> json) => _$ChatChannelFromJson(json);

@override final  String id;
@override final  String type;
@override final  String? matchId;
@override final  String? competitionId;
@override final  String? friendshipId;
@override final  String? name;
@override@JsonKey() final  bool isArchived;
@override final  DateTime? createdAt;
@override final  DateTime? deletedAt;

/// Create a copy of ChatChannel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ChatChannelCopyWith<_ChatChannel> get copyWith => __$ChatChannelCopyWithImpl<_ChatChannel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ChatChannelToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ChatChannel&&(identical(other.id, id) || other.id == id)&&(identical(other.type, type) || other.type == type)&&(identical(other.matchId, matchId) || other.matchId == matchId)&&(identical(other.competitionId, competitionId) || other.competitionId == competitionId)&&(identical(other.friendshipId, friendshipId) || other.friendshipId == friendshipId)&&(identical(other.name, name) || other.name == name)&&(identical(other.isArchived, isArchived) || other.isArchived == isArchived)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.deletedAt, deletedAt) || other.deletedAt == deletedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,type,matchId,competitionId,friendshipId,name,isArchived,createdAt,deletedAt);
}

@override
String toString() {
    return 'ChatChannel(id: $id, type: $type, matchId: $matchId, competitionId: $competitionId, friendshipId: $friendshipId, name: $name, isArchived: $isArchived, createdAt: $createdAt, deletedAt: $deletedAt)';
}


}

/// @nodoc
abstract mixin class _$ChatChannelCopyWith<$Res> implements $ChatChannelCopyWith<$Res> {
  factory _$ChatChannelCopyWith(_ChatChannel value, $Res Function(_ChatChannel) _then) = __$ChatChannelCopyWithImpl;
@override @useResult
$Res call({
 String id, String type, String? matchId, String? competitionId, String? friendshipId, String? name, bool isArchived, DateTime? createdAt, DateTime? deletedAt
});




}
/// @nodoc
class __$ChatChannelCopyWithImpl<$Res>
    implements _$ChatChannelCopyWith<$Res> {
  __$ChatChannelCopyWithImpl(this._self, this._then);

  final _ChatChannel _self;
  final $Res Function(_ChatChannel) _then;

/// Create a copy of ChatChannel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? type = null,Object? matchId = freezed,Object? competitionId = freezed,Object? friendshipId = freezed,Object? name = freezed,Object? isArchived = null,Object? createdAt = freezed,Object? deletedAt = freezed,}) {
  return _then(_ChatChannel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,matchId: freezed == matchId ? _self.matchId : matchId // ignore: cast_nullable_to_non_nullable
as String?,competitionId: freezed == competitionId ? _self.competitionId : competitionId // ignore: cast_nullable_to_non_nullable
as String?,friendshipId: freezed == friendshipId ? _self.friendshipId : friendshipId // ignore: cast_nullable_to_non_nullable
as String?,name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,isArchived: null == isArchived ? _self.isArchived : isArchived // ignore: cast_nullable_to_non_nullable
as bool,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,deletedAt: freezed == deletedAt ? _self.deletedAt : deletedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
