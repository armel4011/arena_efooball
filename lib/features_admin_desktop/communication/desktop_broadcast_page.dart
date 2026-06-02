import 'dart:io';

import 'package:arena/core/theme/arena_fluent_theme.dart';
import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/data/repositories/admin/admin_audit_log_repository.dart';
import 'package:arena/data/repositories/admin/admin_users_repository.dart';
import 'package:arena/data/repositories/admin_chat_repository.dart';
import 'package:arena/data/repositories/profile_repository.dart';
import 'package:arena/features_shared/auth_common/shared_auth_providers.dart';
// Dépendance transitive (umbrella `file_selector` absent du pubspec) : on
// cible l'interface plateforme, l'implémentation Windows s'enregistre via
// le plugin registrant.
// ignore: depend_on_referenced_packages
import 'package:file_selector_platform_interface/file_selector_platform_interface.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show FileOptions;

const _imageTypeGroup = XTypeGroup(
  label: 'Images',
  extensions: <String>['jpg', 'jpeg', 'png', 'webp', 'gif'],
);

/// Mode de diffusion :
///  * [push] : INSERT dans `notifications` (titre + corps + route + image).
///  * [chat] : bulk INSERT dans `admin_chat_messages` (message + image),
///    persistant côté inbox utilisateur.
enum _BroadcastMode { push, chat }

/// Diffusion de notifications ciblées — version desktop (Fluent UI).
///
/// Reprend les 5 filtres d'audience de la RPC `admin_filter_users`
/// (statut, pays, activité, 3-strikes, compétitions), la composition du
/// message et l'upload d'image (via `file_selector`, compatible Windows).
class DesktopBroadcastPage extends ConsumerStatefulWidget {
  const DesktopBroadcastPage({super.key});

  @override
  ConsumerState<DesktopBroadcastPage> createState() =>
      _DesktopBroadcastPageState();
}

class _DesktopBroadcastPageState extends ConsumerState<DesktopBroadcastPage> {
  final _searchCtrl = TextEditingController();
  final _titleCtrl = TextEditingController();
  final _bodyCtrl = TextEditingController();
  final _routeCtrl = TextEditingController();
  final _captionCtrl = TextEditingController();

  AdminUsersFilter _filter = const AdminUsersFilter();
  _BroadcastMode _mode = _BroadcastMode.push;
  String _notifType = 'system';

  bool _sending = false;
  bool _uploadingImage = false;
  File? _pickedImage;
  String? _uploadedImageUrl;
  InfoBarSeverity? _resultSeverity;
  String? _resultMessage;

  static const _typeOptions = <String>[
    'system',
    'match_starting',
    'competition_starting',
    'payout_received',
    'dispute_opened',
  ];

  static const _statusOptions = <(String?, String)>[
    (null, 'Tous'),
    ('active', 'Actifs'),
    ('banned', 'Bannis'),
    ('kyc_pending', 'KYC en attente'),
  ];

  static const _countryOptions = <(String?, String)>[
    (null, 'Tous'),
    ('CM', 'Cameroun'),
    ('SN', 'Sénégal'),
    ('CI', "Côte d'Ivoire"),
    ('BF', 'Burkina Faso'),
  ];

