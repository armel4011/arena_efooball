import 'dart:io';

import 'package:arena/core/theme/arena_fluent_theme.dart';
import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/data/models/chat_message.dart';
import 'package:arena/data/repositories/chat_repository.dart';
import 'package:arena/features_shared/auth_common/shared_auth_providers.dart';
import 'package:cached_network_image/cached_network_image.dart';
// Dépendance transitive (umbrella `file_selector` absent du pubspec) : on
// cible l'interface plateforme, l'implémentation Windows s'enregistre via
// le plugin registrant.
// ignore: depend_on_referenced_packages
import 'package:file_selector_platform_interface/file_selector_platform_interface.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

const _imageTypeGroup = XTypeGroup(
  label: 'Images',
  extensions: <String>['jpg', 'jpeg', 'png', 'webp', 'gif'],
);

/// Boîte de support (super-admin) — version desktop (Fluent UI), en
/// maître-détail : la colonne de gauche liste les fils de support
/// (canaux `chat_channels.type='admin_user'`), la colonne de droite
/// affiche la conversation sélectionnée et permet de répondre.
///
/// Réutilise l'infra de chat générique : [adminSupportThreadsProvider]
/// (liste), [channelMessagesProvider] (stream Realtime du fil),
/// `chatRepositoryProvider.sendMessage` / `sendMediaMessage` (envoi).
class DesktopSupportPage extends ConsumerStatefulWidget {
  const DesktopSupportPage({super.key});

  @override
  ConsumerState<DesktopSupportPage> createState() => _DesktopSupportPageState();
}

class _DesktopSupportPageState extends ConsumerState<DesktopSupportPage> {
  String? _channelId;
  String _username = 'Support';

