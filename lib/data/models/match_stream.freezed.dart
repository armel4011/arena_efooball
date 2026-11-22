// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'match_stream.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$MatchStream {

 String get id; String get matchId; String get playerId; bool get isPublic; bool get isActive; String? get url; DateTime? get startedAt; DateTime? get endedAt; String get provider; String? get storagePath; String? get egressId; DateTime? get expiresAt; String? get proofSha256; int? get proofBytes; int? get proofDurationSeconds; DateTime? get proofCommittedAt; DateTime? get proofClaimedAt; DateTime? get proofUploadedAt; bool? get proofHashVerified;
/// Create a copy of MatchStream
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MatchStreamCopyWith<MatchStream> get copyWith => _$MatchStreamCopyWithImpl<MatchStream>(this as MatchStream, _$identity);

  /// Serializes this MatchStream to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as MatchStream;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MatchStream&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.matchId, _this.matchId) || other.matchId == _this.matchId)&&(identical(other.playerId, _this.playerId) || other.playerId == _this.playerId)&&(identical(other.isPublic, _this.isPublic) || other.isPublic == _this.isPublic)&&(identical(other.isActive, _this.isActive) || other.isActive == _this.isActive)&&(identical(other.url, _this.url) || other.url == _this.url)&&(identical(other.startedAt, _this.startedAt) || other.startedAt == _this.startedAt)&&(identical(other.endedAt, _this.endedAt) || other.endedAt == _this.endedAt)&&(identical(other.provider, _this.provider) || other.provider == _this.provider)&&(identical(other.storagePath, _this.storagePath) || other.storagePath == _this.storagePath)&&(identical(other.egressId, _this.egressId) || other.egressId == _this.egressId)&&(identical(other.expiresAt, _this.expiresAt) || other.expiresAt == _this.expiresAt)&&(identical(other.proofSha256, _this.proofSha256) || other.proofSha256 == _this.proofSha256)&&(identical(other.proofBytes, _this.proofBytes) || other.proofBytes == _this.proofBytes)&&(identical(other.proofDurationSeconds, _this.proofDurationSeconds) || other.proofDurationSeconds == _this.proofDurationSeconds)&&(identical(other.proofCommittedAt, _this.proofCommittedAt) || other.proofCommittedAt == _this.proofCommittedAt)&&(identical(other.proofClaimedAt, _this.proofClaimedAt) || other.proofClaimedAt == _this.proofClaimedAt)&&(identical(other.proofUploadedAt, _this.proofUploadedAt) || other.proofUploadedAt == _this.proofUploadedAt)&&(identical(other.proofHashVerified, _this.proofHashVerified) || other.proofHashVerified == _this.proofHashVerified));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as MatchStream;
  return Object.hashAll([runtimeType,_this.id,_this.matchId,_this.playerId,_this.isPublic,_this.isActive,_this.url,_this.startedAt,_this.endedAt,_this.provider,_this.storagePath,_this.egressId,_this.expiresAt,_this.proofSha256,_this.proofBytes,_this.proofDurationSeconds,_this.proofCommittedAt,_this.proofClaimedAt,_this.proofUploadedAt,_this.proofHashVerified]);
}

@override
String toString() {
  final _this = this as MatchStream;
  return 'MatchStream(id: ${_this.id}, matchId: ${_this.matchId}, playerId: ${_this.playerId}, isPublic: ${_this.isPublic}, isActive: ${_this.isActive}, url: ${_this.url}, startedAt: ${_this.startedAt}, endedAt: ${_this.endedAt}, provider: ${_this.provider}, storagePath: ${_this.storagePath}, egressId: ${_this.egressId}, expiresAt: ${_this.expiresAt}, proofSha256: ${_this.proofSha256}, proofBytes: ${_this.proofBytes}, proofDurationSeconds: ${_this.proofDurationSeconds}, proofCommittedAt: ${_this.proofCommittedAt}, proofClaimedAt: ${_this.proofClaimedAt}, proofUploadedAt: ${_this.proofUploadedAt}, proofHashVerified: ${_this.proofHashVerified})';
}


}

