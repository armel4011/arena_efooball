import 'dart:async';

import 'package:arena/core/router/user_router.dart';
import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/data/models/arena_match.dart';
import 'package:arena/data/models/match_status.dart';
import 'package:arena/data/models/profile.dart';
import 'package:arena/data/repositories/match_repository.dart';
import 'package:arena/data/repositories/profile_repository.dart';
import 'package:arena/features_shared/widgets/arena_app_bar.dart';
import 'package:arena/features_shared/widgets/arena_avatar.dart';
import 'package:arena/features_shared/widgets/arena_button.dart';
import 'package:arena/features_shared/widgets/empty_state.dart';
import 'package:arena/features_shared/widgets/error_state.dart';
import 'package:arena/features_user/auth/auth_providers.dart';
import 'package:arena/features_user/match_room/widgets/manual_upload_button.dart';
import 'package:arena/features_user/match_room/widgets/match_recording_lifecycle.dart';
import 'package:arena/features_user/streaming/start_streaming_banner.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// Optimistic state survives remounts (back-to-bracket-and-return). Lives
// outside the widget tree.
final _pendingScoreSubmissionProvider =
    StateProvider.family<Map<String, dynamic>?, String>((ref, matchId) => null);
final _pendingRoomCodeProvider =
    StateProvider.family<String?, String>((ref, matchId) => null);

/// Loads the two players' profiles in parallel for the match header.
final _matchPlayersProvider =
    FutureProvider.family<_MatchPlayers, String>((ref, matchId) async {
  final match = await ref.watch(matchByIdProvider(matchId).future);
  if (match == null) return const _MatchPlayers(p1: null, p2: null);
  final repo = ref.watch(profileRepositoryProvider);
  final p1 = match.player1Id == null ? null : await repo.getById(match.player1Id!);
  final p2 = match.player2Id == null ? null : await repo.getById(match.player2Id!);
  return _MatchPlayers(p1: p1, p2: p2);
});

class _MatchPlayers {
  const _MatchPlayers({required this.p1, required this.p2});
  final Profile? p1;
  final Profile? p2;
}

/// Maps the match status onto the four-step v2 progress indicator.
///
/// Steps follow the v2 mockup (`docs/arena_v2.html` line 799+):
///   1 — Code room  (HOME shares the code)
///   2 — Adversaire rejoint  (AWAY confirms in the room)
///   3 — Match en cours  (recording / score submission)
///   4 — Score validé  (terminal: completed / disputed / forfeited)
enum _MatchStep {
  codeRoom(1, 'Code room'),
  opponentJoining(2, 'Adversaire rejoint'),
  matchInProgress(3, 'Match en cours'),
  result(4, 'Résultat');

  const _MatchStep(this.number, this.label);

  final int number;
  final String label;

  static _MatchStep fromStatus(MatchStatus s) => switch (s) {
        MatchStatus.pending || MatchStatus.scheduled => _MatchStep.codeRoom,
        MatchStatus.ready => _MatchStep.opponentJoining,
        MatchStatus.inProgress ||
        MatchStatus.scorePending ||
        MatchStatus.awaitingValidation =>
          _MatchStep.matchInProgress,
        MatchStatus.completed ||
        MatchStatus.disputed ||
        MatchStatus.forfeited ||
        MatchStatus.cancelled =>
          _MatchStep.result,
      };
}

/// PHASE 5 + v2 redesign — Match Room shell.
///
/// Layout per `docs/arena_v2.html` #11: ArenaAppBar → 4-step progress →
/// player avatars (HOME/AWAY) → step-specific body. The scoring,
/// recording-lifecycle and streaming-banner wiring from v1 stays intact;
/// only the chrome and the share-code / room-ready surfaces are restyled
/// to match the v2 mockup.
class MatchRoomPage extends ConsumerWidget {
  const MatchRoomPage({required this.matchId, super.key});

  final String matchId;

