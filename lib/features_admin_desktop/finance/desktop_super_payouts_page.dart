import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/core/utils/arena_error_message.dart';
import 'package:arena/data/repositories/payout_repository.dart';
import 'package:arena/features_admin_desktop/shared/desktop_scope_banner.dart';
import 'package:arena/features_shared/admin/admin_formatters.dart';
import 'package:arena/features_shared/admin_sections.dart';
import 'package:arena/features_shared/auth_common/shared_auth_providers.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Au-delà de N jours après réclamation sans versement, on signale un retard.
const _slaOverdueDays = 3;

/// Finance · SA — Versements de gains P2P (desktop). Port fidèle de
/// `super_admin_payouts_page` (mobile) — distinct de la *validation* des
/// payouts (`DesktopPayoutsPage`). Deux sections :
///   • À VERSER — payouts réclamés (prêts à payer) → `markPaid`.
///   • À GÉNÉRER — compétitions terminées avec gains sans payouts → `generate`.
class DesktopSuperPayoutsPage extends ConsumerStatefulWidget {
  const DesktopSuperPayoutsPage({super.key});

  @override
  ConsumerState<DesktopSuperPayoutsPage> createState() =>
      _DesktopSuperPayoutsPageState();
}

class _DesktopSuperPayoutsPageState
    extends ConsumerState<DesktopSuperPayoutsPage> {
  int _tab = 0; // 0 = À verser, 1 = À générer

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(currentProfileProvider).valueOrNull;
    return ScaffoldPage(
      header: PageHeader(
        title: const Text('VERSEMENTS'),
        commandBar: CommandBar(
          mainAxisAlignment: MainAxisAlignment.end,
          primaryItems: [
            CommandBarButton(
              icon: const Icon(FluentIcons.refresh),
              label: const Text('Actualiser'),
              onPressed: () {
                ref
                  ..invalidate(pendingPayoutsProvider)
                  ..invalidate(competitionsPendingPayoutProvider);
              },
            ),
          ],
        ),
      ),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (adminHasCountryScope(profile))
            DesktopScopeBanner(profile: profile),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
            child: Row(
              children: [
                _SegButton(
                  label: 'À verser',
                  selected: _tab == 0,
                  onPressed: () => setState(() => _tab = 0),
                ),
                const SizedBox(width: 8),
                _SegButton(
                  label: 'À générer',
                  selected: _tab == 1,
                  onPressed: () => setState(() => _tab = 1),
                ),
              ],
            ),
          ),
          Expanded(
            child: _tab == 0 ? const _ToPayList() : const _ToGenerateList(),
          ),
        ],
      ),
    );
  }
}

class _SegButton extends StatelessWidget {
  const _SegButton({
    required this.label,
    required this.selected,
    required this.onPressed,
  });

  final String label;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    if (selected) {
      return FilledButton(onPressed: onPressed, child: Text(label));
    }
    return Button(onPressed: onPressed, child: Text(label));
  }
}

// ─── À VERSER ────────────────────────────────────────────────────────

class _ToPayList extends ConsumerWidget {
  const _ToPayList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(pendingPayoutsProvider);
    return async.when(
      loading: () => const Center(child: ProgressRing()),
      error: (e, _) => _error(e),
      data: (list) {
        if (list.isEmpty) {
          return const _Empty(
            icon: FluentIcons.money,
            message: 'Aucun versement en attente.',
          );
        }
        return ListView(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          children: [
            for (final p in list) ...[
              _PayoutCard(
                payout: p,
                onPaid: () => _markPaid(context, ref, p),
              ),
              const SizedBox(height: 12),
            ],
          ],
        );
      },
    );
  }

  Future<void> _markPaid(
    BuildContext context,
    WidgetRef ref,
    PayoutRecord payout,
  ) async {
    final ok = await _confirm(
      context,
      title: 'Confirmer le versement ?',
      body: 'Confirme avoir versé ${adminMoney(payout.amountLocal)} '
          '${payout.currency} sur le ${_methodLabel(payout.payeeMethod)} '
          '${payout.payeePhone ?? "—"}.',
      confirmLabel: 'Marquer payé',
    );
    if (ok != true || !context.mounted) return;
    try {
      await ref.read(payoutRepositoryProvider).markPaid(payout.id);
      ref.invalidate(pendingPayoutsProvider);
      if (!context.mounted) return;
      await _info(context, 'Versement marqué payé · gagnant notifié.');
    } catch (e) {
      if (!context.mounted) return;
      await _info(context, _scopeAwareError(e), isError: true);
    }
  }
}

