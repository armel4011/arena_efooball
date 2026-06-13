import 'dart:io';

import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/data/models/promo_banner.dart';
import 'package:arena/data/repositories/admin/admin_audit_log_repository.dart';
import 'package:arena/data/repositories/profile_repository.dart';
import 'package:arena/data/repositories/promo_banner_repository.dart';
import 'package:arena/features_admin/auth_admin/widgets/totp_gate.dart';
import 'package:arena/features_shared/auth_common/shared_auth_providers.dart';
import 'package:arena/features_shared/widgets/arena_app_bar.dart';
import 'package:arena/features_shared/widgets/arena_button.dart';
import 'package:arena/features_shared/widgets/arena_screen_background.dart';
import 'package:arena/features_shared/widgets/arena_text_field.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show FileOptions;

/// Destination interne sélectionnable pour une redirection `internal_page`.
/// Liste fermée → pas de route invalide possible côté super-admin.
typedef _InternalPage = ({String label, String route});

/// SA · Espace publicitaire — gestion de la bannière promo de la home user.
///
/// Le super-admin uploade une image (bucket public `notification_images`,
/// prefix `promo_banner/`), choisit une redirection (page interne / lien
/// web / WhatsApp) et publie. Une seule bannière active à la fois : publier
/// remplace la précédente. Un bouton permet de retirer la bannière de la
/// home sans en publier une nouvelle.
class SuperAdminPromoBanner extends ConsumerStatefulWidget {
  const SuperAdminPromoBanner({super.key});

  @override
  ConsumerState<SuperAdminPromoBanner> createState() =>
      _SuperAdminPromoBannerState();
}