  @override
  Widget build(BuildContext context, WidgetRef widgetRef) {
    final async = widgetRef.watch(matchByIdProvider(matchId));
    final selfId = widgetRef.watch(currentSessionProvider)?.user.id;
    final loadedMatch = async.value;
    final isPlayer = loadedMatch != null &&
        MatchRole.resolve(match: loadedMatch, selfId: selfId) !=
            MatchRole.observer;

    return PopScope(
      // The bracket reads `competitionMatchesProvider` as a Future; refresh
      // it on every exit so a status change here shows up without a manual
      // pull-to-refresh.
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) widgetRef.invalidate(competitionMatchesProvider);
      },
      child: Scaffold(
        appBar: ArenaAppBar(
          title: async.value?.matchNumber == null
              ? 'MATCH'
              : 'MATCH #${async.value!.matchNumber}',
          onBack: () {
            widgetRef.invalidate(competitionMatchesProvider);
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(UserRoutes.home);
            }
          },
          actions: [
            if (isPlayer)
              IconButton(
                icon: const Icon(
                  Icons.chat_bubble_outline,
                  color: ArenaColors.gameEfoot,
                ),
                tooltip: 'Chat avec ton adversaire',
                onPressed: () =>
                    context.push(UserRoutes.matchChatPath(matchId)),
              ),
          ],
        ),
        body: async.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => ErrorState(
            description: e.toString(),
            onRetry: () => widgetRef.invalidate(matchByIdProvider(matchId)),
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
            return _MatchRoomBody(match: m, role: role, selfId: selfId);
          },
        ),
      ),
    );
  }
}

/// Where the current user stands relative to the match.
enum MatchRole {
  player1,
  player2,
  observer;

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

class _MatchRoomBody extends ConsumerWidget {
  const _MatchRoomBody({
    required this.match,
    required this.role,
    required this.selfId,
  });

  final ArenaMatch match;
  final MatchRole role;
  final String? selfId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final players = ref.watch(_matchPlayersProvider(match.id));
    final step = _MatchStep.fromStatus(match.status);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        ArenaSpacing.lg,
        ArenaSpacing.md,
        ArenaSpacing.lg,
        ArenaSpacing.xxl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _StepIndicator(step: step),
          const SizedBox(height: ArenaSpacing.sm),
          _StepLabel(step: step),
          const SizedBox(height: ArenaSpacing.lg),
          _PlayersHeader(
            match: match,
            role: role,
            p1: players.value?.p1,
            p2: players.value?.p2,
          ),
          // Anti-cheat recording banner (Android-only, no-op elsewhere).
          MatchRecordingLifecycle(match: match, selfId: selfId),
          if (role != MatchRole.observer)
            StartStreamingBanner(matchId: match.id),
          const SizedBox(height: ArenaSpacing.lg),
          _StepBody(match: match, role: role, selfId: selfId),
        ],
      ),
    );
  }
}

class _StepIndicator extends StatelessWidget {
  const _StepIndicator({required this.step});

  final _MatchStep step;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(4, (i) {
        final active = i + 1 <= step.number;
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(right: i == 3 ? 0 : 6),
            height: 4,
            decoration: BoxDecoration(
              color: active ? ArenaColors.signalBlue : ArenaColors.borderHi,
              borderRadius: BorderRadius.circular(2),
              boxShadow: active && i + 1 == step.number
                  ? [
                      BoxShadow(
                        color: ArenaColors.signalBlue.withValues(alpha: 0.45),
                        blurRadius: 12,
                      ),
                    ]
                  : null,
            ),
          ),
        );
      }),
    );
  }
}

class _StepLabel extends StatelessWidget {
  const _StepLabel({required this.step});

  final _MatchStep step;

  @override
  Widget build(BuildContext context) {
    return Text(
      'Étape ${step.number} / 4 — ${step.label}',
      style: ArenaText.small.copyWith(color: ArenaColors.silver),
    );
  }
}