  static const _guiltyOptions = <(int?, String)>[
    (null, 'Indifférent'),
    (1, '≥ 1 verdict'),
    (2, '≥ 2 verdicts'),
    (3, '≥ 3 (banni à vie)'),
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

  bool get _isChat => _mode == _BroadcastMode.chat;

  bool get _canSend {
    if (_sending || _uploadingImage) return false;
    final hasBody = _bodyCtrl.text.trim().isNotEmpty;
    final hasImage = _uploadedImageUrl != null;
    if (_isChat) return hasBody || hasImage;
    return _titleCtrl.text.trim().isNotEmpty && (hasBody || hasImage);
  }

  // ─── Image ───────────────────────────────────────────────────────────

  Future<void> _pickAndUploadImage() async {
    final picked = await FileSelectorPlatform.instance.openFile(
      acceptedTypeGroups: const [_imageTypeGroup],
    );
    if (picked == null || !mounted) return;

    final file = File(picked.path);
    setState(() {
      _pickedImage = file;
      _uploadingImage = true;
      _uploadedImageUrl = null;
    });
    try {
      final url = await _uploadImage(file);
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
        _resultSeverity = InfoBarSeverity.error;
        _resultMessage = 'Échec de l’upload : $e';
      });
    }
  }

  Future<String> _uploadImage(File file) async {
    if (_isChat) {
      final adminId = ref.read(currentSessionProvider)?.user.id;
      if (adminId == null) throw StateError('Session admin expirée.');
      return ref
          .read(adminChatRepositoryProvider)
          .uploadBroadcastImage(adminId: adminId, file: file);
    }
    final client = ref.read(supabaseClientProvider);
    final ext = file.path.split('.').last.toLowerCase();
    final mime = switch (ext) {
      'png' => 'image/png',
      'webp' => 'image/webp',
      'gif' => 'image/gif',
      _ => 'image/jpeg',
    };
    final path = 'broadcast/${DateTime.now().millisecondsSinceEpoch}.$ext';
    await client.storage.from('notification_images').upload(
          path,
          file,
          fileOptions: FileOptions(contentType: mime, upsert: false),
        );
    return client.storage.from('notification_images').getPublicUrl(path);
  }

  void _clearImage() {
    setState(() {
      _pickedImage = null;
      _uploadedImageUrl = null;
      _captionCtrl.clear();
    });
  }

  // ─── Envoi ─────────────────────────────────────────────────────────────

  Future<void> _send(List<String> userIds) async {
    if (userIds.isEmpty) return;
    final adminId = ref.read(currentSessionProvider)?.user.id;
    if (adminId == null) return;

    setState(() {
      _sending = true;
      _resultMessage = null;
      _resultSeverity = null;
    });

    try {
      if (_isChat) {
        await _sendChat(adminId, userIds);
      } else {
        await _sendPush(adminId, userIds);
      }
      if (!mounted) return;
      setState(() {
        _sending = false;
        _resultSeverity = InfoBarSeverity.success;
        _resultMessage = 'Envoyé à ${userIds.length} utilisateur(s).';
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
        _resultSeverity = InfoBarSeverity.error;
        _resultMessage = 'Erreur : $e';
      });
    }
  }

  Future<void> _sendChat(String adminId, List<String> userIds) async {
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
      beforeState: const {},
      afterState: {
        'recipients_count': userIds.length,
        'text_length': body.length,
        'has_image': imageUrl != null,
        'has_caption': caption.isNotEmpty,
        'competition_ids': _filter.competitionIds,
      },
    );
  }

  Future<void> _sendPush(String adminId, List<String> userIds) async {
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
      beforeState: const {},
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

  // ─── UI ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(adminUsersProvider(_filter));
    final compsAsync = ref.watch(filterableCompetitionsProvider);

    return ScaffoldPage(
      header: const PageHeader(title: Text('DIFFUSION')),
      content: ListView(
        padding: const EdgeInsets.symmetric(
          horizontal: ArenaDesktop.pagePadding,
        ),
        children: [
          _ModeToggle(
            mode: _mode,
            onChanged: (m) => setState(() => _mode = m),
          ),
          const SizedBox(height: 20),

          const _SectionTitle('CIBLE'),
          const SizedBox(height: 8),
          _AudienceFilters(
            filter: _filter,
            searchCtrl: _searchCtrl,
            statusOptions: _statusOptions,
            countryOptions: _countryOptions,
            guiltyOptions: _guiltyOptions,
            competitions: compsAsync.valueOrNull ?? const [],
            onFilterChanged: (f) => setState(() => _filter = f),
          ),
          const SizedBox(height: 12),
          _RecipientsBar(usersAsync: usersAsync),
          const SizedBox(height: 24),

          const _SectionTitle('MESSAGE'),
          const SizedBox(height: 8),
          if (!_isChat) ...[
            InfoLabel(
              label: 'Titre',
              child: TextBox(
                controller: _titleCtrl,
                placeholder: 'Titre visible dans la notification',
                maxLength: 60,
              ),
            ),
            const SizedBox(height: 12),
          ],
          InfoLabel(
            label: _isChat ? 'Message' : 'Corps du message',
            child: TextBox(
              controller: _bodyCtrl,
              placeholder: _isChat
                  ? 'Texte du message (optionnel si image jointe)'
                  : 'Corps du message',
              minLines: 3,
              maxLines: _isChat ? 10 : 6,
              maxLength: _isChat ? 2000 : null,
            ),
          ),
          if (!_isChat) ...[
            const SizedBox(height: 12),
            InfoLabel(
              label: 'Route deep-link (optionnel)',
              child: TextBox(
                controller: _routeCtrl,
                placeholder: 'ex. /competitions',
              ),
            ),
            const SizedBox(height: 12),
            InfoLabel(
              label: 'Type',
              child: ComboBox<String>(
                value: _notifType,
                items: [
                  for (final t in _typeOptions)
                    ComboBoxItem(value: t, child: Text(t)),
                ],
                onChanged: (v) =>
                    setState(() => _notifType = v ?? _notifType),
              ),
            ),
          ],
          const SizedBox(height: 16),

          const _SectionTitle('IMAGE (OPTIONNEL)'),
          const SizedBox(height: 8),
          _ImagePicker(
            pickedImage: _pickedImage,
            uploadedUrl: _uploadedImageUrl,
            uploading: _uploadingImage,
            onPick: _pickAndUploadImage,
            onClear: _clearImage,
          ),
          if (_isChat && _pickedImage != null) ...[
            const SizedBox(height: 12),
            InfoLabel(
              label: 'Légende',
              child: TextBox(
                controller: _captionCtrl,
                placeholder: 'Légende sous l’image (optionnel)',
                minLines: 1,
                maxLines: 4,
                maxLength: 1024,
              ),
            ),
          ],
          const SizedBox(height: 24),

          if (_resultMessage != null) ...[
            InfoBar(
              title: Text(
                _resultSeverity == InfoBarSeverity.success
                    ? 'Succès'
                    : 'Erreur',
              ),
              content: Text(_resultMessage!),
              severity: _resultSeverity ?? InfoBarSeverity.info,
              onClose: () => setState(() => _resultMessage = null),
            ),
            const SizedBox(height: 12),
          ],

          FilledButton(
            onPressed: !_canSend
                ? null
                : () => usersAsync.whenData(
                      (list) => _send([for (final u in list) u.id]),
                    ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: _sending
                  ? const SizedBox(
                      height: 18,
                      child: ProgressRing(strokeWidth: 2.5),
                    )
                  : Text(
                      _isChat
                          ? 'ENVOYER LE MESSAGE'
                          : 'ENVOYER LA NOTIFICATION',
                    ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Widgets privés
// ─────────────────────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.bebasNeue(
        color: ArenaColors.silver,
        fontSize: 16,
        letterSpacing: 1.5,
      ),
    );
  }
}

class _ModeToggle extends StatelessWidget {
  const _ModeToggle({required this.mode, required this.onChanged});

  final _BroadcastMode mode;
  final ValueChanged<_BroadcastMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ToggleButton(
            checked: mode == _BroadcastMode.push,
            onChanged: (_) => onChanged(_BroadcastMode.push),
            child: const SizedBox(
              width: double.infinity,
              child: Center(child: Text('NOTIFICATION PUSH')),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ToggleButton(
            checked: mode == _BroadcastMode.chat,
            onChanged: (_) => onChanged(_BroadcastMode.chat),
            child: const SizedBox(
              width: double.infinity,
              child: Center(child: Text('MESSAGE CHAT')),
            ),
          ),
        ),
      ],
    );
  }
}

class _AudienceFilters extends StatelessWidget {
  const _AudienceFilters({
    required this.filter,
    required this.searchCtrl,
    required this.statusOptions,
    required this.countryOptions,
    required this.guiltyOptions,
    required this.competitions,
    required this.onFilterChanged,
  });

  final AdminUsersFilter filter;
  final TextEditingController searchCtrl;
  final List<(String?, String)> statusOptions;
  final List<(String?, String)> countryOptions;
  final List<(int?, String)> guiltyOptions;
  final List<FilterableCompetition> competitions;
  final ValueChanged<AdminUsersFilter> onFilterChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      backgroundColor: ArenaColors.carbon,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextBox(
            controller: searchCtrl,
            placeholder: 'Username ou email (vide = tout le monde)',
            prefix: const Padding(
              padding: EdgeInsets.only(left: 8),
              child: Icon(FluentIcons.people, size: 14),
            ),
            onChanged: (v) {
              final q = v.trim();
              onFilterChanged(
                filter.copyWith(
                  searchQuery: q.isEmpty ? null : q,
                  resetSearch: q.isEmpty,
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 16,
            runSpacing: 12,
            children: [
              InfoLabel(
                label: 'Statut',
                child: ComboBox<String?>(
                  value: filter.filter,
                  placeholder: const Text('Tous'),
                  items: [
                    for (final (id, label) in statusOptions)
                      ComboBoxItem(value: id, child: Text(label)),
                  ],
                  onChanged: (v) => onFilterChanged(
                    filter.copyWith(filter: v, resetFilter: v == null),
                  ),
                ),
              ),
              InfoLabel(
                label: 'Pays',
                child: ComboBox<String?>(
                  value: filter.countryCode,
                  placeholder: const Text('Tous'),
                  items: [
                    for (final (id, label) in countryOptions)
                      ComboBoxItem(value: id, child: Text(label)),
                  ],
                  onChanged: (v) => onFilterChanged(
                    filter.copyWith(
                      countryCode: v,
                      resetCountryCode: v == null,
                    ),
                  ),
                ),
              ),
              InfoLabel(
                label: '3-strikes',
                child: ComboBox<int?>(
                  value: filter.guiltyMinCount,
                  placeholder: const Text('Indifférent'),
                  items: [
                    for (final (id, label) in guiltyOptions)
                      ComboBoxItem(value: id, child: Text(label)),
                  ],
                  onChanged: (v) => onFilterChanged(
                    filter.copyWith(
                      guiltyMinCount: v,
                      resetGuiltyMin: v == null,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Activité',
            style: GoogleFonts.spaceGrotesk(
              color: ArenaColors.silver,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              Checkbox(
                checked: filter.wonCompetition,
                content: const Text('A gagné'),
                onChanged: (v) => onFilterChanged(
                  filter.copyWith(wonCompetition: v ?? false),
                ),
              ),
              Checkbox(
                checked: filter.paidEntry,
                content: const Text('A payé'),
                onChanged: (v) =>
                    onFilterChanged(filter.copyWith(paidEntry: v ?? false)),
              ),
              Checkbox(
                checked: filter.receivedReward,
                content: const Text('A reçu un gain'),
                onChanged: (v) => onFilterChanged(
                  filter.copyWith(receivedReward: v ?? false),
                ),
              ),
              Checkbox(
                checked: filter.hadDispute,
                content: const Text('A eu un litige'),
                onChanged: (v) =>
                    onFilterChanged(filter.copyWith(hadDispute: v ?? false)),
              ),
            ],
          ),
          if (competitions.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'Compétitions (multi-sélection)',
              style: GoogleFonts.spaceGrotesk(
                color: ArenaColors.silver,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final c in competitions)
                  ToggleButton(
                    checked: filter.competitionIds.contains(c.id),
                    onChanged: (checked) {
                      final ids = [...filter.competitionIds];
                      if (checked) {
                        ids.add(c.id);
                      } else {
                        ids.remove(c.id);
                      }
                      onFilterChanged(
                        filter.copyWith(
                          competitionIds: ids,
                          resetCompetitionIds: ids.isEmpty,
                        ),
                      );
                    },
                    child: Text(
                      '${c.name} · ${c.currentPlayers}/${c.maxPlayers}',
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _RecipientsBar extends StatelessWidget {
  const _RecipientsBar({required this.usersAsync});

  final AsyncValue<List<dynamic>> usersAsync;

  @override
  Widget build(BuildContext context) {
    return usersAsync.when(
      loading: () => const _RecipientCard(
        icon: FluentIcons.people,
        color: ArenaColors.silver,
        text: 'Calcul du nombre de destinataires…',
        showRing: true,
      ),
      error: (e, _) => _RecipientCard(
        icon: FluentIcons.error_badge,
        color: ArenaColors.neonRed,
        text: 'Erreur de filtre : $e',
      ),
      data: (list) => _RecipientCard(
        icon: list.isEmpty ? FluentIcons.warning : FluentIcons.group,
        color: list.isEmpty ? ArenaColors.statusWarn : ArenaColors.signalBlue,
        text: list.isEmpty
            ? 'Aucun destinataire — ajustez les filtres.'
            : '${list.length} destinataire(s) ciblé(s)',
      ),
    );
  }
}

class _RecipientCard extends StatelessWidget {
  const _RecipientCard({
    required this.icon,
    required this.color,
    required this.text,
    this.showRing = false,
  });

  final IconData icon;
  final Color color;
  final String text;
  final bool showRing;

  @override
  Widget build(BuildContext context) {
    return Card(
      backgroundColor: ArenaColors.carbon,
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          if (showRing)
            const SizedBox(
              height: 16,
              width: 16,
              child: ProgressRing(strokeWidth: 2),
            )
          else
            Icon(icon, color: color, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.spaceGrotesk(
                color: ArenaColors.bone,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ImagePicker extends StatelessWidget {
  const _ImagePicker({
    required this.pickedImage,
    required this.uploadedUrl,
    required this.uploading,
    required this.onPick,
    required this.onClear,
  });

  final File? pickedImage;
  final String? uploadedUrl;
  final bool uploading;
  final VoidCallback onPick;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    if (pickedImage == null) {
      return Button(
        onPressed: onPick,
        child: const Padding(
          padding: EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(FluentIcons.photo2_add, size: 16),
              SizedBox(width: 8),
              Text('Ajouter une image (PNG / JPG / WebP)'),
            ],
          ),
        ),
      );
    }
    return Card(
      backgroundColor: ArenaColors.carbon,
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(ArenaRadius.sm),
            child: Image.file(
              pickedImage!,
              height: 160,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              if (uploading)
                const SizedBox(
                  height: 14,
                  width: 14,
                  child: ProgressRing(strokeWidth: 2),
                )
              else
                Icon(
                  uploadedUrl != null
                      ? FluentIcons.completed_solid
                      : FluentIcons.error_badge,
                  size: 16,
                  color: uploadedUrl != null
                      ? ArenaColors.statusOk
                      : ArenaColors.neonRed,
                ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  uploading
                      ? 'Upload en cours…'
                      : (uploadedUrl != null
                          ? 'Image prête à envoyer'
                          : 'Échec de l’upload'),
                  style: GoogleFonts.spaceGrotesk(
                    color: ArenaColors.silver,
                    fontSize: 12,
                  ),
                ),
              ),
              HyperlinkButton(
                onPressed: uploading ? null : onClear,
                child: Text(
                  'Retirer',
                  style: GoogleFonts.spaceGrotesk(
                    color: ArenaColors.neonRed,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
