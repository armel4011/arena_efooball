import 'package:arena/core/router/user_router.dart';
import 'package:arena/core/theme/arena_colors.dart';
import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/core/theme/arena_typography.dart';
import 'package:arena/data/models/arena_match.dart';
import 'package:arena/data/models/match_status.dart';
import 'package:arena/data/repositories/match_repository.dart';
import 'package:arena/features_shared/widgets/arena_button.dart';
import 'package:arena/features_shared/widgets/arena_card.dart';
import 'package:arena/features_shared/widgets/arena_text_field.dart';
import 'package:arena/features_shared/widgets/empty_state.dart';
import 'package:arena/features_shared/widgets/error_state.dart';
import 'package:arena/features_user/auth/auth_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// In-flight optimistic score submissions, keyed by matchId. Lives
/// outside the widget tree so a player who taps SOUMETTRE, steps back
/// to the bracket and re-enters the match room still sees the "waiting
/// for opponent" UI — instead of being shown the entry form again
/// (and worst-case double-submitting).
///
/// The realtime stream of `match_events` is the source of truth; this
/// provider only fills the gap between "we just inserted" and "the
/// stream echoed it back" — typically a few hundred ms, but the gap
/// also covers the entire time the widget is unmounted.
final _pendingScoreSubmissionProvider =
    StateProvider.family<Map<String, dynamic>?, String>((ref, matchId) => null);

/// Same idea as [_pendingScoreSubmissionProvider] but for the share-code
/// step: holds the room code we just posted while the realtime stream
/// catches up to `status = ready`. Persisting it across remounts means
/// stepping back to the bracket and re-entering the room still shows
/// the "code partagé" interstitial instead of dropping back to the
/// empty share form.
final _pendingRoomCodeProvider =
    StateProvider.family<String?, String>((ref, matchId) => null);

/// PHASE 5 — Match Room shell.
///
/// Watches the match in realtime and dispatches to a status-specific
/// view. The actual interactive flows (sharing the room code,
/// submitting scores) land in sub-steps 5.C and 5.D — for now each
/// branch shows a clear "what should happen here" placeholder so the
/// scaffold can be tested end-to-end without mocking deep providers.
class MatchRoomPage extends ConsumerWidget {
  const MatchRoomPage({required this.matchId, super.key});

  final String matchId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(matchByIdProvider(matchId));
    final selfId = ref.watch(currentSessionProvider)?.user.id;

    return PopScope(
      // The bracket reads `competitionMatchesProvider` as a Future (no
      // realtime), so a status change made here would otherwise need a
      // manual pull-to-refresh to show up. We invalidate the whole
      // family on every exit path — AppBar back, system back gesture,
      // and the deep-link fallback below — so the bracket re-fetches on
      // its next build.
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) ref.invalidate(competitionMatchesProvider);
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('MATCH ROOM'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              ref.invalidate(competitionMatchesProvider);
              if (context.canPop()) {
                context.pop();
              } else {
                context.go(UserRoutes.home);
              }
            },
          ),
        ),
        body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorState(
          description: e.toString(),
          onRetry: () => ref.invalidate(matchByIdProvider(matchId)),
        ),
        data: (m) {
          if (m == null) {
            return const EmptyState(
              icon: Icons.search_off_outlined,
              title: 'Match introuvable',
              description: 'Le match a peut-être été annulé par un admin.',
            );
          }
          final role = MatchRole.resolve(match: m, selfId: selfId);
          return _MatchRoomBody(match: m, role: role);
        },
        ),
      ),
    );
  }
}

/// Where the current user stands relative to the match.
enum MatchRole {
  /// Player 1 (the bracket-determined slot 1).
  player1,

  /// Player 2 (slot 2).
  player2,

  /// Anyone else looking at the match (admin tools, future spectator).
  observer;

  /// Convenience: did the user actually claim the home seat?
  bool isHomeOf(ArenaMatch m) {
    final selfMap = switch (this) {
      MatchRole.player1 => m.player1Id,
      MatchRole.player2 => m.player2Id,
      MatchRole.observer => null,
    };
    return selfMap != null && selfMap == m.homePlayerId;
  }

  static MatchRole resolve({required ArenaMatch match, String? selfId}) {
    if (selfId == null) return MatchRole.observer;
    if (selfId == match.player1Id) return MatchRole.player1;
    if (selfId == match.player2Id) return MatchRole.player2;
    return MatchRole.observer;
  }
}