class _PlayersHeader extends StatelessWidget {
  const _PlayersHeader({
    required this.match,
    required this.role,
    required this.p1,
    required this.p2,
  });

  final ArenaMatch match;
  final MatchRole role;
  final Profile? p1;
  final Profile? p2;

  @override
  Widget build(BuildContext context) {
    final p1IsHome = match.homePlayerId != null &&
        match.homePlayerId == match.player1Id;
    final p2IsHome = match.homePlayerId != null &&
        match.homePlayerId == match.player2Id;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _PlayerSeat(
            profile: p1,
            seatLabel: 'Joueur 1',
            isSelf: role == MatchRole.player1,
            isHome: p1IsHome,
            fallbackColor: ArenaAvatarColor.blue,
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 14),
          child: Text(
            'VS',
            style: ArenaText.h2.copyWith(color: ArenaColors.silverDim),
          ),
        ),
        Expanded(
          child: _PlayerSeat(
            profile: p2,
            seatLabel: 'Joueur 2',
            isSelf: role == MatchRole.player2,
            isHome: p2IsHome,
            fallbackColor: ArenaAvatarColor.green,
          ),
        ),
      ],
    );
  }
}

class _PlayerSeat extends StatelessWidget {
  const _PlayerSeat({
    required this.profile,
    required this.seatLabel,
    required this.isSelf,
    required this.isHome,
    required this.fallbackColor,
  });

  final Profile? profile;
  final String seatLabel;
  final bool isSelf;
  final bool isHome;
  final ArenaAvatarColor fallbackColor;

  @override
  Widget build(BuildContext context) {
    final username = profile?.username ?? seatLabel;
    final initial =
        username.isEmpty ? '?' : username.characters.first.toUpperCase();
    final color = profile == null
        ? fallbackColor
        : _avatarColorFromHex(profile!.avatarColor) ?? fallbackColor;

    return Column(
      children: [
        ArenaAvatar(
          initials: initial,
          color: color,
          size: ArenaAvatarSize.lg,
          selected: isSelf,
        ),
        const SizedBox(height: ArenaSpacing.sm),
        Text(
          isSelf ? '$username · TOI' : username,
          style: ArenaText.body.copyWith(
            color: ArenaColors.bone,
            fontWeight: FontWeight.w700,
          ),
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 6),
        if (isHome)
          const _SeatBadge(label: 'HOME', color: ArenaColors.signalBlue)
        else if (profile != null)
          const _SeatBadge(label: 'AWAY', color: ArenaColors.statusWarn),
      ],
    );
  }
}

class _SeatBadge extends StatelessWidget {
  const _SeatBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: ArenaRadius.pill,
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: ArenaText.badge.copyWith(color: color, fontSize: 9),
      ),
    );
  }
}

class _StepBody extends StatelessWidget {
  const _StepBody({
    required this.match,
    required this.role,
    required this.selfId,
  });

  final ArenaMatch match;
  final MatchRole role;
  final String? selfId;

  @override
  Widget build(BuildContext context) {
    return switch (match.status) {
      MatchStatus.pending || MatchStatus.scheduled => role ==
              MatchRole.observer
          ? const _ObserverWaitingPlaceholder(
              icon: Icons.vpn_key_outlined,
              title: 'En attente du code room',
              description: 'Les joueurs vont créer une room dans le jeu et'
                  ' partager le code ici.',
            )
          : _ShareCodeForm(match: match),
      MatchStatus.ready => _RoomReadyView(match: match, role: role),
      MatchStatus.inProgress ||
      MatchStatus.scorePending ||
      MatchStatus.awaitingValidation =>
        role == MatchRole.observer
            ? const _ObserverWaitingPlaceholder(
                icon: Icons.sports_esports,
                title: 'Match en cours',
                description: 'Les joueurs sont en train de jouer ou de'
                    ' valider le score.',
              )
            : _ScoreFlowView(match: match, role: role),
      MatchStatus.disputed => _DisputedView(match: match, selfId: selfId),
      MatchStatus.completed => _CompletedView(match: match, selfId: selfId),
      MatchStatus.cancelled => const _TerminalCard(
          icon: Icons.block,
          color: ArenaColors.silverDim,
          title: 'MATCH ANNULÉ',
          description: "L'admin a annulé ce match.",
        ),
      MatchStatus.forfeited => const _TerminalCard(
          icon: Icons.exit_to_app,
          color: ArenaColors.neonRed,
          title: 'FORFAIT',
          description: "L'un des joueurs n'a pas démarré à temps.",
        ),
    };
  }
}

