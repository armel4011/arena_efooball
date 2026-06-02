import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/core/utils/arena_error_message.dart';
import 'package:arena/data/models/payout.dart';
import 'package:arena/data/repositories/admin/admin_audit_log_repository.dart';
import 'package:arena/data/repositories/admin/admin_payouts_repository.dart';
import 'package:arena/features_admin_desktop/shared/desktop_totp_gate.dart';
import 'package:arena/features_shared/auth_common/shared_auth_providers.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

/// Finance · Payouts (desktop) — file des payouts en attente de
/// validation, avec un tableau par carte, statuts colorés et actions
/// protégées par le step-up TOTP.
///
/// Réutilise [adminPendingPayoutsProvider], [adminPayoutsRepositoryProvider]
/// et [adminAuditLogRepositoryProvider] (mêmes providers que le mobile).
class DesktopPayoutsPage extends ConsumerWidget {
  const DesktopPayoutsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final payoutsAsync = ref.watch(adminPendingPayoutsProvider);

    return ScaffoldPage(
      header: PageHeader(
        title: const Text('PAYOUTS'),
        commandBar: CommandBar(
          mainAxisAlignment: MainAxisAlignment.end,
          primaryItems: [
            CommandBarButton(
              icon: const Icon(FluentIcons.refresh),
              label: const Text('Actualiser'),
              onPressed: () => ref.invalidate(adminPendingPayoutsProvider),
            ),
          ],
        ),
      ),
      content: payoutsAsync.when(
        loading: () => const Center(child: ProgressRing()),
        error: (e, _) => Padding(
          padding: const EdgeInsets.all(24),
          child: InfoBar(
            title: const Text('Impossible de charger les payouts'),
            content: Text('$e'),
            severity: InfoBarSeverity.error,
          ),
        ),
        data: (list) {
          if (list.isEmpty) {
            return const _EmptyState(
              message: 'Aucun payout en attente de validation.',
            );
          }
          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            children: [
              _SummaryCard(payouts: list),
              const SizedBox(height: 16),
              for (final payout in list) ...[
                _PayoutCard(payout: payout),
                const SizedBox(height: 12),
              ],
              const SizedBox(height: 24),
            ],
          );
        },
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.payouts});

  final List<Payout> payouts;

  @override
  Widget build(BuildContext context) {
    final total = payouts.fold<double>(0, (acc, p) => acc + p.amountLocal);
    return Card(
      backgroundColor: ArenaColors.carbon,
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          const Icon(FluentIcons.money, size: 22, color: ArenaColors.neonRed),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'À verser',
                  style: GoogleFonts.spaceGrotesk(
                    color: ArenaColors.silver,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_money(total)} XAF',
                  style: GoogleFonts.bebasNeue(
                    color: ArenaColors.neonRed,
                    fontSize: 32,
                    height: 1,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${payouts.length} en attente',
            style: GoogleFonts.spaceGrotesk(
              color: ArenaColors.silver,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _PayoutCard extends ConsumerWidget {
  const _PayoutCard({required this.payout});

  final Payout payout;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allOk = payout.allAutoChecksPassed;
    final accent = allOk ? ArenaColors.statusOk : ArenaColors.statusWarn;
    final checks = _buildChecks(payout);

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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Joueur ${_shortId(payout.userId)}',
                      style: GoogleFonts.spaceGrotesk(
                        color: ArenaColors.bone,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Compétition ${_shortId(payout.competitionId)}',
                      style: GoogleFonts.spaceGrotesk(
                        color: ArenaColors.silver,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${_money(payout.amountLocal)} ${payout.currency}',
                    style: GoogleFonts.spaceGrotesk(
                      color: allOk ? ArenaColors.statusOk : ArenaColors.bone,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    payout.payoutMethod ?? '—',
                    style: GoogleFonts.spaceGrotesk(
                      color: ArenaColors.silver,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            '${checks.length} CONTRÔLES AUTOMATIQUES',
            style: GoogleFonts.spaceGrotesk(
              color: ArenaColors.silver,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          for (final c in checks)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Icon(
                    c.ok ? FluentIcons.completed : FluentIcons.warning,
                    size: 14,
                    color: c.ok ? ArenaColors.statusOk : ArenaColors.neonRed,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      c.label,
                      style: GoogleFonts.spaceGrotesk(
                        color: c.ok ? ArenaColors.bone : ArenaColors.neonRed,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Button(
                  onPressed: () => _refuse(context, ref),
                  child: const Text('Refuser'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: () => _validate(context, ref),
                  child: Text(
                    allOk
                        ? 'Valider · ${_money(payout.amountLocal)} '
                            '${payout.currency}'
                        : 'Valider (revue manuelle)',
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _validate(BuildContext context, WidgetRef ref) async {
    final adminId = ref.read(currentSessionProvider)?.user.id;
    if (adminId == null) return;
    final justification = await _askJustification(
      context,
      title: 'Valider ce payout ?',
      hint: 'Justification (vérifications effectuées)',
    );
    if (justification == null || !context.mounted) return;
    final totpOk = await showDesktopTotpGate(
      context,
      ref,
      reason: 'Valider un payout · ${payout.currency} '
          '${_money(payout.amountLocal)}',
    );
    if (!totpOk || !context.mounted) return;
    try {
      await ref.read(adminPayoutsRepositoryProvider).validate(
            payoutId: payout.id,
            adminId: adminId,
            justification: justification,
          );
      await ref.read(adminAuditLogRepositoryProvider).record(
        adminId: adminId,
        action: 'payout_validated',
        targetType: 'payout',
        targetId: payout.id,
        afterState: {
          'amount_local': payout.amountLocal,
          'currency': payout.currency,
          'justification': justification,
        },
      );
      ref.invalidate(adminPendingPayoutsProvider);
      if (!context.mounted) return;
      await _showResult(context, 'Payout validé.', isError: false);
    } catch (e) {
      if (!context.mounted) return;
      await _showResult(context, arenaErrorMessage(e), isError: true);
    }
  }

  Future<void> _refuse(BuildContext context, WidgetRef ref) async {
    final adminId = ref.read(currentSessionProvider)?.user.id;
    if (adminId == null) return;
    final justification = await _askJustification(
      context,
      title: 'Refuser ce payout ?',
      hint: 'Justification écrite (obligatoire)',
    );
    if (justification == null || !context.mounted) return;
    final totpOk = await showDesktopTotpGate(
      context,
      ref,
      reason: 'Refuser un payout',
    );
    if (!totpOk || !context.mounted) return;
    try {
      await ref.read(adminPayoutsRepositoryProvider).refuse(
            payoutId: payout.id,
            adminId: adminId,
            justification: justification,
          );
      await ref.read(adminAuditLogRepositoryProvider).record(
        adminId: adminId,
        action: 'payout_refused',
        targetType: 'payout',
        targetId: payout.id,
        afterState: {'justification': justification},
      );
      ref.invalidate(adminPendingPayoutsProvider);
      if (!context.mounted) return;
      await _showResult(context, 'Payout refusé.', isError: false);
    } catch (e) {
      if (!context.mounted) return;
      await _showResult(context, arenaErrorMessage(e), isError: true);
    }
  }

  static List<_Check> _buildChecks(Payout payout) {
    final raw = payout.autoChecks;
    if (raw.isEmpty) {
      return const [_Check(label: 'Aucun contrôle automatique', ok: false)];
    }
    return [
      for (final entry in raw.entries)
        _Check(label: _labelFor(entry.key), ok: entry.value == true),
    ];
  }

  static String _labelFor(String key) {
    switch (key) {
      case 'kyc_verified':
      case 'kyc':
        return 'KYC vérifié';
      case 'no_dispute':
        return 'Aucun litige ouvert';
      case 'no_anti_cheat':
      case 'anti_cheat':
        return "Pas d'alerte anti-cheat";
      case 'not_banned':
      case 'account_active':
        return 'Compte non banni';
      case 'momo_valid':
      case 'payment_destination':
        return 'Destination paiement valide';
      default:
        return key.replaceAll('_', ' ');
    }
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            FluentIcons.completed,
            size: 40,
            color: ArenaColors.statusOk,
          ),
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

class _Check {
  const _Check({required this.label, required this.ok});

  final String label;
  final bool ok;
}

// ─────────────────────────────────────────────────────────────────────
// Helpers partagés (dialogs + formatage) — locaux à la feature finance.
// ─────────────────────────────────────────────────────────────────────

Future<String?> _askJustification(
  BuildContext context, {
  required String title,
  required String hint,
}) async {
  final controller = TextEditingController();
  final result = await showDialog<String>(
    context: context,
    builder: (ctx) => ContentDialog(
      title: Text(
        title,
        style: GoogleFonts.bebasNeue(
          color: ArenaColors.bone,
          fontSize: 20,
          letterSpacing: 1,
        ),
      ),
      content: TextBox(
        controller: controller,
        placeholder: hint,
        maxLines: 3,
        autofocus: true,
      ),
      actions: [
        Button(
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('Annuler'),
        ),
        FilledButton(
          onPressed: () {
            final v = controller.text.trim();
            if (v.isEmpty) return;
            Navigator.of(ctx).pop(v);
          },
          child: const Text('Confirmer'),
        ),
      ],
    ),
  );
  WidgetsBinding.instance.addPostFrameCallback((_) => controller.dispose());
  return result;
}

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

String _money(double xaf) => NumberFormat('#,###', 'fr').format(xaf.round());

String _shortId(String id) =>
    id.length <= 8 ? id : id.substring(0, 8).toUpperCase();