class _MatchRoomBody extends StatelessWidget {
  const _MatchRoomBody({required this.match, required this.role});

  final ArenaMatch match;
  final MatchRole role;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _Header(match: match, role: role),
        const Divider(height: 1, thickness: 1, color: ArenaColors.border),
        Expanded(child: _bodyForStatus(match.status)),
      ],
    );
  }

  Widget _bodyForStatus(MatchStatus status) => switch (status) {
        MatchStatus.pending || MatchStatus.scheduled =>
          role == MatchRole.observer
              ? const _PlaceholderView(
                  phase: '—',
                  icon: Icons.vpn_key_outlined,
                  title: 'En attente du code room',
                  description: 'Les joueurs vont créer une room dans le jeu'
                      ' et partager le code ici.',
                )
              : _ShareCodeForm(match: match),
        MatchStatus.ready => _RoomReadyView(match: match, role: role),
        MatchStatus.inProgress ||
        MatchStatus.scorePending ||
        MatchStatus.awaitingValidation =>
          role == MatchRole.observer
              ? const _PlaceholderView(
                  phase: '—',
                  icon: Icons.sports_esports,
                  title: 'Match en cours',
                  description: 'Les joueurs sont en train de jouer ou de'
                      ' valider le score.',
                )
              : _ScoreFlowView(match: match, role: role),
        MatchStatus.disputed => const _PlaceholderView(
            phase: 'PHASE 12.5',
            icon: Icons.gavel,
            title: 'Litige en cours',
            description: 'Vos scores ne concordent pas. Un admin va'
                ' trancher. Ce flux automatique arrive avec le bot'
                " d'arbitrage de la phase 12.5.",
          ),
        MatchStatus.completed => _CompletedView(match: match),
        MatchStatus.cancelled => const _PlaceholderView(
            phase: '—',
            icon: Icons.block,
            title: 'Match annulé',
            description: "L'admin a annulé ce match.",
          ),
        MatchStatus.forfeited => const _PlaceholderView(
            phase: '—',
            icon: Icons.exit_to_app,
            title: 'Forfait',
            description: "L'un des joueurs n'a pas démarré à temps.",
          ),
      };
}

class _Header extends StatelessWidget {
  const _Header({required this.match, required this.role});

  final ArenaMatch match;
  final MatchRole role;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(ArenaSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                match.matchNumber == null
                    ? 'MATCH'
                    : 'MATCH #${match.matchNumber}',
                style: ArenaTypography.headlineMedium,
              ),
              const Spacer(),
              _StatusChip(status: match.status),
            ],
          ),
          const SizedBox(height: ArenaSpacing.sm),
          Row(
            children: [
              Expanded(
                child: _SeatLine(
                  label: 'Joueur 1',
                  playerId: match.player1Id,
                  highlight: role == MatchRole.player1,
                ),
              ),
              const SizedBox(width: ArenaSpacing.md),
              Text(
                'vs',
                style: ArenaTypography.bodyMedium.copyWith(
                  color: ArenaColors.textFaint,
                ),
              ),
              const SizedBox(width: ArenaSpacing.md),
              Expanded(
                child: _SeatLine(
                  label: 'Joueur 2',
                  playerId: match.player2Id,
                  highlight: role == MatchRole.player2,
                  alignEnd: true,
                ),
              ),
            ],
          ),
          if (role == MatchRole.observer) ...[
            const SizedBox(height: ArenaSpacing.sm),
            Text(
              "Tu n'es pas inscrit à ce match — vue en lecture.",
              style: ArenaTypography.bodyMedium.copyWith(
                color: ArenaColors.textMuted,
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SeatLine extends StatelessWidget {
  const _SeatLine({
    required this.label,
    required this.playerId,
    required this.highlight,
    this.alignEnd = false,
  });

  final String label;
  final String? playerId;
  final bool highlight;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    final pid = playerId;
    final stub = pid == null ? 'À déterminer' : 'Joueur ${pid.substring(0, 6)}…';
    return Column(
      crossAxisAlignment:
          alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(
          highlight ? '$label · TOI' : label,
          style: ArenaTypography.labelLarge.copyWith(
            color: highlight
                ? Theme.of(context).colorScheme.primary
                : ArenaColors.textMuted,
            fontSize: 11,
          ),
        ),
        Text(
          stub,
          style: ArenaTypography.bodyMedium.copyWith(
            color: pid == null ? ArenaColors.textMuted : ArenaColors.text,
            fontWeight: highlight ? FontWeight.bold : FontWeight.normal,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final MatchStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      MatchStatus.pending => ('À VENIR', ArenaColors.textMuted),
      MatchStatus.scheduled => ('PROGRAMMÉ', ArenaColors.textMuted),
      MatchStatus.ready => ('PRÊT', ArenaColors.primary),
      MatchStatus.inProgress => ('EN COURS', ArenaColors.success),
      MatchStatus.scorePending => ('SCORE EN ATTENTE', ArenaColors.warning),
      MatchStatus.awaitingValidation => ('VALIDATION', ArenaColors.warning),
      MatchStatus.disputed => ('LITIGE', ArenaColors.danger),
      MatchStatus.completed => ('TERMINÉ', ArenaColors.textMuted),
      MatchStatus.cancelled => ('ANNULÉ', ArenaColors.textFaint),
      MatchStatus.forfeited => ('FORFAIT', ArenaColors.danger),
    };
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: ArenaSpacing.sm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: ArenaRadius.pill,
      ),
      child: Text(
        label,
        style: ArenaTypography.labelLarge.copyWith(
          color: color,
          fontSize: 10,
        ),
      ),
    );
  }
}

class _PlaceholderView extends StatelessWidget {
  const _PlaceholderView({
    required this.phase,
    required this.icon,
    required this.title,
    required this.description,
  });

  final String phase;
  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: icon,
      title: title,
      description: phase == '—' ? description : '$phase — $description',
    );
  }
}

