import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/core/utils/supported_countries.dart';
import 'package:arena/core/utils/youtube_url.dart';
import 'package:arena/data/models/competition_enums.dart';
import 'package:arena/data/models/tutorial_video.dart';
import 'package:arena/data/repositories/admin/admin_audit_log_repository.dart';
import 'package:arena/data/repositories/tutorial_video_repository.dart';
import 'package:arena/features_admin/auth_admin/widgets/totp_gate.dart';
import 'package:arena/features_shared/auth_common/shared_auth_providers.dart';
import 'package:arena/features_shared/widgets/arena_app_bar.dart';
import 'package:arena/features_shared/widgets/arena_button.dart';
import 'package:arena/features_shared/widgets/arena_screen_background.dart';
import 'package:arena/features_shared/widgets/arena_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// SA · Vidéos tutoriel — gestion CRUD des bannières de prise en main.
///
/// Plusieurs bannières peuvent être actives, chacune ciblant une page
/// (Accueil / Compétitions) ou toutes (Toutes les pages). Le super-admin
/// peut ajouter, modifier, activer/désactiver et supprimer chaque bannière.
/// La fenêtre d'affichage par nouvel utilisateur (jours) est gérée par
/// bannière. Toutes les mutations exigent un step-up TOTP + un audit log.
/// Côté user, la bannière ouvre le lien vidéo en EXTERNE au tap.
class SuperAdminTutorialVideo extends ConsumerWidget {
  const SuperAdminTutorialVideo({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final banners = ref.watch(allTutorialBannersProvider);

    return Scaffold(
      appBar: const ArenaAppBar(title: '🎬 VIDÉOS TUTORIEL'),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: ArenaColors.signalBlue,
        onPressed: () => _openForm(context, ref, existing: null),
        icon: const Icon(Icons.add),
        label: const Text('Ajouter une bannière'),
      ),
      body: ArenaScreenBackground(
        accent: ArenaColors.neonRed,
        child: SafeArea(
          child: banners.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(ArenaSpacing.lg),
                child: Text(
                  'Erreur : $e',
                  style:
                      ArenaText.bodyMuted.copyWith(color: ArenaColors.neonRed),
                ),
              ),
            ),
            data: (list) {
              if (list.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(ArenaSpacing.lg),
                    child: Text(
                      'Aucune bannière. Touchez « Ajouter une bannière » '
                      'pour en créer une.',
                      textAlign: TextAlign.center,
                      style: ArenaText.bodyMuted,
                    ),
                  ),
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(
                  ArenaSpacing.lg,
                  ArenaSpacing.lg,
                  ArenaSpacing.lg,
                  // Espace pour le FAB.
                  ArenaSpacing.xl * 2,
                ),
                itemCount: list.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: ArenaSpacing.md),
                itemBuilder: (_, i) => _BannerCard(
                  banner: list[i],
                  onEdit: () => _openForm(context, ref, existing: list[i]),
                  onToggle: () => _toggleActive(context, ref, list[i]),
                  onDelete: () => _delete(context, ref, list[i]),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _openForm(
    BuildContext context,
    WidgetRef ref, {
    required TutorialVideo? existing,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _BannerFormSheet(existing: existing),
    );
  }

  Future<void> _toggleActive(
    BuildContext context,
    WidgetRef ref,
    TutorialVideo banner,
  ) async {
    final adminId = ref.read(currentSessionProvider)?.user.id;
    if (adminId == null) return;
    final messenger = ScaffoldMessenger.of(context);
    final next = !banner.isActive;
    final totpOk = await TotpGate.confirm(
      context,
      ref,
      reason: next
          ? 'Activer la bannière tutoriel « ${banner.title} »'
          : 'Désactiver la bannière tutoriel « ${banner.title} »',
    );
    if (!totpOk) return;
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
      _snack(
          messenger, next ? '✓ Bannière activée.' : '✓ Bannière désactivée.',);
    } catch (e) {
      _snack(messenger, '✗ Erreur : $e', error: true);
    }
  }

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    TutorialVideo banner,
  ) async {
    final adminId = ref.read(currentSessionProvider)?.user.id;
    if (adminId == null) return;
    final messenger = ScaffoldMessenger.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ArenaColors.carbon,
        title: Text('Supprimer la bannière ?', style: ArenaText.h3),
        content: Text(
          'La bannière « ${banner.title} » sera supprimée définitivement.',
          style: ArenaText.bodyMuted,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Annuler', style: ArenaText.body),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              'Supprimer',
              style: ArenaText.body.copyWith(color: ArenaColors.neonRed),
            ),
          ),
        ],
      ),
    );
    if (confirm != true || !context.mounted) return;

    final totpOk = await TotpGate.confirm(
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
          'game': banner.game,
          'country_code': banner.countryCode,
        },
      );
      _snack(messenger, '✓ Bannière supprimée.');
    } catch (e) {
      _snack(messenger, '✗ Erreur : $e', error: true);
    }
  }

  void _snack(
    ScaffoldMessengerState messenger,
    String msg, {
    bool error = false,
  }) {
    messenger.showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: error ? ArenaColors.neonRed : ArenaColors.statusOk,
      ),
    );
  }
}

