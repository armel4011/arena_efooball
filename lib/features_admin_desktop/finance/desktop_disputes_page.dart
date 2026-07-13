import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/core/utils/arena_error_message.dart';
import 'package:arena/data/models/anticheat_plan.dart';
import 'package:arena/data/models/arena_match.dart';
import 'package:arena/data/models/dispute.dart';
import 'package:arena/data/models/match_stream.dart';
import 'package:arena/data/models/proof_status.dart';
import 'package:arena/data/repositories/admin/admin_disputes_repository.dart';
import 'package:arena/data/repositories/competition_repository.dart';
import 'package:arena/data/repositories/match_repository.dart';
import 'package:arena/features_admin_desktop/shared/desktop_totp_gate.dart';
import 'package:arena/features_shared/admin_result_gate.dart';
import 'package:arena/features_shared/auth_common/shared_auth_providers.dart';
import 'package:arena/features_shared/widgets/arena_image_viewer.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

part 'desktop_disputes_proof_widgets.dart';
part 'desktop_disputes_commitment_widgets.dart';

/// Finance · Litige (desktop) — détail d'un litige sur un match donné +
/// résolution (verdict J1 / J2 / annulation), protégée par le step-up
/// TOTP.
///
/// Réutilise [adminDisputeByMatchProvider], [matchByIdProvider] et
/// [adminDisputesRepositoryProvider] (résolution atomique via
/// `resolve_dispute`, mêmes providers que le mobile).
class DesktopDisputesPage extends ConsumerStatefulWidget {
  const DesktopDisputesPage({required this.matchId, super.key});

  final String matchId;

  @override
  ConsumerState<DesktopDisputesPage> createState() =>
      _DesktopDisputesPageState();
}

class _DesktopDisputesPageState extends ConsumerState<DesktopDisputesPage> {
  final _justificationController = TextEditingController();

