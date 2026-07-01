/// PHASE 3 — Abstraction du provider anti-triche (système DUAL).
///
/// ARENA enregistre le gameplay des joueurs comme preuve anti-triche. Deux
/// implémentations COEXISTENT (jamais l'une sans l'autre) :
///
///   * [AntiCheatProviderKind.nativeRecorder] — le recorder d'écran natif
///     MediaProjection (Kotlin `ArenaRecorderService`), historique. Filet de
///     sécurité, JAMAIS supprimé. Riche : overlay flottant, pause/forfait,
///     export galerie, bascule "Live" Agora.
///
///   * [AntiCheatProviderKind.livekitTrackEgress] — capture LiveKit Cloud
///     publish-only + enregistrement serveur via Track Egress (1 piste vidéo
///     par joueur → Supabase Storage). Provider PAR DÉFAUT.
///
/// Un seul provider est ACTIF à la fois (réglage `app_config.anticheat_provider`,
/// cf. `AntiCheatConfigService`). Contrainte MediaProjection (Android 14+) :
/// une seule capture d'écran simultanée — d'où l'exclusivité.
///
/// ⚠️ Le changement de provider n'est JAMAIS rétroactif : un match déjà
/// enregistré garde le provider avec lequel il a tourné.
library;

/// Provider anti-triche disponible. La valeur `wire` est ce qui est persisté
/// dans `app_config` (clé `anticheat_provider`) et lisible par les Edge
/// Functions — d'où un snake_case stable, découplé du nom Dart.
enum AntiCheatProviderKind {
  /// Recorder d'écran natif MediaProjection (filet de sécurité historique).
  nativeRecorder('native_recorder'),

  /// Capture LiveKit Cloud + Track Egress côté serveur (par défaut).
  livekitTrackEgress('livekit_track_egress');

  const AntiCheatProviderKind(this.wire);

  /// Valeur stable persistée en base / lue par le serveur.
  final String wire;

  /// Provider retenu quand le réglage `app_config` est ILLISIBLE (cold start,
  /// blip réseau, table vide). Repli SÛR sur le recorder natif : c'est le
  /// filet de sécurité toujours présent et sans crash (APK targetSdk=35),
  /// alors que LiveKit exige un consentement FGS mediaProjection qui a déjà
  /// crashé l'app à froid sur Android 14+/targetSdk36. Un échec transitoire
  /// de lecture ne doit donc JAMAIS basculer silencieusement sur LiveKit.
  /// NB : le provider ACTIF par défaut (quand la ligne existe) reste piloté
  /// par l'admin via `app_config` — ce fallback ne concerne que l'illisible.
  static const AntiCheatProviderKind fallback =
      AntiCheatProviderKind.nativeRecorder;

  /// Parse tolérante depuis la valeur `wire` (clé `app_config`). Toute valeur
  /// inconnue / nulle retombe sur [fallback].
  static AntiCheatProviderKind fromWire(Object? value) {
    final raw = value is String ? value : null;
    for (final kind in AntiCheatProviderKind.values) {
      if (kind.wire == raw) return kind;
    }
    return fallback;
  }
}

/// Contrat minimal câblé par le cycle de vie du match
/// (`MatchRecordingLifecycle`) : démarrage à l'entrée en jeu, arrêt aux
/// états terminaux. Les capacités spécifiques au recorder natif
/// (pause/forfait/overlay/export) restent hors de ce contrat et ne sont
/// exposées que par son implémentation concrète.
abstract class AntiCheatProvider {
  /// Identité du provider — sert au logging et au choix d'UI (bannière
  /// riche pour le natif, simple pour LiveKit).
  AntiCheatProviderKind get kind;

  /// Démarre la capture anti-triche pour ce joueur sur ce match. Doit être
  /// idempotent vis-à-vis d'un démarrage déjà en cours (lever/ignorer selon
  /// l'implémentation). [opponentId] sert au natif (auto-forfait) ; LiveKit
  /// peut l'ignorer.
  Future<void> startForMatch({
    required String matchId,
    required String playerId,
    String? opponentId,
  });

  /// Arrête proprement la capture et libère les ressources. Idempotent :
  /// un arrêt sur un provider inactif est un no-op.
  Future<void> stopCleanly();

  /// True si une capture est actuellement en cours.
  bool get isCapturing;
}
