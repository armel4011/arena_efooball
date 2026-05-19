// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'chat_message.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

ChatMessage _$ChatMessageFromJson(Map<String, dynamic> json) {
  return _ChatMessage.fromJson(json);
}

/// @nodoc
mixin _$ChatMessage {
  String get id => throw _privateConstructorUsedError;
  String get channelId => throw _privateConstructorUsedError;
  String get content => throw _privateConstructorUsedError;
  String? get senderId => throw _privateConstructorUsedError;
  String get type => throw _privateConstructorUsedError;
  bool get isModerated => throw _privateConstructorUsedError;
  DateTime? get moderatedAt => throw _privateConstructorUsedError;
  String? get moderatedReason => throw _privateConstructorUsedError;
  DateTime? get createdAt =>
      throw _privateConstructorUsedError; // Phase 12.5 — médias dans le chat (image/video/audio).
  String? get mediaUrl => throw _privateConstructorUsedError;
  String? get mediaType =>
      throw _privateConstructorUsedError; // Soft-delete par sender. UI affiche "Message supprimé" si !=null.
  DateTime? get deletedAt => throw _privateConstructorUsedError;

  /// Serializes this ChatMessage to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ChatMessage
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ChatMessageCopyWith<ChatMessage> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ChatMessageCopyWith<$Res> {
  factory $ChatMessageCopyWith(
          ChatMessage value, $Res Function(ChatMessage) then) =
      _$ChatMessageCopyWithImpl<$Res, ChatMessage>;
  @useResult
  $Res call(
      {String id,
      String channelId,
      String content,
      String? senderId,
      String type,
      bool isModerated,
      DateTime? moderatedAt,
      String? moderatedReason,
      DateTime? createdAt,
      String? mediaUrl,
      String? mediaType,
      DateTime? deletedAt});
}

/// @nodoc
class _$ChatMessageCopyWithImpl<$Res, $Val extends ChatMessage>
    implements $ChatMessageCopyWith<$Res> {
  _$ChatMessageCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ChatMessage
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? channelId = null,
    Object? content = null,
    Object? senderId = freezed,
    Object? type = null,
    Object? isModerated = null,
    Object? moderatedAt = freezed,
    Object? moderatedReason = freezed,
    Object? createdAt = freezed,
    Object? mediaUrl = freezed,
    Object? mediaType = freezed,
    Object? deletedAt = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      channelId: null == channelId
          ? _value.channelId
          : channelId // ignore: cast_nullable_to_non_nullable
              as String,
      content: null == content
          ? _value.content
          : content // ignore: cast_nullable_to_non_nullable
              as String,
      senderId: freezed == senderId
          ? _value.senderId
          : senderId // ignore: cast_nullable_to_non_nullable
              as String?,
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as String,
      isModerated: null == isModerated
          ? _value.isModerated
          : isModerated // ignore: cast_nullable_to_non_nullable
              as bool,
      moderatedAt: freezed == moderatedAt
          ? _value.moderatedAt
          : moderatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      moderatedReason: freezed == moderatedReason
          ? _value.moderatedReason
          : moderatedReason // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      mediaUrl: freezed == mediaUrl
          ? _value.mediaUrl
          : mediaUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      mediaType: freezed == mediaType
          ? _value.mediaType
          : mediaType // ignore: cast_nullable_to_non_nullable
              as String?,
      deletedAt: freezed == deletedAt
          ? _value.deletedAt
          : deletedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ChatMessageImplCopyWith<$Res>
    implements $ChatMessageCopyWith<$Res> {
  factory _$$ChatMessageImplCopyWith(
          _$ChatMessageImpl value, $Res Function(_$ChatMessageImpl) then) =
      __$$ChatMessageImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String channelId,
      String content,
      String? senderId,
      String type,
      bool isModerated,
      DateTime? moderatedAt,
      String? moderatedReason,
      DateTime? createdAt,
      String? mediaUrl,
      String? mediaType,
      DateTime? deletedAt});
}

