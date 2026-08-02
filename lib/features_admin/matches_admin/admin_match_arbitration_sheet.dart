import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/data/repositories/admin/admin_matches_repository.dart';
import 'package:arena/features_shared/widgets/error_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Ouvre le volet « Arbitrage » d'un match côté admin : verdict expliqué,
/// récap des signaux Domicile/Extérieur, et chronologie des events. Alimenté
/// par la RPC `admin_match_arbitration` (gardée is_admin).
Future<void> showMatchArbitrationSheet(BuildContext context, String matchId) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _ArbitrationSheet(matchId: matchId),
  );
}

class _ArbitrationSheet extends ConsumerWidget {
  const _ArbitrationSheet({required this.matchId});
  final String matchId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(adminMatchArbitrationProvider(matchId));
    return DraggableScrollableSheet(
      initialChildSize: 0.8,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scroll) => Container(
        decoration: const BoxDecoration(
          color: ArenaColors.void_,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          border: Border(top: BorderSide(color: ArenaColors.borderHi)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: ArenaColors.silverDim,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Expanded(
              child: async.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(
                  child: ErrorState(
                    description: e.toString(),
                    onRetry: () => ref.invalidate(
                        adminMatchArbitrationProvider(matchId),),
                  ),
                ),
                data: (data) => _Content(data: data, scroll: scroll),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Content extends StatelessWidget {
  const _Content({required this.data, required this.scroll});
  final Map<String, dynamic> data;
  final ScrollController scroll;

  @override
  Widget build(BuildContext context) {
    final match = (data['match'] as Map).cast<String, dynamic>();
    final verdict = (data['verdict'] as Map).cast<String, dynamic>();
    final players = (data['players'] as List? ?? [])
        .map((e) => (e as Map).cast<String, dynamic>())
        .toList();
    final events = (data['events'] as List? ?? [])
        .map((e) => (e as Map).cast<String, dynamic>())
        .toList();

    final v = _verdictInfo(verdict, players);

    return ListView(
      controller: scroll,
      padding: const EdgeInsets.fromLTRB(
          ArenaSpacing.lg, ArenaSpacing.md, ArenaSpacing.lg, ArenaSpacing.xxl,),
      children: [
        Row(
          children: [
            const Text('Arbitrage',
                style: TextStyle(
                    color: ArenaColors.bone,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,),),
            const Spacer(),
            Text('M-${(match['id'] as String).substring(0, 6).toUpperCase()}',
                style: ArenaText.monoSmall,),
          ],
        ),
        const SizedBox(height: ArenaSpacing.md),

        // Verdict banner
        Container(
          padding: const EdgeInsets.all(ArenaSpacing.md),
          decoration: BoxDecoration(
            color: v.color.withValues(alpha: 0.12),
            border: Border.all(color: v.color.withValues(alpha: 0.4)),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Text(v.icon, style: const TextStyle(fontSize: 26)),
              const SizedBox(width: ArenaSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(v.title,
                        style: TextStyle(
                            color: v.color,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,),),
                    if (v.detail != null) ...[
                      const SizedBox(height: 2),
                      Text(v.detail!,
                          style: ArenaText.bodyMuted,),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: ArenaSpacing.lg),

        _sectionTitle('Ce que chaque joueur a fait'),
        const SizedBox(height: ArenaSpacing.sm),
        if (players.length == 2)
          _SignalsTable(p1: players[0], p2: players[1]),
        const SizedBox(height: ArenaSpacing.lg),

        _sectionTitle('Chronologie'),
        const SizedBox(height: ArenaSpacing.sm),
        if (events.isEmpty)
          Text('Aucun événement enregistré.', style: ArenaText.bodyMuted)
        else
          ...events.map(_eventTile),
      ],
    );
  }

  Widget _sectionTitle(String t) => Text(t.toUpperCase(),
      style: ArenaText.badge.copyWith(
          color: ArenaColors.silverDim, letterSpacing: 1.4,),);

  Widget _eventTile(Map<String, dynamic> e) {
    final label = _eventLabel(
        e['type'] as String?, (e['payload'] as Map?)?.cast<String, dynamic>(),);
    final who = e['username'] as String?;
    final ts = _fmtTime(e['created_at'] as String?);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.$1, style: const TextStyle(fontSize: 15)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label.$2,
                    style: ArenaText.body.copyWith(color: ArenaColors.bone),),
                if (who != null || ts != null)
                  Text([who, ts].whereType<String>().join(' · '),
                      style: ArenaText.monoSmall,),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SignalsTable extends StatelessWidget {
  const _SignalsTable({required this.p1, required this.p2});
  final Map<String, dynamic> p1;
  final Map<String, dynamic> p2;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: ArenaColors.carbon,
        border: Border.all(color: ArenaColors.border),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Row(children: [
            const SizedBox(width: 150),
            Expanded(child: _playerHead(p1)),
            Expanded(child: _playerHead(p2)),
          ],),
          const Divider(height: 1, color: ArenaColors.border),
          _row('🎮 Synchro (jeu ouvert)', p1['sync_confirmed'],
              p2['sync_confirmed'],),
          _row('🔑 Code envoyé', p1['sent_code'], p2['sent_code'],
              homeOnly: true, p1: p1, p2: p2,),
          _row('🚪 Salle rejointe', p1['joined'], p2['joined'],
              awayOnly: true, p1: p1, p2: p2,),
          _row('🛡️ Équipe saisie', p1['team_named'], p2['team_named']),
          _row('🔴 Enregistrement', p1['recorded'], p2['recorded']),
          _row('📊 Score soumis', p1['submitted'], p2['submitted']),
        ],
      ),
    );
  }

  Widget _playerHead(Map<String, dynamic> p) {
    final isHome = p['is_home'] == true;
    final isWinner = p['is_winner'] == true;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
      child: Column(
        children: [
          Text(isHome ? '🏠' : '✈️', style: const TextStyle(fontSize: 15)),
          const SizedBox(height: 2),
          Text(
            (p['username'] as String?) ?? '—',
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: ArenaText.body.copyWith(
                color: ArenaColors.bone, fontWeight: FontWeight.w700,),
          ),
          Text(isHome ? 'Domicile' : 'Extérieur',
              style: ArenaText.monoSmall,),
          if (isWinner)
            const Padding(
              padding: EdgeInsets.only(top: 2),
              child: Text('🏆 Vainqueur',
                  style: TextStyle(
                      color: ArenaColors.statusOk,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,),),
            ),
        ],
      ),
    );
  }

  Widget _row(String label, Object? v1, Object? v2,
      {bool homeOnly = false,
      bool awayOnly = false,
      Map<String, dynamic>? p1,
      Map<String, dynamic>? p2,}) {
    return Container(
      decoration:
          const BoxDecoration(border: Border(top: BorderSide(color: ArenaColors.border))),
      child: Row(
        children: [
          SizedBox(
            width: 150,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
              child: Text(label, style: ArenaText.body),
            ),
          ),
          Expanded(child: _cell(v1 == true, _muted(homeOnly, awayOnly, p1))),
          Expanded(child: _cell(v2 == true, _muted(homeOnly, awayOnly, p2))),
        ],
      ),
    );
  }

  // Une case « — » (non applicable) quand le signal ne concerne pas ce rôle
  // (code = Domicile seulement ; salle rejointe = Extérieur seulement).
  bool _muted(bool homeOnly, bool awayOnly, Map<String, dynamic>? p) {
    if (p == null) return false;
    final isHome = p['is_home'] == true;
    if (homeOnly && !isHome) return true;
    if (awayOnly && isHome) return true;
    return false;
  }

  Widget _cell(bool ok, bool muted) {
    if (muted) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: Text('—', style: TextStyle(color: ArenaColors.silverDim)),
        ),
      );
    }
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Icon(
          ok ? Icons.check_circle : Icons.cancel,
          size: 20,
          color: ok ? ArenaColors.statusOk : ArenaColors.neonRed,
        ),
      ),
    );
  }
}