class _CompletedView extends StatelessWidget {
  const _CompletedView({required this.match});

  final ArenaMatch match;

  @override
  Widget build(BuildContext context) {
    final s1 = match.score1 ?? 0;
    final s2 = match.score2 ?? 0;
    return Padding(
      padding: const EdgeInsets.all(ArenaSpacing.lg),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.emoji_events,
            size: 64,
            color: ArenaColors.warning,
          ),
          const SizedBox(height: ArenaSpacing.md),
          Text('SCORE FINAL', style: ArenaTypography.labelLarge),
          const SizedBox(height: ArenaSpacing.sm),
          Text(
            '$s1 — $s2',
            style: ArenaTypography.displayMedium.copyWith(fontSize: 48),
          ),
          const SizedBox(height: ArenaSpacing.md),
          if (match.winnerId != null)
            Text(
              'Gagnant : Joueur ${match.winnerId!.substring(0, 6)}…',
              style: ArenaTypography.bodyMedium.copyWith(
                color: ArenaColors.textMuted,
              ),
            )
          else
            Text(
              'Match nul.',
              style: ArenaTypography.bodyMedium.copyWith(
                color: ArenaColors.textMuted,
              ),
            ),
        ],
      ),
    );
  }
}

/// PHASE 5.C — Share-the-room-code form (status `pending` / `scheduled`).
///
/// Either player can be the first to post a code; whoever does claims the
/// HOME seat (single UPDATE in [MatchRepository.setRoomCode]) and flips the
/// match to `ready`. The other player then sees [_RoomReadyView] in
/// realtime via the [matchByIdProvider] stream.
///
/// V1.0 keeps it simple: no atomic seat claim — if both players post at the
/// exact same instant, the second write wins and the first becomes AWAY.
/// Acceptable trade-off; we'll harden in PHASE 12.5 if it bites.
class _ShareCodeForm extends ConsumerStatefulWidget {
  const _ShareCodeForm({required this.match});

  final ArenaMatch match;

  @override
  ConsumerState<_ShareCodeForm> createState() => _ShareCodeFormState();
}

