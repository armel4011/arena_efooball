import 'dart:io';

import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/data/repositories/admin_chat_repository.dart';
import 'package:arena/features_shared/auth_common/shared_auth_providers.dart';
import 'package:arena/features_shared/widgets/arena_app_bar.dart';
import 'package:arena/features_shared/widgets/arena_button.dart';
import 'package:arena/features_shared/widgets/arena_image_viewer.dart';
import 'package:arena/features_shared/widgets/arena_screen_background.dart';
import 'package:arena/features_shared/widgets/arena_text_field.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

/// F4 — Page admin : fil de messages prives avec UN user. Accessible
/// via `/super/messages/:userId` (ex. depuis super_admin_users).
///
/// Supporte texte + image (style WhatsApp) : tap sur l'icone photo ouvre
/// un picker, puis un bottom-sheet propose une caption avant envoi.
class AdminChatThreadPage extends ConsumerStatefulWidget {
  const AdminChatThreadPage({required this.userId, super.key});

  final String userId;

  @override
  ConsumerState<AdminChatThreadPage> createState() =>
      _AdminChatThreadPageState();
}

class _AdminChatThreadPageState extends ConsumerState<AdminChatThreadPage> {
  final _ctrl = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _sendText() async {
    final txt = _ctrl.text.trim();
    if (txt.isEmpty) return;
    final adminId = ref.read(currentSessionProvider)?.user.id;
    if (adminId == null) return;
    setState(() => _sending = true);
    try {
      await ref.read(adminChatRepositoryProvider).send(
            adminId: adminId,
            recipientId: widget.userId,
            text: txt,
          );
      _ctrl.clear();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Échec envoi : $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _pickAndSendImage() async {
    final adminId = ref.read(currentSessionProvider)?.user.id;
    if (adminId == null) return;
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1920,
      maxHeight: 1080,
      imageQuality: 85,
    );
    if (picked == null) return;
    if (!mounted) return;
    final file = File(picked.path);
    final caption = await _ImageCaptionSheet.show(context, file: file);
    if (caption == null) return; // user a annule depuis la sheet
    if (!mounted) return;
    setState(() => _sending = true);
    try {
      await ref.read(adminChatRepositoryProvider).sendImage(
            adminId: adminId,
            recipientId: widget.userId,
            file: file,
            caption: caption.isEmpty ? null : caption,
          );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Échec envoi image : $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final adminId = ref.watch(currentSessionProvider)?.user.id;
    if (adminId == null) {
      return const Scaffold(body: SizedBox.shrink());
    }
    return Scaffold(
      appBar: const ArenaAppBar(title: 'Chat privé'),
      body: ArenaScreenBackground(
        accent: ArenaColors.neonRed,
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: StreamBuilder<List<AdminChatMessage>>(
                  stream: ref
                      .read(adminChatRepositoryProvider)
                      .watchThread(adminId: adminId, userId: widget.userId),
                  builder: (context, snap) {
                    if (snap.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }
                    final msgs = snap.data ?? const [];
                    if (msgs.isEmpty) {
                      return Center(
                        child: Text(
                          'Aucun message. Sois le premier à écrire.',
                          style: ArenaText.bodyMuted,
                        ),
                      );
                    }
                    return ListView.builder(
                      padding: const EdgeInsets.all(ArenaSpacing.md),
                      itemCount: msgs.length,
                      itemBuilder: (_, i) =>
                          AdminChatBubble(msg: msgs[i], outgoing: true),
                    );
                  },
                ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.all(ArenaSpacing.sm),
                  child: Row(
                    children: [
                      IconButton(
                        tooltip: 'Envoyer une image',
                        onPressed: _sending ? null : _pickAndSendImage,
                        icon: const Icon(
                          Icons.add_photo_alternate_outlined,
                          color: ArenaColors.silver,
                        ),
                      ),
                      Expanded(
                        child: ArenaTextField(
                          controller: _ctrl,
                          hint: 'Ton message…',
                          minLines: 1,
                          maxLines: 4,
                          maxLength: 2000,
                        ),
                      ),
                      const SizedBox(width: ArenaSpacing.sm),
                      ArenaButton(
                        label: _sending ? '…' : 'ENVOYER',
                        onPressed: _sending ? null : _sendText,
                        isLoading: _sending,
                      ),
                    ],
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

/// Bottom-sheet WhatsApp-like : preview + champ caption + ENVOYER.
/// Retourne `null` si l'admin annule, ou la caption (peut etre vide).
class _ImageCaptionSheet extends StatefulWidget {
  const _ImageCaptionSheet({required this.file});
  final File file;

  static Future<String?> show(BuildContext context, {required File file}) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: ArenaColors.carbon,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _ImageCaptionSheet(file: file),
    );
  }

  @override
  State<_ImageCaptionSheet> createState() => _ImageCaptionSheetState();
}

class _ImageCaptionSheetState extends State<_ImageCaptionSheet> {
  final _captionCtrl = TextEditingController();

  @override
  void dispose() {
    _captionCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: ArenaSpacing.sm),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: ArenaColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(ArenaSpacing.lg),
              child: Column(
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
                  const SizedBox(height: ArenaSpacing.md),
                  ArenaTextField(
                    controller: _captionCtrl,
                    hint: 'Ajouter une légende (optionnel)…',
                    minLines: 1,
                    maxLines: 4,
                    maxLength: 1024,
                  ),
                  const SizedBox(height: ArenaSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: Text(
                            'Annuler',
                            style: ArenaText.body.copyWith(
                              color: ArenaColors.silver,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: ArenaSpacing.sm),
                      Expanded(
                        child: ArenaButton(
                          label: 'ENVOYER',
                          onPressed: () => Navigator.of(context).pop(
                            _captionCtrl.text.trim(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bulle de message reutilisable (admin thread + user inbox).
/// - texte seul : texte simple
/// - image seule : image cliquable (zoom fullscreen)
/// - image + caption : image au-dessus, caption en dessous
class AdminChatBubble extends StatelessWidget {
  const AdminChatBubble({
    required this.msg,
    required this.outgoing,
    super.key,
  });

  final AdminChatMessage msg;
  final bool outgoing;

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('HH:mm');
    final bgColor = outgoing
        ? ArenaColors.neonRed.withValues(alpha: 0.18)
        : ArenaColors.carbon;
    final borderColor = outgoing ? ArenaColors.neonRed : ArenaColors.border;
    return Align(
      alignment: outgoing ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 2),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(ArenaRadius.md),
          border: Border.all(color: borderColor, width: 1),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(ArenaRadius.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (msg.hasImage) _BubbleImage(url: msg.imageUrl!, caption: msg.caption),
              if (msg.text != null && msg.text!.isNotEmpty)
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    ArenaSpacing.md,
                    msg.hasImage ? ArenaSpacing.sm : ArenaSpacing.sm,
                    ArenaSpacing.md,
                    4,
                  ),
                  child: Text(msg.text!, style: ArenaText.body),
                ),
              if (msg.caption != null && msg.caption!.isNotEmpty && msg.hasImage)
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    ArenaSpacing.md,
                    ArenaSpacing.sm,
                    ArenaSpacing.md,
                    4,
                  ),
                  child: Text(msg.caption!, style: ArenaText.body),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  ArenaSpacing.md, 2, ArenaSpacing.md, ArenaSpacing.sm,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      fmt.format(msg.sentAt.toLocal()),
                      style: ArenaText.small,
                    ),
                    if (outgoing) ...[
                      const SizedBox(width: 4),
                      Icon(
                        msg.readAt == null ? Icons.done : Icons.done_all,
                        size: 12,
                        color: msg.readAt == null
                            ? ArenaColors.silver
                            : ArenaColors.signalBlue,
                      ),
                    ],
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
  const _BubbleImage({required this.url, this.caption});
  final String url;
  final String? caption;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => ArenaImageViewer.show(
        context,
        imageUrl: url,
        caption: caption,
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 280),
        child: CachedNetworkImage(
          imageUrl: url,
          fit: BoxFit.cover,
          width: double.infinity,
          placeholder: (_, __) => Container(
            height: 200,
            color: ArenaColors.carbon,
            child: const Center(
              child: CircularProgressIndicator(
                color: ArenaColors.silver,
              ),
            ),
          ),
          errorWidget: (_, __, ___) => Container(
            height: 120,
            color: ArenaColors.carbon,
            child: Center(
              child: Icon(
                Icons.broken_image_outlined,
                color: ArenaColors.silver.withValues(alpha: 0.6),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
