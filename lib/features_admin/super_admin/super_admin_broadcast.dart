import 'dart:io';

import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/data/repositories/admin/admin_audit_log_repository.dart';
import 'package:arena/data/repositories/admin/admin_users_repository.dart';
import 'package:arena/data/repositories/admin_chat_repository.dart';
import 'package:arena/data/repositories/profile_repository.dart';
import 'package:arena/features_admin/auth_admin/widgets/totp_gate.dart';
import 'package:arena/features_shared/auth_common/shared_auth_providers.dart';
import 'package:arena/features_shared/widgets/arena_app_bar.dart';
import 'package:arena/features_shared/widgets/arena_button.dart';
import 'package:arena/features_shared/widgets/arena_filter_menu.dart';
import 'package:arena/features_shared/widgets/arena_screen_background.dart';
import 'package:arena/features_shared/widgets/arena_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show FileOptions;

part 'super_admin_broadcast_widgets.dart';
part 'super_admin_broadcast_filters.dart';

/// Modes du broadcast super-admin :
/// - [push] : insert dans `notifications` → trigger DB → FCM (titre, body,
///   image, route, type). Non-persistant côté inbox user.
/// - [chat] : bulk insert dans `admin_chat_messages` via [AdminChatRepository.broadcast]
///   → trigger DB crée aussi une row `notifications type=admin_message`
///   (donc FCM aussi). Persistant dans `/admin-messages` côté user.
enum _BroadcastMode { push, chat }

/// PHASE 12.5 — Écran super-admin pour envoyer une notification ciblée.
///
/// Lot C : la sélection de cible passe par `ArenaFilterMenu` qui réunit
/// tous les critères (status, pays, activité, 3-strikes, compétition).
/// Le filtre par compétition permet de broadcaster aux inscrits d'une
/// compétition précise (item 3 du prompt utilisateur).
class SuperAdminBroadcast extends ConsumerStatefulWidget {
  const SuperAdminBroadcast({super.key});

  @override
  ConsumerState<SuperAdminBroadcast> createState() =>
      _SuperAdminBroadcastState();
}

class _SuperAdminBroadcastState extends ConsumerState<SuperAdminBroadcast> {
  final _searchCtrl = TextEditingController();
  final _titleCtrl = TextEditingController();
  final _bodyCtrl = TextEditingController();
  final _routeCtrl = TextEditingController();

  AdminUsersFilter _filter = const AdminUsersFilter();
  String _notifType = 'system';
  _BroadcastMode _mode = _BroadcastMode.push;
  bool _sending = false;
  String? _lastResult;
  File? _pickedImage;
  String? _uploadedImageUrl;
  bool _uploadingImage = false;

  /// Caption optionnelle (mode push : sous-titre de la notif sous l'image,
  /// mode chat : legende affichee sous l'image dans le fil — comme WhatsApp).
  final _captionCtrl = TextEditingController();

  static const _typeOptions = <String>[
    'system',
    'match_starting',
    'competition_starting',
    'payout_received',
    'dispute_opened',
  ];

  @override
  void initState() {
    super.initState();
    _titleCtrl.addListener(_onChanged);
    _bodyCtrl.addListener(_onChanged);
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _titleCtrl
      ..removeListener(_onChanged)
      ..dispose();
    _bodyCtrl
      ..removeListener(_onChanged)
      ..dispose();
    _routeCtrl.dispose();
    _captionCtrl.dispose();
    super.dispose();
  }

  bool get _canSend {
    if (_sending) return false;
    if (_uploadingImage) return false;
    final hasBody = _bodyCtrl.text.trim().isNotEmpty;
    final hasImage = _uploadedImageUrl != null;
    if (_mode == _BroadcastMode.chat) {
      // Mode chat (WhatsApp-like) : autorise body OU image (ou les deux).
      // Si image seule, la caption peut aussi etre vide.
      return hasBody || hasImage;
    }
    // Mode push : titre + (body ou image). L'image seule sans body est OK
    // tant que le titre est present (titre = headline de la notif systeme).
    return _titleCtrl.text.trim().isNotEmpty && (hasBody || hasImage);
  }