class _ObserverWaitingPlaceholder extends StatelessWidget {
  const _ObserverWaitingPlaceholder({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: ArenaSpacing.xxl),
      child: EmptyState(
        icon: icon,
        title: title,
        description: description,
      ),
    );
  }
}

// ─── Step 1 — Share the room code (cyan dashed input + forfeit timer) ────

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
    ref.read(_pendingRoomCodeProvider(widget.match.id).notifier).state = raw;
    setState(() => _submitting = false);
  }

  @override
  Widget build(BuildContext context) {
    final optimisticCode =
        ref.watch(_pendingRoomCodeProvider(widget.match.id));
    if (optimisticCode != null) {
      return _CodeSharedInterstitial(
        code: optimisticCode,
        matchId: widget.match.id,
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'CODE ROOM (HOME CRÉE)',
          style: ArenaText.inputLabel,
        ),
        const SizedBox(height: ArenaSpacing.sm),
        _CyanDashedContainer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Saisis ton code eFootball :',
                textAlign: TextAlign.center,
                style: ArenaText.bodyMuted.copyWith(
                  color: ArenaColors.silver,
                ),
              ),
              const SizedBox(height: ArenaSpacing.sm),
              _CodeInput(
                controller: _controller,
                enabled: !_submitting,
              ),
              const SizedBox(height: ArenaSpacing.sm),
              Text(
                widget.match.player2Id == null
                    ? 'Ton adversaire recevra ce code au chat dès envoi.'
                    : 'Ton adversaire reçoit ce code au chat dès envoi.',
                textAlign: TextAlign.center,
                style: ArenaText.small.copyWith(color: ArenaColors.silver),
              ),
            ],
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: ArenaSpacing.sm),
          Text(
            _error!,
            style: ArenaText.bodyMuted.copyWith(color: ArenaColors.neonRed),
          ),
        ],
        if (widget.match.scheduledAt != null) ...[
          const SizedBox(height: ArenaSpacing.lg),
          _ForfeitTimerCard(scheduledAt: widget.match.scheduledAt!),
        ],
        const SizedBox(height: ArenaSpacing.lg),
        ArenaButton(
          label: 'ENVOYER LE CODE',
          icon: Icons.send_outlined,
          fullWidth: true,
          isLoading: _submitting,
          onPressed: _submit,
        ),
        const SizedBox(height: ArenaSpacing.sm),
        _OpenChatLink(matchId: widget.match.id),
      ],
    );
  }
}

class _CodeInput extends StatelessWidget {
  const _CodeInput({required this.controller, required this.enabled});

  final TextEditingController controller;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      enabled: enabled,
      autofocus: true,
      maxLength: 12,
      textAlign: TextAlign.center,
      textCapitalization: TextCapitalization.characters,
      textInputAction: TextInputAction.done,
      style: ArenaText.roomCode.copyWith(
        color: ArenaColors.bone,
        fontSize: 22,
        letterSpacing: 4,
      ),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp('[A-Za-z0-9-]')),
        _UpperCaseFormatter(),
      ],
      decoration: InputDecoration(
        hintText: 'Ex: 8K3-TZ9',
        hintStyle: ArenaText.body.copyWith(
          color: ArenaColors.silverDim,
          letterSpacing: 4,
        ),
        counterText: '',
        filled: true,
        fillColor: ArenaColors.void_,
        contentPadding: const EdgeInsets.symmetric(
          vertical: ArenaSpacing.md,
          horizontal: ArenaSpacing.lg,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ArenaRadius.md),
          borderSide: const BorderSide(color: ArenaColors.gameEfoot, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ArenaRadius.md),
          borderSide: const BorderSide(color: ArenaColors.gameEfoot, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ArenaRadius.md),
          borderSide: const BorderSide(color: ArenaColors.gameEfoot, width: 2),
        ),
      ),
    );
  }
}

