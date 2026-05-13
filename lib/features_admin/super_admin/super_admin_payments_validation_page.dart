import 'dart:async';

import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/data/repositories/admin/admin_audit_log_repository.dart';
import 'package:arena/data/repositories/admin/admin_payments_repository.dart';
import 'package:arena/features_shared/widgets/arena_app_bar.dart';
import 'package:arena/features_shared/widgets/arena_badge.dart';
import 'package:arena/features_shared/widgets/arena_button.dart';
import 'package:arena/features_user/auth/auth_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

/// PHASE 11bis · SA — Validation manuelle des paiements P2P.
///
/// Le super-admin voit la file des paiements `awaiting_admin` (triés par
/// expiration croissante = les plus urgents en haut), avec pour chaque
/// ligne : joueur, compétition, montant, méthode + numéro payeur,
/// temps restant avant expiration auto.
///
/// Deux actions par carte : **VALIDER** (status → succeeded → trigger
/// DB insère la registration en confirmed) et **REFUSER** (status →
/// rejected + raison saisie). L'onglet *Historique* liste les rows
/// fermés (validés / rejetés / expirés).
class SuperAdminPaymentsValidationPage extends ConsumerStatefulWidget {
  const SuperAdminPaymentsValidationPage({super.key});

  @override
  ConsumerState<SuperAdminPaymentsValidationPage> createState() =>
      _SuperAdminPaymentsValidationPageState();
}

