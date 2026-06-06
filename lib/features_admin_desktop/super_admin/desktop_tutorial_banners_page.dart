import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/core/utils/arena_error_message.dart';
import 'package:arena/data/models/tutorial_video.dart';
import 'package:arena/data/repositories/admin/admin_audit_log_repository.dart';
import 'package:arena/data/repositories/tutorial_video_repository.dart';
import 'package:arena/features_admin_desktop/shared/desktop_totp_gate.dart';
import 'package:arena/features_shared/auth_common/shared_auth_providers.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

/// Super-admin · Bannières tutoriel (desktop) — gestion CRUD des bannières
/// de prise en main, équivalent Fluent UI de l'écran mobile
/// `SuperAdminTutorialVideo`.
///
/// Plusieurs bannières peuvent être actives, chacune ciblant une page
/// (Accueil / Compétitions / Profil / Messagerie) ou toutes (Toutes les
/// pages). La fenêtre d'affichage par nouvel utilisateur (jours) est gérée
/// par bannière. Toutes les mutations exigent un step-up TOTP
/// ([showDesktopTotpGate]) + un audit log.
///
/// Réutilise [allTutorialBannersProvider], [tutorialVideoRepositoryProvider]
/// et [adminAuditLogRepositoryProvider] (mêmes providers que le mobile).
class DesktopTutorialBannersPage extends ConsumerWidget {
  const DesktopTutorialBannersPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bannersAsync = ref.watch(allTutorialBannersProvider);

    return ScaffoldPage(
      header: PageHeader(
        title: const Text('BANNIÈRES TUTO'),
        commandBar: CommandBar(
          mainAxisAlignment: MainAxisAlignment.end,
          primaryItems: [
            CommandBarButton(
              icon: const Icon(FluentIcons.add),
              label: const Text('Ajouter une bannière'),
              onPressed: () => _openForm(context, ref, existing: null),
            ),
          ],
        ),
      ),
      content: bannersAsync.when(
        loading: () => const Center(child: ProgressRing()),
        error: (e, _) => Padding(
          padding: const EdgeInsets.all(24),
          child: InfoBar(
            title: const Text('Erreur de chargement'),
            content: Text('$e'),
            severity: InfoBarSeverity.error,
          ),
        ),
        data: (list) {
          if (list.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    FluentIcons.video,
                    size: 40,
                    color: ArenaColors.silver,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Aucune bannière. Cliquez sur « Ajouter une bannière » '
                    'pour en créer une.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.spaceGrotesk(
                      color: ArenaColors.silver,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
            itemCount: list.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, i) => _BannerCard(banner: list[i]),
          );
        },
      ),
    );
  }
}

Future<void> _openForm(
  BuildContext context,
  WidgetRef ref, {
  required TutorialVideo? existing,
}) async {
  await showDialog<void>(
    context: context,
    builder: (_) => _BannerFormDialog(existing: existing),
  );
}

/// Carte récapitulative d'une bannière dans la liste admin desktop.
class _BannerCard extends ConsumerWidget {
  const _BannerCard({required this.banner});

  final TutorialVideo banner;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final active = banner.isActive;
    final accent = active ? ArenaColors.statusOk : ArenaColors.silverDim;
    final days = banner.displayDays;

