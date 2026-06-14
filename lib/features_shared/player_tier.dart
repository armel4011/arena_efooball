import 'package:arena/core/theme/arena_theme.dart';
import 'package:flutter/material.dart';

/// Palier compétitif d'un joueur, dérivé de son nombre de victoires.
///
/// La règle de tier vit ici (pure, testable) — l'UI ne fait que traduire
/// le libellé associé et appliquer le [PlayerTierVisuals.gradient]. Cela évite de
/// coder en dur un tier "Bronze" partout (cf. bug profil 2026-06-14).
enum PlayerTier {
  /// `< 5` victoires.
  bronze,

  /// `5–14` victoires.
  silver,

  /// `15–29` victoires.
  gold,

  /// `>= 30` victoires.
  elite,
}

extension PlayerTierVisuals on PlayerTier {
  /// Dégradé appliqué au badge de tier. Bronze/Argent/Élite utilisent un
  /// dégradé "plat" (même couleur des deux côtés) ; l'Or garde le dégradé
  /// or chaud → corail déjà en place sur la maquette.
  List<Color> get gradient => switch (this) {
        PlayerTier.bronze => const [
            ArenaColors.tierBronze,
            ArenaColors.tierBronze,
          ],
        PlayerTier.silver => const [
            ArenaColors.silver,
            ArenaColors.pearl,
          ],
        PlayerTier.gold => const [
            ArenaColors.tierGoldWarm,
            ArenaColors.hotCoral,
          ],
        PlayerTier.elite => const [
            ArenaColors.iceCyan,
            ArenaColors.signalBlue,
          ],
      };
}

/// Retourne le palier correspondant à un nombre de [wins].
///
/// Paliers : `<5` → bronze, `5–14` → argent, `15–29` → or, `>=30` → élite.
PlayerTier tierFor(int wins) {
  if (wins >= 30) return PlayerTier.elite;
  if (wins >= 15) return PlayerTier.gold;
  if (wins >= 5) return PlayerTier.silver;
  return PlayerTier.bronze;
}