// ─── À GÉNÉRER ───────────────────────────────────────────────────────

class _ToGenerateList extends ConsumerWidget {
  const _ToGenerateList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(competitionsPendingPayoutProvider);
    return async.when(
      loading: () => const Center(child: ProgressRing()),
      error: (e, _) => _error(e),
      data: (list) {
        if (list.isEmpty) {
          return const _Empty(
            icon: FluentIcons.completed,
            message: 'Toutes les compétitions sont réglées.',
          );
        }
        return ListView(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          children: [
            for (final c in list) ...[
              _CompetitionToSettleCard(
                comp: c,
                onGenerate: () => _generate(context, ref, c),
              ),
              const SizedBox(height: 12),
            ],
          ],
        );
      },
    );
  }

  Future<void> _generate(
    BuildContext context,
    WidgetRef ref,
    PendingPayoutCompetition comp,
  ) async {
    final ok = await _confirm(
      context,
      title: 'Générer les versements ?',
      body: 'Crée une ligne de versement pour chaque gagnant de '
          '« ${comp.name} » selon le classement final. Nécessite que le '
          'classement soit publié.',
      confirmLabel: 'Générer',
    );
    if (ok != true || !context.mounted) return;
    try {
      final n = await ref.read(payoutRepositoryProvider).generate(comp.id);
      ref
        ..invalidate(competitionsPendingPayoutProvider)
        ..invalidate(pendingPayoutsProvider);
      if (!context.mounted) return;
      await _info(context, '$n versement(s) généré(s) — gagnants notifiés.');
    } catch (e) {
      if (!context.mounted) return;
      await _info(context, _scopeAwareError(e), isError: true);
    }
  }
}

/// Un rejet 42501 des RPC `generate_payouts`/`mark_payout_paid` = action
/// hors périmètre (pays/section) de l'admin → message dédié.
String _scopeAwareError(Object e) {
  if (e is PostgrestException && e.code == '42501') {
    return 'Action hors de votre périmètre.';
  }
  return arenaErrorMessage(e);
}

// ─── Cartes ──────────────────────────────────────────────────────────

class _PayoutCard extends StatelessWidget {
  const _PayoutCard({required this.payout, required this.onPaid});

  final PayoutRecord payout;
  final VoidCallback onPaid;

