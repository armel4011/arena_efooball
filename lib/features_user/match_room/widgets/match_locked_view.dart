import 'dart:async';

import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/core/utils/youtube_url.dart';
import 'package:arena/data/models/tutorial_video.dart';
import 'package:arena/data/repositories/game_rules_repository.dart';
import 'package:arena/data/repositories/match_repository.dart';
import 'package:arena/data/repositories/tutorial_video_repository.dart';
import 'package:arena/features_shared/widgets/arena_youtube_player.dart';
import 'package:arena/features_user/match_room/match_room_providers.dart';
import 'package:arena/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

/// Écran de verrouillage de la salle de match : l'accès n'ouvre qu'à T-5 min
/// avant le coup d'envoi planifié (`scheduledAt`). Affiche un compte-à-rebours
/// vers l'ouverture et déverrouille automatiquement (invalide
/// [matchByIdProvider]) une fois l'heure atteinte, sans que le joueur ait à
/// quitter puis revenir.
///
/// Deux cas :
///  * [opensAt] non-null → match planifié : compte-à-rebours + heure du match.
///  * [opensAt] null → match pas encore programmé : message d'attente, sans
///    rebours (l'horaire sera fixé quand le round précédent se termine).
class MatchLockedView extends ConsumerStatefulWidget {
  const MatchLockedView({
    required this.matchId,
    required this.scheduledAt,
    required this.opensAt,
    super.key,
  });

  final String matchId;
  final DateTime? scheduledAt;
  final DateTime? opensAt;

  @override
  ConsumerState<MatchLockedView> createState() => _MatchLockedViewState();
}