  Future<void> _pickAndUploadImage() async {
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
    setState(() {
      _pickedImage = file;
      _uploadingImage = true;
      _uploadedImageUrl = null;
    });
    try {
      String url;
      if (_mode == _BroadcastMode.chat) {
        // Mode chat : route via le repo qui ecrit dans
        // `admin_chat_broadcast/<adminId>/...` (cf. RLS admin-write).
        final adminId = ref.read(currentSessionProvider)?.user.id;
        if (adminId == null) {
          throw StateError('admin session expired');
        }
        url = await ref
            .read(adminChatRepositoryProvider)
            .uploadBroadcastImage(adminId: adminId, file: file);
      } else {
        // Mode push : bucket public, prefix `broadcast/`.
        final client = ref.read(supabaseClientProvider);
        final ext = picked.path.split('.').last.toLowerCase();
        // `image/$ext` produit `image/jpg` pour un .jpg → MIME invalide
        // (le vrai est `image/jpeg`), rejete par le bucket en 415. On mappe
        // vers des types IANA standards.
        final mime = switch (ext) {
          'png' => 'image/png',
          'webp' => 'image/webp',
          'gif' => 'image/gif',
          _ => 'image/jpeg',
        };
        // Cle propre `<ts>.<ext>` comme le chat admin — `picked.name` peut
        // contenir espaces/caracteres speciaux (ex. "WhatsApp Image ... .jpeg")
        // qui cassent la cle de l'objet storage.
        final path =
            'broadcast/${DateTime.now().millisecondsSinceEpoch}.$ext';
        await client.storage.from('notification_images').upload(
              path,
              file,
              fileOptions: FileOptions(
                contentType: mime,
                upsert: false,
              ),
            );
        url = client.storage.from('notification_images').getPublicUrl(path);
      }
      if (!mounted) return;
      setState(() {
        _uploadingImage = false;
        _uploadedImageUrl = url;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _uploadingImage = false;
        _pickedImage = null;
        _lastResult = '✗ Upload image échoué : $e';
      });
    }
  }

  void _clearImage() {
    setState(() {
      _pickedImage = null;
      _uploadedImageUrl = null;
      _captionCtrl.clear();
    });
  }