// ─── Libellés ──────────────────────────────────────────────────────────────

class _Verdict {
  const _Verdict(this.icon, this.title, this.detail, this.color);
  final String icon;
  final String title;
  final String? detail;
  final Color color;
}

_Verdict _verdictInfo(
    Map<String, dynamic> verdict, List<Map<String, dynamic>> players,) {
  final kind = verdict['kind'] as String? ?? 'pending';
  final winnerId = verdict['winner_id'] as String?;
  String? winnerName;
  for (final p in players) {
    if (p['id'] == winnerId) winnerName = p['username'] as String?;
  }
  final role = verdict['winner_role'] as String?;
  final roleLabel =
      role == 'home' ? 'Domicile' : role == 'away' ? 'Extérieur' : null;
  final winLine = winnerName == null
      ? null
      : '$winnerName gagne${roleLabel != null ? ' ($roleLabel)' : ''}';

  switch (kind) {
    case 'auto_no_show':
      return _Verdict('⚖️', 'Auto-forfait · no-show', winLine,
          ArenaColors.neonRed,);
    case 'auto_double_no_show':
      return const _Verdict('⬛', 'Annulé · double absence',
          "Aucun joueur ne s'est présenté", ArenaColors.silverDim,);
    case 'manual_forfeit':
      return _Verdict('🏳️', 'Forfait manuel', winLine, ArenaColors.neonRed);
    case 'cancelled':
      return const _Verdict(
          '⬛', 'Match annulé', null, ArenaColors.silverDim,);
    case 'disputed':
      return const _Verdict('⚠️', 'En litige',
          "Résolution réservée à l'arbitrage", ArenaColors.statusWarn,);
    case 'completed':
      return _Verdict('✅', 'Terminé', winLine, ArenaColors.statusOk);
    default:
      return const _Verdict('⏳', 'En cours / en attente',
          "Le match n'est pas encore soldé", ArenaColors.signalBlue,);
  }
}

(String, String) _eventLabel(String? type, Map<String, dynamic>? payload) {
  switch (type) {
    case 'room_code_sent':
      return ('🔑', 'Code de salle envoyé');
    case 'room_joined':
      return ('🚪', 'Salle rejointe');
    case 'match_started':
      return ('▶️', 'Match démarré');
    case 'score_submitted':
      return ('📊', 'Score soumis');
    case 'score_validated':
      return ('✅', 'Score validé');
    case 'score_disputed':
      return ('⚠️', 'Score contesté');
    case 'proof_missing':
      return ('🚫', 'Preuve manquante');
    case 'match_finished':
      return ('🏁', 'Match terminé');
    case 'goal':
      return ('⚽', 'But');
    case 'admin_adjustment':
      return ('🛠️', 'Ajustement admin');
    case 'forfeit':
      final reason = payload?['reason'] as String?;
      if (reason == 'auto_timeout_no_show') {
        return ('⚖️', 'Forfait automatique (no-show)');
      }
      if (reason == 'auto_timeout_double_no_show') {
        return ('⬛', 'Annulation automatique (double absence)');
      }
      return ('🏳️', 'Forfait');
    default:
      return ('•', type ?? 'Événement');
  }
}

String? _fmtTime(String? iso) {
  if (iso == null) return null;
  final dt = DateTime.tryParse(iso)?.toLocal();
  if (dt == null) return null;
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(dt.day)}/${two(dt.month)} ${two(dt.hour)}:${two(dt.minute)}';
}
