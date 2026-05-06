import 'package:arena/data/models/chat_channel.dart';
import 'package:arena/data/models/chat_message.dart';
import 'package:arena/data/repositories/profile_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Reads + writes over `chat_channels` / `chat_messages`. Persistent
/// messages only — Agora RTM (presence, typing) lands in PHASE 12.5.
class ChatRepository {
  const ChatRepository(this._client);

  static const _channelsTable = 'chat_channels';
  static const _messagesTable = 'chat_messages';

  final SupabaseClient _client;

  /// Returns the existing match channel for [matchId], or creates one
  /// on the fly. RLS makes sure only the two seated players (or an
  /// admin) can hit this insert path.
  Future<ChatChannel> ensureMatchChannel(String matchId) async {
    final existing = await _client
        .from(_channelsTable)
        .select()
        .eq('type', 'match')
        .eq('match_id', matchId)
        .maybeSingle();

    if (existing != null) {
      return ChatChannel.fromJson(existing);
    }

    final inserted = await _client
        .from(_channelsTable)
        .insert({
          'type': 'match',
          'match_id': matchId,
        })
        .select()
        .single();

    return ChatChannel.fromJson(inserted);
  }

  /// Realtime stream of every message in a channel, **oldest first**.
  /// The Supabase `.stream().order()` chain doesn't reliably enforce the
  /// order on realtime broadcast events, so we sort client-side as well
  /// — the chat UI uses a `reverse: true` ListView so newest sits at
  /// the bottom.
  Stream<List<ChatMessage>> watchMessages(String channelId) {
    return _client
        .from(_messagesTable)
        .stream(primaryKey: ['id'])
        .eq('channel_id', channelId)
        .order('created_at')
        .map(
          (rows) => [
            for (final row in rows) ChatMessage.fromJson(row),
          ]..sort(_byCreatedAtAsc),
        );
  }

  static int _byCreatedAtAsc(ChatMessage a, ChatMessage b) {
    final ad = a.createdAt;
    final bd = b.createdAt;
    if (ad == null && bd == null) return 0;
    if (ad == null) return 1;
    if (bd == null) return -1;
    return ad.compareTo(bd);
  }

  /// Sends a text message. Content is trimmed and capped at 2000 chars
  /// (the DB length check would reject anything bigger).
  Future<void> sendMessage({
    required String channelId,
    required String senderId,
    required String content,
  }) async {
    final trimmed = content.trim();
    if (trimmed.isEmpty) return;
    final capped =
        trimmed.length > 2000 ? trimmed.substring(0, 2000) : trimmed;
    await _client.from(_messagesTable).insert({
      'channel_id': channelId,
      'sender_id': senderId,
      'content': capped,
      'type': 'text',
    });
  }
}

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return ChatRepository(ref.watch(supabaseClientProvider));
});

/// Auto-fetches (or creates) the chat channel attached to a match.
final matchChannelProvider =
    FutureProvider.family<ChatChannel, String>((ref, matchId) {
  return ref.watch(chatRepositoryProvider).ensureMatchChannel(matchId);
});

/// Realtime stream of all messages in a chat channel, oldest → newest.
final channelMessagesProvider =
    StreamProvider.family<List<ChatMessage>, String>((ref, channelId) {
  return ref.watch(chatRepositoryProvider).watchMessages(channelId);
});