/// @nodoc
abstract mixin class $MatchStreamCopyWith<$Res>  {
  factory $MatchStreamCopyWith(MatchStream value, $Res Function(MatchStream) _then) = _$MatchStreamCopyWithImpl;
@useResult
$Res call({
 String id, String matchId, String playerId, bool isPublic, bool isActive, String? url, DateTime? startedAt, DateTime? endedAt, String provider, String? storagePath, String? egressId, DateTime? expiresAt, String? proofSha256, int? proofBytes, int? proofDurationSeconds, DateTime? proofCommittedAt, DateTime? proofClaimedAt, DateTime? proofUploadedAt, bool? proofHashVerified
});




}
/// @nodoc
class _$MatchStreamCopyWithImpl<$Res>
    implements $MatchStreamCopyWith<$Res> {
  _$MatchStreamCopyWithImpl(this._self, this._then);

  final MatchStream _self;
  final $Res Function(MatchStream) _then;

/// Create a copy of MatchStream
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? matchId = null,Object? playerId = null,Object? isPublic = null,Object? isActive = null,Object? url = freezed,Object? startedAt = freezed,Object? endedAt = freezed,Object? provider = null,Object? storagePath = freezed,Object? egressId = freezed,Object? expiresAt = freezed,Object? proofSha256 = freezed,Object? proofBytes = freezed,Object? proofDurationSeconds = freezed,Object? proofCommittedAt = freezed,Object? proofClaimedAt = freezed,Object? proofUploadedAt = freezed,Object? proofHashVerified = freezed,}) {
  return _then(MatchStream(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,matchId: null == matchId ? _self.matchId : matchId // ignore: cast_nullable_to_non_nullable
as String,playerId: null == playerId ? _self.playerId : playerId // ignore: cast_nullable_to_non_nullable
as String,isPublic: null == isPublic ? _self.isPublic : isPublic // ignore: cast_nullable_to_non_nullable
as bool,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,url: freezed == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String?,startedAt: freezed == startedAt ? _self.startedAt : startedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,endedAt: freezed == endedAt ? _self.endedAt : endedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,provider: null == provider ? _self.provider : provider // ignore: cast_nullable_to_non_nullable
as String,storagePath: freezed == storagePath ? _self.storagePath : storagePath // ignore: cast_nullable_to_non_nullable
as String?,egressId: freezed == egressId ? _self.egressId : egressId // ignore: cast_nullable_to_non_nullable
as String?,expiresAt: freezed == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime?,proofSha256: freezed == proofSha256 ? _self.proofSha256 : proofSha256 // ignore: cast_nullable_to_non_nullable
as String?,proofBytes: freezed == proofBytes ? _self.proofBytes : proofBytes // ignore: cast_nullable_to_non_nullable
as int?,proofDurationSeconds: freezed == proofDurationSeconds ? _self.proofDurationSeconds : proofDurationSeconds // ignore: cast_nullable_to_non_nullable
as int?,proofCommittedAt: freezed == proofCommittedAt ? _self.proofCommittedAt : proofCommittedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,proofClaimedAt: freezed == proofClaimedAt ? _self.proofClaimedAt : proofClaimedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,proofUploadedAt: freezed == proofUploadedAt ? _self.proofUploadedAt : proofUploadedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,proofHashVerified: freezed == proofHashVerified ? _self.proofHashVerified : proofHashVerified // ignore: cast_nullable_to_non_nullable
as bool?,
  ));
}

}


