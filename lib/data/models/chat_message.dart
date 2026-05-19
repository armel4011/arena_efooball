import 'package:freezed_annotation/freezed_annotation.dart';

part 'chat_message.freezed.dart';
part 'chat_message.g.dart';

/// Mirror of the `chat_messages` table. Persistent text messages — the
/// realtime presence/typing layer (Agora RTM, deferred to PHASE 12.5)
/// is intentionally not modelled here.
@Freezed(fromJson: true, toJson: true)
sealed class ChatMessage with _$ChatMessage {
  const factory ChatMessage({
    required String id,
    required String channelId,
    required String content,
    String? senderId,
    @Default('text') String type,
    @Default(false) bool isModerated,
    DateTime? moderatedAt,
    String? moderatedReason,
    DateTime? createdAt,
    // Phase 12.5 — médias dans le chat (image/video/audio).
    String? mediaUrl,
    String? mediaType,
    // Soft-delete par sender. UI affiche "Message supprimé" si !=null.
    DateTime? deletedAt,
  }) = _ChatMessage;

  factory ChatMessage.fromJson(Map<String, dynamic> json) =>
      _$ChatMessageFromJson(json);
}