/// Ligne de contexte affichée sous une vidéo dans la liste admin : jeu pour la
/// salle/l'intro de rôle, pays pour le tuto paiement, durée pour les bannières.
String _bannerContextLabel(TutorialVideo v) {
  if (v.targetPage.needsGame) {
    // Intro de rôle : préciser le côté (Domicile/Extérieur), 2 vidéos par jeu.
    final side = v.targetPage.needsRoleSide
        ? ' · ${v.roleSide == MatchRoleSide.away.wire ? MatchRoleSide.away.labelFr : MatchRoleSide.home.labelFr}'
        : '';
    return '🎮 ${v.gameType?.label ?? '—'}$side';
  }
  if (v.targetPage.needsCountry) {
    final c =
        kSupportedCountries.where((e) => e.code == v.countryCode).firstOrNull;
    return '🌍 ${c == null ? (v.countryCode ?? '—') : '${c.flag} ${c.name}'}';
  }
  return '⏳ ${v.displayDays} jour${v.displayDays > 1 ? 's' : ''}';
}

/// Carte récapitulative d'une bannière dans la liste admin.
class _BannerCard extends StatelessWidget {
  const _BannerCard({
    required this.banner,
    required this.onEdit,
    required this.onToggle,
    required this.onDelete,
  });

  final TutorialVideo banner;
  final VoidCallback onEdit;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final active = banner.isActive;
    return Container(
      padding: const EdgeInsets.all(ArenaSpacing.md),
      decoration: BoxDecoration(
        color: ArenaColors.carbon,
        borderRadius: BorderRadius.circular(ArenaRadius.md),
        border: Border.all(
          color: active ? ArenaColors.statusOk : ArenaColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  banner.title,
                  style: ArenaText.body.copyWith(fontWeight: FontWeight.w700),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              _StatusBadge(active: active),
            ],
          ),
          const SizedBox(height: ArenaSpacing.xs),
          Text(banner.videoUrl, style: ArenaText.bodyMuted, maxLines: 1),
          const SizedBox(height: ArenaSpacing.xs),
          Text(
            '🎯 ${banner.targetPage.labelFr}  ·  ${_bannerContextLabel(banner)}',
            style: ArenaText.bodyMuted,
          ),
          const SizedBox(height: ArenaSpacing.sm),
          Row(
            children: [
              Expanded(
                child: ArenaButton(
                  label: 'MODIFIER',
                  variant: ArenaButtonVariant.secondary,
                  onPressed: onEdit,
                ),
              ),
              const SizedBox(width: ArenaSpacing.sm),
              Expanded(
                child: ArenaButton(
                  label: active ? 'DÉSACTIVER' : 'ACTIVER',
                  variant: ArenaButtonVariant.secondary,
                  onPressed: onToggle,
                ),
              ),
            ],
          ),
          const SizedBox(height: ArenaSpacing.sm),
          ArenaButton(
            label: 'SUPPRIMER',
            variant: ArenaButtonVariant.danger,
            fullWidth: true,
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.active});
  final bool active;

  @override
  Widget build(BuildContext context) {
    final color = active ? ArenaColors.statusOk : ArenaColors.silver;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(ArenaRadius.sm),
        border: Border.all(color: color),
      ),
      child: Text(
        active ? 'ACTIVE' : 'INACTIVE',
        style: ArenaText.monoSmall.copyWith(color: color, letterSpacing: 1),
      ),
    );
  }
}