    return Card(
      backgroundColor: ArenaColors.carbon,
      borderColor: accent.withValues(alpha: 0.4),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  banner.title,
                  style: GoogleFonts.spaceGrotesk(
                    color: ArenaColors.bone,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: accent.withValues(alpha: 0.4)),
                ),
                child: Text(
                  active ? 'ACTIVE' : 'INACTIVE',
                  style: GoogleFonts.spaceGrotesk(
                    color: accent,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            banner.videoUrl,
            style: GoogleFonts.spaceGrotesk(
              color: ArenaColors.silver,
              fontSize: 12,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Text(
            '${banner.targetPage.labelFr}  ·  $days '
            'jour${days > 1 ? 's' : ''}',
            style: GoogleFonts.spaceGrotesk(
              color: ArenaColors.silverDim,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Button(
                onPressed: () => _openForm(context, ref, existing: banner),
                child: const Text('Modifier'),
              ),
              const SizedBox(width: 8),
              Button(
                onPressed: () => _toggleActive(context, ref, banner),
                child: Text(active ? 'Désactiver' : 'Activer'),
              ),
              const SizedBox(width: 8),
              Button(
                onPressed: () => _delete(context, ref, banner),
                child: const Text('Supprimer'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _toggleActive(
    BuildContext context,
    WidgetRef ref,
    TutorialVideo banner,
  ) async {
    final adminId = ref.read(currentSessionProvider)?.user.id;
    if (adminId == null) return;
    final next = !banner.isActive;
    final totpOk = await showDesktopTotpGate(
      context,
      ref,
      reason: next
          ? 'Activer la bannière tutoriel « ${banner.title} »'
          : 'Désactiver la bannière tutoriel « ${banner.title} »',
    );
    if (!totpOk || !context.mounted) return;
    try {
      await ref
          .read(tutorialVideoRepositoryProvider)
          .setActive(banner.id, next);
      await ref.read(adminAuditLogRepositoryProvider).record(
        adminId: adminId,
        action:
            next ? 'tutorial_video_activated' : 'tutorial_video_deactivated',
        targetType: 'tutorial_video',
        targetId: banner.id,
        beforeState: {'is_active': banner.isActive},
        afterState: {'is_active': next},
      );
      if (!context.mounted) return;
      await _showResult(
        context,
        next ? 'Bannière activée.' : 'Bannière désactivée.',
        isError: false,
      );
    } catch (e) {
      if (!context.mounted) return;
      await _showResult(context, arenaErrorMessage(e), isError: true);
    }
  }

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    TutorialVideo banner,
  ) async {
    final adminId = ref.read(currentSessionProvider)?.user.id;
    if (adminId == null) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => ContentDialog(
        title: const Text('Supprimer la bannière ?'),
        content: Text(
          'La bannière « ${banner.title} » sera supprimée définitivement. '
          'Cette action est irréversible.',
        ),
        actions: [
          Button(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (confirm != true || !context.mounted) return;

    final totpOk = await showDesktopTotpGate(
      context,
      ref,
      reason: 'Supprimer la bannière tutoriel « ${banner.title} »',
    );
    if (!totpOk || !context.mounted) return;
    try {
      await ref.read(tutorialVideoRepositoryProvider).deleteBanner(banner.id);
      await ref.read(adminAuditLogRepositoryProvider).record(
        adminId: adminId,
        action: 'tutorial_video_deleted',
        targetType: 'tutorial_video',
        targetId: banner.id,
        beforeState: {
          'title': banner.title,
          'video_url': banner.videoUrl,
          'target_page': banner.targetPage.wire,
          'display_days': banner.displayDays,
          'is_active': banner.isActive,
        },
      );
      if (!context.mounted) return;
      await _showResult(context, 'Bannière supprimée.', isError: false);
    } catch (e) {
      if (!context.mounted) return;
      await _showResult(context, arenaErrorMessage(e), isError: true);
    }
  }
}

/// Formulaire en [ContentDialog] pour créer / modifier une bannière.
class _BannerFormDialog extends ConsumerStatefulWidget {
  const _BannerFormDialog({required this.existing});

  final TutorialVideo? existing;

  @override
  ConsumerState<_BannerFormDialog> createState() => _BannerFormDialogState();
}

class _BannerFormDialogState extends ConsumerState<_BannerFormDialog> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _urlCtrl;
  late final TextEditingController _daysCtrl;
  late TutorialPage _page;
  bool _saving = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _titleCtrl = TextEditingController(text: e?.title ?? '');
    _urlCtrl = TextEditingController(text: e?.videoUrl ?? '');
    _daysCtrl = TextEditingController(text: (e?.displayDays ?? 7).toString());
    _page = e?.targetPage ?? TutorialPage.home;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _urlCtrl.dispose();
    _daysCtrl.dispose();
    super.dispose();
  }

  String get _title => _titleCtrl.text.trim();
  String get _url => _urlCtrl.text.trim();

  int? get _displayDays {
    final n = int.tryParse(_daysCtrl.text.trim());
    if (n == null || n < 1 || n > 365) return null;
    return n;
  }

  bool get _urlValid {
    final uri = Uri.tryParse(_url);
    return uri != null &&
        uri.hasScheme &&
        (uri.scheme == 'http' || uri.scheme == 'https') &&
        uri.host.isNotEmpty;
  }

  bool get _canSave =>
      !_saving &&
      _title.isNotEmpty &&
      _url.isNotEmpty &&
      _urlValid &&
      _displayDays != null;

  Future<void> _save() async {
    if (!_canSave) return;
    final adminId = ref.read(currentSessionProvider)?.user.id;
    if (adminId == null) return;
    final totpOk = await showDesktopTotpGate(
      context,
      ref,
      reason: _isEdit
          ? 'Modifier la bannière tutoriel « $_title »'
          : 'Créer une bannière tutoriel « $_title »',
    );
    if (!totpOk || !mounted) return;

    setState(() => _saving = true);
    final days = _displayDays!;
    final repo = ref.read(tutorialVideoRepositoryProvider);
    final audit = ref.read(adminAuditLogRepositoryProvider);
    try {
      if (_isEdit) {
        final before = widget.existing!;
        await repo.updateBanner(
          id: before.id,
          title: _title,
          videoUrl: _url,
          targetPage: _page,
          displayDays: days,
          isActive: before.isActive,
          updatedBy: adminId,
        );
        await audit.record(
          adminId: adminId,
          action: 'tutorial_video_updated',
          targetType: 'tutorial_video',
          targetId: before.id,
          beforeState: {
            'title': before.title,
            'video_url': before.videoUrl,
            'target_page': before.targetPage.wire,
            'display_days': before.displayDays,
          },
          afterState: {
            'title': _title,
            'video_url': _url,
            'target_page': _page.wire,
            'display_days': days,
          },
        );
      } else {
        await repo.createBanner(
          title: _title,
          videoUrl: _url,
          targetPage: _page,
          displayDays: days,
          updatedBy: adminId,
        );
        await audit.record(
          adminId: adminId,
          action: 'tutorial_video_created',
          targetType: 'tutorial_video',
          afterState: {
            'title': _title,
            'video_url': _url,
            'target_page': _page.wire,
            'display_days': days,
          },
        );
      }
      if (!mounted) return;
      Navigator.of(context).pop();
      await _showResult(
        context,
        _isEdit ? 'Bannière modifiée.' : 'Bannière créée.',
        isError: false,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      await _showResult(context, arenaErrorMessage(e), isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final showUrlError = _url.isNotEmpty && !_urlValid;
    final showDaysError =
        _daysCtrl.text.trim().isNotEmpty && _displayDays == null;

    return ContentDialog(
      constraints: const BoxConstraints(maxWidth: 520),
      title: Text(
        _isEdit ? 'MODIFIER LA BANNIÈRE' : 'NOUVELLE BANNIÈRE',
        style: GoogleFonts.bebasNeue(
          color: ArenaColors.bone,
          fontSize: 22,
          letterSpacing: 1.2,
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            InfoLabel(
              label: 'Titre',
              child: TextBox(
                controller: _titleCtrl,
                placeholder: 'Ex. Comment créer ta première compétition',
                autofocus: true,
                enabled: !_saving,
                onChanged: (_) => setState(() {}),
              ),
            ),
            const SizedBox(height: 16),
            InfoLabel(
              label: 'Lien vidéo',
              child: TextBox(
                controller: _urlCtrl,
                placeholder: 'https://youtu.be/…',
                enabled: !_saving,
                onChanged: (_) => setState(() {}),
              ),
            ),
            if (showUrlError) ...[
              const SizedBox(height: 8),
              const InfoBar(
                title: Text('Lien invalide'),
                content: Text('Utilisez une URL http(s) complète.'),
                severity: InfoBarSeverity.warning,
              ),
            ],
            const SizedBox(height: 16),
            InfoLabel(
              label: 'Page cible',
              child: ComboBox<TutorialPage>(
                value: _page,
                isExpanded: true,
                items: [
                  for (final p in TutorialPage.values)
                    ComboBoxItem(value: p, child: Text(p.labelFr)),
                ],
                onChanged: _saving
                    ? null
                    : (p) => p == null ? null : setState(() => _page = p),
              ),
            ),
            const SizedBox(height: 16),
            InfoLabel(
              label: "Durée d'affichage pour les nouveaux (jours)",
              child: TextBox(
                controller: _daysCtrl,
                placeholder: '7',
                enabled: !_saving,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(3),
                ],
                onChanged: (_) => setState(() {}),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "La bannière s'affiche à chaque nouvel utilisateur pendant ce "
              'nombre de jours après sa 1re impression (1 à 365), puis '
              'disparaît.',
              style: GoogleFonts.spaceGrotesk(
                color: ArenaColors.silverDim,
                fontSize: 11,
              ),
            ),
            if (showDaysError) ...[
              const SizedBox(height: 8),
              const InfoBar(
                title: Text('Durée invalide'),
                content: Text('Entrez un nombre entre 1 et 365.'),
                severity: InfoBarSeverity.warning,
              ),
            ],
          ],
        ),
      ),
      actions: [
        Button(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        FilledButton(
          onPressed: _canSave ? _save : null,
          child: _saving
              ? const SizedBox(
                  height: 16,
                  width: 16,
                  child: ProgressRing(strokeWidth: 2.5),
                )
              : Text(_isEdit ? 'Enregistrer' : 'Créer la bannière'),
        ),
      ],
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
