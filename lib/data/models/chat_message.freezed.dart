// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'chat_message.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ChatMessage {

 String get id; String get channelId; String get content; String? get senderId; String get type; bool get isModerated; DateTime? get moderatedAt; String? get moderatedReason; DateTime? get createdAt; String? get mediaUrl; String? get mediaType; DateTime? get deletedAt;
/// Create a copy of ChatMessage
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChatMessageCopyWith<ChatMessage> get copyWith => _$ChatMessageCopyWithImpl<ChatMessage>(this as ChatMessage, _$identity);

  /// Serializes this ChatMessage to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as ChatMessage;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChatMessage&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.channelId, _this.channelId) || other.channelId == _this.channelId)&&(identical(other.content, _this.content) || other.content == _this.content)&&(identical(other.senderId, _this.senderId) || other.senderId == _this.senderId)&&(identical(other.type, _this.type) || other.type == _this.type)&&(identical(other.isModerated, _this.isModerated) || other.isModerated == _this.isModerated)&&(identical(other.moderatedAt, _this.moderatedAt) || other.moderatedAt == _this.moderatedAt)&&(identical(other.moderatedReason, _this.moderatedReason) || other.moderatedReason == _this.moderatedReason)&&(identical(other.createdAt, _this.createdAt) || other.createdAt == _this.createdAt)&&(identical(other.mediaUrl, _this.mediaUrl) || other.mediaUrl == _this.mediaUrl)&&(identical(other.mediaType, _this.mediaType) || other.mediaType == _this.mediaType)&&(identical(other.deletedAt, _this.deletedAt) || other.deletedAt == _this.deletedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as ChatMessage;
  return Object.hash(runtimeType,_this.id,_this.channelId,_this.content,_this.senderId,_this.type,_this.isModerated,_this.moderatedAt,_this.moderatedReason,_this.createdAt,_this.mediaUrl,_this.mediaType,_this.deletedAt);
}

@override
String toString() {
  final _this = this as ChatMessage;
  return 'ChatMessage(id: ${_this.id}, channelId: ${_this.channelId}, content: ${_this.content}, senderId: ${_this.senderId}, type: ${_this.type}, isModerated: ${_this.isModerated}, moderatedAt: ${_this.moderatedAt}, moderatedReason: ${_this.moderatedReason}, createdAt: ${_this.createdAt}, mediaUrl: ${_this.mediaUrl}, mediaType: ${_this.mediaType}, deletedAt: ${_this.deletedAt})';
}


}

