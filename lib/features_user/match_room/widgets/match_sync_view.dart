import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/data/models/arena_match.dart';
import 'package:arena/data/models/profile.dart';
import 'package:arena/data/repositories/match_repository.dart';
import 'package:arena/features_shared/widgets/arena_avatar.dart';
import 'package:arena/features_shared/widgets/arena_button.dart';
import 'package:arena/features_user/match_room/match_room_page.dart'
    show MatchRole;
import 'package:arena/features_user/match_room/match_room_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// ÉTAPE 0 — Synchronisation. Avant que le processus démarre, les DEUX joueurs
/// confirment mutuellement que leur APPLICATION DE JEU est déjà ouverte. Tant
/// que les deux n'ont pas confirmé, la salle reste ici ; dès que c'est le cas,
/// le déroulé continue automatiquement (l'état arrive en temps réel).
class MatchSyncView extends ConsumerStatefulWidget {
  const MatchSyncView({
    required this.match,
    required this.role,
    super.key,
  });

  final ArenaMatch match;
  final MatchRole role;

  @override
  ConsumerState<MatchSyncView> createState() => _MatchSyncViewState();
}

class _MatchSyncViewState extends ConsumerState<MatchSyncView> {
  bool _submitting = false;

  bool get _isPlayer1 => widget.role == MatchRole.player1;

  bool get _selfReady =>
      _isPlayer1 ? widget.match.player1Ready : widget.match.player2Ready;

  bool get _opponentReady =>
      _isPlayer1 ? widget.match.player2Ready : widget.match.player1Ready;

