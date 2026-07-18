import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/data/models/competition_enums.dart';
import 'package:arena/data/repositories/profile_repository.dart';
import 'package:arena/features_shared/auth_common/shared_auth_providers.dart';
import 'package:arena/features_shared/widgets/arena_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Sondage OBLIGATOIRE des « jeux d'intérêt », affiché une seule fois au 1er
/// démarrage des NOUVEAUX comptes. Condition serveur : `game_interests IS NULL`
/// (les comptes existants ont été backfillés à `{}` → jamais sollicités).
///
/// À appeler après login depuis un point stable (home). No-op si l'utilisateur
/// a déjà répondu ou si le profil n'est pas encore chargé. Le dialogue est
/// NON dismissible : l'utilisateur doit cocher au moins un jeu pour continuer.
Future<void> maybePromptGameInterests(
  BuildContext context,
  WidgetRef ref,
) async {
  final profile = ref.read(currentProfileProvider).valueOrNull;
  // Profil pas encore hydraté, ou a déjà répondu → rien à faire.
  if (profile == null || profile.hasAnsweredGameInterests) return;
  if (!context.mounted) return;
  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const _GameInterestsDialog(),
  );
}

class _GameInterestsDialog extends ConsumerStatefulWidget {
  const _GameInterestsDialog();

  @override
  ConsumerState<_GameInterestsDialog> createState() =>
      _GameInterestsDialogState();
}

class _GameInterestsDialogState extends ConsumerState<_GameInterestsDialog> {
  final Set<GameType> _selected = <GameType>{};
  bool _submitting = false;
  String? _error;

  /// Couleur d'accent par jeu (alignée sur competitions_list_page.dart).
  Color _colorFor(GameType g) => switch (g) {
        GameType.draughts => ArenaColors.gameDraughts,
        GameType.efootball => ArenaColors.gameEfoot,
        GameType.eaSportsFc => ArenaColors.gameFc,
        GameType.dreamLeague => ArenaColors.gameDream,
      };

  Future<void> _submit() async {
    if (_selected.isEmpty || _submitting) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await ref
          .read(profileRepositoryProvider)
          .setGameInterests(_selected.toList());
      // Rafraîchit le profil courant → `hasAnsweredGameInterests` passe à true,
      // le dialogue ne sera plus reproposé.
      ref.invalidate(currentProfileProvider);
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (mounted) {
        setState(() {
          _submitting = false;
          _error = "Impossible d'enregistrer ton choix. Réessaie.";
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Bloque le back système : le sondage est obligatoire.
    return PopScope(
      canPop: false,
      child: Dialog(
        backgroundColor: ArenaColors.carbon,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ArenaRadius.lg),
        ),
        child: Padding(
          padding: const EdgeInsets.all(ArenaSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.sports_esports,
                    color: ArenaColors.signalBlue,
                    size: 22,
                  ),
                  const SizedBox(width: ArenaSpacing.sm),
                  Expanded(
                    child: Text(
                      "Quels jeux t'intéressent ?",
                      style:
                          ArenaText.body.copyWith(fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: ArenaSpacing.sm),
              Text(
                'Choisis les jeux dont tu veux disputer des compétitions. '
                "On t'enverra les tournois qui correspondent. Tu peux en "
                'cocher plusieurs.',
                style: ArenaText.small.copyWith(color: ArenaColors.silver),
              ),
              const SizedBox(height: ArenaSpacing.md),
              for (final game in GameType.values) ...[
                _GameTile(
                  label: game.label,
                  color: _colorFor(game),
                  selected: _selected.contains(game),
                  onTap: _submitting
                      ? null
                      : () => setState(() {
                            if (!_selected.add(game)) _selected.remove(game);
                          }),
                ),
                const SizedBox(height: ArenaSpacing.sm),
              ],
              if (_error != null) ...[
                const SizedBox(height: ArenaSpacing.xs),
                Text(
                  _error!,
                  style: ArenaText.small.copyWith(color: ArenaColors.neonRed),
                ),
              ],
              const SizedBox(height: ArenaSpacing.sm),
              ArenaButton(
                label: 'Valider',
                fullWidth: true,
                isLoading: _submitting,
                // Désactivé tant qu'aucun jeu n'est coché (sondage = ≥1 jeu).
                onPressed: _selected.isEmpty ? null : _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GameTile extends StatelessWidget {
  const _GameTile({
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final Color color;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(ArenaRadius.md),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: ArenaSpacing.md,
          vertical: ArenaSpacing.md,
        ),
        decoration: BoxDecoration(
          color: selected
              ? color.withValues(alpha: 0.15)
              : ArenaColors.void_,
          borderRadius: BorderRadius.circular(ArenaRadius.md),
          border: Border.all(
            color: selected ? color : ArenaColors.border,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: ArenaSpacing.md),
            Expanded(
              child: Text(
                label,
                style: ArenaText.small.copyWith(
                  fontWeight: FontWeight.w700,
                  color: selected ? Colors.white : ArenaColors.silver,
                ),
              ),
            ),
            Icon(
              selected ? Icons.check_circle : Icons.circle_outlined,
              color: selected ? color : ArenaColors.textMuted,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
