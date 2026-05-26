import 'package:arena/data/repositories/profile_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// 1 message admin -> user dans `public.admin_chat_messages`.
class AdminChatMessage {
  const AdminChatMessage({
    required this.id,
    required this.adminId,
    required this.recipientId,
    required this.text,
    required this.sentAt,
    this.readAt,
  });

  factory AdminChatMessage.fromJson(Map<String, dynamic> json) =>
      AdminChatMessage(
        id: json['id'] as String,
        adminId: json['admin_id'] as String,
        recipientId: json['recipient_id'] as String,
        text: json['text'] as String,
        sentAt: DateTime.parse(json['sent_at'] as String),
        readAt: json['read_at'] == null
            ? null
            : DateTime.parse(json['read_at'] as String),
      );

  final String id;
  final String adminId;
  final String recipientId;
  final String text;
  final DateTime sentAt;
  final DateTime? readAt;

  bool get isUnread => readAt == null;
}

/// Une conversation = derniers messages echanges avec UN user (groupes
/// cote admin pour afficher la liste des conversations).
class AdminChatThreadSummary {
  const AdminChatThreadSummary({
    required this.userId,
    required this.username,
    required this.lastMessage,
    required this.lastSentAt,
    required this.unreadCount,
  });

  final String userId;
  final String username;
  final String lastMessage;
  final DateTime lastSentAt;
  final int unreadCount;
}

class AdminChatRepository {
  AdminChatRepository(this._client);

  final SupabaseClient _client;
  static const _table = 'admin_chat_messages';

  /// Stream des messages d'un fil (cote admin OU cote user). Realtime
  /// via `.stream()` qui souscrit a la publication supabase_realtime.
  Stream<List<AdminChatMessage>> watchThread({
    required String adminId,
    required String userId,
  }) {
    return _client
        .from(_table)
        .stream(primaryKey: ['id'])
        .order('sent_at')
        .map(
          (rows) => rows
              .where(
                (r) =>
                    r['admin_id'] == adminId &&
                    r['recipient_id'] == userId,
              )
              .map(AdminChatMessage.fromJson)
              .toList(),
        );
  }

  /// Cote user : stream tous les messages recus de n'importe quel admin.
  Stream<List<AdminChatMessage>> watchInbox(String userId) {
    return _client
        .from(_table)
        .stream(primaryKey: ['id'])
        .order('sent_at', ascending: false)
        .map(
          (rows) => rows
              .where((r) => r['recipient_id'] == userId)
              .map(AdminChatMessage.fromJson)
              .toList(),
        );
  }

  Future<void> send({
    required String adminId,
    required String recipientId,
    required String text,
  }) async {
    await _client.from(_table).insert({
      'admin_id': adminId,
      'recipient_id': recipientId,
      'text': text.trim(),
    });
  }

  /// Bulk insert pour broadcast cible (1 row par recipient, meme texte).
  Future<void> broadcast({
    required String adminId,
    required List<String> recipientIds,
    required String text,
  }) async {
    if (recipientIds.isEmpty) return;
    final rows = [
      for (final r in recipientIds)
        {
          'admin_id': adminId,
          'recipient_id': r,
          'text': text.trim(),
        },
    ];
    await _client.from(_table).insert(rows);
  }

  Future<void> markRead(String messageId) async {
    await _client
        .from(_table)
        .update({'read_at': DateTime.now().toIso8601String()})
        .eq('id', messageId);
  }

  /// Liste des fils d'un admin (group_by user_id, dernier message,
  /// nombre non-lus). One-shot — la list page de l'admin se rafraichit
  /// via un FutureProvider invalide a chaque envoi.
  Future<List<AdminChatThreadSummary>> listAdminThreads(String adminId) async {
    final rows = await _client
        .from(_table)
        .select('id, admin_id, recipient_id, text, sent_at, read_at, '
            'profiles!admin_chat_messages_recipient_id_fkey(username)')
        .eq('admin_id', adminId)
        .order('sent_at', ascending: false);
    final byUser = <String, List<Map<String, dynamic>>>{};
    for (final r in rows) {
      final uid = r['recipient_id'] as String;
      byUser.putIfAbsent(uid, () => []).add(Map<String, dynamic>.from(r));
    }
    return [
      for (final entry in byUser.entries)
        AdminChatThreadSummary(
          userId: entry.key,
          username: ((entry.value.first['profiles']
                      as Map?)?['username'] as String?) ??
              'Inconnu',
          lastMessage: entry.value.first['text'] as String,
          lastSentAt: DateTime.parse(entry.value.first['sent_at'] as String),
          unreadCount:
              entry.value.where((r) => r['read_at'] == null).length,
        ),
    ];
  }
}

final adminChatRepositoryProvider = Provider<AdminChatRepository>((ref) {
  return AdminChatRepository(ref.watch(supabaseClientProvider));
});