class _ShareCodeFormState extends ConsumerState<_ShareCodeForm> {
  final _controller = TextEditingController();
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final raw = _controller.text.trim().toUpperCase();
    if (raw.length < 4 || raw.length > 12) {
      setState(() => _error = 'Le code doit faire entre 4 et 12 caractères.');
      return;
    }
    final selfId = ref.read(currentSessionProvider)?.user.id;
    if (selfId == null) return;

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      await ref.read(matchRepositoryProvider).setRoomCode(
            matchId: widget.match.id,
            hostProfileId: selfId,
            code: raw,
          );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = 'Impossible de partager le code : $e';
      });
      return;
    }
    if (!mounted) return;
    ref
        .read(_pendingRoomCodeProvider(widget.match.id).notifier)
        .state = raw;
    setState(() => _submitting = false);
  }

  @override
  Widget build(BuildContext context) {
    final optimisticCode =
        ref.watch(_pendingRoomCodeProvider(widget.match.id));
    if (optimisticCode != null) {
      return _CodeSharedInterstitial(code: optimisticCode);
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(ArenaSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: ArenaSpacing.lg),
          const Icon(
            Icons.vpn_key_outlined,
            size: 56,
            color: ArenaColors.primary,
          ),
          const SizedBox(height: ArenaSpacing.md),
          Text(
            'PARTAGE LE CODE DE LA ROOM',
            textAlign: TextAlign.center,
            style: ArenaTypography.headlineMedium,
          ),
          const SizedBox(height: ArenaSpacing.sm),
          Text(
            'Crée une room dans le jeu, puis colle le code ici. Ton'
            ' adversaire le verra apparaître en temps réel.',
            textAlign: TextAlign.center,
            style: ArenaTypography.bodyMedium.copyWith(
              color: ArenaColors.textMuted,
            ),
          ),
          const SizedBox(height: ArenaSpacing.xl),
          ArenaTextField(
            label: 'Code de la room',
            hint: 'Ex: ABC123',
            controller: _controller,
            maxLength: 12,
            autofocus: true,
            textInputAction: TextInputAction.done,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp('[A-Za-z0-9]')),
              _UpperCaseFormatter(),
            ],
            errorText: _error,
            enabled: !_submitting,
          ),
          const SizedBox(height: ArenaSpacing.md),
          ArenaButton(
            label: 'PARTAGER LE CODE',
            icon: Icons.send_outlined,
            fullWidth: true,
            isLoading: _submitting,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }
}

/// PHASE 5.C — Room is set (status `ready`). Shows the code prominently and
/// lets either player flip the match to `in_progress` once both have joined
/// the in-game room.
class _RoomReadyView extends ConsumerStatefulWidget {
  const _RoomReadyView({required this.match, required this.role});

  final ArenaMatch match;
  final MatchRole role;

  @override
  ConsumerState<_RoomReadyView> createState() => _RoomReadyViewState();
}

class _RoomReadyViewState extends ConsumerState<_RoomReadyView> {
  bool _submitting = false;

  bool get _isHome =>
      widget.match.homePlayerId != null &&
      switch (widget.role) {
        MatchRole.player1 => widget.match.player1Id == widget.match.homePlayerId,
        MatchRole.player2 => widget.match.player2Id == widget.match.homePlayerId,
        MatchRole.observer => false,
      };

