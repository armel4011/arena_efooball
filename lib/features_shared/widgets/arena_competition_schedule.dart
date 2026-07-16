import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/core/utils/date_formatter.dart';
import 'package:arena/data/models/arena_match.dart';
import 'package:arena/data/models/match_status.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Calendrier d'une compétition : tous ses matchs, groupés par JOUR puis triés
/// par créneau.
///
/// Volontairement une liste d'agenda et non une grille mensuelle : un tournoi se
/// joue sur quelques journées denses, pas étalé sur un mois. Une grille serait
/// surtout du vide, et illisible sur mobile.
///
/// Les matchs **non encore programmés** (rounds dont le précédent n'est pas
/// terminé — leur `scheduled_at` est posé par `try_schedule_next_round`)
/// atterrissent dans une section « À programmer » en fin de liste, plutôt que
/// d'être masqués : leur absence de date EST une information.
///
/// Flutter pur — donc réutilisable tel quel dans la console desktop (Fluent),
/// comme `ArenaBracketTree`.
class ArenaCompetitionSchedule extends StatelessWidget {
  const ArenaCompetitionSchedule({
    required this.matches,
    this.usernamesByPlayerId = const {},
    this.onTapMatch,
    this.unscheduledLabel = 'À programmer',
    this.padding = const EdgeInsets.all(ArenaSpacing.md),
    super.key,
  });

  /// Tous les matchs de la compétition (tous formats — pas seulement KO).
  final List<ArenaMatch> matches;

  /// Résolution `playerId -> username` (fallback `P-XXXX`).
  final Map<String, String> usernamesByPlayerId;

  /// Tap sur une ligne. `null` = lecture seule.
  final ValueChanged<ArenaMatch>? onTapMatch;

  /// En-tête de la section des matchs sans date. Injecté par le caller : la
  /// console admin est en français dur, l'app user est localisée.
  final String unscheduledLabel;

  final EdgeInsets padding;

  /// Groupe par jour local, non programmés à part. Exposé (visible for testing)
  /// : c'est la seule logique non triviale du widget.
  static ({List<({DateTime day, List<ArenaMatch> matches})> days,
      List<ArenaMatch> unscheduled}) groupByDay(List<ArenaMatch> matches) {
    final byDay = <DateTime, List<ArenaMatch>>{};
    final unscheduled = <ArenaMatch>[];
    for (final m in matches) {
      final at = m.scheduledAt;
      if (at == null) {
        unscheduled.add(m);
        continue;
      }
      final local = at.toLocal();
      final key = DateTime(local.year, local.month, local.day);
      (byDay[key] ??= []).add(m);
    }
    final days = byDay.keys.toList()..sort();
    // Dans une journée : par heure, puis round, puis numéro — l'ordre dans
    // lequel on les joue.
    int cmp(ArenaMatch a, ArenaMatch b) {
      final c = a.scheduledAt!.compareTo(b.scheduledAt!);
      if (c != 0) return c;
      final r = (a.round ?? 0).compareTo(b.round ?? 0);
      if (r != 0) return r;
      return (a.matchNumber ?? 0).compareTo(b.matchNumber ?? 0);
    }

    unscheduled.sort((a, b) {
      final r = (a.round ?? 0).compareTo(b.round ?? 0);
      if (r != 0) return r;
      return (a.matchNumber ?? 0).compareTo(b.matchNumber ?? 0);
    });

    return (
      days: [
        for (final d in days) (day: d, matches: byDay[d]!..sort(cmp)),
      ],
      unscheduled: unscheduled,
    );
  }

