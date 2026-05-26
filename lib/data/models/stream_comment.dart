/// Mirror of the `public.stream_comments` table.
///
/// Chat publique des spectateurs d'un live Agora. Distinct du chat DM
/// entre joueurs d'un match (`chat_messages`). Read-only côté client :
/// on insère via `StreamCommentRepository.post` et on lit via le stream
/// realtime, jamais d'update/delete (chat = log immuable).
class StreamComment {
  const StreamComment({
    required this.id,
    required this.matchId,
    required this.content,
    required this.createdAt,
    this.authorId,
  });

  factory StreamComment.fromJson(Map<String, dynamic> json) {
    return StreamComment(
      id: json['id'] as String,
      matchId: json['match_id'] as String,
      authorId: json['author_id'] as String?,
      content: json['content'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  final String id;
  final String matchId;
  final String? authorId;
  final String content;
  final DateTime createdAt;
}