  @override
  void dispose() {
    _justificationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final disputeAsync =
        ref.watch(adminDisputeByMatchProvider(widget.matchId));
    final matchAsync = ref.watch(matchByIdProvider(widget.matchId));
    // Scores DÉCLARÉS par chaque joueur (matches.score1/2 sont NULL en litige).
    final submissions =
        ref.watch(matchSubmittedScoresProvider(widget.matchId));

    return ScaffoldPage(
      header: PageHeader(
        title: Text(
          'LITIGE · M-${_shortId(widget.matchId)}',
        ),
      ),
      content: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        children: [
          disputeAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: ProgressRing()),
            ),
            error: (e, _) => InfoBar(
              title: const Text('Impossible de charger le litige'),
              content: Text('$e'),
              severity: InfoBarSeverity.error,
            ),
            data: (dispute) => dispute == null
                ? const InfoBar(
                    title: Text('Aucun litige'),
                    content: Text('Aucun litige ouvert pour ce match.'),
                  )
                : _DisputeHeader(dispute: dispute),
          ),
          const SizedBox(height: 24),
          Text(
            'PREUVES',
            style: _sectionStyle,
          ),
          const SizedBox(height: 12),
          _ProofsSection(matchId: widget.matchId),
          const SizedBox(height: 24),
          Text(
            'PLAN ANTI-TRICHE',
            style: _sectionStyle,
          ),
          const SizedBox(height: 12),
          _AnticheatPlanSection(matchId: widget.matchId),
          const SizedBox(height: 24),
          Text(
            'ENREGISTREMENTS AUTO',
            style: _sectionStyle,
          ),
          const SizedBox(height: 12),
          _RecordingsSection(matchId: widget.matchId),
          const SizedBox(height: 24),
          Text(
            'PREUVES ENGAGÉES',
            style: _sectionStyle,
          ),
          const SizedBox(height: 12),
          _ProofCommitmentsSection(matchId: widget.matchId),
          const SizedBox(height: 24),
          Text(
            'SCORES SAISIS',
            style: _sectionStyle,
          ),
          const SizedBox(height: 12),
          matchAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: ProgressRing()),
            ),
            error: (e, _) => InfoBar(
              title: const Text('Impossible de charger le match'),
              content: Text('$e'),
              severity: InfoBarSeverity.error,
            ),
            data: (match) => match == null
                ? const InfoBar(
                    title: Text('Match introuvable'),
                    content: Text('Ce match n’existe pas ou plus.'),
                  )
                : _ScoresCard(
                    match: match,
                    submissions: submissions.valueOrNull ?? const {},
                  ),
          ),
          const SizedBox(height: 24),
          Text(
            'TRANCHER',
            style: _sectionStyle.copyWith(color: ArenaColors.neonRed),
          ),
          const SizedBox(height: 12),
          InfoLabel(
            label: 'Justification (obligatoire)',
            child: TextBox(
              controller: _justificationController,
              placeholder: 'Expliquez votre décision pour audit…',
              maxLines: 4,
            ),
          ),
          const SizedBox(height: 12),
          matchAsync.maybeWhen(
            data: (match) => match == null
                ? const SizedBox.shrink()
                : _VerdictButtons(
                    match: match,
                    dispute: disputeAsync.valueOrNull,
                    justificationController: _justificationController,
                  ),
            orElse: () => const SizedBox.shrink(),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _DisputeHeader extends StatelessWidget {
  const _DisputeHeader({required this.dispute});

  final Dispute dispute;

  @override
  Widget build(BuildContext context) {
    final since = dispute.createdAt;
    final ageLabel = since == null
        ? ''
        : 'Ouvert depuis ${_humanDuration(DateTime.now().difference(since))}';
    return Card(
      backgroundColor: ArenaColors.carbon,
      borderColor: ArenaColors.statusWarn.withValues(alpha: 0.4),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: ArenaColors.statusWarn.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: ArenaColors.statusWarn.withValues(alpha: 0.4),
                  ),
                ),
                child: Text(
                  'ESCALADE NIVEAU ${dispute.escalationLevel}',
                  style: GoogleFonts.spaceGrotesk(
                    color: ArenaColors.statusWarn,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                ageLabel,
                style: GoogleFonts.spaceGrotesk(
                  color: ArenaColors.silver,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            dispute.reason ?? 'Désaccord sur le score',
            style: GoogleFonts.spaceGrotesk(
              color: ArenaColors.bone,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (dispute.evidence['note'] is String) ...[
            const SizedBox(height: 4),
            Text(
              dispute.evidence['note'] as String,
              style: GoogleFonts.spaceGrotesk(
                color: ArenaColors.silver,
                fontSize: 13,
              ),
            ),
          ],
        ],
      ),
    );
  }

  static String _humanDuration(Duration d) {
    if (d.inMinutes < 60) return '${d.inMinutes} min';
    final h = d.inHours;
    final m = d.inMinutes - h * 60;
    if (m == 0) return '${h}h';
    return '${h}h ${m}min';
  }
}

/// Rôle d'un joueur pour l'affichage des preuves : « Domicile » (player1/HOME),
/// « Extérieur » (player2/AWAY), sinon un fallback court sur l'id.
String _disputePlayerRole(String? playerId, {String? homeId, String? awayId}) {
  if (playerId == null || playerId.isEmpty) return 'Joueur ?';
  if (homeId != null && homeId.isNotEmpty && playerId == homeId) {
    return 'Domicile (HOME)';
  }
  if (awayId != null && awayId.isNotEmpty && playerId == awayId) {
    return 'Extérieur (AWAY)';
  }
  final n = playerId.length < 6 ? playerId.length : 6;
  return 'Joueur ${playerId.substring(0, n).toUpperCase()}';
}

/// Variante compacte (« Domicile » / « Extérieur ») pour les légendes de tuiles.
String _disputePlayerRoleShort(
  String? playerId, {
  String? homeId,
  String? awayId,
}) {
  if (playerId != null && playerId.isNotEmpty) {
    if (playerId == homeId) return 'Domicile';
    if (playerId == awayId) return 'Extérieur';
  }
  return _disputePlayerRole(playerId, homeId: homeId, awayId: awayId);
}

class _ScoresCard extends StatelessWidget {
  const _ScoresCard({required this.match, this.submissions = const {}});

  final ArenaMatch match;

  /// Scoreline déclaré par chaque joueur (`player_id → SubmittedScore`).
  final Map<String, SubmittedScore> submissions;

  @override
  Widget build(BuildContext context) {
    return Card(
      backgroundColor: ArenaColors.carbon,
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          _scoreRow(
            label: 'Joueur 1 (HOME) · a déclaré',
            score: _declaredFor(match.player1Id, fallback: match.score1),
            color: ArenaColors.gameDraughts,
            border: true,
          ),
          _scoreRow(
            label: 'Joueur 2 (AWAY) · a déclaré',
            score: _declaredFor(match.player2Id, fallback: match.score2),
            color: ArenaColors.neonRed,
            border: false,
          ),
        ],
      ),
    );
  }

  /// Scoreline complet « s1-s2 » déclaré par [playerId] (source de vérité en
  /// litige) ; repli sur le score final agréé [fallback] ; « — » si aucun.
  String _declaredFor(String? playerId, {int? fallback}) {
    final sub = playerId == null ? null : submissions[playerId];
    if (sub != null) return sub.label;
    if (fallback != null) return '$fallback';
    return '—';
  }

  Widget _scoreRow({
    required String label,
    required String score,
    required Color color,
    required bool border,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        border: border
            ? const Border(bottom: BorderSide(color: ArenaColors.border))
            : null,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.spaceGrotesk(
                color: ArenaColors.bone,
                fontSize: 14,
              ),
            ),
          ),
          Text(
            score,
            style: GoogleFonts.spaceGrotesk(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

final TextStyle _sectionStyle = GoogleFonts.bebasNeue(
  color: ArenaColors.silver,
  fontSize: 16,
  letterSpacing: 1.5,
);

Future<void> _showResult(
  BuildContext context,
  String message, {
  required bool isError,
}) async {
  await displayInfoBar(
    context,
    builder: (ctx, close) => InfoBar(
      title: Text(isError ? 'Échec' : 'Succès'),
      content: Text(message),
      severity: isError ? InfoBarSeverity.error : InfoBarSeverity.success,
      onClose: close,
    ),
  );
}

String _shortId(String id) =>
    id.length <= 6 ? id.toUpperCase() : id.substring(0, 6).toUpperCase();
