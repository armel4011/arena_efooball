/// Helpers partagés pour l'affichage des rangs de récompense d'une
/// compétition. Gardent le wizard admin (`CreateCompetitionPage`) et
/// l'écran joueur (`RegistrationConfirmPage`) alignés sur le même
/// barème visuel, quel que soit le nombre de récompensés.
library;

/// Paliers de récompensés proposés à l'admin dans le wizard de
/// création : 1, puis puissances de 2 jusqu'à 64.
const List<int> kRewardedRankOptions = [1, 2, 4, 8, 16, 32, 64];

/// Nombre maximum de rangs récompensés qu'un admin peut configurer.
const int kMaxRewardedRanks = 64;

/// Emoji du rang : médailles pour le podium, 🏅 au-delà.
String prizeRankEmoji(int position) => switch (position) {
      0 => '🥇',
      1 => '🥈',
      2 => '🥉',
      _ => '🏅',
    };

/// Libellé ordinal du rang : « 1ʳᵉ », « 2ᵉ », … « 16ᵉ ».
String prizeRankLabel(int position) =>
    position == 0 ? '1ʳᵉ' : '${position + 1}ᵉ';