  Future<void> _confirm() async {
    setState(() => _submitting = true);
    try {
      await ref.read(matchRepositoryProvider).markGameReady(
            matchId: widget.match.id,
            isPlayer1: _isPlayer1,
          );
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur : $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final players = ref.watch(matchPlayersProvider(widget.match.id)).valueOrNull;
    final selfProfile = _isPlayer1 ? players?.p1 : players?.p2;
    final oppProfile = _isPlayer1 ? players?.p2 : players?.p1;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: ArenaSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1 — Eyebrow discret (au lieu d'un 2e bloc rouge criard).
          Text(
            'ÉTAPE 0 · SYNCHRONISATION',
            textAlign: TextAlign.center,
            style: ArenaText.badge.copyWith(
              color: ArenaColors.neonRed,
              fontWeight: FontWeight.w800,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: ArenaSpacing.lg),

          // 1 + 5 — LE point rouge focal : consigne agrandie + icône + halo.
          Container(
            padding: const EdgeInsets.all(ArenaSpacing.lg),
            decoration: BoxDecoration(
              color: ArenaColors.neonRed.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(ArenaRadius.md),
              border: Border.all(
                color: ArenaColors.neonRed.withValues(alpha: 0.5),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: ArenaColors.neonRed.withValues(alpha: 0.22),
                  blurRadius: 22,
                  spreadRadius: -6,
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.warning_amber_rounded,
                    color: ArenaColors.neonRed, size: 32,),
                const SizedBox(width: ArenaSpacing.sm),
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      style: ArenaText.body.copyWith(
                        color: ArenaColors.neonRed,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        height: 1.35,
                      ),
                      children: const [
                        TextSpan(
                          text: "Ouvre D'ABORD ton application de jeu ",
                          style: TextStyle(fontWeight: FontWeight.w900),
                        ),
                        TextSpan(
                          text: "(jusqu'au menu principal), puis confirme "
                              'ci-dessous. ',
                        ),
                        TextSpan(
                          text: 'Le match ne démarre QUE lorsque les DEUX '
                              'joueurs ont confirmé.',
                          style: TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: ArenaSpacing.xxl),

          // 2 — Face-à-face : avatars + état (✓ prêt / ⏳ en attente qui pulse).
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _PlayerFace(
                  name: 'TOI',
                  profile: selfProfile,
                  ready: _selfReady,
                  fallbackColor: ArenaAvatarColor.blue,
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(top: 16),
                child: _VsBadge(),
              ),
              Expanded(
                child: _PlayerFace(
                  name: oppProfile?.username ?? 'Adversaire',
                  profile: oppProfile,
                  ready: _opponentReady,
                  fallbackColor: ArenaAvatarColor.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: ArenaSpacing.xxl),

          // 3 + 5 — Action rouge pleine, ou feedback animé après confirmation.
          if (!_selfReady)
            ArenaButton(
              label: '✅ MON JEU EST OUVERT',
              icon: Icons.check_circle_outline,
              variant: ArenaButtonVariant.danger,
              size: ArenaButtonSize.large,
              fullWidth: true,
              isLoading: _submitting,
              onPressed: _confirm,
            )
          else
            _WaitingCard(bothReady: _opponentReady),
        ],
      ),
    );
  }
}

/// Colonne joueur du face-à-face : avatar + nom + puce d'état.
class _PlayerFace extends StatelessWidget {
  const _PlayerFace({
    required this.name,
    required this.profile,
    required this.ready,
    required this.fallbackColor,
  });

  final String name;
  final Profile? profile;
  final bool ready;
  final ArenaAvatarColor fallbackColor;

  @override
  Widget build(BuildContext context) {
    final initial = name.isEmpty ? '?' : name.characters.first.toUpperCase();
    return Column(
      children: [
        ArenaAvatar(
          initials: initial,
          color: _avatarColorFromHex(profile?.avatarColor) ?? fallbackColor,
          size: ArenaAvatarSize.lg,
          selected: ready,
          imageUrl: profile?.avatarUrl,
        ),
        const SizedBox(height: ArenaSpacing.sm),
        Text(
          name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: ArenaText.body.copyWith(
            color: ArenaColors.bone,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        _StatusChip(ready: ready),
      ],
    );
  }
}

/// Puce d'état : « Prêt » (vert) ou « En attente » (ambre) qui pulse.
class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.ready});

  final bool ready;

  @override
  Widget build(BuildContext context) {
    final color = ready ? ArenaColors.statusOk : ArenaColors.statusWarn;
    final chip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: ArenaRadius.pill,
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(ready ? Icons.check_circle : Icons.hourglass_empty,
              color: color, size: 14,),
          const SizedBox(width: 4),
          Text(
            ready ? 'Prêt' : 'En attente',
            style: ArenaText.small.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
    if (ready) return chip;
    // 3 — pulse tant que le joueur n'a pas confirmé.
    return chip
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .fade(begin: 0.45, end: 1, duration: 700.ms);
  }
}

class _VsBadge extends StatelessWidget {
  const _VsBadge();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: ArenaSpacing.sm),
      child: Text(
        'VS',
        style: ArenaText.h3.copyWith(color: ArenaColors.silverDim),
      ),
    );
  }
}

/// Feedback après confirmation : attente animée, ou « les deux prêts ».
class _WaitingCard extends StatelessWidget {
  const _WaitingCard({required this.bothReady});

  final bool bothReady;

  @override
  Widget build(BuildContext context) {
    final color = bothReady ? ArenaColors.statusOk : ArenaColors.statusWarn;
    return Container(
      padding: const EdgeInsets.all(ArenaSpacing.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(ArenaRadius.md),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
          const SizedBox(width: ArenaSpacing.sm),
          Flexible(
            child: Text(
              bothReady
                  ? 'Les deux joueurs sont prêts — le match démarre…'
                  : "En attente de l'adversaire…",
              textAlign: TextAlign.center,
              style: ArenaText.body.copyWith(color: ArenaColors.bone),
            ),
          ),
        ],
      ),
    );
  }
}

ArenaAvatarColor? _avatarColorFromHex(String? hex) {
  if (hex == null) return null;
  return switch (hex.replaceAll('#', '').trim().toUpperCase()) {
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