  Future<void> _markStarted() async {
    setState(() => _submitting = true);
    try {
      await ref
          .read(matchRepositoryProvider)
          .markInProgress(widget.match.id);
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Impossible de marquer démarré : $e')),
      );
    }
    // On success the realtime stream pushes the new status and the body
    // rebuilds — no local state to flip back.
  }

  Future<void> _copyCode(String code) async {
    final messenger = ScaffoldMessenger.of(context);
    await Clipboard.setData(ClipboardData(text: code));
    if (!mounted) return;
    messenger.showSnackBar(
      const SnackBar(
        content: Text('Code copié dans le presse-papier'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final code = widget.match.roomCode;
    final isPlayer = widget.role != MatchRole.observer;
    final hint = switch (widget.role) {
      MatchRole.observer =>
        'Les joueurs vont rejoindre la room et démarrer le match.',
      _ when _isHome =>
        'Tu as partagé le code. En attente que ton adversaire rejoigne, '
            'puis confirmez le démarrage.',
      _ =>
        'Rejoins la room dans le jeu avec ce code, puis confirme une fois'
            ' que les deux joueurs sont dedans.',
    };

    return SingleChildScrollView(
      padding: const EdgeInsets.all(ArenaSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: ArenaSpacing.lg),
          const Icon(
            Icons.meeting_room_outlined,
            size: 56,
            color: ArenaColors.success,
          ),
          const SizedBox(height: ArenaSpacing.sm),
          Text(
            'CODE DE LA ROOM',
            textAlign: TextAlign.center,
            style: ArenaTypography.labelLarge.copyWith(
              color: ArenaColors.textMuted,
            ),
          ),
          const SizedBox(height: ArenaSpacing.sm),
          ArenaCard(
            elevated: true,
            padding: const EdgeInsets.symmetric(
              vertical: ArenaSpacing.lg,
              horizontal: ArenaSpacing.md,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: SelectableText(
                    code ?? '—',
                    textAlign: TextAlign.center,
                    style: ArenaTypography.displayMedium.copyWith(
                      fontSize: 40,
                      letterSpacing: 4,
                    ),
                  ),
                ),
                if (code != null) ...[
                  const SizedBox(width: ArenaSpacing.sm),
                  IconButton(
                    icon: const Icon(Icons.copy_outlined),
                    tooltip: 'Copier le code',
                    color: ArenaColors.textMuted,
                    onPressed: () => _copyCode(code),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: ArenaSpacing.lg),
          Text(
            hint,
            textAlign: TextAlign.center,
            style: ArenaTypography.bodyMedium.copyWith(
              color: ArenaColors.textMuted,
            ),
          ),
          if (isPlayer) ...[
            const SizedBox(height: ArenaSpacing.xl),
            ArenaButton(
              label: 'JE SUIS DANS LA ROOM',
              icon: Icons.play_arrow_rounded,
              fullWidth: true,
              isLoading: _submitting,
              onPressed: _markStarted,
            ),
          ],
        ],
      ),
    );
  }
}

/// PHASE 5.D — Collaborative score-submission flow.
///
/// Watches `match_events` of type `score_submitted` in realtime, then:
///  - `mySubmission == null`  → render the entry form
///  - `mySubmission != null && !bothSubmitted` → "waiting for opponent"
///  - `bothSubmitted` → auto-resolve once via `_resolve`: matching scores
///    commit (with `winnerId` derived from the higher score, or null on a
///    draw), divergent scores flip the match to `disputed`. Both clients
///    reach the same conclusion from identical inputs, so the redundant
///    write is a no-op — `_resolutionTriggered` just avoids re-firing on
///    every rebuild of this widget.
class _ScoreFlowView extends ConsumerStatefulWidget {
  const _ScoreFlowView({required this.match, required this.role});

  final ArenaMatch match;
  final MatchRole role;

  @override
  ConsumerState<_ScoreFlowView> createState() => _ScoreFlowViewState();
}

class _ScoreFlowViewState extends ConsumerState<_ScoreFlowView> {
  final _myScoreCtrl = TextEditingController();
  final _oppScoreCtrl = TextEditingController();
  final _myPenCtrl = TextEditingController();
  final _oppPenCtrl = TextEditingController();
  bool _viaPenalties = false;
  bool _submitting = false;
  String? _error;
  bool _resolutionTriggered = false;

  @override
  void dispose() {
    _myScoreCtrl.dispose();
    _oppScoreCtrl.dispose();
    _myPenCtrl.dispose();
    _oppPenCtrl.dispose();
    super.dispose();
  }

  bool get _isPlayer1 => widget.role == MatchRole.player1;

  /// Group-stage matches stay on the regulation-time score (draws are
  /// allowed). Only knockout matches expose the "decided by penalties"
  /// toggle. We use `groupId` as the marker because it's set by the
  /// admin when the match belongs to a group, and left null for every
  /// knockout slot.
  bool get _isKnockout => widget.match.groupId == null;

  Future<void> _submit() async {
    final my = int.tryParse(_myScoreCtrl.text.trim());
    final opp = int.tryParse(_oppScoreCtrl.text.trim());
    if (my == null || opp == null || my < 0 || my > 99 || opp < 0 || opp > 99) {
      setState(() => _error = 'Scores attendus entre 0 et 99.');
      return;
    }

    int? myPen;
    int? oppPen;
    if (_viaPenalties) {
      if (my != opp) {
        setState(() {
          _error = 'Le score réglementaire doit être à égalité avant'
              ' les tirs au but.';
        });
        return;
      }
      myPen = int.tryParse(_myPenCtrl.text.trim());
      oppPen = int.tryParse(_oppPenCtrl.text.trim());
      if (myPen == null ||
          oppPen == null ||
          myPen < 0 ||
          oppPen < 0 ||
          myPen > 30 ||
          oppPen > 30) {
        setState(() => _error = 'Tirs au but attendus entre 0 et 30.');
        return;
      }
      if (myPen == oppPen) {
        setState(() {
          _error = 'Les tirs au but ne peuvent pas finir à égalité.';
        });
        return;
      }
    }

    final selfId = ref.read(currentSessionProvider)?.user.id;
    if (selfId == null) return;

    // The DB stores score1 / score2 keyed to the bracket-ordered seats,
    // not "me / opponent" — flip when the user is on the player2 seat.
    final s1 = _isPlayer1 ? my : opp;
    final s2 = _isPlayer1 ? opp : my;
    final pen1 = _viaPenalties ? (_isPlayer1 ? myPen : oppPen) : null;
    final pen2 = _viaPenalties ? (_isPlayer1 ? oppPen : myPen) : null;

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      await ref.read(matchRepositoryProvider).submitScore(
            matchId: widget.match.id,
            byProfileId: selfId,
            scoreP1: s1,
            scoreP2: s2,
            decidedByPenalties: _viaPenalties,
            penaltyP1: pen1,
            penaltyP2: pen2,
          );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = 'Impossible de soumettre : $e';
      });
      return;
    }
    if (!mounted) return;
    ref
        .read(_pendingScoreSubmissionProvider(widget.match.id).notifier)
        .state = {
      'created_by': selfId,
      'payload': {
        'score1': s1,
        'score2': s2,
        if (_viaPenalties) ...{
          'via_penalties': true,
          'penalty1': pen1,
          'penalty2': pen2,
        },
      },
    };
    setState(() => _submitting = false);
  }

  Future<void> _resolve(
    Map<String, dynamic> p1Submission,
    Map<String, dynamic> p2Submission,
  ) async {
    final pl1 = (p1Submission['payload'] as Map?)?.cast<String, dynamic>() ?? {};
    final pl2 = (p2Submission['payload'] as Map?)?.cast<String, dynamic>() ?? {};
    final s1A = pl1['score1'] as int?;
    final s2A = pl1['score2'] as int?;
    final s1B = pl2['score1'] as int?;
    final s2B = pl2['score2'] as int?;
    if (s1A == null || s2A == null || s1B == null || s2B == null) return;

    final viaPenA = pl1['via_penalties'] == true;
    final viaPenB = pl2['via_penalties'] == true;
    final pen1A = pl1['penalty1'] as int?;
    final pen2A = pl1['penalty2'] as int?;
    final pen1B = pl2['penalty1'] as int?;
    final pen2B = pl2['penalty2'] as int?;

    final regulationConcordant = s1A == s1B && s2A == s2B;
    final penaltiesConcordant = viaPenA == viaPenB &&
        (!viaPenA || (pen1A == pen1B && pen2A == pen2B));
    final concordant = regulationConcordant && penaltiesConcordant;

    final repo = ref.read(matchRepositoryProvider);

    try {
      if (concordant) {
        String? winner;
        if (viaPenA && pen1A != null && pen2A != null) {
          // Regulation tied — decide on penalties.
          if (pen1A > pen2A) {
            winner = widget.match.player1Id;
          } else if (pen2A > pen1A) {
            winner = widget.match.player2Id;
          }
        } else if (s1A > s2A) {
          winner = widget.match.player1Id;
        } else if (s2A > s1A) {
          winner = widget.match.player2Id;
        }
        await repo.commitScore(
          matchId: widget.match.id,
          scoreP1: s1A,
          scoreP2: s2A,
          winnerId: winner,
        );
      } else {
        await repo.flagDisputed(widget.match.id);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur de résolution : $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final selfId = ref.watch(currentSessionProvider)?.user.id;
    if (selfId == null) {
      return const EmptyState(
        icon: Icons.lock_outline,
        title: 'Session expirée',
        description: 'Reconnecte-toi pour saisir un score.',
      );
    }

    final submissionsAsync =
        ref.watch(matchScoreSubmissionsProvider(widget.match.id));

    return submissionsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => ErrorState(
        description: e.toString(),
        onRetry: () => ref.invalidate(
          matchScoreSubmissionsProvider(widget.match.id),
        ),
      ),
      data: (submissions) {
        // Last submission per player wins — guards against a player
        // submitting twice (e.g. correcting a typo before the opponent
        // has posted).
        final byPlayer = <String, Map<String, dynamic>>{};
        for (final s in submissions) {
          final by = s['created_by'] as String?;
          if (by != null) byPlayer[by] = s;
        }
        // Optimistic merge: if we just posted but the realtime stream
        // hasn't echoed back yet — or we've come back to this room
        // after stepping away — fall back to the matchId-keyed state
        // provider so the UI reflects the in-flight submission.
        final optimistic =
            ref.watch(_pendingScoreSubmissionProvider(widget.match.id));
        if (optimistic != null && !byPlayer.containsKey(selfId)) {
          byPlayer[selfId] = optimistic;
        }
        final mine = byPlayer[selfId];
        final p1Sub = widget.match.player1Id == null
            ? null
            : byPlayer[widget.match.player1Id];
        final p2Sub = widget.match.player2Id == null
            ? null
            : byPlayer[widget.match.player2Id];
        final bothSubmitted = p1Sub != null && p2Sub != null;

        if (bothSubmitted && !_resolutionTriggered) {
          _resolutionTriggered = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _resolve(p1Sub, p2Sub);
          });
        }

        if (mine == null) {
          return _buildForm();
        }
        return _buildAfterSubmit(mine, bothSubmitted);
      },
    );
  }

  Widget _buildForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(ArenaSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: ArenaSpacing.lg),
          const Icon(
            Icons.edit_outlined,
            size: 56,
            color: ArenaColors.warning,
          ),
          const SizedBox(height: ArenaSpacing.md),
          Text(
            'SAISIS LE SCORE FINAL',
            textAlign: TextAlign.center,
            style: ArenaTypography.headlineMedium,
          ),
          const SizedBox(height: ArenaSpacing.sm),
          Text(
            'Entre les buts de chaque côté. Si vos deux saisies'
            ' concordent, le match est validé automatiquement.',
            textAlign: TextAlign.center,
            style: ArenaTypography.bodyMedium.copyWith(
              color: ArenaColors.textMuted,
            ),
          ),
          const SizedBox(height: ArenaSpacing.xl),
          Row(
            children: [
              Expanded(
                child: ArenaTextField(
                  label: 'Mon score',
                  hint: '0',
                  controller: _myScoreCtrl,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.next,
                  maxLength: 2,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  enabled: !_submitting,
                ),
              ),
              const SizedBox(width: ArenaSpacing.md),
              Expanded(
                child: ArenaTextField(
                  label: 'Score adversaire',
                  hint: '0',
                  controller: _oppScoreCtrl,
                  keyboardType: TextInputType.number,
                  textInputAction: _isKnockout
                      ? TextInputAction.next
                      : TextInputAction.done,
                  maxLength: 2,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  enabled: !_submitting,
                ),
              ),
            ],
          ),
          if (_isKnockout) ...[
            const SizedBox(height: ArenaSpacing.md),
            SwitchListTile.adaptive(
              title: Text(
                'Match décidé aux tirs au but',
                style: ArenaTypography.bodyMedium,
              ),
              subtitle: Text(
                'À cocher uniquement si le score réglementaire'
                ' est à égalité.',
                style: ArenaTypography.bodyMedium.copyWith(
                  color: ArenaColors.textMuted,
                  fontSize: 12,
                ),
              ),
              value: _viaPenalties,
              contentPadding: EdgeInsets.zero,
              onChanged: _submitting
                  ? null
                  : (v) => setState(() {
                        _viaPenalties = v;
                        if (!v) {
                          _myPenCtrl.clear();
                          _oppPenCtrl.clear();
                        }
                      }),
            ),
            if (_viaPenalties) ...[
              const SizedBox(height: ArenaSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: ArenaTextField(
                      label: 'Mes tirs au but',
                      hint: '0',
                      controller: _myPenCtrl,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.next,
                      maxLength: 2,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      enabled: !_submitting,
                    ),
                  ),
                  const SizedBox(width: ArenaSpacing.md),
                  Expanded(
                    child: ArenaTextField(
                      label: 'Tirs adversaire',
                      hint: '0',
                      controller: _oppPenCtrl,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.done,
                      maxLength: 2,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      enabled: !_submitting,
                    ),
                  ),
                ],
              ),
            ],
          ],
          if (_error != null) ...[
            const SizedBox(height: ArenaSpacing.sm),
            Text(
              _error!,
              style: ArenaTypography.bodyMedium.copyWith(
                color: ArenaColors.danger,
              ),
            ),
          ],
          const SizedBox(height: ArenaSpacing.lg),
          ArenaButton(
            label: 'SOUMETTRE LE SCORE',
            icon: Icons.check_circle_outline,
            fullWidth: true,
            isLoading: _submitting,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }

  Widget _buildAfterSubmit(Map<String, dynamic> mine, bool bothSubmitted) {
    final pl = (mine['payload'] as Map?)?.cast<String, dynamic>() ?? {};
    final s1 = pl['score1'] as int? ?? 0;
    final s2 = pl['score2'] as int? ?? 0;
    final myGoals = _isPlayer1 ? s1 : s2;
    final oppGoals = _isPlayer1 ? s2 : s1;
    final viaPen = pl['via_penalties'] == true;
    final myPen = viaPen
        ? (_isPlayer1 ? pl['penalty1'] as int? : pl['penalty2'] as int?)
        : null;
    final oppPen = viaPen
        ? (_isPlayer1 ? pl['penalty2'] as int? : pl['penalty1'] as int?)
        : null;

    return Padding(
      padding: const EdgeInsets.all(ArenaSpacing.lg),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            bothSubmitted ? Icons.hourglass_top : Icons.hourglass_bottom,
            size: 56,
            color: ArenaColors.warning,
          ),
          const SizedBox(height: ArenaSpacing.md),
          Text(
            bothSubmitted ? 'VALIDATION EN COURS' : 'EN ATTENTE DE TON ADVERSAIRE',
            textAlign: TextAlign.center,
            style: ArenaTypography.labelLarge,
          ),
          const SizedBox(height: ArenaSpacing.sm),
          Text(
            'Tu as soumis : $myGoals — $oppGoals',
            textAlign: TextAlign.center,
            style: ArenaTypography.headlineMedium,
          ),
          if (viaPen && myPen != null && oppPen != null) ...[
            const SizedBox(height: ArenaSpacing.xs),
            Text(
              'Aux tirs au but : $myPen — $oppPen',
              textAlign: TextAlign.center,
              style: ArenaTypography.bodyMedium.copyWith(
                color: ArenaColors.textMuted,
              ),
            ),
          ],
          const SizedBox(height: ArenaSpacing.md),
          Text(
            bothSubmitted
                ? 'On compare les scores des deux joueurs…'
                : "Ton adversaire n'a pas encore saisi son score. Le match"
                    ' sera validé dès que ce sera le cas.',
            textAlign: TextAlign.center,
            style: ArenaTypography.bodyMedium.copyWith(
              color: ArenaColors.textMuted,
            ),
          ),
          if (bothSubmitted) ...[
            const SizedBox(height: ArenaSpacing.lg),
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ],
        ],
      ),
    );
  }
}

