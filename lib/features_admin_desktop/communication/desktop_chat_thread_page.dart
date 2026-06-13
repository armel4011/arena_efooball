import 'dart:io';

import 'package:arena/core/theme/arena_fluent_theme.dart';
import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/data/repositories/admin_chat_repository.dart';
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

/// Groupe de types d'image accepté par le sélecteur de fichiers desktop.
const _imageTypeGroup = XTypeGroup(
  label: 'Images',
  extensions: <String>['jpg', 'jpeg', 'png', 'webp', 'gif'],
);

/// Chat admin → utilisateur — version desktop (Fluent UI).
///
/// Réutilise [AdminChatRepository.watchThread] (stream Supabase Realtime)
/// pour afficher le fil en temps réel, et `send` / `sendImage` pour
/// l'envoi. L'image passe par `file_selector` (compatible Windows) —
/// jamais `image_picker`.
class DesktopChatThreadPage extends ConsumerStatefulWidget {
  const DesktopChatThreadPage({required this.userId, super.key});

  final String userId;

  @override
  ConsumerState<DesktopChatThreadPage> createState() =>
      _DesktopChatThreadPageState();
}

class _DesktopChatThreadPageState extends ConsumerState<DesktopChatThreadPage> {
  final _ctrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  bool _sending = false;
  String? _error;

  @override
  void dispose() {
    _ctrl.dispose();
    _scrollCtrl.dispose();
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
      await ref.read(adminChatRepositoryProvider).send(
            adminId: adminId,
            recipientId: widget.userId,
            text: text,
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

    final file = File(picked.path);
    final caption = await _ImageCaptionDialog.show(context, file: file);
    if (caption == null || !mounted) return; // annulé

    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      await ref.read(adminChatRepositoryProvider).sendImage(
            adminId: adminId,
            recipientId: widget.userId,
            file: file,
            caption: caption.isEmpty ? null : caption,
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
    if (adminId == null) {
      return const ScaffoldPage(
        content: Center(child: Text('Session expirée.')),
      );
    }

    return ScaffoldPage(
      header: const PageHeader(title: Text('CHAT PRIVÉ')),
      content: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: ArenaDesktop.pagePadding,
        ),
        child: Column(
          children: [
            Expanded(
              child: StreamBuilder<List<AdminChatMessage>>(
                stream: ref.read(adminChatRepositoryProvider).watchThread(
                      adminId: adminId,
                      userId: widget.userId,
                    ),
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(child: ProgressRing());
                  }
                  if (snap.hasError) {
                    return InfoBar(
                      title: const Text('Impossible de charger le fil'),
                      content: Text('${snap.error}'),
                      severity: InfoBarSeverity.error,
                    );
                  }
                  final msgs = snap.data ?? const <AdminChatMessage>[];
                  if (msgs.isEmpty) {
                    return const Center(
                      child: Text(
                        'Aucun message. Écrivez le premier message.',
                      ),
                    );
                  }
                  return ListView.builder(
                    controller: _scrollCtrl,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    itemCount: msgs.length,
                    itemBuilder: (_, i) =>
                        _DesktopChatBubble(msg: msgs[i]),
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
            _Composer(
              controller: _ctrl,
              sending: _sending,
              onSendText: _sendText,
              onPickImage: _pickAndSendImage,
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.sending,
    required this.onSendText,
    required this.onPickImage,
  });

  final TextEditingController controller;
  final bool sending;
  final VoidCallback onSendText;
  final VoidCallback onPickImage;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        IconButton(
          icon: const Icon(FluentIcons.photo2_add, size: 18),
          onPressed: sending ? null : onPickImage,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: TextBox(
            controller: controller,
            placeholder: 'Votre message…',
            enabled: !sending,
            maxLines: 4,
            minLines: 1,
            onSubmitted: (_) => onSendText(),
          ),
        ),
        const SizedBox(width: 8),
        FilledButton(
          onPressed: sending ? null : onSendText,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
            child: sending
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
    );
  }
}

/// Dialog Fluent (équivalent du bottom-sheet mobile) : aperçu de l'image
/// + champ légende. Retourne `null` si annulé, sinon la légende (peut
/// être vide).
class _ImageCaptionDialog extends StatefulWidget {
  const _ImageCaptionDialog({required this.file});

  final File file;

  static Future<String?> show(BuildContext context, {required File file}) {
    return showDialog<String>(
      context: context,
      builder: (_) => _ImageCaptionDialog(file: file),
    );
  }

  @override
  State<_ImageCaptionDialog> createState() => _ImageCaptionDialogState();
}

class _ImageCaptionDialogState extends State<_ImageCaptionDialog> {
  final _captionCtrl = TextEditingController();

  @override
  void dispose() {
    _captionCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ContentDialog(
      title: const Text('Envoyer une image'),
      constraints: const BoxConstraints(maxWidth: 460),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(ArenaRadius.md),
            child: Image.file(
              widget.file,
              height: 240,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: 12),
          TextBox(
            controller: _captionCtrl,
            placeholder: 'Légende (optionnelle)…',
            maxLines: 3,
            minLines: 1,
          ),
        ],
      ),
      actions: [
        Button(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        FilledButton(
          onPressed: () =>
              Navigator.of(context).pop(_captionCtrl.text.trim()),
          child: const Text('Envoyer'),
        ),
      ],
    );
  }
}

/// Bulle d'un message sortant (admin → user). Le thread admin n'affiche
/// que ses propres messages, alignés à droite, accent rouge.
class _DesktopChatBubble extends StatelessWidget {
  const _DesktopChatBubble({required this.msg});

  final AdminChatMessage msg;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        constraints: const BoxConstraints(maxWidth: 460),
        decoration: BoxDecoration(
          color: ArenaColors.neonRed.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(ArenaRadius.md),
          border: Border.all(color: ArenaColors.neonRed),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(ArenaRadius.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (msg.hasImage) _BubbleImage(url: msg.imageUrl!),
              if (msg.text != null && msg.text!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
                  child: Text(
                    msg.text!,
                    style: GoogleFonts.spaceGrotesk(
                      color: ArenaColors.bone,
                      fontSize: 13,
                    ),
                  ),
                ),
              if (msg.hasImage &&
                  msg.caption != null &&
                  msg.caption!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                  child: Text(
                    msg.caption!,
                    style: GoogleFonts.spaceGrotesk(
                      color: ArenaColors.bone,
                      fontSize: 13,
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 2, 12, 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      DateFormat('HH:mm').format(msg.sentAt.toLocal()),
                      style: GoogleFonts.spaceGrotesk(
                        color: ArenaColors.silver,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      msg.readAt == null
                          ? FluentIcons.accept
                          : FluentIcons.completed_solid,
                      size: 11,
                      color: msg.readAt == null
                          ? ArenaColors.silver
                          : ArenaColors.signalBlue,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BubbleImage extends StatelessWidget {
  const _BubbleImage({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 280),
      child: CachedNetworkImage(
        imageUrl: url,
        fit: BoxFit.cover,
        width: double.infinity,
        placeholder: (_, __) => Container(
          height: 200,
          color: ArenaColors.carbon,
          child: const Center(child: ProgressRing()),
        ),
        errorWidget: (_, __, ___) => Container(
          height: 120,
          color: ArenaColors.carbon,
          child: const Center(
            child: Icon(
              FluentIcons.photo_error,
              color: ArenaColors.silver,
            ),
          ),
        ),
      ),
    );
  }
}