class _CyanDashedContainer extends StatelessWidget {
  const _CyanDashedContainer({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedBorderPainter(
        color: ArenaColors.gameEfoot,
        radius: ArenaRadius.lg,
      ),
      child: Container(
        padding: const EdgeInsets.all(ArenaSpacing.lg),
        decoration: BoxDecoration(
          color: ArenaColors.gameEfoot.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(ArenaRadius.lg),
        ),
        child: child,
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  _DashedBorderPainter({required this.color, required this.radius});

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Radius.circular(radius),
    );
    final path = Path()..addRRect(rect);
    final dashed = _dashPath(path, dashLength: 6, gapLength: 4);
    canvas.drawPath(dashed, paint);
  }

  Path _dashPath(
    Path source, {
    required double dashLength,
    required double gapLength,
  }) {
    final dest = Path();
    for (final metric in source.computeMetrics()) {
      double dist = 0;
      while (dist < metric.length) {
        dest.addPath(
          metric.extractPath(dist, dist + dashLength),
          Offset.zero,
        );
        dist += dashLength + gapLength;
      }
    }
    return dest;
  }

  @override
  bool shouldRepaint(_DashedBorderPainter old) =>
      old.color != color || old.radius != radius;
}

class _ForfeitTimerCard extends StatefulWidget {
  const _ForfeitTimerCard({required this.scheduledAt});

  final DateTime scheduledAt;

  @override
  State<_ForfeitTimerCard> createState() => _ForfeitTimerCardState();
}

class _ForfeitTimerCardState extends State<_ForfeitTimerCard> {
  static const _forfeitWindow = Duration(minutes: 10);
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final deadline = widget.scheduledAt.add(_forfeitWindow);
    final remaining = deadline.difference(DateTime.now());
    final mmss = _format(remaining);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: ArenaSpacing.lg,
        vertical: ArenaSpacing.md,
      ),
      decoration: arenaWarningCardDecoration(),
      child: Row(
        children: [
          const Icon(
            Icons.timer_outlined,
            color: ArenaColors.statusWarn,
            size: 18,
          ),
          const SizedBox(width: ArenaSpacing.sm),
          Expanded(
            child: Text(
              'Timer forfait auto',
              style: ArenaText.body.copyWith(
                color: ArenaColors.bone,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            mmss,
            style: ArenaText.monoLg.copyWith(color: ArenaColors.statusWarn),
          ),
        ],
      ),
    );
  }

  String _format(Duration d) {
    if (d.isNegative) return '00:00';
    final mm = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final ss = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$mm:$ss';
  }
}

class _OpenChatLink extends StatelessWidget {
  const _OpenChatLink({required this.matchId});

  final String matchId;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ArenaButton(
        label: 'OUVRIR LE CHAT',
        icon: Icons.chat_bubble_outline,
        variant: ArenaButtonVariant.ghost,
        onPressed: () => context.push(UserRoutes.matchChatPath(matchId)),
      ),
    );
  }
}

