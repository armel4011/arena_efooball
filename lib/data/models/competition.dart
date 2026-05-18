import 'package:arena/data/models/competition_enums.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'competition.freezed.dart';
part 'competition.g.dart';

/// Mirror of the `competitions` table.
///
/// Snake-case columns are mapped automatically via `fieldRename: snake`.
/// Custom converters bridge Postgres enum strings (`'efootball'`,
/// `'registration_open'`, `'single_elimination'`) and Dart enums.
@Freezed(fromJson: true, toJson: true)
sealed class Competition with _$Competition {
  const factory Competition({
    // ─── required ──────────────────────────────────────────────────────────
    required String id,
    required String name,
    @GameTypeConverter() required GameType game,
    @TournamentFormatConverter() required TournamentFormat format,
    required DateTime startDate,

    // ─── defaults ──────────────────────────────────────────────────────────
    @CompetitionStatusConverter()
    @Default(CompetitionStatus.draft)
    CompetitionStatus status,
    @Default(2) int maxPlayers,
    @Default(0) int currentPlayers,
    @Default(0) double registrationFee,
    @Default('XAF') String registrationCurrency,
    @Default(10) double commissionPct,
    @Default(0) double prizePoolLocal,
    @Default(0) double commissionXaf,
    @Default(0) double sponsorBonusLocal,

    // ─── optional / nullable ───────────────────────────────────────────────
    String? description,
    String? bannerUrl,
    DateTime? registrationOpensAt,
    DateTime? registrationClosesAt,
    DateTime? endDate,
    String? prizePoolCurrency,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,

    /// Merchant codes saisis par l'admin créateur — affichés sur P2
    /// quand le joueur choisit la méthode correspondante. PHASE 11bis.
    String? orangeMoneyCode,
    String? mtnMomoCode,

    /// Répartition des gains par rang d'arrivée, en **montants** (monnaie
    /// locale, ex. `[100000, 50000, 25000, 10000]`). Saisie dans le
    /// wizard admin ; `prizePoolLocal` en est la somme.
    @Default(<int>[0, 0, 0, 0]) List<int> prizeDistribution,

    /// Minutes entre la fin d'un round et le scheduled_at du round suivant
    /// (Lot A — auto-management). Typiquement 30/60/120/240/1440.
    /// Le trigger DB `try_schedule_next_round` lit cette valeur.
    @Default(60) int matchIntervalMinutes,

    /// Si vrai, le bracket est généré automatiquement dès que max_players
    /// est atteint. V1 : single_elimination uniquement. Le trigger DB
    /// `trigger_auto_generate_bracket` consume ce flag.
    @Default(true) bool autoGenerateBracket,

    /// Lot D — quota de parrainages requis avant qu'un joueur puisse
    /// s'inscrire. 0 = pas de gating (la majorité des comp.). Utilisé
    /// uniquement pour les comp. gratuites avec récompense (variante
    /// « invite N amis pour t'inscrire »). Trigger DB
    /// `enforce_referral_quota_on_registration` consume cette colonne.
    @Default(0) int referralQuota,

    /// Lot D.2 — Pondération du compteur parrainage.
    /// - `'any'`  : tous les filleuls actifs comptent (défaut)
    /// - `'engaged'` : seulement ceux ayant joué un match OU payé une
    ///   inscription. Bloque l'astuce "10 faux comptes" pour bypasser.
    @Default('any') String referralActivityMode,

    /// Lot A.2 — Overrides d'intervalle par round (en minutes). Null =
    /// utilise `matchIntervalMinutes` global. `roundIntervals[N-1]` =
    /// délai après le round N.
    List<int>? roundIntervals,

    /// Lot F.1 — Config dépendante du format. Pour `groups_then_knockout`,
    /// peut contenir `{group_count: int, qualifiers_per_group: int}`.
    /// Defaults serveur : 4 groupes × 2 qualifiés.
    @Default(<String, dynamic>{}) Map<String, dynamic> formatConfig,
  }) = _Competition;

  const Competition._();

  factory Competition.fromJson(Map<String, dynamic> json) =>
      _$CompetitionFromJson(json);

  // ─── Computed helpers ────────────────────────────────────────────────────

  /// `true` quand la compétition est gratuite (frais d'inscription = 0).
  /// L'inscription bypass alors le flow paiement P1-P5.
  bool get isFree => registrationFee == 0;

  /// `true` when registration is officially open AND there's still room.
  bool get canRegister =>
      status.isRegistrationOpen && currentPlayers < maxPlayers;

  /// `true` once the bracket / group phase has started.
  bool get hasStarted => status.isOngoing || status.isCompleted;

  /// `currentPlayers / maxPlayers`, clamped to [0, 1].
  double get fillRatio {
    if (maxPlayers <= 0) return 0;
    final r = currentPlayers / maxPlayers;
    return r.clamp(0, 1).toDouble();
  }

  int get spotsLeft {
    final left = maxPlayers - currentPlayers;
    return left < 0 ? 0 : left;
  }
}
