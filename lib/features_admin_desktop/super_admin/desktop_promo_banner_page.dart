import 'dart:io';

import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/core/utils/arena_error_message.dart';
import 'package:arena/data/models/promo_banner.dart';
import 'package:arena/data/repositories/admin/admin_audit_log_repository.dart';
import 'package:arena/data/repositories/profile_repository.dart';
import 'package:arena/data/repositories/promo_banner_repository.dart';
import 'package:arena/features_admin_desktop/shared/desktop_totp_gate.dart';
import 'package:arena/features_shared/auth_common/shared_auth_providers.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:file_picker/file_picker.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show FileOptions;

typedef _InternalPage = ({String label, String route});

/// Super-admin · Espace publicitaire (desktop) — gestion de la bannière
/// promo affichée sur la home utilisateur.
///
/// Équivalent Fluent UI de l'écran mobile SuperAdminPromoBanner.
/// Utilise file_picker pour la sélection d'image côté Windows.
class DesktopPromoBannerPage extends ConsumerStatefulWidget {
  const DesktopPromoBannerPage({super.key});

  @override
  ConsumerState<DesktopPromoBannerPage> createState() =>
      _DesktopPromoBannerPageState();
}

class _DesktopPromoBannerPageState
    extends ConsumerState<DesktopPromoBannerPage> {
  static const List<_InternalPage> _internalPages = [
    (label: 'Streams en direct', route: '/streams'),
    (label: 'Notifications', route: '/notifications'),
    (label: 'Messagerie', route: '/messages'),
    (label: 'Amis', route: '/friends'),
    (label: 'Paramètres', route: '/settings'),
    (label: 'Historique des paiements', route: '/payments/history'),
  ];

  final _webCtrl = TextEditingController();
  final _whatsappCtrl = TextEditingController();

  PromoRedirectType _type = PromoRedirectType.internalPage;
  String _selectedRoute = _internalPages.first.route;

  File? _pickedFile;
  String? _uploadedImageUrl;
  bool _uploadingImage = false;
  bool _saving = false;

  @override
  void dispose() {
    _webCtrl.dispose();
    _whatsappCtrl.dispose();
    super.dispose();
  }

  String get _target => switch (_type) {
        PromoRedirectType.internalPage => _selectedRoute,
        PromoRedirectType.webLink => _webCtrl.text.trim(),
        PromoRedirectType.whatsapp => _whatsappCtrl.text.trim(),
      };

  bool get _canSave {
    if (_saving || _uploadingImage) return false;
    if (_uploadedImageUrl == null) return false;
    return _target.isNotEmpty;
  }

  Future<void> _pickAndUploadImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );
    if (result == null || result.files.isEmpty || !mounted) return;
    final picked = result.files.first;
    if (picked.path == null) return;
    final file = File(picked.path!);
    setState(() {
      _pickedFile = file;
      _uploadingImage = true;
      _uploadedImageUrl = null;
    });
    try {
      final client = ref.read(supabaseClientProvider);
      final ext = (picked.extension ?? 'jpg').toLowerCase();
      final mime = switch (ext) {
        'png' => 'image/png',
        'webp' => 'image/webp',
        'gif' => 'image/gif',
        _ => 'image/jpeg',
      };
      final path =
          'promo_banner/${DateTime.now().millisecondsSinceEpoch}.$ext';
      await client.storage.from('notification_images').upload(
            path,
            file,
            fileOptions: FileOptions(contentType: mime, upsert: false),
          );
      final url =
          client.storage.from('notification_images').getPublicUrl(path);
      if (!mounted) return;
      setState(() {
        _uploadingImage = false;
        _uploadedImageUrl = url;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _uploadingImage = false;
        _pickedFile = null;
      });
      if (mounted) {
        await _showResult(
          context,
          'Upload image échoué : ${arenaErrorMessage(e)}',
          isError: true,
        );
      }
    }
  }

  Future<void> _publish() async {
    if (!_canSave) return;
    final adminId = ref.read(currentSessionProvider)?.user.id;
    if (adminId == null) return;
    final totpOk = await showDesktopTotpGate(
      context,
      ref,
      reason: 'Publier une bannière publicitaire sur la home',
    );
    if (!totpOk || !mounted) return;

    setState(() => _saving = true);
    try {
      await ref.read(promoBannerRepositoryProvider).saveActive(
            imageUrl: _uploadedImageUrl!,
            redirectType: _type,
            redirectTarget: _target,
            updatedBy: adminId,
          );
      await ref.read(adminAuditLogRepositoryProvider).record(
        adminId: adminId,
        action: 'promo_banner_published',
        targetType: 'promo_banner',
        targetId: null,
        afterState: {
          'redirect_type': _type.wire,
          'redirect_target': _target,
        },
      );
      ref.invalidate(currentPromoBannerProvider);
      if (!mounted) return;
      setState(() {
        _saving = false;
        _pickedFile = null;
        _uploadedImageUrl = null;
        _webCtrl.clear();
        _whatsappCtrl.clear();
      });
      await _showResult(context, 'Bannière publiée sur la home.', isError: false);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      await _showResult(context, arenaErrorMessage(e), isError: true);
    }
  }

  Future<void> _removeCurrent() async {
    final adminId = ref.read(currentSessionProvider)?.user.id;
    if (adminId == null) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => ContentDialog(
        title: const Text('Retirer la bannière ?'),
        content: const Text(
          'La bannière sera retirée de la home utilisateur. '
          'Elle restera dans la base pour consultation.',
        ),
        actions: [
          Button(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Retirer'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;

    final totpOk = await showDesktopTotpGate(
      context,
      ref,
      reason: 'Retirer la bannière publicitaire de la home',
    );
    if (!totpOk || !mounted) return;

    setState(() => _saving = true);
    try {
      await ref.read(promoBannerRepositoryProvider).deactivate();
      await ref.read(adminAuditLogRepositoryProvider).record(
            adminId: adminId,
            action: 'promo_banner_removed',
            targetType: 'promo_banner',
            targetId: null,
            afterState: {},
          );
      ref.invalidate(currentPromoBannerProvider);
      if (!mounted) return;
      setState(() => _saving = false);
      await _showResult(context, 'Bannière retirée de la home.', isError: false);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      await _showResult(context, arenaErrorMessage(e), isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentAsync = ref.watch(currentPromoBannerProvider);

    return ScaffoldPage(
      header: const PageHeader(title: Text('ESPACE PUBLICITAIRE')),
      content: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ─── Bannière actuelle ───────────────────────────────────
              const _SectionHeader(label: 'BANNIÈRE ACTUELLE'),
              const SizedBox(height: 12),
              currentAsync.when(
                loading: () => const Center(child: ProgressRing()),
                error: (e, _) => InfoBar(
                  title: const Text('Erreur'),
                  content: Text('$e'),
                  severity: InfoBarSeverity.error,
                ),
                data: (banner) => _CurrentBannerCard(
                  banner: banner,
                  saving: _saving,
                  onRemove: _saving ? null : _removeCurrent,
                ),
              ),
              const SizedBox(height: 32),

              // ─── Nouvelle bannière ───────────────────────────────────
              const _SectionHeader(label: 'NOUVELLE BANNIÈRE'),
              const SizedBox(height: 16),

              // Image
              InfoLabel(
                label: 'Image (PNG / JPG / WebP — format 16:9 conseillé)',
                child: _ImagePickerCard(
                  pickedFile: _pickedFile,
                  uploadedUrl: _uploadedImageUrl,
                  uploading: _uploadingImage,
                  onPick: _uploadingImage ? null : _pickAndUploadImage,
                  onClear: _uploadingImage
                      ? null
                      : () => setState(() {
                            _pickedFile = null;
                            _uploadedImageUrl = null;
                          }),
                ),
              ),
              const SizedBox(height: 16),

              // Type de redirection
              InfoLabel(
                label: 'Redirection au clic',
                child: ComboBox<PromoRedirectType>(
                  value: _type,
                  isExpanded: true,
                  items: const [
                    ComboBoxItem(
                      value: PromoRedirectType.internalPage,
                      child: Text("Page interne de l'app"),
                    ),
                    ComboBoxItem(
                      value: PromoRedirectType.webLink,
                      child: Text('Lien web externe'),
                    ),
                    ComboBoxItem(
                      value: PromoRedirectType.whatsapp,
                      child: Text('WhatsApp'),
                    ),
                  ],
                  onChanged: _saving
                      ? null
                      : (v) => v == null ? null : setState(() => _type = v),
                ),
              ),
              const SizedBox(height: 12),
              _targetField(),
              const SizedBox(height: 24),

              FilledButton(
                onPressed: _canSave ? _publish : null,
                child: _saving
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: ProgressRing(strokeWidth: 2.5),
                      )
                    : const Text('Publier la bannière'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _targetField() {
    switch (_type) {
      case PromoRedirectType.internalPage:
        return InfoLabel(
          label: 'Page cible',
          child: ComboBox<String>(
            value: _selectedRoute,
            isExpanded: true,
            items: [
              for (final p in _internalPages)
                ComboBoxItem(value: p.route, child: Text(p.label)),
            ],
            onChanged: _saving
                ? null
                : (v) => v == null ? null : setState(() => _selectedRoute = v),
          ),
        );
      case PromoRedirectType.webLink:
        return InfoLabel(
          label: 'URL web',
          child: TextBox(
            controller: _webCtrl,
            placeholder: 'https://exemple.com/promo',
            enabled: !_saving,
            onChanged: (_) => setState(() {}),
          ),
        );
      case PromoRedirectType.whatsapp:
        return InfoLabel(
          label: 'Numéro WhatsApp',
          child: TextBox(
            controller: _whatsappCtrl,
            placeholder: 'Ex. +237 6XX XX XX XX',
            enabled: !_saving,
            onChanged: (_) => setState(() {}),
          ),
        );
    }
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: GoogleFonts.bebasNeue(
        color: ArenaColors.bone,
        fontSize: 18,
        letterSpacing: 1.2,
      ),
    );
  }
}

class _CurrentBannerCard extends StatelessWidget {
  const _CurrentBannerCard({
    required this.banner,
    required this.saving,
    required this.onRemove,
  });

  final PromoBanner? banner;
  final bool saving;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    if (banner == null || !banner!.isActive) {
      return Card(
        backgroundColor: ArenaColors.carbon,
        padding: const EdgeInsets.all(16),
        child: Text(
          'Aucune bannière active — la section pub est masquée sur la home.',
          style: GoogleFonts.spaceGrotesk(
            color: ArenaColors.silver,
            fontSize: 13,
          ),
        ),
      );
    }
    final b = banner!;
    final typeLabel = switch (b.redirectType) {
      PromoRedirectType.internalPage => 'Page interne',
      PromoRedirectType.webLink => 'Lien web',
      PromoRedirectType.whatsapp => 'WhatsApp',
    };
    return Card(
      backgroundColor: ArenaColors.carbon,
      borderColor: ArenaColors.statusOk.withValues(alpha: 0.4),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(ArenaRadius.sm),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: CachedNetworkImage(
                imageUrl: b.imageUrl,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => Container(
                  color: ArenaColors.carbon2,
                  alignment: Alignment.center,
                  child: const Icon(
                    FluentIcons.photo_error,
                    color: ArenaColors.silver,
                    size: 32,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Active  ·  $typeLabel',
            style: GoogleFonts.spaceGrotesk(
              color: ArenaColors.statusOk,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            b.redirectTarget,
            style: GoogleFonts.spaceGrotesk(
              color: ArenaColors.silver,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 12),
          Button(
            onPressed: onRemove,
            child: saving
                ? const SizedBox(
                    height: 14,
                    width: 14,
                    child: ProgressRing(strokeWidth: 2),
                  )
                : const Text('Retirer de la home'),
          ),
        ],
      ),
    );
  }
}

class _ImagePickerCard extends StatelessWidget {
  const _ImagePickerCard({
    required this.pickedFile,
    required this.uploadedUrl,
    required this.uploading,
    required this.onPick,
    required this.onClear,
  });

  final File? pickedFile;
  final String? uploadedUrl;
  final bool uploading;
  final VoidCallback? onPick;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    if (pickedFile == null) {
      return GestureDetector(
        onTap: onPick,
        child: Container(
          height: 80,
          decoration: BoxDecoration(
            color: ArenaColors.carbon,
            border: Border.all(color: ArenaColors.silverDim),
            borderRadius: BorderRadius.circular(ArenaRadius.sm),
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                FluentIcons.photo2_add,
                color: ArenaColors.silver,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Sélectionner une image…',
                style: GoogleFonts.spaceGrotesk(
                  color: ArenaColors.silver,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      );
    }
    return Card(
      backgroundColor: ArenaColors.carbon,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(ArenaRadius.sm),
            child: Image.file(pickedFile!, height: 120, fit: BoxFit.cover),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                uploading
                    ? FluentIcons.upload
                    : (uploadedUrl != null
                        ? FluentIcons.check_mark
                        : FluentIcons.error),
                color: uploading
                    ? ArenaColors.silver
                    : (uploadedUrl != null
                        ? ArenaColors.statusOk
                        : ArenaColors.neonRed),
                size: 16,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  uploading
                      ? 'Upload en cours…'
                      : (uploadedUrl != null
                          ? 'Image prête'
                          : "Échec d'upload"),
                  style: GoogleFonts.spaceGrotesk(
                    color: ArenaColors.silver,
                    fontSize: 12,
                  ),
                ),
              ),
              Button(
                onPressed: uploading ? null : onClear,
                child: const Text('Retirer'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

Future<void> _showResult(
  BuildContext context,
  String message, {
  required bool isError,
}) async {
  await displayInfoBar(
    context,
    builder: (ctx, close) => InfoBar(
      title: Text(isError ? 'Échec' : 'Succès'),
      content: Text(message),
      severity: isError ? InfoBarSeverity.error : InfoBarSeverity.success,
      onClose: close,
    ),
  );
}