class _SuperAdminPromoBannerState
    extends ConsumerState<SuperAdminPromoBanner> {
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

  File? _pickedImage;
  String? _uploadedImageUrl;
  bool _uploadingImage = false;
  bool _saving = false;
  String? _lastResult;

  @override
  void dispose() {
    _webCtrl.dispose();
    _whatsappCtrl.dispose();
    super.dispose();
  }

  /// La cible textuelle à stocker selon le type sélectionné.
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
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1920,
      maxHeight: 1080,
      imageQuality: 85,
    );
    if (picked == null || !mounted) return;
    final file = File(picked.path);
    setState(() {
      _pickedImage = file;
      _uploadingImage = true;
      _uploadedImageUrl = null;
    });
    try {
      final client = ref.read(supabaseClientProvider);
      final ext = picked.path.split('.').last.toLowerCase();
      final mime = switch (ext) {
        'png' => 'image/png',
        'webp' => 'image/webp',
        'gif' => 'image/gif',
        _ => 'image/jpeg',
      };
      final path = 'promo_banner/${DateTime.now().millisecondsSinceEpoch}.$ext';
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
        _pickedImage = null;
        _lastResult = '✗ Upload image échoué : $e';
      });
    }
  }

  Future<void> _publish() async {
    if (!_canSave) return;
    final adminId = ref.read(currentSessionProvider)?.user.id;
    if (adminId == null) return;
    final totpOk = await TotpGate.confirm(
      context,
      ref,
      reason: 'Publier une bannière publicitaire sur la home',
    );
    if (!totpOk || !mounted) return;

    setState(() {
      _saving = true;
      _lastResult = null;
    });
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
        _lastResult = '✓ Bannière publiée sur la home.';
        _pickedImage = null;
        _uploadedImageUrl = null;
        _webCtrl.clear();
        _whatsappCtrl.clear();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _lastResult = '✗ Erreur : $e';
      });
    }
  }

  Future<void> _removeCurrent() async {
    final adminId = ref.read(currentSessionProvider)?.user.id;
    if (adminId == null) return;
    final totpOk = await TotpGate.confirm(
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
      setState(() {
        _saving = false;
        _lastResult = '✓ Bannière retirée de la home.';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _lastResult = '✗ Erreur : $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final current = ref.watch(currentPromoBannerProvider);

    return Scaffold(
      appBar: const ArenaAppBar(title: '🖼 ESPACE PUBLICITAIRE'),
      body: ArenaScreenBackground(
        accent: ArenaColors.neonRed,
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(ArenaSpacing.lg),
            children: [
              Text('BANNIÈRE ACTUELLE', style: ArenaText.inputLabel),
              const SizedBox(height: ArenaSpacing.sm),
              current.when(
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(ArenaSpacing.md),
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (e, _) => Text(
                  'Erreur : $e',
                  style: ArenaText.bodyMuted
                      .copyWith(color: ArenaColors.neonRed),
                ),
                data: (banner) => _CurrentBannerCard(
                  banner: banner,
                  onRemove: _saving ? null : _removeCurrent,
                ),
              ),
              const SizedBox(height: ArenaSpacing.lg),
              Text('NOUVELLE BANNIÈRE', style: ArenaText.h3),
              const SizedBox(height: ArenaSpacing.sm),

              // ─── Image ────────────────────────────────────────────────
              Text('🖼 IMAGE', style: ArenaText.inputLabel),
              const SizedBox(height: ArenaSpacing.sm),
              _ImagePickerCard(
                pickedImage: _pickedImage,
                uploadedUrl: _uploadedImageUrl,
                uploading: _uploadingImage,
                onPick: _pickAndUploadImage,
                onClear: () => setState(() {
                  _pickedImage = null;
                  _uploadedImageUrl = null;
                }),
              ),
              const SizedBox(height: ArenaSpacing.lg),

              // ─── Redirection ──────────────────────────────────────────
              Text('🔗 REDIRECTION AU CLIC', style: ArenaText.inputLabel),
              const SizedBox(height: ArenaSpacing.sm),
              _TypeDropdown(
                value: _type,
                onChanged: (t) => setState(() => _type = t),
              ),
              const SizedBox(height: ArenaSpacing.sm),
              _targetField(),
              const SizedBox(height: ArenaSpacing.lg),

              ArenaButton(
                label: _saving ? 'PUBLICATION…' : '🚀 PUBLIER LA BANNIÈRE',
                fullWidth: true,
                size: ArenaButtonSize.large,
                isLoading: _saving,
                onPressed: _canSave ? _publish : null,
              ),
              if (_lastResult != null) ...[
                const SizedBox(height: ArenaSpacing.sm),
                Text(
                  _lastResult!,
                  textAlign: TextAlign.center,
                  style: ArenaText.body.copyWith(
                    color: _lastResult!.startsWith('✓')
                        ? ArenaColors.statusOk
                        : ArenaColors.neonRed,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _targetField() {
    switch (_type) {
      case PromoRedirectType.internalPage:
        return _RouteDropdown(
          pages: _internalPages,
          value: _selectedRoute,
          onChanged: (r) => setState(() => _selectedRoute = r),
        );
      case PromoRedirectType.webLink:
        return ArenaTextField(
          controller: _webCtrl,
          hint: 'https://exemple.com/promo',
          helper: 'Lien web ouvert dans le navigateur externe.',
          onChanged: (_) => setState(() {}),
        );
      case PromoRedirectType.whatsapp:
        return ArenaTextField(
          controller: _whatsappCtrl,
          hint: 'Ex. +237 6XX XX XX XX',
          helper: 'Numéro WhatsApp — ouvre une discussion (wa.me).',
          onChanged: (_) => setState(() {}),
        );
    }
  }
}

class _CurrentBannerCard extends StatelessWidget {
  const _CurrentBannerCard({required this.banner, required this.onRemove});

  final PromoBanner? banner;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    if (banner == null || !banner!.isActive) {
      return Container(
        padding: const EdgeInsets.all(ArenaSpacing.md),
        decoration: BoxDecoration(
          color: ArenaColors.carbon,
          borderRadius: BorderRadius.circular(ArenaRadius.md),
          border: Border.all(color: ArenaColors.border),
        ),
        child: Text(
          'Aucune bannière active — la section pub est masquée sur la home.',
          style: ArenaText.bodyMuted,
        ),
      );
    }
    final b = banner!;
    final typeLabel = switch (b.redirectType) {
      PromoRedirectType.internalPage => 'Page interne',
      PromoRedirectType.webLink => 'Lien web',
      PromoRedirectType.whatsapp => 'WhatsApp',
    };
    return Container(
      padding: const EdgeInsets.all(ArenaSpacing.sm),
      decoration: BoxDecoration(
        color: ArenaColors.carbon,
        borderRadius: BorderRadius.circular(ArenaRadius.md),
        border: Border.all(color: ArenaColors.statusOk),
      ),
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
                    Icons.broken_image_outlined,
                    color: ArenaColors.silver,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: ArenaSpacing.sm),
          Text('🟢 Active · $typeLabel', style: ArenaText.body),
          const SizedBox(height: 2),
          Text(b.redirectTarget, style: ArenaText.bodyMuted),
          const SizedBox(height: ArenaSpacing.sm),
          ArenaButton(
            label: 'RETIRER DE LA HOME',
            variant: ArenaButtonVariant.danger,
            fullWidth: true,
            onPressed: onRemove,
          ),
        ],
      ),
    );
  }
}

class _TypeDropdown extends StatelessWidget {
  const _TypeDropdown({required this.value, required this.onChanged});

  final PromoRedirectType value;
  final ValueChanged<PromoRedirectType> onChanged;

  @override
  Widget build(BuildContext context) {
    return _DropdownFrame(
      child: DropdownButton<PromoRedirectType>(
        value: value,
        isExpanded: true,
        underline: const SizedBox.shrink(),
        dropdownColor: ArenaColors.carbon,
        style: ArenaText.body,
        items: const [
          DropdownMenuItem(
            value: PromoRedirectType.internalPage,
            child: Text('Page interne de l’app'),
          ),
          DropdownMenuItem(
            value: PromoRedirectType.webLink,
            child: Text('Lien web externe'),
          ),
          DropdownMenuItem(
            value: PromoRedirectType.whatsapp,
            child: Text('WhatsApp'),
          ),
        ],
        onChanged: (v) => v == null ? null : onChanged(v),
      ),
    );
  }
}

class _RouteDropdown extends StatelessWidget {
  const _RouteDropdown({
    required this.pages,
    required this.value,
    required this.onChanged,
  });

  final List<_InternalPage> pages;
  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return _DropdownFrame(
      child: DropdownButton<String>(
        value: value,
        isExpanded: true,
        underline: const SizedBox.shrink(),
        dropdownColor: ArenaColors.carbon,
        style: ArenaText.body,
        items: [
          for (final p in pages)
            DropdownMenuItem(value: p.route, child: Text(p.label)),
        ],
        onChanged: (v) => v == null ? null : onChanged(v),
      ),
    );
  }
}

class _DropdownFrame extends StatelessWidget {
  const _DropdownFrame({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: ArenaSpacing.md),
      decoration: BoxDecoration(
        color: ArenaColors.carbon,
        borderRadius: BorderRadius.circular(ArenaRadius.md),
        border: Border.all(color: ArenaColors.border),
      ),
      child: child,
    );
  }
}

/// Carte de sélection/upload d'image — variante locale du widget homonyme
/// de `super_admin_broadcast.dart`.
class _ImagePickerCard extends StatelessWidget {
  const _ImagePickerCard({
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
      return InkWell(
        onTap: onPick,
        borderRadius: BorderRadius.circular(ArenaRadius.md),
        child: Container(
          padding: const EdgeInsets.all(ArenaSpacing.lg),
          decoration: BoxDecoration(
            color: ArenaColors.carbon,
            border: Border.all(color: ArenaColors.silverDim, width: 1.5),
            borderRadius: BorderRadius.circular(ArenaRadius.md),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.add_photo_alternate_outlined,
                color: ArenaColors.silver,
              ),
              const SizedBox(width: ArenaSpacing.sm),
              Expanded(
                child: Text(
                  'Ajouter une image (PNG / JPG / WebP · 5 MB max · format 16:9 conseillé)',
                  style: ArenaText.bodyMuted,
                ),
              ),
            ],
          ),
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.all(ArenaSpacing.sm),
      decoration: BoxDecoration(
        color: ArenaColors.carbon,
        border: Border.all(color: ArenaColors.border),
        borderRadius: BorderRadius.circular(ArenaRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(ArenaRadius.sm),
            child: Image.file(pickedImage!, height: 140, fit: BoxFit.cover),
          ),
          const SizedBox(height: ArenaSpacing.sm),
          Row(
            children: [
              Icon(
                uploading
                    ? Icons.cloud_upload_outlined
                    : (uploadedUrl != null
                        ? Icons.check_circle
                        : Icons.error_outline),
                color: uploading
                    ? ArenaColors.silver
                    : (uploadedUrl != null
                        ? ArenaColors.statusOk
                        : ArenaColors.neonRed),
                size: 18,
              ),
              const SizedBox(width: ArenaSpacing.xs),
              Expanded(
                child: Text(
                  uploading
                      ? 'Upload en cours…'
                      : (uploadedUrl != null
                          ? 'Image prête'
                          : "Échec d'upload"),
                  style: ArenaText.small,
                ),
              ),
              TextButton(
                onPressed: uploading ? null : onClear,
                child: Text(
                  'Retirer',
                  style: ArenaText.small.copyWith(color: ArenaColors.neonRed),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