/// @nodoc
abstract mixin class $ChatMessageCopyWith<$Res>  {
  factory $ChatMessageCopyWith(ChatMessage value, $Res Function(ChatMessage) _then) = _$ChatMessageCopyWithImpl;
@useResult
$Res call({
 String id, String channelId, String content, String? senderId, String type, bool isModerated, DateTime? moderatedAt, String? moderatedReason, DateTime? createdAt, String? mediaUrl, String? mediaType, DateTime? deletedAt
});




}
/// @nodoc
class _$ChatMessageCopyWithImpl<$Res>
    implements $ChatMessageCopyWith<$Res> {
  _$ChatMessageCopyWithImpl(this._self, this._then);

  final ChatMessage _self;
  final $Res Function(ChatMessage) _then;

/// Create a copy of ChatMessage
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? channelId = null,Object? content = null,Object? senderId = freezed,Object? type = null,Object? isModerated = null,Object? moderatedAt = freezed,Object? moderatedReason = freezed,Object? createdAt = freezed,Object? mediaUrl = freezed,Object? mediaType = freezed,Object? deletedAt = freezed,}) {
  return _then(ChatMessage(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,channelId: null == channelId ? _self.channelId : channelId // ignore: cast_nullable_to_non_nullable
as String,content: null == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String,senderId: freezed == senderId ? _self.senderId : senderId // ignore: cast_nullable_to_non_nullable
as String?,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,isModerated: null == isModerated ? _self.isModerated : isModerated // ignore: cast_nullable_to_non_nullable
as bool,moderatedAt: freezed == moderatedAt ? _self.moderatedAt : moderatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,moderatedReason: freezed == moderatedReason ? _self.moderatedReason : moderatedReason // ignore: cast_nullable_to_non_nullable
as String?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,mediaUrl: freezed == mediaUrl ? _self.mediaUrl : mediaUrl // ignore: cast_nullable_to_non_nullable
as String?,mediaType: freezed == mediaType ? _self.mediaType : mediaType // ignore: cast_nullable_to_non_nullable
as String?,deletedAt: freezed == deletedAt ? _self.deletedAt : deletedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [ChatMessage].
extension ChatMessagePatterns on ChatMessage {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ChatMessage value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ChatMessage() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ChatMessage value)  $default,){
final _that = this;
switch (_that) {
case _ChatMessage():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ChatMessage value)?  $default,){
final _that = this;
switch (_that) {
case _ChatMessage() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String channelId,  String content,  String? senderId,  String type,  bool isModerated,  DateTime? moderatedAt,  String? moderatedReason,  DateTime? createdAt,  String? mediaUrl,  String? mediaType,  DateTime? deletedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ChatMessage() when $default != null:
return $default(_that.id,_that.channelId,_that.content,_that.senderId,_that.type,_that.isModerated,_that.moderatedAt,_that.moderatedReason,_that.createdAt,_that.mediaUrl,_that.mediaType,_that.deletedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String channelId,  String content,  String? senderId,  String type,  bool isModerated,  DateTime? moderatedAt,  String? moderatedReason,  DateTime? createdAt,  String? mediaUrl,  String? mediaType,  DateTime? deletedAt)  $default,) {final _that = this;
switch (_that) {
case _ChatMessage():
return $default(_that.id,_that.channelId,_that.content,_that.senderId,_that.type,_that.isModerated,_that.moderatedAt,_that.moderatedReason,_that.createdAt,_that.mediaUrl,_that.mediaType,_that.deletedAt);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String channelId,  String content,  String? senderId,  String type,  bool isModerated,  DateTime? moderatedAt,  String? moderatedReason,  DateTime? createdAt,  String? mediaUrl,  String? mediaType,  DateTime? deletedAt)?  $default,) {final _that = this;
switch (_that) {
case _ChatMessage() when $default != null:
return $default(_that.id,_that.channelId,_that.content,_that.senderId,_that.type,_that.isModerated,_that.moderatedAt,_that.moderatedReason,_that.createdAt,_that.mediaUrl,_that.mediaType,_that.deletedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ChatMessage implements ChatMessage {
  const _ChatMessage({required this.id, required this.channelId, required this.content, this.senderId, this.type = 'text', this.isModerated = false, this.moderatedAt, this.moderatedReason, this.createdAt, this.mediaUrl, this.mediaType, this.deletedAt});
  factory _ChatMessage.fromJson(Map<String, dynamic> json) => _$ChatMessageFromJson(json);

@override final  String id;
@override final  String channelId;
@override final  String content;
@override final  String? senderId;
@override@JsonKey() final  String type;
@override@JsonKey() final  bool isModerated;
@override final  DateTime? moderatedAt;
@override final  String? moderatedReason;
@override final  DateTime? createdAt;
@override final  String? mediaUrl;
@override final  String? mediaType;
@override final  DateTime? deletedAt;

/// Create a copy of ChatMessage
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ChatMessageCopyWith<_ChatMessage> get copyWith => __$ChatMessageCopyWithImpl<_ChatMessage>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ChatMessageToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ChatMessage&&(identical(other.id, id) || other.id == id)&&(identical(other.channelId, channelId) || other.channelId == channelId)&&(identical(other.content, content) || other.content == content)&&(identical(other.senderId, senderId) || other.senderId == senderId)&&(identical(other.type, type) || other.type == type)&&(identical(other.isModerated, isModerated) || other.isModerated == isModerated)&&(identical(other.moderatedAt, moderatedAt) || other.moderatedAt == moderatedAt)&&(identical(other.moderatedReason, moderatedReason) || other.moderatedReason == moderatedReason)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.mediaUrl, mediaUrl) || other.mediaUrl == mediaUrl)&&(identical(other.mediaType, mediaType) || other.mediaType == mediaType)&&(identical(other.deletedAt, deletedAt) || other.deletedAt == deletedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,channelId,content,senderId,type,isModerated,moderatedAt,moderatedReason,createdAt,mediaUrl,mediaType,deletedAt);
}

@override
String toString() {
    return 'ChatMessage(id: $id, channelId: $channelId, content: $content, senderId: $senderId, type: $type, isModerated: $isModerated, moderatedAt: $moderatedAt, moderatedReason: $moderatedReason, createdAt: $createdAt, mediaUrl: $mediaUrl, mediaType: $mediaType, deletedAt: $deletedAt)';
}


}

/// @nodoc
abstract mixin class _$ChatMessageCopyWith<$Res> implements $ChatMessageCopyWith<$Res> {
  factory _$ChatMessageCopyWith(_ChatMessage value, $Res Function(_ChatMessage) _then) = __$ChatMessageCopyWithImpl;
@override @useResult
$Res call({
 String id, String channelId, String content, String? senderId, String type, bool isModerated, DateTime? moderatedAt, String? moderatedReason, DateTime? createdAt, String? mediaUrl, String? mediaType, DateTime? deletedAt
});




}
/// @nodoc
class __$ChatMessageCopyWithImpl<$Res>
    implements _$ChatMessageCopyWith<$Res> {
  __$ChatMessageCopyWithImpl(this._self, this._then);

  final _ChatMessage _self;
  final $Res Function(_ChatMessage) _then;

/// Create a copy of ChatMessage
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? channelId = null,Object? content = null,Object? senderId = freezed,Object? type = null,Object? isModerated = null,Object? moderatedAt = freezed,Object? moderatedReason = freezed,Object? createdAt = freezed,Object? mediaUrl = freezed,Object? mediaType = freezed,Object? deletedAt = freezed,}) {
  return _then(_ChatMessage(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,channelId: null == channelId ? _self.channelId : channelId // ignore: cast_nullable_to_non_nullable
as String,content: null == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String,senderId: freezed == senderId ? _self.senderId : senderId // ignore: cast_nullable_to_non_nullable
as String?,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,isModerated: null == isModerated ? _self.isModerated : isModerated // ignore: cast_nullable_to_non_nullable
as bool,moderatedAt: freezed == moderatedAt ? _self.moderatedAt : moderatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,moderatedReason: freezed == moderatedReason ? _self.moderatedReason : moderatedReason // ignore: cast_nullable_to_non_nullable
as String?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,mediaUrl: freezed == mediaUrl ? _self.mediaUrl : mediaUrl // ignore: cast_nullable_to_non_nullable
as String?,mediaType: freezed == mediaType ? _self.mediaType : mediaType // ignore: cast_nullable_to_non_nullable
as String?,deletedAt: freezed == deletedAt ? _self.deletedAt : deletedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