class _SuperAdminPaymentsValidationPageState
    extends ConsumerState<SuperAdminPaymentsValidationPage> {
  Timer? _sweepTimer;

  @override
  void initState() {
    super.initState();
    // Sweep des paiements expirés au mount puis toutes les 30s, pour
    // que la liste soit toujours à jour côté admin sans dépendre du
    // pg_cron qui n'arrive qu'en PHASE 12.5.
    _runSweep();
    _sweepTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) _runSweep();
    });
  }

  Future<void> _runSweep() async {
    try {
      await ref.read(adminPaymentsRepositoryProvider).sweepExpired();
    } catch (_) {
      // best-effort — la prochaine tick réessaiera
    }
  }

  @override
  void dispose() {
    _sweepTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: const ArenaAppBar(title: 'Validation paiements'),
        body: SafeArea(
          child: Column(
            children: [
              const TabBar(
                labelColor: ArenaColors.bone,
                unselectedLabelColor: ArenaColors.silver,
                indicatorColor: ArenaColors.signalBlue,
                indicatorWeight: 2,
                tabs: [
                  Tab(text: 'EN ATTENTE'),
                  Tab(text: 'HISTORIQUE'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    _PendingList(onValidate: _validate, onReject: _reject),
                    const _HistoryList(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _validate(AdminPaymentRow row) async {
    final adminId = ref.read(currentSessionProvider)?.user.id;
    if (adminId == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ArenaColors.carbon,
        title: const Text('Valider le paiement ?'),
        content: Text(
          'Vérifie sur ton compte ${_methodLabel(row.payment.payerMethod)} '
          'que tu as bien reçu ${_xaf(row.payment.amountLocal)} XAF depuis '
          'le numéro ${row.payment.payerPhone ?? "—"}.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            style:
                TextButton.styleFrom(foregroundColor: ArenaColors.statusOk),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('VALIDER'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await ref.read(adminPaymentsRepositoryProvider).validate(
            paymentId: row.payment.id,
            adminId: adminId,
          );
      await ref.read(adminAuditLogRepositoryProvider).record(
        adminId: adminId,
        action: 'payment_validated',
        targetType: 'payment',
        targetId: row.payment.id,
        afterState: {
          'user_id': row.payment.userId,
          'competition_id': row.payment.competitionId,
          'amount_local': row.payment.amountLocal,
        },
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Paiement validé · ${row.username} inscrit.'),
          backgroundColor: ArenaColors.statusOk,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur : $e')),
      );
    }
  }

  Future<void> _reject(AdminPaymentRow row) async {
    final adminId = ref.read(currentSessionProvider)?.user.id;
    if (adminId == null) return;
    final reasonCtrl = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ArenaColors.carbon,
        title: const Text('Refuser le paiement ?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Justification (affichée au joueur sur P5) :',
              style: ArenaText.bodyMuted,
            ),
            const SizedBox(height: ArenaSpacing.sm),
            TextField(
              controller: reasonCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText:
                    'Ex. montant incorrect, transaction introuvable…',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          TextButton(
            style:
                TextButton.styleFrom(foregroundColor: ArenaColors.neonRed),
            onPressed: () {
              final r = reasonCtrl.text.trim();
              if (r.isEmpty) return;
              Navigator.pop(ctx, r);
            },
            child: const Text('REFUSER'),
          ),
        ],
      ),
    );
    if (reason == null || !mounted) return;
    try {
      await ref.read(adminPaymentsRepositoryProvider).reject(
            paymentId: row.payment.id,
            adminId: adminId,
            reason: reason,
          );
      await ref.read(adminAuditLogRepositoryProvider).record(
        adminId: adminId,
        action: 'payment_rejected',
        targetType: 'payment',
        targetId: row.payment.id,
        afterState: {'rejection_reason': reason},
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Paiement refusé · ${row.username} notifié.'),
          backgroundColor: ArenaColors.neonRed,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur : $e')),
      );
    }
  }
}

class _PendingList extends ConsumerWidget {
  const _PendingList({required this.onValidate, required this.onReject});

  final Future<void> Function(AdminPaymentRow) onValidate;
  final Future<void> Function(AdminPaymentRow) onReject;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(adminPendingPaymentsProvider);
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(ArenaSpacing.lg),
          child: Text('Erreur : $e', style: ArenaText.bodyMuted),
        ),
      ),
      data: (list) {
        if (list.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(ArenaSpacing.xl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('🌴', style: ArenaText.h1.copyWith(fontSize: 48)),
                  const SizedBox(height: ArenaSpacing.sm),
                  Text(
                    'Rien à valider pour le moment.',
                    style: ArenaText.body,
                  ),
                ],
              ),
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(ArenaSpacing.lg),
          itemCount: list.length,
          separatorBuilder: (_, __) =>
              const SizedBox(height: ArenaSpacing.sm),
          itemBuilder: (_, i) => _PendingCard(
            row: list[i],
            onValidate: () => onValidate(list[i]),
            onReject: () => onReject(list[i]),
          ),
        );
      },
    );
  }
}

class _PendingCard extends StatefulWidget {
  const _PendingCard({
    required this.row,
    required this.onValidate,
    required this.onReject,
  });

  final AdminPaymentRow row;
  final VoidCallback onValidate;
  final VoidCallback onReject;

  @override
  State<_PendingCard> createState() => _PendingCardState();
}

class _PendingCardState extends State<_PendingCard> {
  Timer? _ticker;
  Duration _left = Duration.zero;

  @override
  void initState() {
    super.initState();
    _recompute();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(_recompute);
    });
  }

  void _recompute() {
    final exp = widget.row.payment.expiresAt;
    if (exp == null) {
      _left = Duration.zero;
    } else {
      final d = exp.difference(DateTime.now());
      _left = d.isNegative ? Duration.zero : d;
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.row.payment;
    final urgent = _left.inMinutes < 5;
    final color = urgent ? ArenaColors.neonRed : ArenaColors.signalBlue;
    final countdown =
        '${_left.inMinutes.toString().padLeft(2, '0')}:'
        '${(_left.inSeconds % 60).toString().padLeft(2, '0')}';
    return Container(
      padding: const EdgeInsets.all(ArenaSpacing.md),
      decoration: BoxDecoration(
        color: ArenaColors.carbon,
        borderRadius: BorderRadius.circular(ArenaRadius.lg),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  widget.row.username,
                  style: ArenaText.body
                      .copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(ArenaRadius.round),
                  border: Border.all(color: color.withValues(alpha: 0.4)),
                ),
                child: Text(
                  '⏱ $countdown',
                  style: ArenaText.mono.copyWith(color: color, fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(widget.row.competitionName, style: ArenaText.bodyMuted),
          const SizedBox(height: ArenaSpacing.sm),
          Container(
            padding: const EdgeInsets.all(ArenaSpacing.sm),
            decoration: BoxDecoration(
              color: ArenaColors.surface,
              borderRadius: BorderRadius.circular(ArenaRadius.md),
            ),
            child: Column(
              children: [
                _kv(
                  'Montant',
                  '${_xaf(p.amountLocal)} ${p.currency}',
                  emphasize: true,
                ),
                _kv('Méthode', _methodLabel(p.payerMethod)),
                _kv('Numéro payeur', p.payerPhone ?? '—', mono: true),
                _kv(
                  'Reçu le',
                  DateFormat('dd/MM HH:mm').format(p.createdAt.toLocal()),
                ),
                _kv(
                  'Référence',
                  'ARENA-${p.id.substring(0, 8).toUpperCase()}',
                  mono: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: ArenaSpacing.sm),
          Row(
            children: [
              Expanded(
                child: ArenaButton(
                  label: '✗ REFUSER',
                  variant: ArenaButtonVariant.secondary,
                  onPressed: widget.onReject,
                ),
              ),
              const SizedBox(width: ArenaSpacing.sm),
              Expanded(
                child: ArenaButton(
                  label: '✓ VALIDER',
                  onPressed: widget.onValidate,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _kv(
    String key,
    String value, {
    bool mono = false,
    bool emphasize = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(key, style: ArenaText.bodyMuted),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: (mono ? ArenaText.mono : ArenaText.body).copyWith(
                color: emphasize ? ArenaColors.signalBlue : null,
                fontWeight: emphasize ? FontWeight.w700 : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryList extends ConsumerWidget {
  const _HistoryList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(adminPaymentsHistoryProvider);
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Text('Erreur : $e', style: ArenaText.bodyMuted),
      ),
      data: (list) {
        if (list.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(ArenaSpacing.lg),
              child: Text(
                'Pas encore d\'historique.',
                style: ArenaText.bodyMuted,
              ),
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(ArenaSpacing.lg),
          itemCount: list.length,
          separatorBuilder: (_, __) =>
              const SizedBox(height: ArenaSpacing.xs),
          itemBuilder: (_, i) => _HistoryCard(row: list[i]),
        );
      },
    );
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({required this.row});

  final AdminPaymentRow row;

  @override
  Widget build(BuildContext context) {
    final p = row.payment;
    final (label, variant, color) = switch (p.status) {
      'succeeded' => ('VALIDÉ', ArenaBadgeVariant.success, ArenaColors.statusOk),
      'rejected' => ('REFUSÉ', ArenaBadgeVariant.danger, ArenaColors.neonRed),
      'expired' => ('EXPIRÉ', ArenaBadgeVariant.warn, ArenaColors.statusWarn),
      _ => ('—', ArenaBadgeVariant.info, ArenaColors.silver),
    };
    return Container(
      padding: const EdgeInsets.all(ArenaSpacing.md),
      decoration: BoxDecoration(
        color: ArenaColors.carbon,
        borderRadius: BorderRadius.circular(ArenaRadius.lg),
        border: Border.all(color: ArenaColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  row.username,
                  style: ArenaText.body
                      .copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              ArenaBadge(label: label, variant: variant),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${row.competitionName} · ${_xaf(p.amountLocal)} XAF · '
            '${_methodLabel(p.payerMethod)}',
            style: ArenaText.bodyMuted,
          ),
          if (p.rejectionReason != null) ...[
            const SizedBox(height: 4),
            Text(
              'Refus : ${p.rejectionReason}',
              style: ArenaText.small.copyWith(color: color),
            ),
          ],
          const SizedBox(height: 4),
          Text(
            DateFormat('dd/MM/yyyy HH:mm').format(
              (p.validatedAt ?? p.createdAt).toLocal(),
            ),
            style: ArenaText.small,
          ),
        ],
      ),
    );
  }
}

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

String _xaf(double amount) {
  final s = amount.round().toString();
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write(' ');
    buf.write(s[i]);
  }
  return buf.toString();
}