/// Optimistic interstitial shown after the room code POST succeeds, until
/// the realtime stream pushes the new `status = ready` and the parent
/// swaps in [_RoomReadyView]. Without it, the user sees the loading
/// spinner on the form until the stream catches up — usually fast, but
/// noticeable on slow links.
class _CodeSharedInterstitial extends StatelessWidget {
  const _CodeSharedInterstitial({required this.code});

  final String code;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(ArenaSpacing.lg),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.check_circle,
            size: 56,
            color: ArenaColors.success,
          ),
          const SizedBox(height: ArenaSpacing.md),
          Text(
            'CODE PARTAGÉ',
            style: ArenaTypography.labelLarge.copyWith(
              color: ArenaColors.textMuted,
            ),
          ),
          const SizedBox(height: ArenaSpacing.sm),
          Text(
            code,
            style: ArenaTypography.displayMedium.copyWith(
              fontSize: 40,
              letterSpacing: 4,
            ),
          ),
          const SizedBox(height: ArenaSpacing.lg),
          const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(height: ArenaSpacing.sm),
          Text(
            'Synchronisation avec ton adversaire…',
            style: ArenaTypography.bodyMedium.copyWith(
              color: ArenaColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

/// Forces every typed character to upper-case while keeping the cursor
/// where the user expects it. Used by the room-code field.
class _UpperCaseFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return newValue.copyWith(text: newValue.text.toUpperCase());
  }
}