/// Adds pattern-matching-related methods to [MatchStream].
extension MatchStreamPatterns on MatchStream {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MatchStream value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MatchStream() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MatchStream value)  $default,){
final _that = this;
switch (_that) {
case _MatchStream():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MatchStream value)?  $default,){
final _that = this;
switch (_that) {
case _MatchStream() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String matchId,  String playerId,  bool isPublic,  bool isActive,  String? url,  DateTime? startedAt,  DateTime? endedAt,  String provider,  String? storagePath,  String? egressId,  DateTime? expiresAt,  String? proofSha256,  int? proofBytes,  int? proofDurationSeconds,  DateTime? proofCommittedAt,  DateTime? proofClaimedAt,  DateTime? proofUploadedAt,  bool? proofHashVerified)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MatchStream() when $default != null:
return $default(_that.id,_that.matchId,_that.playerId,_that.isPublic,_that.isActive,_that.url,_that.startedAt,_that.endedAt,_that.provider,_that.storagePath,_that.egressId,_that.expiresAt,_that.proofSha256,_that.proofBytes,_that.proofDurationSeconds,_that.proofCommittedAt,_that.proofClaimedAt,_that.proofUploadedAt,_that.proofHashVerified);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String matchId,  String playerId,  bool isPublic,  bool isActive,  String? url,  DateTime? startedAt,  DateTime? endedAt,  String provider,  String? storagePath,  String? egressId,  DateTime? expiresAt,  String? proofSha256,  int? proofBytes,  int? proofDurationSeconds,  DateTime? proofCommittedAt,  DateTime? proofClaimedAt,  DateTime? proofUploadedAt,  bool? proofHashVerified)  $default,) {final _that = this;
switch (_that) {
case _MatchStream():
return $default(_that.id,_that.matchId,_that.playerId,_that.isPublic,_that.isActive,_that.url,_that.startedAt,_that.endedAt,_that.provider,_that.storagePath,_that.egressId,_that.expiresAt,_that.proofSha256,_that.proofBytes,_that.proofDurationSeconds,_that.proofCommittedAt,_that.proofClaimedAt,_that.proofUploadedAt,_that.proofHashVerified);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String matchId,  String playerId,  bool isPublic,  bool isActive,  String? url,  DateTime? startedAt,  DateTime? endedAt,  String provider,  String? storagePath,  String? egressId,  DateTime? expiresAt,  String? proofSha256,  int? proofBytes,  int? proofDurationSeconds,  DateTime? proofCommittedAt,  DateTime? proofClaimedAt,  DateTime? proofUploadedAt,  bool? proofHashVerified)?  $default,) {final _that = this;
switch (_that) {
case _MatchStream() when $default != null:
return $default(_that.id,_that.matchId,_that.playerId,_that.isPublic,_that.isActive,_that.url,_that.startedAt,_that.endedAt,_that.provider,_that.storagePath,_that.egressId,_that.expiresAt,_that.proofSha256,_that.proofBytes,_that.proofDurationSeconds,_that.proofCommittedAt,_that.proofClaimedAt,_that.proofUploadedAt,_that.proofHashVerified);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MatchStream implements MatchStream {
  const _MatchStream({required this.id, required this.matchId, required this.playerId, this.isPublic = false, this.isActive = true, this.url, this.startedAt, this.endedAt, this.provider = 'native_recorder', this.storagePath, this.egressId, this.expiresAt, this.proofSha256, this.proofBytes, this.proofDurationSeconds, this.proofCommittedAt, this.proofClaimedAt, this.proofUploadedAt, this.proofHashVerified});
  factory _MatchStream.fromJson(Map<String, dynamic> json) => _$MatchStreamFromJson(json);

@override final  String id;
@override final  String matchId;
@override final  String playerId;
@override@JsonKey() final  bool isPublic;
@override@JsonKey() final  bool isActive;
@override final  String? url;
@override final  DateTime? startedAt;
@override final  DateTime? endedAt;
@override@JsonKey() final  String provider;
@override final  String? storagePath;
@override final  String? egressId;
@override final  DateTime? expiresAt;
@override final  String? proofSha256;
@override final  int? proofBytes;
@override final  int? proofDurationSeconds;
@override final  DateTime? proofCommittedAt;
@override final  DateTime? proofClaimedAt;
@override final  DateTime? proofUploadedAt;
@override final  bool? proofHashVerified;

/// Create a copy of MatchStream
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MatchStreamCopyWith<_MatchStream> get copyWith => __$MatchStreamCopyWithImpl<_MatchStream>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MatchStreamToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _MatchStream&&(identical(other.id, id) || other.id == id)&&(identical(other.matchId, matchId) || other.matchId == matchId)&&(identical(other.playerId, playerId) || other.playerId == playerId)&&(identical(other.isPublic, isPublic) || other.isPublic == isPublic)&&(identical(other.isActive, isActive) || other.isActive == isActive)&&(identical(other.url, url) || other.url == url)&&(identical(other.startedAt, startedAt) || other.startedAt == startedAt)&&(identical(other.endedAt, endedAt) || other.endedAt == endedAt)&&(identical(other.provider, provider) || other.provider == provider)&&(identical(other.storagePath, storagePath) || other.storagePath == storagePath)&&(identical(other.egressId, egressId) || other.egressId == egressId)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt)&&(identical(other.proofSha256, proofSha256) || other.proofSha256 == proofSha256)&&(identical(other.proofBytes, proofBytes) || other.proofBytes == proofBytes)&&(identical(other.proofDurationSeconds, proofDurationSeconds) || other.proofDurationSeconds == proofDurationSeconds)&&(identical(other.proofCommittedAt, proofCommittedAt) || other.proofCommittedAt == proofCommittedAt)&&(identical(other.proofClaimedAt, proofClaimedAt) || other.proofClaimedAt == proofClaimedAt)&&(identical(other.proofUploadedAt, proofUploadedAt) || other.proofUploadedAt == proofUploadedAt)&&(identical(other.proofHashVerified, proofHashVerified) || other.proofHashVerified == proofHashVerified));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hashAll([runtimeType,id,matchId,playerId,isPublic,isActive,url,startedAt,endedAt,provider,storagePath,egressId,expiresAt,proofSha256,proofBytes,proofDurationSeconds,proofCommittedAt,proofClaimedAt,proofUploadedAt,proofHashVerified]);
}