  @override
  Widget build(BuildContext context) {
    final grouped = groupByDay(matches);
    if (grouped.days.isEmpty && grouped.unscheduled.isEmpty) {
      return const SizedBox.shrink();
    }
    return ListView(
      padding: padding,
      children: [
        for (final d in grouped.days) ...[
          _DayHeader(label: formatRelativeDate(d.day, withTime: false)),
          for (final m in d.matches)
            _ScheduleRow(
              match: m,
              usernamesByPlayerId: usernamesByPlayerId,
              onTap: onTapMatch == null ? null : () => onTapMatch!(m),
            ),
          const SizedBox(height: ArenaSpacing.md),
        ],
        if (grouped.unscheduled.isNotEmpty) ...[
          _DayHeader(label: unscheduledLabel),
          for (final m in grouped.unscheduled)
            _ScheduleRow(
              match: m,
              usernamesByPlayerId: usernamesByPlayerId,
              onTap: onTapMatch == null ? null : () => onTapMatch!(m),
            ),
        ],
      ],
    );
  }
}

class _DayHeader extends StatelessWidget {
  const _DayHeader({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: ArenaSpacing.xs),
      child: Text(
        label.toUpperCase(),
        style: ArenaText.monoSmall.copyWith(
          color: ArenaColors.signalBlue,
          letterSpacing: 1.5,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _ScheduleRow extends StatelessWidget {
  const _ScheduleRow({
    required this.match,
    required this.usernamesByPlayerId,
    required this.onTap,
  });

  final ArenaMatch match;
  final Map<String, String> usernamesByPlayerId;
  final VoidCallback? onTap;

  String _name(String? id) {
    if (id == null) return 'À déterminer';
    final u = usernamesByPlayerId[id];
    if (u != null && u.isNotEmpty) return u;
    return 'P-${id.substring(0, 4).toUpperCase()}';
  }

  @override
  Widget build(BuildContext context) {
    final at = match.scheduledAt;
    final hasScore = match.score1 != null && match.score2 != null;
    final row = Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(
        horizontal: ArenaSpacing.md,
        vertical: ArenaSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: ArenaColors.carbon,
        borderRadius: BorderRadius.circular(ArenaRadius.lg),
        border: Border.all(color: ArenaColors.border),
      ),
      child: Row(
        children: [
          // Créneau — colonne fixe pour que les heures s'alignent d'une ligne
          // à l'autre (c'est ce qu'on scanne dans un planning).
          SizedBox(
            width: 46,
            child: Text(
              // Heure seule : le jour est déjà porté par l'en-tête de section.
              at == null ? '—' : DateFormat('HH:mm', 'fr').format(at.toLocal()),
              style: ArenaText.monoSmall.copyWith(
                color: ArenaColors.bone,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_name(match.player1Id)}  vs  ${_name(match.player2Id)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: ArenaText.body.copyWith(
                    color: ArenaColors.bone,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (match.round != null)
                  Text(
                    'Round ${match.round}',
                    style: ArenaText.small.copyWith(color: ArenaColors.silver),
                  ),
              ],
            ),
          ),
          if (hasScore)
            Text(
              '${match.score1} — ${match.score2}',
              style: ArenaText.monoSmall.copyWith(
                color: ArenaColors.bone,
                fontWeight: FontWeight.w800,
              ),
            )
          else
            _StatusDot(status: match.status),
        ],
      ),
    );
    if (onTap == null) return row;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(ArenaRadius.lg),
      child: row,
    );
  }
}

/// Pastille d'état pour un match sans score : ce qu'un joueur veut savoir d'un
/// coup d'œil, c'est « ça se joue maintenant ? ».
class _StatusDot extends StatelessWidget {
  const _StatusDot({required this.status});

  final MatchStatus status;

  @override
  Widget build(BuildContext context) {
    final (color, label) = switch (status) {
      MatchStatus.inProgress ||
      MatchStatus.scorePending ||
      MatchStatus.awaitingValidation =>
        (ArenaColors.success, 'EN COURS'),
      MatchStatus.disputed => (ArenaColors.danger, 'LITIGE'),
      MatchStatus.cancelled => (ArenaColors.silver, 'ANNULÉ'),
      MatchStatus.forfeited => (ArenaColors.warning, 'FORFAIT'),
      _ => (ArenaColors.silver, 'À VENIR'),
    };
    return Text(
      label,
      style: ArenaText.monoSmall.copyWith(
        color: color,
        fontSize: 10,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}
