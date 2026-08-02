import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/data/models/arena_match.dart';
import 'package:arena/data/repositories/match_repository.dart';
import 'package:arena/features_shared/widgets/arena_button.dart';
import 'package:arena/features_user/match_room/match_room_page.dart'
    show MatchRole;
import 'package:flutter/material.dart';
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

  bool get _selfReady => _isPlayer1
      ? widget.match.player1Ready
      : widget.match.player2Ready;

  bool get _opponentReady => _isPlayer1
      ? widget.match.player2Ready
      : widget.match.player1Ready;

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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Bandeau proéminent : cette étape est TRÈS IMPORTANTE.
        Center(
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: ArenaSpacing.md,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: ArenaColors.neonRed.withValues(alpha: 0.16),
              borderRadius: ArenaRadius.pill,
              border: Border.all(
                color: ArenaColors.neonRed.withValues(alpha: 0.55),
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.warning_amber_rounded,
                    color: ArenaColors.neonRed, size: 18,),
                const SizedBox(width: 6),
                Text(
                  'ÉTAPE IMPORTANTE',
                  style: ArenaText.badge.copyWith(
                    color: ArenaColors.neonRed,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: ArenaSpacing.lg),
        const Icon(Icons.sync, size: 48, color: ArenaColors.signalBlue),
        const SizedBox(height: ArenaSpacing.md),
        Text(
          'Synchronisation',
          textAlign: TextAlign.center,
          style: ArenaText.h2,
        ),
        const SizedBox(height: ArenaSpacing.sm),
        // Consigne mise en avant : texte AGRANDI, en ROUGE, avec une icône
        // d'avertissement à côté.
        Container(
          padding: const EdgeInsets.all(ArenaSpacing.md),
          decoration: BoxDecoration(
            color: ArenaColors.neonRed.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(ArenaRadius.md),
            border: Border.all(
              color: ArenaColors.neonRed.withValues(alpha: 0.45),
              width: 1.5,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                color: ArenaColors.neonRed,
                size: 30,
              ),
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
        const SizedBox(height: ArenaSpacing.xl),

        // Statuts des deux joueurs.
        _ReadyRow(label: 'Toi', ready: _selfReady),
        const SizedBox(height: ArenaSpacing.sm),
        _ReadyRow(label: 'Adversaire', ready: _opponentReady),
        const SizedBox(height: ArenaSpacing.xl),

        if (_selfReady) ...[
          Container(
            padding: const EdgeInsets.all(ArenaSpacing.md),
            decoration: BoxDecoration(
              color: ArenaColors.statusOk.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(ArenaRadius.md),
              border:
                  Border.all(color: ArenaColors.statusOk.withValues(alpha: 0.4)),
            ),
            child: Text(
              _opponentReady
                  ? 'Les deux joueurs sont prêts — le match démarre…'
                  : "En attente de l'adversaire…",
              textAlign: TextAlign.center,
              style: ArenaText.body.copyWith(color: ArenaColors.bone),
            ),
          ),
        ] else
          ArenaButton(
            label: '✅ MON JEU EST OUVERT',
            icon: Icons.check_circle_outline,
            fullWidth: true,
            isLoading: _submitting,
            onPressed: _confirm,
          ),
      ],
    );
  }
}

class _ReadyRow extends StatelessWidget {
  const _ReadyRow({required this.label, required this.ready});

  final String label;
  final bool ready;

  @override
  Widget build(BuildContext context) {
    final color = ready ? ArenaColors.statusOk : ArenaColors.silverDim;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: ArenaSpacing.md,
        vertical: ArenaSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: ArenaColors.carbon,
        borderRadius: BorderRadius.circular(ArenaRadius.md),
        border: Border.all(color: ArenaColors.border),
      ),
      child: Row(
        children: [
          Icon(
            ready ? Icons.check_circle : Icons.hourglass_empty,
            color: color,
            size: 20,
          ),
          const SizedBox(width: ArenaSpacing.sm),
          Expanded(
            child: Text(
              label,
              style: ArenaText.body.copyWith(
                color: ArenaColors.bone,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
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
  }
}