/// @nodoc
class __$$ChatMessageImplCopyWithImpl<$Res>
    extends _$ChatMessageCopyWithImpl<$Res, _$ChatMessageImpl>
    implements _$$ChatMessageImplCopyWith<$Res> {
  __$$ChatMessageImplCopyWithImpl(
      _$ChatMessageImpl _value, $Res Function(_$ChatMessageImpl) _then)
      : super(_value, _then);

  /// Create a copy of ChatMessage
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? channelId = null,
    Object? content = null,
    Object? senderId = freezed,
    Object? type = null,
    Object? isModerated = null,
    Object? moderatedAt = freezed,
    Object? moderatedReason = freezed,
    Object? createdAt = freezed,
    Object? mediaUrl = freezed,
    Object? mediaType = freezed,
    Object? deletedAt = freezed,
  }) {
    return _then(_$ChatMessageImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      channelId: null == channelId
          ? _value.channelId
          : channelId // ignore: cast_nullable_to_non_nullable
              as String,
      content: null == content
          ? _value.content
          : content // ignore: cast_nullable_to_non_nullable
              as String,
      senderId: freezed == senderId
          ? _value.senderId
          : senderId // ignore: cast_nullable_to_non_nullable
              as String?,
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as String,
      isModerated: null == isModerated
          ? _value.isModerated
          : isModerated // ignore: cast_nullable_to_non_nullable
              as bool,
      moderatedAt: freezed == moderatedAt
          ? _value.moderatedAt
          : moderatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      moderatedReason: freezed == moderatedReason
          ? _value.moderatedReason
          : moderatedReason // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      mediaUrl: freezed == mediaUrl
          ? _value.mediaUrl
          : mediaUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      mediaType: freezed == mediaType
          ? _value.mediaType
          : mediaType // ignore: cast_nullable_to_non_nullable
              as String?,
      deletedAt: freezed == deletedAt
          ? _value.deletedAt
          : deletedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ChatMessageImpl implements _ChatMessage {
  const _$ChatMessageImpl(
      {required this.id,
      required this.channelId,
      required this.content,
      this.senderId,
      this.type = 'text',
      this.isModerated = false,
      this.moderatedAt,
      this.moderatedReason,
      this.createdAt,
      this.mediaUrl,
      this.mediaType,
      this.deletedAt});

  factory _$ChatMessageImpl.fromJson(Map<String, dynamic> json) =>
      _$$ChatMessageImplFromJson(json);

  @override
  final String id;
  @override
  final String channelId;
  @override
  final String content;
  @override
  final String? senderId;
  @override
  @JsonKey()
  final String type;
  @override
  @JsonKey()
  final bool isModerated;
  @override
  final DateTime? moderatedAt;
  @override
  final String? moderatedReason;
  @override
  final DateTime? createdAt;
// Phase 12.5 — médias dans le chat (image/video/audio).
  @override
  final String? mediaUrl;
  @override
  final String? mediaType;
// Soft-delete par sender. UI affiche "Message supprimé" si !=null.
  @override
  final DateTime? deletedAt;

  @override
  String toString() {
    return 'ChatMessage(id: $id, channelId: $channelId, content: $content, senderId: $senderId, type: $type, isModerated: $isModerated, moderatedAt: $moderatedAt, moderatedReason: $moderatedReason, createdAt: $createdAt, mediaUrl: $mediaUrl, mediaType: $mediaType, deletedAt: $deletedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ChatMessageImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.channelId, channelId) ||
                other.channelId == channelId) &&
            (identical(other.content, content) || other.content == content) &&
            (identical(other.senderId, senderId) ||
                other.senderId == senderId) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.isModerated, isModerated) ||
                other.isModerated == isModerated) &&
            (identical(other.moderatedAt, moderatedAt) ||
                other.moderatedAt == moderatedAt) &&
            (identical(other.moderatedReason, moderatedReason) ||
                other.moderatedReason == moderatedReason) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.mediaUrl, mediaUrl) ||
                other.mediaUrl == mediaUrl) &&
            (identical(other.mediaType, mediaType) ||
                other.mediaType == mediaType) &&
            (identical(other.deletedAt, deletedAt) ||
                other.deletedAt == deletedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      channelId,
      content,
      senderId,
      type,
      isModerated,
      moderatedAt,
      moderatedReason,
      createdAt,
      mediaUrl,
      mediaType,
      deletedAt);

  /// Create a copy of ChatMessage
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ChatMessageImplCopyWith<_$ChatMessageImpl> get copyWith =>
      __$$ChatMessageImplCopyWithImpl<_$ChatMessageImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ChatMessageImplToJson(
      this,
    );
  }
}

abstract class _ChatMessage implements ChatMessage {
  const factory _ChatMessage(
      {required final String id,
      required final String channelId,
      required final String content,
      final String? senderId,
      final String type,
      final bool isModerated,
      final DateTime? moderatedAt,
      final String? moderatedReason,
      final DateTime? createdAt,
      final String? mediaUrl,
      final String? mediaType,
      final DateTime? deletedAt}) = _$ChatMessageImpl;

  factory _ChatMessage.fromJson(Map<String, dynamic> json) =
      _$ChatMessageImpl.fromJson;

  @override
  String get id;
  @override
  String get channelId;
  @override
  String get content;
  @override
  String? get senderId;
  @override
  String get type;
  @override
  bool get isModerated;
  @override
  DateTime? get moderatedAt;
  @override
  String? get moderatedReason;
  @override
  DateTime?
      get createdAt; // Phase 12.5 — médias dans le chat (image/video/audio).
  @override
  String? get mediaUrl;
  @override
  String?
      get mediaType; // Soft-delete par sender. UI affiche "Message supprimé" si !=null.
  @override
  DateTime? get deletedAt;

  /// Create a copy of ChatMessage
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ChatMessageImplCopyWith<_$ChatMessageImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
