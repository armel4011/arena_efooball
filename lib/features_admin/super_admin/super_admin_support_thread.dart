import 'dart:io';

import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/data/repositories/chat_repository.dart';
import 'package:arena/features_shared/auth_common/shared_auth_providers.dart';
import 'package:arena/features_shared/widgets/arena_app_bar.dart';
import 'package:arena/features_shared/widgets/arena_button.dart';
import 'package:arena/features_shared/widgets/arena_screen_background.dart';
import 'package:arena/features_shared/widgets/arena_text_field.dart';
import 'package:arena/features_shared/widgets/empty_state.dart';
import 'package:arena/features_shared/widgets/error_state.dart';
import 'package:arena/features_user/chat/chat_page.dart' show ChatBubble;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

/// Fil de support (super-admin) avec UN utilisateur — répond dans le canal
/// `chat_channels.type='admin_user'`. Réutilise le stream
/// [channelMessagesProvider] + la bulle [ChatBubble] (côté admin, les
/// messages de l'admin s'affichent à droite). L'envoi passe par
/// `chatRepositoryProvider.sendMessage` (la garde RLS autorise les admins).
class SuperAdminSupportThread extends ConsumerStatefulWidget {
  const SuperAdminSupportThread({
    required this.channelId,
    required this.username,
    super.key,
  });

  final String channelId;
  final String username;

  @override
  ConsumerState<SuperAdminSupportThread> createState() =>
      _SuperAdminSupportThreadState();
}

class _SuperAdminSupportThreadState
    extends ConsumerState<SuperAdminSupportThread> {
  final _ctrl = TextEditingController();
  bool _sending = false;
  bool _uploading = false;

  @override
  void initState() {
    super.initState();
    // Marque le fil comme lu pour l'admin courant à l'ouverture.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(chatRepositoryProvider).markChannelAsRead(widget.channelId);
    });
  }

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
      await ref.read(chatRepositoryProvider).sendMessage(
            channelId: widget.channelId,
            senderId: adminId,
            content: txt,
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
    if (_uploading) return;
    final adminId = ref.read(currentSessionProvider)?.user.id;
    if (adminId == null) return;
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1920,
      imageQuality: 85,
    );
    if (picked == null || !mounted) return;
    setState(() => _uploading = true);
    try {
      await ref.read(chatRepositoryProvider).sendMediaMessage(
            channelId: widget.channelId,
            senderId: adminId,
            file: File(picked.path),
            mediaType: 'image',
          );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Échec envoi image : $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final adminId = ref.watch(currentSessionProvider)?.user.id;
    final messagesAsync = ref.watch(channelMessagesProvider(widget.channelId));
    final busy = _sending || _uploading;

    return Scaffold(
      appBar: ArenaAppBar(title: widget.username),
      body: ArenaScreenBackground(
        accent: ArenaColors.neonRed,
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: messagesAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => ErrorState(
                    description: e.toString(),
                    onRetry: () => ref.invalidate(
                      channelMessagesProvider(widget.channelId),
                    ),
                  ),
                  data: (messages) {
                    if (messages.isEmpty) {
                      return const EmptyState(
                        icon: Icons.support_agent_outlined,
                        title: 'Aucun message',
                        description: 'Réponds pour démarrer la conversation.',
                      );
                    }
                    return ListView.builder(
                      reverse: true,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: ArenaSpacing.md,
                      ),
                      itemCount: messages.length,
                      itemBuilder: (context, i) {
                        final msg = messages[messages.length - 1 - i];
                        return ChatBubble(
                          message: msg,
                          isSelf: msg.senderId == adminId,
                        );
                      },
                    );
                  },
                ),
              ),
              const Divider(height: 1, color: ArenaColors.border),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.all(ArenaSpacing.sm),
                  child: Row(
                    children: [
                      IconButton(
                        tooltip: 'Envoyer une image',
                        onPressed: busy ? null : _pickAndSendImage,
                        icon: const Icon(
                          Icons.add_photo_alternate_outlined,
                          color: ArenaColors.silver,
                        ),
                      ),
                      Expanded(
                        child: ArenaTextField(
                          controller: _ctrl,
                          hint: 'Ta réponse…',
                          enabled: !busy,
                          minLines: 1,
                          maxLines: 4,
                          maxLength: 2000,
                        ),
                      ),
                      const SizedBox(width: ArenaSpacing.sm),
                      ArenaButton(
                        label: busy ? '…' : 'ENVOYER',
                        onPressed: busy ? null : _sendText,
                        isLoading: busy,
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