// ─── Step 2 — Code shared, opponent joining ──────────────────────────────

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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'CODE DE LA ROOM',
          style: ArenaText.inputLabel,
        ),
        const SizedBox(height: ArenaSpacing.sm),
        _CyanDashedContainer(
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: SelectableText(
                      code ?? '—',
                      textAlign: TextAlign.center,
                      style: ArenaText.roomCode.copyWith(fontSize: 28),
                    ),
                  ),
                  if (code != null)
                    IconButton(
                      icon: const Icon(Icons.copy_outlined, size: 18),
                      tooltip: 'Copier le code',
                      color: ArenaColors.silver,
                      onPressed: () => _copyCode(code),
                    ),
                ],
              ),
              const SizedBox(height: ArenaSpacing.sm),
              Text(
                hint,
                textAlign: TextAlign.center,
                style: ArenaText.small.copyWith(color: ArenaColors.silver),
              ),
            ],
          ),
        ),
        if (widget.match.scheduledAt != null) ...[
          const SizedBox(height: ArenaSpacing.lg),
          _ForfeitTimerCard(scheduledAt: widget.match.scheduledAt!),
        ],
        if (isPlayer) ...[
          const SizedBox(height: ArenaSpacing.lg),
          ArenaButton(
            label: 'JE SUIS DANS LA ROOM',
            icon: Icons.play_arrow_rounded,
            fullWidth: true,
            isLoading: _submitting,
            onPressed: _markStarted,
          ),
          const SizedBox(height: ArenaSpacing.sm),
          _OpenChatLink(matchId: widget.match.id),
        ],
      ],
    );
  }
}

class _CodeSharedInterstitial extends StatelessWidget {
  const _CodeSharedInterstitial({required this.code, required this.matchId});

  final String code;
  final String matchId;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('CODE DE LA ROOM', style: ArenaText.inputLabel),
        const SizedBox(height: ArenaSpacing.sm),
        _CyanDashedContainer(
          child: Column(
            children: [
              const Icon(
                Icons.check_circle,
                color: ArenaColors.statusOk,
                size: 28,
              ),
              const SizedBox(height: ArenaSpacing.xs),
              Text(
                'CODE PARTAGÉ',
                style: ArenaText.inputLabel.copyWith(
                  color: ArenaColors.statusOk,
                ),
              ),
              const SizedBox(height: ArenaSpacing.sm),
              Text(
                code,
                textAlign: TextAlign.center,
                style: ArenaText.roomCode.copyWith(fontSize: 28),
              ),
              const SizedBox(height: ArenaSpacing.sm),
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(height: ArenaSpacing.xs),
              Text(
                'Synchronisation avec ton adversaire…',
                textAlign: TextAlign.center,
                style: ArenaText.small.copyWith(color: ArenaColors.silver),
              ),
            ],
          ),
        ),
        const SizedBox(height: ArenaSpacing.lg),
        _OpenChatLink(matchId: matchId),
      ],
    );
  }
}