class _MatchLockedViewState extends ConsumerState<MatchLockedView> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _syncTicker();
  }

  @override
  void didUpdateWidget(MatchLockedView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Le parent reconstruit ce widget à chaque tick du stream realtime du
    // match : l'horaire peut apparaître (round précédent terminé → l'horaire
    // du round suivant est posé) ou changer (reprogrammation admin) SANS que
    // l'écran soit démonté. Sans re-synchronisation, un rebours créé en
    // `initState` sur l'ancien horaire resterait seul juge — et un écran monté
    // sans horaire n'aurait jamais de rebours du tout.
    if (widget.opensAt != oldWidget.opensAt ||
        widget.matchId != oldWidget.matchId) {
      _syncTicker();
    }
  }

  /// (Re)pose le rebours sur l'horaire courant. Sans horaire, pas de ticker :
  /// l'écran affiche un message d'attente fixe.
  void _syncTicker() {
    _ticker?.cancel();
    _ticker = null;
    if (widget.opensAt == null) return;
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (!DateTime.now().isBefore(widget.opensAt!)) {
        // L'accès vient d'ouvrir : on invalide le match → la page parente
        // re-évalue le verrou et laisse entrer dans la room.
        _ticker?.cancel();
        ref.invalidate(matchByIdProvider(widget.matchId));
      } else {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toString();
    final scheduledAt = widget.scheduledAt;
    final opensAt = widget.opensAt;

    // Scrollable : le compte-à-rebours reste centré quand l'écran est court,
    // mais les règles + la vidéo (qui peuvent être longues) peuvent défiler
    // sans déborder — l'ancien `Center > Column` figé le rendait impossible.
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Padding(
              padding: const EdgeInsets.all(ArenaSpacing.xl),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    opensAt == null
                        ? Icons.schedule_outlined
                        : Icons.lock_clock,
                    size: 56,
                    color: ArenaColors.signalBlue,
                  ),
                  const SizedBox(height: ArenaSpacing.lg),
                  Text(
                    opensAt == null
                        ? l10n.matchLockedNoScheduleTitle
                        : l10n.matchLockedTitle,
                    style: ArenaText.h2,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: ArenaSpacing.sm),
                  if (opensAt == null) ...[
                    Text(
                      l10n.matchLockedNoScheduleBody,
                      style: ArenaText.body.copyWith(color: ArenaColors.silver),
                      textAlign: TextAlign.center,
                    ),
                  ] else ...[
                    Text(
                      l10n.matchLockedBody,
                      style: ArenaText.body.copyWith(color: ArenaColors.silver),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: ArenaSpacing.lg),
                    Text(
                      _formatCountdown(opensAt.difference(DateTime.now())),
                      style: ArenaText.monoLg.copyWith(
                        color: ArenaColors.signalBlue,
                        fontSize: 32,
                      ),
                    ),
                    if (scheduledAt != null) ...[
                      const SizedBox(height: ArenaSpacing.sm),
                      Text(
                        l10n.matchLockedScheduled(
                          DateFormat('EEE d MMM · HH:mm', locale)
                              .format(scheduledAt.toLocal()),
                        ),
                        style: ArenaText.small
                            .copyWith(color: ArenaColors.silver),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                  _gameBriefing(l10n),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Bloc « à réviser avant de jouer » : règles du jeu + vidéo explicative,
  /// discriminés par le jeu de la compétition. Rendu vide tant que le jeu n'est
  /// pas résolu ou qu'aucun contenu n'a été saisi par l'admin — l'écran de
  /// verrouillage reste alors identique à avant.
  Widget _gameBriefing(AppLocalizations l10n) {
    final game = ref.watch(matchGameTypeProvider(widget.matchId)).valueOrNull;
    if (game == null) return const SizedBox.shrink();

    final rules = ref.watch(gameRulesProvider(game)).valueOrNull;
    // Plusieurs vidéos possibles (règles, prolongations, tirs au but…) — on
    // n'affiche que celles dont le lien est exploitable. Lecture IN-APP plein
    // écran au tap (léger : pas N lecteurs embarqués simultanés).
    final videos = ref.watch(matchLockedVideosProvider(game)).valueOrNull ??
        const <TutorialVideo>[];
    final playable = [
      for (final v in videos)
        if (isPlayableYoutubeUrl(v.videoUrl)) v,
    ];
    final hasRules = rules != null && rules.trim().isNotEmpty;
    if (!hasRules && playable.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: ArenaSpacing.xl),
        const Divider(color: ArenaColors.border),
        const SizedBox(height: ArenaSpacing.lg),
        if (playable.isNotEmpty) ...[
          Text(l10n.matchRulesVideoTitle, style: ArenaText.h3),
          const SizedBox(height: ArenaSpacing.sm),
          for (final v in playable) ...[
            _LockedVideoCard(video: v),
            const SizedBox(height: ArenaSpacing.sm),
          ],
          const SizedBox(height: ArenaSpacing.md),
        ],
        if (hasRules) ...[
          Text(l10n.matchRulesSectionTitle, style: ArenaText.h3),
          const SizedBox(height: ArenaSpacing.sm),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(ArenaSpacing.md),
            decoration: BoxDecoration(
              color: ArenaColors.carbon,
              borderRadius: BorderRadius.circular(ArenaRadius.md),
              border: Border.all(color: ArenaColors.border),
            ),
            child: Text(
              rules.trim(),
              style: ArenaText.body.copyWith(color: ArenaColors.silver),
            ),
          ),
        ],
      ],
    );
  }

  // (déplacé) — la carte vidéo est un widget dédié plus bas.

  /// hh:mm:ss si ≥ 1h, sinon mm:ss. Borné à 0.
  String _formatCountdown(Duration raw) {
    final d = raw.isNegative ? Duration.zero : raw;
    final h = d.inHours;
    final mm = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final ss = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (h > 0) return '${h.toString().padLeft(2, '0')}:$mm:$ss';
    return '$mm:$ss';
  }
}

/// Carte d'une vidéo de l'écran de verrouillage : titre + tap → lecture IN-APP
/// plein écran (`openFullscreenYoutube`). Évite d'embarquer N lecteurs YouTube
/// simultanés (lourd / WebView capricieuse) quand il y a plusieurs vidéos.
class _LockedVideoCard extends StatelessWidget {
  const _LockedVideoCard({required this.video});

  final TutorialVideo video;

  @override
  Widget build(BuildContext context) {
    final title =
        video.title.trim().isEmpty ? 'Vidéo explicative' : video.title.trim();
    return InkWell(
      borderRadius: BorderRadius.circular(ArenaRadius.md),
      onTap: () => openFullscreenYoutube(context, video.videoUrl),
      child: Container(
        padding: const EdgeInsets.all(ArenaSpacing.md),
        decoration: BoxDecoration(
          color: ArenaColors.carbon,
          borderRadius: BorderRadius.circular(ArenaRadius.md),
          border: Border.all(color: ArenaColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: ArenaColors.signalBlue.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(ArenaRadius.sm),
              ),
              child: const Icon(
                Icons.play_arrow_rounded,
                color: ArenaColors.signalBlue,
              ),
            ),
            const SizedBox(width: ArenaSpacing.md),
            Expanded(
              child: Text(
                title,
                style: ArenaText.body.copyWith(fontWeight: FontWeight.w700),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Icon(Icons.chevron_right, color: ArenaColors.silver),
          ],
        ),
      ),
    );
  }
}