  Future<void> _send(List<String> userIds) async {
    if (userIds.isEmpty) return;
    final adminId = ref.read(currentSessionProvider)?.user.id;
    if (adminId == null) return;

    final isChat = _mode == _BroadcastMode.chat;
    final totpOk = await TotpGate.confirm(
      context,
      ref,
      reason: isChat
          ? 'Envoyer un message chat à ${userIds.length} utilisateur(s)'
          : 'Envoyer une notif à ${userIds.length} utilisateur(s)',
    );
    if (!totpOk) return;
    if (!mounted) return;

    setState(() {
      _sending = true;
      _lastResult = null;
    });

    try {
      if (isChat) {
        // Bulk insert dans admin_chat_messages. Le trigger DB
        // `_notify_admin_message` créera 1 row notifications type=admin_message
        // par destinataire → FCM auto + persistance dans /admin-messages.
        // L'image (si presente) est UPLOADEE UNE SEULE FOIS dans
        // `admin_chat_broadcast/<adminId>/...` et la meme URL est insérée
        // pour chaque destinataire — pas de duplication storage.
        final body = _bodyCtrl.text.trim();
        final imageUrl = _uploadedImageUrl;
        final caption = _captionCtrl.text.trim();
        await ref.read(adminChatRepositoryProvider).broadcast(
              adminId: adminId,
              recipientIds: userIds,
              text: body.isEmpty ? null : body,
              imageUrl: imageUrl,
              caption: caption.isEmpty ? null : caption,
            );
        await ref.read(adminAuditLogRepositoryProvider).record(
          adminId: adminId,
          action: 'broadcast_chat_message',
          targetType: 'admin_chat_message',
          targetId: null,
          beforeState: {},
          afterState: {
            'recipients_count': userIds.length,
            'text_length': body.length,
            'has_image': imageUrl != null,
            'has_caption': caption.isNotEmpty,
            'competition_ids': _filter.competitionIds,
          },
        );
      } else {
        final client = ref.read(supabaseClientProvider);
        final route = _routeCtrl.text.trim();
        final imageUrl = _uploadedImageUrl;
        final rows = [
          for (final uid in userIds)
            {
              'user_id': uid,
              'type': _notifType,
              'title': _titleCtrl.text.trim(),
              'body': _bodyCtrl.text.trim(),
              if (imageUrl != null) 'image_url': imageUrl,
              'data': route.isEmpty ? <String, dynamic>{} : {'route': route},
            },
        ];
        await client.from('notifications').insert(rows);
        await ref.read(adminAuditLogRepositoryProvider).record(
          adminId: adminId,
          action: 'broadcast_notification',
          targetType: 'notification',
          targetId: null,
          beforeState: {},
          afterState: {
            'recipients_count': userIds.length,
            'type': _notifType,
            'title': _titleCtrl.text.trim(),
            'has_route': route.isNotEmpty,
            'has_image': imageUrl != null,
            'competition_ids': _filter.competitionIds,
          },
        );
      }
      if (!mounted) return;
      setState(() {
        _sending = false;
        _lastResult = '✓ Envoyé à ${userIds.length} utilisateur(s)';
        _titleCtrl.clear();
        _bodyCtrl.clear();
        _routeCtrl.clear();
        _captionCtrl.clear();
        _pickedImage = null;
        _uploadedImageUrl = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _sending = false;
        _lastResult = '✗ Erreur : $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(adminUsersProvider(_filter));
    final compsAsync = ref.watch(filterableCompetitionsProvider);

    final isChat = _mode == _BroadcastMode.chat;
    return Scaffold(
      appBar: ArenaAppBar(
        title: isChat ? 'Message chat broadcast' : 'Notification broadcast',
      ),
      body: ArenaScreenBackground(
        accent: ArenaColors.neonRed,
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(ArenaSpacing.lg),
            children: [
              // ─── Mode toggle ───────────────────────────────────────
              _ModeToggle(
                mode: _mode,
                onChanged: (m) => setState(() => _mode = m),
              ),
              const SizedBox(height: ArenaSpacing.md),
              // ─── Filtres cible ──────────────────────────────────────
              Text('🎯 CIBLE', style: ArenaText.h3),
              const SizedBox(height: ArenaSpacing.sm),
              ArenaTextField(
                controller: _searchCtrl,
                hint: '🔍 Username ou email (laisser vide pour tous)',
                onChanged: (v) => setState(() {
                  final q = v.trim();
                  _filter = _filter.copyWith(
                    searchQuery: q.isEmpty ? null : q,
                    resetSearch: q.isEmpty,
                  );
                }),
              ),
              const SizedBox(height: ArenaSpacing.sm),
              Row(
                children: [
                  compsAsync.when(
                    data: (comps) => ArenaFilterMenu(
                      activeCount: _activeFilterCount(),
                      sections: _buildSections(comps),
                      initialSelection: _selectionFromFilter(),
                      onApply: _applySelection,
                    ),
                    loading: () => const _LoadingFilterButton(),
                    error: (_, __) => ArenaFilterMenu(
                      activeCount: _activeFilterCount(),
                      sections: _buildSections(const []),
                      initialSelection: _selectionFromFilter(),
                      onApply: _applySelection,
                    ),
                  ),
                  const Spacer(),
                  if (_activeFilterCount() > 0)
                    TextButton(
                      onPressed: () => setState(() {
                        _filter = AdminUsersFilter(
                          searchQuery: _filter.searchQuery,
                        );
                      }),
                      child: Text(
                        'Réinitialiser',
                        style: ArenaText.small.copyWith(
                          color: ArenaColors.signalBlue,
                        ),
                      ),
                    ),
                ],
              ),
              if (_filter.competitionIds.isNotEmpty) ...[
                const SizedBox(height: ArenaSpacing.sm),
                _ActiveCompetitionsBadges(
                  competitionIds: _filter.competitionIds,
                  comps: compsAsync.asData?.value ?? const [],
                  onClearOne: (id) => setState(() {
                    final remaining =
                        _filter.competitionIds.where((c) => c != id).toList();
                    _filter = _filter.copyWith(
                      competitionIds: remaining,
                      resetCompetitionIds: remaining.isEmpty,
                    );
                  }),
                ),
              ],
              const SizedBox(height: ArenaSpacing.md),

              // ─── Compteur destinataires + bouton envoi ──────────────
              usersAsync.when(
                loading: () => _RecipientCard(
                  child: Row(
                    children: [
                      const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      const SizedBox(width: ArenaSpacing.sm),
                      Text(
                        'Calcul du nombre de destinataires…',
                        style: ArenaText.bodyMuted,
                      ),
                    ],
                  ),
                ),
                error: (e, _) => _RecipientCard(
                  child: Text(
                    'Erreur de filtre : $e',
                    style: ArenaText.bodyMuted
                        .copyWith(color: ArenaColors.neonRed),
                  ),
                ),
                data: (list) => _RecipientCard(
                  child: Row(
                    children: [
                      Icon(
                        list.isEmpty ? Icons.warning_amber : Icons.group,
                        color: list.isEmpty
                            ? ArenaColors.statusWarn
                            : ArenaColors.signalBlue,
                      ),
                      const SizedBox(width: ArenaSpacing.sm),
                      Expanded(
                        child: Text(
                          list.isEmpty
                              ? 'Aucun destinataire — ajuste les filtres.'
                              : '${list.length} destinataire(s) ciblé(s)',
                          style: ArenaText.body,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: ArenaSpacing.lg),

              // ─── Composition du message ─────────────────────────────
              Text('📝 MESSAGE', style: ArenaText.h3),
              const SizedBox(height: ArenaSpacing.sm),
              if (!isChat) ...[
                ArenaTextField(
                  controller: _titleCtrl,
                  hint: 'Titre (visible dans la notification)',
                  maxLength: 60,
                ),
                const SizedBox(height: ArenaSpacing.sm),
              ],
              ArenaTextField(
                controller: _bodyCtrl,
                hint: isChat
                    ? 'Texte du message (optionnel si image jointe)'
                    : 'Corps du message',
                minLines: 3,
                maxLines: isChat ? 10 : 6,
                maxLength: isChat ? 2000 : null,
              ),
              if (!isChat) ...[
                const SizedBox(height: ArenaSpacing.sm),
                ArenaTextField(
                  controller: _routeCtrl,
                  hint: 'Route deep-link (optionnel) — ex. /competitions',
                  helper:
                      "Si défini, taper la notif redirige l'utilisateur sur"
                      " cette page de l'app.",
                ),
              ],
              // ─── Image (les 2 modes) ──────────────────────────────────
              // Mode push : header image de la notif systeme (BigPicture).
              // Mode chat : image jointe affichee dans la bulle (WhatsApp).
              const SizedBox(height: ArenaSpacing.md),
              Text('🖼 IMAGE (optionnel)', style: ArenaText.h3),
              const SizedBox(height: ArenaSpacing.sm),
              _ImagePickerCard(
                pickedImage: _pickedImage,
                uploadedUrl: _uploadedImageUrl,
                uploading: _uploadingImage,
                onPick: _pickAndUploadImage,
                onClear: _clearImage,
              ),
              // ─── Caption (mode chat uniquement, WhatsApp-like) ────────
              if (isChat && _pickedImage != null) ...[
                const SizedBox(height: ArenaSpacing.sm),
                ArenaTextField(
                  controller: _captionCtrl,
                  hint: "Légende sous l'image (optionnel, max 1024)",
                  minLines: 1,
                  maxLines: 4,
                  maxLength: 1024,
                ),
              ],
              if (!isChat) ...[
                const SizedBox(height: ArenaSpacing.sm),
                Text('Type', style: ArenaText.inputLabel),
                const SizedBox(height: ArenaSpacing.xs),
                Wrap(
                  spacing: ArenaSpacing.xs,
                  runSpacing: ArenaSpacing.xs,
                  children: [
                    for (final t in _typeOptions)
                      _toggle(t, _notifType == t, () {
                        setState(() => _notifType = t);
                      }),
                  ],
                ),
              ],
              const SizedBox(height: ArenaSpacing.lg),

              // ─── Action ─────────────────────────────────────────────
              ArenaButton(
                label: _sending
                    ? 'ENVOI EN COURS…'
                    : (isChat
                        ? '💬 ENVOYER LE MESSAGE'
                        : '🚀 ENVOYER LA NOTIF'),
                fullWidth: true,
                size: ArenaButtonSize.large,
                isLoading: _sending,
                onPressed: !_canSend
                    ? null
                    : () {
                        usersAsync.whenData((list) {
                          _send([for (final u in list) u.id]);
                        });
                      },
              ),
              if (_lastResult != null) ...[
                const SizedBox(height: ArenaSpacing.sm),
                Text(
                  _lastResult!,
                  style: ArenaText.body.copyWith(
                    color: _lastResult!.startsWith('✓')
                        ? ArenaColors.statusOk
                        : ArenaColors.neonRed,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _applySelection(Map<String, List<String>> selection) {
    setState(() => _filter = _filterFromSelection(selection));
  }

  Widget _toggle(String label, bool active, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(ArenaRadius.round),
      child: AnimatedContainer(
        duration: ArenaDurations.short,
        padding: const EdgeInsets.symmetric(
          horizontal: ArenaSpacing.md,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color: active
              ? ArenaColors.signalBlue.withValues(alpha: 0.15)
              : ArenaColors.carbon,
          borderRadius: BorderRadius.circular(ArenaRadius.round),
          border: Border.all(
            color: active ? ArenaColors.signalBlue : ArenaColors.border,
          ),
        ),
        child: Text(
          label,
          style: ArenaText.body.copyWith(
            color: active ? ArenaColors.signalBlue : ArenaColors.silver,
            fontWeight: active ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