// ─── Step 3 — Score submission flow ──────────────────────────────────────

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
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: ArenaSpacing.xxl),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => ErrorState(
        description: e.toString(),
        onRetry: () => ref.invalidate(
          matchScoreSubmissionsProvider(widget.match.id),
        ),
      ),
      data: (submissions) {
        final byPlayer = <String, Map<String, dynamic>>{};
        for (final s in submissions) {
          final by = s['created_by'] as String?;
          if (by != null) byPlayer[by] = s;
        }
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'SAISIS LE SCORE FINAL',
          style: ArenaText.inputLabel,
        ),
        const SizedBox(height: ArenaSpacing.sm),
        Text(
          'Entre les buts de chaque côté. Si vos deux saisies'
          ' concordent, le match est validé automatiquement.',
          style: ArenaText.bodyMuted,
        ),
        const SizedBox(height: ArenaSpacing.lg),
        Row(
          children: [
            Expanded(
              child: _ScoreField(
                label: 'Mon score',
                controller: _myScoreCtrl,
                enabled: !_submitting,
                action: TextInputAction.next,
              ),
            ),
            const SizedBox(width: ArenaSpacing.md),
            Expanded(
              child: _ScoreField(
                label: 'Score adversaire',
                controller: _oppScoreCtrl,
                enabled: !_submitting,
                action: _isKnockout
                    ? TextInputAction.next
                    : TextInputAction.done,
              ),
            ),
          ],
        ),
        if (_isKnockout) ...[
          const SizedBox(height: ArenaSpacing.md),
          SwitchListTile.adaptive(
            title: Text(
              'Match décidé aux tirs au but',
              style: ArenaText.body,
            ),
            subtitle: Text(
              'À cocher uniquement si le score réglementaire est à égalité.',
              style: ArenaText.small.copyWith(color: ArenaColors.silver),
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
                  child: _ScoreField(
                    label: 'Mes tirs au but',
                    controller: _myPenCtrl,
                    enabled: !_submitting,
                    action: TextInputAction.next,
                  ),
                ),
                const SizedBox(width: ArenaSpacing.md),
                Expanded(
                  child: _ScoreField(
                    label: 'Tirs adversaire',
                    controller: _oppPenCtrl,
                    enabled: !_submitting,
                    action: TextInputAction.done,
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
            style: ArenaText.bodyMuted.copyWith(color: ArenaColors.neonRed),
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
        const SizedBox(height: ArenaSpacing.sm),
        _OpenChatLink(matchId: widget.match.id),
      ],
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

    return Container(
      padding: const EdgeInsets.all(ArenaSpacing.lg),
      decoration: arenaWarningCardDecoration(),
      child: Column(
        children: [
          Icon(
            bothSubmitted ? Icons.hourglass_top : Icons.hourglass_bottom,
            color: ArenaColors.statusWarn,
            size: 32,
          ),
          const SizedBox(height: ArenaSpacing.sm),
          Text(
            bothSubmitted
                ? 'VALIDATION EN COURS'
                : 'EN ATTENTE DE TON ADVERSAIRE',
            style: ArenaText.inputLabel.copyWith(
              color: ArenaColors.statusWarn,
            ),
          ),
          const SizedBox(height: ArenaSpacing.sm),
          Text(
            'Tu as soumis : $myGoals — $oppGoals',
            style: ArenaText.h2,
          ),
          if (viaPen && myPen != null && oppPen != null) ...[
            const SizedBox(height: 4),
            Text(
              'Aux tirs au but : $myPen — $oppPen',
              style: ArenaText.small.copyWith(color: ArenaColors.silver),
            ),
          ],
          const SizedBox(height: ArenaSpacing.sm),
          Text(
            bothSubmitted
                ? 'On compare les scores des deux joueurs…'
                : "Ton adversaire n'a pas encore saisi son score.",
            textAlign: TextAlign.center,
            style: ArenaText.small.copyWith(color: ArenaColors.silver),
          ),
          if (bothSubmitted) ...[
            const SizedBox(height: ArenaSpacing.md),
            const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ],
        ],
      ),
    );
  }
}

class _ScoreField extends StatelessWidget {
  const _ScoreField({
    required this.label,
    required this.controller,
    required this.enabled,
    required this.action,
  });

  final String label;
  final TextEditingController controller;
  final bool enabled;
  final TextInputAction action;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: ArenaText.inputLabel),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          enabled: enabled,
          keyboardType: TextInputType.number,
          textInputAction: action,
          maxLength: 2,
          textAlign: TextAlign.center,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: ArenaText.h2,
          decoration: const InputDecoration(
            hintText: '0',
            counterText: '',
            filled: true,
            fillColor: ArenaColors.carbon,
          ),
        ),
      ],
    );
  }
}

// ─── Step 4 — Result (completed / disputed / cancelled / forfeited) ─────

class _CompletedView extends StatelessWidget {
  const _CompletedView({required this.match, required this.selfId});

  final ArenaMatch match;
  final String? selfId;

  bool get _isPlayer =>
      selfId != null &&
      (selfId == match.player1Id || selfId == match.player2Id);