@override
String toString() {
    return 'MatchStream(id: $id, matchId: $matchId, playerId: $playerId, isPublic: $isPublic, isActive: $isActive, url: $url, startedAt: $startedAt, endedAt: $endedAt, provider: $provider, storagePath: $storagePath, egressId: $egressId, expiresAt: $expiresAt, proofSha256: $proofSha256, proofBytes: $proofBytes, proofDurationSeconds: $proofDurationSeconds, proofCommittedAt: $proofCommittedAt, proofClaimedAt: $proofClaimedAt, proofUploadedAt: $proofUploadedAt, proofHashVerified: $proofHashVerified)';
}


}

/// @nodoc
abstract mixin class _$MatchStreamCopyWith<$Res> implements $MatchStreamCopyWith<$Res> {
  factory _$MatchStreamCopyWith(_MatchStream value, $Res Function(_MatchStream) _then) = __$MatchStreamCopyWithImpl;
@override @useResult
$Res call({
 String id, String matchId, String playerId, bool isPublic, bool isActive, String? url, DateTime? startedAt, DateTime? endedAt, String provider, String? storagePath, String? egressId, DateTime? expiresAt, String? proofSha256, int? proofBytes, int? proofDurationSeconds, DateTime? proofCommittedAt, DateTime? proofClaimedAt, DateTime? proofUploadedAt, bool? proofHashVerified
});




}
/// @nodoc
class __$MatchStreamCopyWithImpl<$Res>
    implements _$MatchStreamCopyWith<$Res> {
  __$MatchStreamCopyWithImpl(this._self, this._then);

  final _MatchStream _self;
  final $Res Function(_MatchStream) _then;

/// Create a copy of MatchStream
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? matchId = null,Object? playerId = null,Object? isPublic = null,Object? isActive = null,Object? url = freezed,Object? startedAt = freezed,Object? endedAt = freezed,Object? provider = null,Object? storagePath = freezed,Object? egressId = freezed,Object? expiresAt = freezed,Object? proofSha256 = freezed,Object? proofBytes = freezed,Object? proofDurationSeconds = freezed,Object? proofCommittedAt = freezed,Object? proofClaimedAt = freezed,Object? proofUploadedAt = freezed,Object? proofHashVerified = freezed,}) {
  return _then(_MatchStream(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,matchId: null == matchId ? _self.matchId : matchId // ignore: cast_nullable_to_non_nullable
as String,playerId: null == playerId ? _self.playerId : playerId // ignore: cast_nullable_to_non_nullable
as String,isPublic: null == isPublic ? _self.isPublic : isPublic // ignore: cast_nullable_to_non_nullable
as bool,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,url: freezed == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String?,startedAt: freezed == startedAt ? _self.startedAt : startedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,endedAt: freezed == endedAt ? _self.endedAt : endedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,provider: null == provider ? _self.provider : provider // ignore: cast_nullable_to_non_nullable
as String,storagePath: freezed == storagePath ? _self.storagePath : storagePath // ignore: cast_nullable_to_non_nullable
as String?,egressId: freezed == egressId ? _self.egressId : egressId // ignore: cast_nullable_to_non_nullable
as String?,expiresAt: freezed == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime?,proofSha256: freezed == proofSha256 ? _self.proofSha256 : proofSha256 // ignore: cast_nullable_to_non_nullable
as String?,proofBytes: freezed == proofBytes ? _self.proofBytes : proofBytes // ignore: cast_nullable_to_non_nullable
as int?,proofDurationSeconds: freezed == proofDurationSeconds ? _self.proofDurationSeconds : proofDurationSeconds // ignore: cast_nullable_to_non_nullable
as int?,proofCommittedAt: freezed == proofCommittedAt ? _self.proofCommittedAt : proofCommittedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,proofClaimedAt: freezed == proofClaimedAt ? _self.proofClaimedAt : proofClaimedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,proofUploadedAt: freezed == proofUploadedAt ? _self.proofUploadedAt : proofUploadedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,proofHashVerified: freezed == proofHashVerified ? _self.proofHashVerified : proofHashVerified // ignore: cast_nullable_to_non_nullable
as bool?,
  ));
}


}

// dart format on