  void _select(SupportThreadSummary t) {
    setState(() {
      _channelId = t.channelId;
      _username = t.username;
    });
    ref.read(chatRepositoryProvider).markChannelAsRead(t.channelId);
    ref.invalidate(adminSupportUnreadProvider);
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldPage(
      header: const PageHeader(title: Text('SUPPORT')),
      content: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: ArenaDesktop.pagePadding,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: 320,
              child: _ThreadList(
                selectedChannelId: _channelId,
                onSelect: _select,
              ),
            ),
            const SizedBox(width: 12),
            Container(width: 1, color: ArenaColors.border),
            const SizedBox(width: 12),
            Expanded(
              child: _channelId == null
                  ? const Center(
                      child: Text('Sélectionnez une conversation à gauche.'),
                    )
                  : _SupportThread(
                      key: ValueKey(_channelId),
                      channelId: _channelId!,
                      username: _username,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ThreadList extends ConsumerWidget {
  const _ThreadList({required this.selectedChannelId, required this.onSelect});

  final String? selectedChannelId;
  final void Function(SupportThreadSummary) onSelect;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final threadsAsync = ref.watch(adminSupportThreadsProvider);
    final unread = ref.watch(adminSupportUnreadProvider).valueOrNull ?? const {};

    return threadsAsync.when(
      loading: () => const Center(child: ProgressRing()),
      error: (e, _) => InfoBar(
        title: const Text('Erreur'),
        content: Text('$e'),
        severity: InfoBarSeverity.error,
      ),
      data: (threads) {
        if (threads.isEmpty) {
          return Center(
            child: Text(
              'Aucune demande de support.',
              style: GoogleFonts.spaceGrotesk(color: ArenaColors.silver),
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: threads.length,
          separatorBuilder: (_, __) => const SizedBox(height: 4),
          itemBuilder: (context, i) {
            final t = threads[i];
            return _ThreadTile(
              thread: t,
              selected: t.channelId == selectedChannelId,
              unreadCount: unread[t.channelId] ?? 0,
              onTap: () => onSelect(t),
            );
          },
        );
      },
    );
  }
}

class _ThreadTile extends StatelessWidget {
  const _ThreadTile({
    required this.thread,
    required this.selected,
    required this.unreadCount,
    required this.onTap,
  });

  final SupportThreadSummary thread;
  final bool selected;
  final int unreadCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: selected
              ? ArenaColors.neonRed.withValues(alpha: 0.14)
              : ArenaColors.carbon,
          borderRadius: BorderRadius.circular(ArenaRadius.md),
          border: Border.all(
            color: selected ? ArenaColors.neonRed : ArenaColors.border,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    thread.username,
                    style: GoogleFonts.spaceGrotesk(
                      color: ArenaColors.bone,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (unreadCount > 0)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
                    decoration: BoxDecoration(
                      color: ArenaColors.neonRed,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      unreadCount > 99 ? '99+' : '$unreadCount',
                      style: GoogleFonts.spaceGrotesk(
                        color: ArenaColors.bone,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              thread.lastMessage.isEmpty
                  ? 'Nouvelle conversation'
                  : thread.lastMessage,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.spaceGrotesk(
                color: ArenaColors.silver,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SupportThread extends ConsumerStatefulWidget {
  const _SupportThread({
    required this.channelId,
    required this.username,
    super.key,
  });

  final String channelId;
  final String username;

  @override
  ConsumerState<_SupportThread> createState() => _SupportThreadState();
}

class _SupportThreadState extends ConsumerState<_SupportThread> {
  final _ctrl = TextEditingController();
  bool _sending = false;
  String? _error;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _sendText() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty || _sending) return;
    final adminId = ref.read(currentSessionProvider)?.user.id;
    if (adminId == null) return;
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      await ref.read(chatRepositoryProvider).sendMessage(
            channelId: widget.channelId,
            senderId: adminId,
            content: text,
          );
      _ctrl.clear();
    } catch (e) {
      if (mounted) setState(() => _error = 'Échec de l’envoi : $e');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _pickAndSendImage() async {
    if (_sending) return;
    final adminId = ref.read(currentSessionProvider)?.user.id;
    if (adminId == null) return;
    final picked = await FileSelectorPlatform.instance.openFile(
      acceptedTypeGroups: const [_imageTypeGroup],
    );
    if (picked == null || !mounted) return;
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      await ref.read(chatRepositoryProvider).sendMediaMessage(
            channelId: widget.channelId,
            senderId: adminId,
            file: File(picked.path),
            mediaType: 'image',
          );
    } catch (e) {
      if (mounted) setState(() => _error = 'Échec de l’envoi : $e');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final adminId = ref.watch(currentSessionProvider)?.user.id;
    final messagesAsync = ref.watch(channelMessagesProvider(widget.channelId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 4),
          child: Text(
            widget.username,
            style: GoogleFonts.spaceGrotesk(
              color: ArenaColors.bone,
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
        ),
        Expanded(
          child: messagesAsync.when(
            loading: () => const Center(child: ProgressRing()),
            error: (e, _) => InfoBar(
              title: const Text('Impossible de charger le fil'),
              content: Text('$e'),
              severity: InfoBarSeverity.error,
            ),
            data: (messages) {
              if (messages.isEmpty) {
                return const Center(
                  child: Text('Aucun message. Répondez pour démarrer.'),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 12),
                itemCount: messages.length,
                itemBuilder: (_, i) => _SupportBubble(
                  message: messages[i],
                  outgoing: messages[i].senderId == adminId,
                ),
              );
            },
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: 8),
          InfoBar(
            title: const Text('Erreur'),
            content: Text(_error!),
            severity: InfoBarSeverity.error,
            onClose: () => setState(() => _error = null),
          ),
        ],
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            IconButton(
              icon: const Icon(FluentIcons.photo2_add, size: 18),
              onPressed: _sending ? null : _pickAndSendImage,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextBox(
                controller: _ctrl,
                placeholder: 'Votre réponse…',
                enabled: !_sending,
                maxLines: 4,
                minLines: 1,
                onSubmitted: (_) => _sendText(),
              ),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: _sending ? null : _sendText,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                child: _sending
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: ProgressRing(strokeWidth: 2),
                      )
                    : const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(FluentIcons.send, size: 14),
                          SizedBox(width: 6),
                          Text('Envoyer'),
                        ],
                      ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}

/// Bulle d'un message de support (sortant admin = droite/rouge, entrant
/// user = gauche/carbon). Rend le texte + l'image (signed URL Storage).
class _SupportBubble extends ConsumerWidget {
  const _SupportBubble({required this.message, required this.outgoing});

  final ChatMessage message;
  final bool outgoing;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDeleted = message.deletedAt != null;
    final hasMedia = !isDeleted && message.mediaUrl != null;
    return Align(
      alignment: outgoing ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        constraints: const BoxConstraints(maxWidth: 460),
        decoration: BoxDecoration(
          color: outgoing
              ? ArenaColors.neonRed.withValues(alpha: 0.16)
              : ArenaColors.carbon,
          borderRadius: BorderRadius.circular(ArenaRadius.md),
          border: Border.all(
            color: outgoing ? ArenaColors.neonRed : ArenaColors.border,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(ArenaRadius.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (hasMedia) _SupportBubbleImage(pathInBucket: message.mediaUrl!),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
                child: Text(
                  isDeleted
                      ? 'Message supprimé'
                      : (message.content.isEmpty && hasMedia
                          ? '📷 Pièce jointe'
                          : message.content),
                  style: GoogleFonts.spaceGrotesk(
                    color: ArenaColors.bone,
                    fontSize: 13,
                    fontStyle: isDeleted ? FontStyle.italic : FontStyle.normal,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                child: Text(
                  message.createdAt == null
                      ? ''
                      : DateFormat('dd/MM HH:mm')
                          .format(message.createdAt!.toLocal()),
                  style: GoogleFonts.spaceGrotesk(
                    color: ArenaColors.silver,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SupportBubbleImage extends ConsumerWidget {
  const _SupportBubbleImage({required this.pathInBucket});

  final String pathInBucket;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 280),
      child: FutureBuilder<String>(
        key: ValueKey('support_media_$pathInBucket'),
        future: ref.read(chatRepositoryProvider).signedMediaUrl(pathInBucket),
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return Container(
              height: 200,
              color: ArenaColors.carbon,
              child: const Center(child: ProgressRing()),
            );
          }
          if (snap.hasError || snap.data == null) {
            return Container(
              height: 120,
              color: ArenaColors.carbon,
              child: const Center(
                child: Icon(FluentIcons.photo_error, color: ArenaColors.silver),
              ),
            );
          }
          return CachedNetworkImage(
            imageUrl: snap.data!,
            fit: BoxFit.cover,
            width: double.infinity,
            errorWidget: (_, __, ___) => Container(
              height: 120,
              color: ArenaColors.carbon,
              child: const Center(
                child:
                    Icon(FluentIcons.photo_error, color: ArenaColors.silver),
              ),
            ),
          );
        },
      ),
    );
  }
}