/// Formulaire en bottom-sheet pour créer / modifier une bannière.
class _BannerFormSheet extends ConsumerStatefulWidget {
  const _BannerFormSheet({required this.existing});
  final TutorialVideo? existing;

  @override
  ConsumerState<_BannerFormSheet> createState() => _BannerFormSheetState();
}

class _BannerFormSheetState extends ConsumerState<_BannerFormSheet> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _urlCtrl;
  late final TextEditingController _daysCtrl;
  late TutorialPage _page;
  GameType? _game;
  String? _country;
  MatchRoleSide? _roleSide;
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
    _game = e?.gameType;
    _country = e?.countryCode;
    _roleSide = _sideFromWire(e?.roleSide);
  }

  static MatchRoleSide? _sideFromWire(String? wire) {
    if (wire == null) return null;
    for (final s in MatchRoleSide.values) {
      if (s.wire == wire) return s;
    }
    return null;
  }

  /// Change de cible et réinitialise les discriminants devenus hors-sujet, pour
  /// ne jamais soumettre un couple incohérent (le CHECK DB le refuserait).
  void _onPageChanged(TutorialPage p) {
    setState(() {
      _page = p;
      if (!p.needsGame) _game = null;
      if (!p.needsCountry) _country = null;
      if (!p.needsRoleSide) _roleSide = null;
      // L'intro de rôle n'accepte pas les Dames : on force une resélection.
      if (p.needsGame && !gamesForTutorialPage(p).contains(_game)) _game = null;
    });
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

  /// Les cibles IN-APP exigent un lien YouTube exploitable (le lecteur
  /// n'accepte que ça) ; les bannières de page se contentent d'une URL http(s)
  /// puisqu'elles s'ouvrent en externe.
  bool get _urlValid {
    if (_page.isInApp) return isPlayableYoutubeUrl(_url);
    final uri = Uri.tryParse(_url);
    return uri != null &&
        uri.hasScheme &&
        (uri.scheme == 'http' || uri.scheme == 'https') &&
        uri.host.isNotEmpty;
  }

  /// Discriminant(s) requis présent(s) selon la cible (jeu / pays / côté). Note :
  /// l'intro de rôle exige À LA FOIS un jeu ET un côté (Domicile/Extérieur).
  bool get _contextValid {
    if (_page.needsGame && _game == null) return false;
    if (_page.needsCountry && _country == null) return false;
    if (_page.needsRoleSide && _roleSide == null) return false;
    // Bannières de page (ni jeu ni pays) : fenêtre d'affichage valide requise.
    if (!_page.needsGame && !_page.needsCountry) return _displayDays != null;
    return true;
  }

  bool get _canSave =>
      !_saving &&
      _title.isNotEmpty &&
      _url.isNotEmpty &&
      _urlValid &&
      _contextValid;

  Future<void> _save() async {
    if (!_canSave) return;
    final adminId = ref.read(currentSessionProvider)?.user.id;
    if (adminId == null) return;
    final totpOk = await TotpGate.confirm(
      context,
      ref,
      reason: _isEdit
          ? 'Modifier la bannière tutoriel « $_title »'
          : 'Créer une bannière tutoriel « $_title »',
    );
    if (!totpOk || !mounted) return;

    setState(() => _saving = true);
    // Les cibles contextuelles n'utilisent pas la fenêtre d'affichage : on
    // retombe sur 7 (défaut colonne) sans bloquer la saisie.
    final days = _displayDays ?? 7;
    final gameWire = _page.needsGame ? _game?.value : null;
    final country = _page.needsCountry ? _country : null;
    final roleSide = _page.needsRoleSide ? _roleSide?.wire : null;
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
          game: gameWire,
          countryCode: country,
          roleSide: roleSide,
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
            'game': before.game,
            'country_code': before.countryCode,
            'role_side': before.roleSide,
          },
          afterState: {
            'title': _title,
            'video_url': _url,
            'target_page': _page.wire,
            'display_days': days,
            'game': gameWire,
            'country_code': country,
            'role_side': roleSide,
          },
        );
      } else {
        await repo.createBanner(
          title: _title,
          videoUrl: _url,
          targetPage: _page,
          displayDays: days,
          game: gameWire,
          countryCode: country,
          roleSide: roleSide,
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
            'game': gameWire,
            'country_code': country,
            'role_side': roleSide,
          },
        );
      }
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isEdit ? '✓ Bannière modifiée.' : '✓ Bannière créée.'),
          backgroundColor: ArenaColors.statusOk,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✗ Erreur : $e'),
          backgroundColor: ArenaColors.neonRed,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final showUrlError = _url.isNotEmpty && !_urlValid;
    final showDaysError =
        _daysCtrl.text.trim().isNotEmpty && _displayDays == null;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        decoration: const BoxDecoration(
          color: ArenaColors.carbon2,
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(ArenaRadius.lg)),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(ArenaSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  _isEdit ? 'MODIFIER LA BANNIÈRE' : 'NOUVELLE BANNIÈRE',
                  style: ArenaText.h3,
                ),
                const SizedBox(height: ArenaSpacing.lg),

                Text('📝 TITRE', style: ArenaText.inputLabel),
                const SizedBox(height: ArenaSpacing.sm),
                ArenaTextField(
                  controller: _titleCtrl,
                  hint: 'Ex. Comment créer ta première compétition',
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: ArenaSpacing.lg),

                Text('🔗 LIEN VIDÉO', style: ArenaText.inputLabel),
                const SizedBox(height: ArenaSpacing.sm),
                ArenaTextField(
                  controller: _urlCtrl,
                  hint: 'https://youtu.be/…',
                  helper: _page.isInApp
                      ? "Lien YouTube lu DANS l'app (youtu.be / watch?v=…)."
                      : 'Lien http/https ouvert dans le navigateur externe.',
                  errorText: showUrlError
                      ? (_page.isInApp
                          ? 'Lien YouTube invalide — la vidéo ne se lira pas '
                              "dans l'app."
                          : 'Lien invalide — utilisez une URL http(s) complète.')
                      : null,
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: ArenaSpacing.lg),

                Text('🎯 CIBLE', style: ArenaText.inputLabel),
                const SizedBox(height: ArenaSpacing.sm),
                _PageDropdown(
                  value: _page,
                  onChanged: _onPageChanged,
                ),
                const SizedBox(height: ArenaSpacing.lg),

                // Discriminant contextuel : jeu, pays, ou fenêtre d'affichage.
                if (_page.needsGame) ...[
                  Text('🎮 JEU', style: ArenaText.inputLabel),
                  const SizedBox(height: ArenaSpacing.sm),
                  _GameDropdown(
                    page: _page,
                    value: _game,
                    onChanged: (g) => setState(() => _game = g),
                  ),
                  const SizedBox(height: ArenaSpacing.lg),
                ] else if (_page.needsCountry) ...[
                  Text('🌍 PAYS', style: ArenaText.inputLabel),
                  const SizedBox(height: ArenaSpacing.sm),
                  _CountryDropdown(
                    value: _country,
                    onChanged: (c) => setState(() => _country = c),
                  ),
                  const SizedBox(height: ArenaSpacing.lg),
                ] else ...[
                  Text(
                    "⏳ DURÉE D'AFFICHAGE POUR LES NOUVEAUX (JOURS)",
                    style: ArenaText.inputLabel,
                  ),
                  const SizedBox(height: ArenaSpacing.sm),
                  ArenaTextField(
                    controller: _daysCtrl,
                    hint: '7',
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(3),
                    ],
                    helper: "La bannière s'affiche à chaque nouvel utilisateur "
                        'pendant ce nombre de jours après sa 1re impression '
                        '(1 à 365), puis disparaît.',
                    errorText: showDaysError
                        ? 'Entrez un nombre entre 1 et 365.'
                        : null,
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: ArenaSpacing.lg),
                ],

                // Intro de rôle : EN PLUS du jeu, choisir le côté — Domicile et
                // Extérieur ont chacun leur vidéo.
                if (_page.needsRoleSide) ...[
                  Text(
                    '🏠 CÔTÉ (DOMICILE / EXTÉRIEUR)',
                    style: ArenaText.inputLabel,
                  ),
                  const SizedBox(height: ArenaSpacing.sm),
                  _RoleSideDropdown(
                    value: _roleSide,
                    onChanged: (s) => setState(() => _roleSide = s),
                  ),
                  const SizedBox(height: ArenaSpacing.lg),
                ],

                ArenaButton(
                  label: _saving
                      ? 'ENREGISTREMENT…'
                      : (_isEdit ? '💾 ENREGISTRER' : '🚀 CRÉER LA BANNIÈRE'),
                  fullWidth: true,
                  size: ArenaButtonSize.large,
                  isLoading: _saving,
                  onPressed: _canSave ? _save : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PageDropdown extends StatelessWidget {
  const _PageDropdown({required this.value, required this.onChanged});
  final TutorialPage value;
  final ValueChanged<TutorialPage> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: ArenaSpacing.md),
      decoration: BoxDecoration(
        color: ArenaColors.carbon,
        borderRadius: BorderRadius.circular(ArenaRadius.md),
        border: Border.all(color: ArenaColors.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<TutorialPage>(
          value: value,
          isExpanded: true,
          dropdownColor: ArenaColors.carbon,
          style: ArenaText.body,
          items: [
            for (final p in TutorialPage.values)
              DropdownMenuItem(value: p, child: Text(p.labelFr)),
          ],
          onChanged: (p) {
            if (p != null) onChanged(p);
          },
        ),
      ),
    );
  }
}

