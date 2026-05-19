import 'package:freezed_annotation/freezed_annotation.dart';

part 'chat_channel.freezed.dart';
part 'chat_channel.g.dart';

/// Mirror of the `chat_channels` table — minimal subset used by the chat
/// UI in V1.0 (1-on-1 match chat). Other channel types
/// (`competition_broadcast`, `admin_user`, `global`) are out of scope
/// for PHASE 6 but the model carries the discriminator so they don't
/// blow up `fromJson` if rows of those types ever leak through.
@Freezed(fromJson: true, toJson: true)
sealed class ChatChannel with _$ChatChannel {
  const factory ChatChannel({
    required String id,
    required String type,
    String? matchId,
    String? competitionId,
    String? friendshipId,
    String? name,
    @Default(false) bool isArchived,
    DateTime? createdAt,
    DateTime? deletedAt,
  }) = _ChatChannel;

  factory ChatChannel.fromJson(Map<String, dynamic> json) =>
      _$ChatChannelFromJson(json);
}
