import 'package:arena/core/theme/arena_theme.dart';
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
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// SA · Vidéo tutoriel — gestion de la vidéo de prise en main de la home.
///
/// Le super-admin renseigne un titre + un lien vidéo externe (YouTube,
/// Vimeo, lien direct…) et publie. Une seule vidéo active à la fois :
/// publier remplace la précédente. Un bouton permet de retirer la vidéo de
/// la home sans en publier une nouvelle. Côté user, la bannière ouvre le
/// lien en EXTERNE au tap.
class SuperAdminTutorialVideo extends ConsumerStatefulWidget {
  const SuperAdminTutorialVideo({super.key});

  @override
  ConsumerState<SuperAdminTutorialVideo> createState() =>
      _SuperAdminTutorialVideoState();
}

class _SuperAdminTutorialVideoState
    extends ConsumerState<SuperAdminTutorialVideo> {
  final _titleCtrl = TextEditingController();
  final _urlCtrl = TextEditingController();

  bool _saving = false;
  String? _lastResult;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _urlCtrl.dispose();
    super.dispose();
  }

  String get _title => _titleCtrl.text.trim();
  String get _url => _urlCtrl.text.trim();

  /// URL http/https valide et absolue.
  bool get _urlValid {
    final uri = Uri.tryParse(_url);
    return uri != null &&
        uri.hasScheme &&
        (uri.scheme == 'http' || uri.scheme == 'https') &&
        uri.host.isNotEmpty;
  }

  bool get _canSave =>
      !_saving && _title.isNotEmpty && _url.isNotEmpty && _urlValid;

  Future<void> _publish() async {
    if (!_canSave) return;
    final adminId = ref.read(currentSessionProvider)?.user.id;
    if (adminId == null) return;
    final totpOk = await TotpGate.confirm(
      context,
      ref,
      reason: 'Publier une vidéo tutoriel sur la home',
    );
    if (!totpOk || !mounted) return;

    setState(() {
      _saving = true;
      _lastResult = null;
    });
    try {
      await ref.read(tutorialVideoRepositoryProvider).saveActive(
            title: _title,
            videoUrl: _url,
            updatedBy: adminId,
          );
      await ref.read(adminAuditLogRepositoryProvider).record(
        adminId: adminId,
        action: 'tutorial_video_published',
        targetType: 'tutorial_video',
        targetId: null,
        afterState: {
          'title': _title,
          'video_url': _url,
        },
      );
      ref.invalidate(currentTutorialVideoProvider);
      if (!mounted) return;
      setState(() {
        _saving = false;
        _lastResult = '✓ Vidéo tutoriel publiée sur la home.';
        _titleCtrl.clear();
        _urlCtrl.clear();
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
      reason: 'Retirer la vidéo tutoriel de la home',
    );
    if (!totpOk || !mounted) return;

    setState(() => _saving = true);
    try {
      await ref.read(tutorialVideoRepositoryProvider).deactivate();
      await ref.read(adminAuditLogRepositoryProvider).record(
            adminId: adminId,
            action: 'tutorial_video_removed',
            targetType: 'tutorial_video',
            targetId: null,
            afterState: {},
          );
      ref.invalidate(currentTutorialVideoProvider);
      if (!mounted) return;
      setState(() {
        _saving = false;
        _lastResult = '✓ Vidéo tutoriel retirée de la home.';
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
    final current = ref.watch(currentTutorialVideoProvider);
    final showUrlError = _url.isNotEmpty && !_urlValid;

    return Scaffold(
      appBar: const ArenaAppBar(title: '🎬 VIDÉO TUTORIEL'),
      body: ArenaScreenBackground(
        accent: ArenaColors.neonRed,
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(ArenaSpacing.lg),
            children: [
              Text('VIDÉO ACTUELLE', style: ArenaText.inputLabel),
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
                data: (video) => _CurrentVideoCard(
                  video: video,
                  onRemove: _saving ? null : _removeCurrent,
                ),
              ),
              const SizedBox(height: ArenaSpacing.lg),
              Text('NOUVELLE VIDÉO', style: ArenaText.h3),
              const SizedBox(height: ArenaSpacing.sm),

              // ─── Titre ────────────────────────────────────────────────
              Text('📝 TITRE', style: ArenaText.inputLabel),
              const SizedBox(height: ArenaSpacing.sm),
              ArenaTextField(
                controller: _titleCtrl,
                hint: 'Ex. Comment créer ta première compétition',
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: ArenaSpacing.lg),

              // ─── Lien vidéo ───────────────────────────────────────────
              Text('🔗 LIEN VIDÉO', style: ArenaText.inputLabel),
              const SizedBox(height: ArenaSpacing.sm),
              ArenaTextField(
                controller: _urlCtrl,
                hint: 'https://youtu.be/…',
                helper: 'Lien http/https ouvert dans le navigateur externe.',
                onChanged: (_) => setState(() {}),
              ),
              if (showUrlError) ...[
                const SizedBox(height: ArenaSpacing.xs),
                Text(
                  'Lien invalide — utilisez une URL http(s) complète.',
                  style: ArenaText.small.copyWith(color: ArenaColors.neonRed),
                ),
              ],
              const SizedBox(height: ArenaSpacing.lg),

              ArenaButton(
                label: _saving ? 'PUBLICATION…' : '🚀 PUBLIER LA VIDÉO',
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
}

class _CurrentVideoCard extends StatelessWidget {
  const _CurrentVideoCard({required this.video, required this.onRemove});

  final TutorialVideo? video;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    if (video == null || !video!.isActive) {
      return Container(
        padding: const EdgeInsets.all(ArenaSpacing.md),
        decoration: BoxDecoration(
          color: ArenaColors.carbon,
          borderRadius: BorderRadius.circular(ArenaRadius.md),
          border: Border.all(color: ArenaColors.border),
        ),
        child: Text(
          'Aucune vidéo active — la section tutoriel est masquée sur la home.',
          style: ArenaText.bodyMuted,
        ),
      );
    }
    final v = video!;
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
          Row(
            children: [
              const Icon(
                Icons.play_circle_outline,
                color: ArenaColors.statusOk,
              ),
              const SizedBox(width: ArenaSpacing.sm),
              Expanded(
                child: Text('🟢 Active · ${v.title}', style: ArenaText.body),
              ),
            ],
          ),
          const SizedBox(height: ArenaSpacing.xs),
          Text(v.videoUrl, style: ArenaText.bodyMuted),
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
