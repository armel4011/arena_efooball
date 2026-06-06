import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/core/utils/arena_error_message.dart';
import 'package:arena/data/models/arena_match.dart';
import 'package:arena/data/models/dispute.dart';
import 'package:arena/data/repositories/admin/admin_audit_log_repository.dart';
import 'package:arena/data/repositories/admin/admin_disputes_repository.dart';
import 'package:arena/data/repositories/admin/admin_matches_repository.dart';
import 'package:arena/data/repositories/match_repository.dart';
import 'package:arena/features_admin_desktop/shared/desktop_totp_gate.dart';
import 'package:arena/features_shared/auth_common/shared_auth_providers.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

/// Finance · Litige (desktop) — détail d'un litige sur un match donné +
/// résolution (verdict J1 / J2 / annulation), protégée par le step-up
/// TOTP.
///
/// Réutilise [adminDisputeByMatchProvider], [matchByIdProvider],
/// [adminMatchesRepositoryProvider], [adminDisputesRepositoryProvider]
/// et [adminAuditLogRepositoryProvider] (mêmes providers que le mobile).
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
                : _ScoresCard(match: match),
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

class _ScoresCard extends StatelessWidget {
  const _ScoresCard({required this.match});

  final ArenaMatch match;

  @override
  Widget build(BuildContext context) {
    return Card(
      backgroundColor: ArenaColors.carbon,
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          _scoreRow(
            label: 'Joueur 1 (HOME)',
            score: '${match.score1 ?? '?'}',
            color: ArenaColors.gameDraughts,
            border: true,
          ),
          _scoreRow(
            label: 'Joueur 2 (AWAY)',
            score: '${match.score2 ?? '?'}',
            color: ArenaColors.neonRed,
            border: false,
          ),
        ],
      ),
    );
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

class _VerdictButtons extends ConsumerWidget {
  const _VerdictButtons({
    required this.match,
    required this.dispute,
    required this.justificationController,
  });

  final ArenaMatch match;
  final Dispute? dispute;
  final TextEditingController justificationController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p1 = match.score1 ?? 0;
    final p2 = match.score2 ?? 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FilledButton(
          onPressed: match.player1Id == null
              ? null
              : () => _commit(
                    context,
                    ref,
                    winnerId: match.player1Id,
                    scoreP1: p1,
                    scoreP2: p2,
                  ),
          child: Text('Valider $p1-$p2 (J1 gagne)'),
        ),
        const SizedBox(height: 8),
        FilledButton(
          onPressed: match.player2Id == null
              ? null
              : () => _commit(
                    context,
                    ref,
                    winnerId: match.player2Id,
                    scoreP1: p2,
                    scoreP2: p1,
                  ),
          child: Text('Valider $p2-$p1 (J2 gagne)'),
        ),
        const SizedBox(height: 8),
        Button(
          onPressed: () => _cancelMatch(context, ref),
          child: const Text('Annuler le match'),
        ),
      ],
    );
  }

  Future<void> _commit(
    BuildContext context,
    WidgetRef ref, {
    required String? winnerId,
    required int scoreP1,
    required int scoreP2,
  }) async {
    final justification = justificationController.text.trim();
    if (justification.isEmpty) {
      await _showResult(
        context,
        'Justification obligatoire.',
        isError: true,
      );
      return;
    }
    final adminId = ref.read(currentSessionProvider)?.user.id;
    if (adminId == null) return;
    final totpOk = await showDesktopTotpGate(
      context,
      ref,
      reason: 'Résoudre le litige · verdict $scoreP1-$scoreP2',
    );
    if (!totpOk || !context.mounted) return;
    try {
      await ref.read(adminMatchesRepositoryProvider).setVerdict(
            matchId: match.id,
            scoreP1: scoreP1,
            scoreP2: scoreP2,
            winnerId: winnerId,
          );
      if (dispute != null) {
        await ref.read(adminDisputesRepositoryProvider).resolve(
              disputeId: dispute!.id,
              adminId: adminId,
              resolution: justification,
            );
      }
      await ref.read(adminAuditLogRepositoryProvider).record(
        adminId: adminId,
        action: 'dispute_resolved',
        targetType: 'match',
        targetId: match.id,
        afterState: {
          'winner_id': winnerId,
          'score1': scoreP1,
          'score2': scoreP2,
          'justification': justification,
        },
      );
      if (!context.mounted) return;
      await _showResult(context, 'Verdict enregistré.', isError: false);
    } catch (e) {
      if (!context.mounted) return;
      await _showResult(context, arenaErrorMessage(e), isError: true);
    }
  }

  Future<void> _cancelMatch(BuildContext context, WidgetRef ref) async {
    final justification = justificationController.text.trim();
    if (justification.isEmpty) {
      await _showResult(
        context,
        'Justification obligatoire.',
        isError: true,
      );
      return;
    }
    final adminId = ref.read(currentSessionProvider)?.user.id;
    if (adminId == null) return;
    final totpOk = await showDesktopTotpGate(
      context,
      ref,
      reason: 'Annuler le match (litige)',
    );
    if (!totpOk || !context.mounted) return;
    try {
      await ref.read(adminMatchesRepositoryProvider).cancel(match.id);
      if (dispute != null) {
        await ref.read(adminDisputesRepositoryProvider).resolve(
              disputeId: dispute!.id,
              adminId: adminId,
              resolution: justification,
              status: 'cancelled',
            );
      }
      await ref.read(adminAuditLogRepositoryProvider).record(
        adminId: adminId,
        action: 'dispute_cancelled',
        targetType: 'match',
        targetId: match.id,
        afterState: {'justification': justification},
      );
      if (!context.mounted) return;
      await _showResult(context, 'Match annulé.', isError: false);
    } catch (e) {
      if (!context.mounted) return;
      await _showResult(context, arenaErrorMessage(e), isError: true);
    }
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