  @override
  Widget build(BuildContext context) {
    final s1 = match.score1 ?? 0;
    final s2 = match.score2 ?? 0;
    return Container(
      padding: const EdgeInsets.all(ArenaSpacing.xl),
      decoration: arenaSuccessCardDecoration(),
      child: Column(
        children: [
          const Icon(
            Icons.emoji_events,
            color: ArenaColors.statusWarn,
            size: 56,
          ),
          const SizedBox(height: ArenaSpacing.sm),
          Text('SCORE FINAL', style: ArenaText.inputLabel),
          const SizedBox(height: ArenaSpacing.sm),
          Text(
            '$s1 — $s2',
            style: ArenaText.bigNumber.copyWith(fontSize: 48),
          ),
          const SizedBox(height: ArenaSpacing.sm),
          Text(
            match.winnerId == null
                ? 'Match nul.'
                : 'Gagnant : Joueur ${match.winnerId!.substring(0, 6)}…',
            style: ArenaText.bodyMuted,
          ),
          if (_isPlayer) ...[
            const SizedBox(height: ArenaSpacing.lg),
            ManualUploadButton(matchId: match.id, playerId: selfId!),
          ],
        ],
      ),
    );
  }
}

class _DisputedView extends StatelessWidget {
  const _DisputedView({required this.match, required this.selfId});

  final ArenaMatch match;
  final String? selfId;

  bool get _isPlayer =>
      selfId != null &&
      (selfId == match.player1Id || selfId == match.player2Id);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(ArenaSpacing.xl),
      decoration: arenaDangerCardDecoration(),
      child: Column(
        children: [
          const Icon(Icons.gavel, color: ArenaColors.neonRed, size: 48),
          const SizedBox(height: ArenaSpacing.sm),
          Text(
            'LITIGE EN COURS',
            style: ArenaText.inputLabel.copyWith(color: ArenaColors.neonRed),
          ),
          const SizedBox(height: ArenaSpacing.sm),
          Text(
            'Vos scores ne concordent pas. Un admin va trancher. Tu peux '
            'envoyer une vidéo du match pour appuyer ta version.',
            textAlign: TextAlign.center,
            style: ArenaText.bodyMuted,
          ),
          if (_isPlayer) ...[
            const SizedBox(height: ArenaSpacing.lg),
            ManualUploadButton(matchId: match.id, playerId: selfId!),
          ],
        ],
      ),
    );
  }
}

class _TerminalCard extends StatelessWidget {
  const _TerminalCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(ArenaSpacing.xl),
      decoration: BoxDecoration(
        color: ArenaColors.carbon,
        border: Border.all(color: color.withValues(alpha: 0.4)),
        borderRadius: BorderRadius.circular(ArenaRadius.lg),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 48),
          const SizedBox(height: ArenaSpacing.sm),
          Text(
            title,
            style: ArenaText.inputLabel.copyWith(color: color),
          ),
          const SizedBox(height: ArenaSpacing.sm),
          Text(
            description,
            textAlign: TextAlign.center,
            style: ArenaText.bodyMuted,
          ),
        ],
      ),
    );
  }
}

// ─── Helpers ─────────────────────────────────────────────────────────────

class _UpperCaseFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return newValue.copyWith(text: newValue.text.toUpperCase());
  }
}

ArenaAvatarColor? _avatarColorFromHex(String hex) {
  final cleaned = hex.replaceAll('#', '').trim().toUpperCase();
  return switch (cleaned) {
    '4C7AFF' => ArenaAvatarColor.blue,
    'FF2D55' => ArenaAvatarColor.red,
    '00C896' => ArenaAvatarColor.green,
    'F77F00' => ArenaAvatarColor.orange,
    '00B4D8' => ArenaAvatarColor.cyan,
    '9D4EDD' => ArenaAvatarColor.purple,
    'FF6B9D' => ArenaAvatarColor.pink,
    'FFD700' => ArenaAvatarColor.yellow,
    _ => null,
  };
}