  @override
  Widget build(BuildContext context) {
    final claimed = payout.isClaimed;
    final overdue = claimed &&
        payout.claimedAt != null &&
        DateTime.now().difference(payout.claimedAt!).inDays >= _slaOverdueDays;
    final accent = overdue
        ? ArenaColors.neonRed
        : (claimed ? ArenaColors.statusOk : ArenaColors.silver);
    return Card(
      backgroundColor: ArenaColors.carbon,
      borderColor: accent.withValues(alpha: 0.4),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  payout.competitionName ??
                      'Compétition ${_shortId(payout.competitionId)}',
                  style: GoogleFonts.spaceGrotesk(
                    color: ArenaColors.bone,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (overdue) ...[
                const _Pill(label: '⏱ RETARD', color: ArenaColors.neonRed),
                const SizedBox(width: 6),
              ],
              _Pill(
                label: claimed ? 'À PAYER' : 'NON RÉCLAMÉ',
                color: claimed ? ArenaColors.statusOk : ArenaColors.statusWarn,
              ),
            ],
          ),
          const SizedBox(height: 12),
          _kv(
            'Montant',
            '${adminMoney(payout.amountLocal)} ${payout.currency}',
            emphasize: true,
          ),
          if (payout.rank != null) _kv('Rang', '${payout.rank}'),
          _kv('Méthode', _methodLabel(payout.payeeMethod)),
          _kv('Numéro retrait', payout.payeePhone ?? '—'),
          if (claimed && payout.claimedAt != null)
            _kv(
              'Réclamé le',
              DateFormat('dd/MM/yyyy').format(payout.claimedAt!.toLocal()),
            ),
          _kv(
            'Référence',
            'PAYOUT-${payout.id.substring(0, 8).toUpperCase()}',
          ),
          const SizedBox(height: 12),
          if (claimed)
            FilledButton(
              onPressed: onPaid,
              child: const Text('✓ Marquer payé'),
            )
          else
            Text(
              'En attente que le gagnant réclame (saisie de son numéro).',
              style: GoogleFonts.spaceGrotesk(
                color: ArenaColors.silver,
                fontSize: 12,
              ),
            ),
        ],
      ),
    );
  }
}

class _CompetitionToSettleCard extends StatelessWidget {
  const _CompetitionToSettleCard({
    required this.comp,
    required this.onGenerate,
  });

  final PendingPayoutCompetition comp;
  final VoidCallback onGenerate;

  @override
  Widget build(BuildContext context) {
    return Card(
      backgroundColor: ArenaColors.carbon,
      borderColor: ArenaColors.tierGoldWarm.withValues(alpha: 0.4),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            comp.name,
            style: GoogleFonts.spaceGrotesk(
              color: ArenaColors.bone,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Cagnotte : ${adminMoney(comp.prizePoolLocal)} ${comp.currency}',
            style: GoogleFonts.spaceGrotesk(
              color: ArenaColors.silver,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: onGenerate,
            child: const Text('💰 Générer les versements'),
          ),
        ],
      ),
    );
  }
}

// ─── Helpers UI ──────────────────────────────────────────────────────

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color),
      ),
      child: Text(
        label,
        style: GoogleFonts.spaceGrotesk(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 40, color: ArenaColors.silverDim),
          const SizedBox(height: 12),
          Text(
            message,
            style: GoogleFonts.spaceGrotesk(
              color: ArenaColors.silver,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

Widget _error(Object e) => Padding(
      padding: const EdgeInsets.all(24),
      child: InfoBar(
        title: const Text('Erreur'),
        content: Text('$e'),
        severity: InfoBarSeverity.error,
      ),
    );

Widget _kv(String key, String value, {bool emphasize = false}) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          key,
          style: GoogleFonts.spaceGrotesk(
            color: ArenaColors.silver,
            fontSize: 13,
          ),
        ),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: GoogleFonts.spaceGrotesk(
              color: emphasize ? ArenaColors.tierGoldWarm : ArenaColors.bone,
              fontSize: 13,
              fontWeight: emphasize ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ],
    ),
  );
}

Future<bool?> _confirm(
  BuildContext context, {
  required String title,
  required String body,
  required String confirmLabel,
}) {
  return showDialog<bool>(
    context: context,
    builder: (ctx) => ContentDialog(
      title: Text(title),
      content: Text(body),
      actions: [
        Button(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: const Text('Annuler'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
}

Future<void> _info(
  BuildContext context,
  String message, {
  bool isError = false,
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
    id.length <= 8 ? id : id.substring(0, 8).toUpperCase();

String _methodLabel(String? code) {
  switch (code) {
    case 'MTN_MOMO':
      return 'MTN MoMo';
    case 'ORANGE_MONEY':
      return 'Orange Money';
    default:
      return '—';
  }
}