/// Sélecteur de jeu pour les cibles discriminées par jeu. Le placeholder force
/// une sélection explicite (pas de défaut silencieux).
class _GameDropdown extends StatelessWidget {
  const _GameDropdown({
    required this.page,
    required this.value,
    required this.onChanged,
  });
  final TutorialPage page;
  final GameType? value;
  final ValueChanged<GameType> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: ArenaSpacing.md),
      decoration: BoxDecoration(
        color: ArenaColors.carbon,
        borderRadius: BorderRadius.circular(ArenaRadius.md),
        border: Border.all(color: ArenaColors.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<GameType>(
          value: value,
          isExpanded: true,
          dropdownColor: ArenaColors.carbon,
          style: ArenaText.body,
          hint: Text('Choisir un jeu', style: ArenaText.bodyMuted),
          items: [
            for (final g in gamesForTutorialPage(page))
              DropdownMenuItem(value: g, child: Text(g.label)),
          ],
          onChanged: (g) {
            if (g != null) onChanged(g);
          },
        ),
      ),
    );
  }
}

/// Sélecteur de pays (ISO alpha-2) pour le tuto paiement, calé sur la liste
/// canonique des pays supportés.
class _CountryDropdown extends StatelessWidget {
  const _CountryDropdown({required this.value, required this.onChanged});
  final String? value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: ArenaSpacing.md),
      decoration: BoxDecoration(
        color: ArenaColors.carbon,
        borderRadius: BorderRadius.circular(ArenaRadius.md),
        border: Border.all(color: ArenaColors.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          dropdownColor: ArenaColors.carbon,
          style: ArenaText.body,
          hint: Text('Choisir un pays', style: ArenaText.bodyMuted),
          items: [
            for (final c in kSupportedCountries)
              DropdownMenuItem(
                value: c.code,
                child: Text('${c.flag}  ${c.name}'),
              ),
          ],
          onChanged: (c) {
            if (c != null) onChanged(c);
          },
        ),
      ),
    );
  }
}

/// Sélecteur de côté (Domicile / Extérieur) pour l'intro de rôle.
class _RoleSideDropdown extends StatelessWidget {
  const _RoleSideDropdown({required this.value, required this.onChanged});
  final MatchRoleSide? value;
  final ValueChanged<MatchRoleSide> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: ArenaSpacing.md),
      decoration: BoxDecoration(
        color: ArenaColors.carbon,
        borderRadius: BorderRadius.circular(ArenaRadius.md),
        border: Border.all(color: ArenaColors.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<MatchRoleSide>(
          value: value,
          isExpanded: true,
          dropdownColor: ArenaColors.carbon,
          style: ArenaText.body,
          hint: Text('Choisir un côté', style: ArenaText.bodyMuted),
          items: [
            for (final s in MatchRoleSide.values)
              DropdownMenuItem(value: s, child: Text(s.labelFr)),
          ],
          onChanged: (s) {
            if (s != null) onChanged(s);
          },
        ),
      ),
    );
  }
}
