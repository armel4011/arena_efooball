part of 'desktop_payments_validation_page.dart';

class _PendingList extends ConsumerWidget {
  const _PendingList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(adminPendingPaymentsProvider);
    return async.when(
      loading: () => const Center(child: ProgressRing()),
      error: (e, _) => Padding(
        padding: const EdgeInsets.all(24),
        child: InfoBar(
          title: const Text('Erreur de chargement'),
          content: Text('$e'),
          severity: InfoBarSeverity.error,
        ),
      ),
      data: (list) {
        if (list.isEmpty) {
          return Center(
            child: Text(
              'Aucun paiement à valider pour le moment.',
              style: GoogleFonts.spaceGrotesk(
                color: ArenaColors.silver,
                fontSize: 14,
              ),
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          itemCount: list.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (_, i) => _PendingCard(row: list[i]),
        );
      },
    );
  }
}

class _PendingCard extends ConsumerWidget {
  const _PendingCard({required this.row});

  final AdminPaymentRow row;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final payment = row.payment;
    final age = DateTime.now().difference(payment.createdAt);
    final urgent = age.inHours >= 1;
    final accent = urgent ? ArenaColors.statusWarn : ArenaColors.signalBlue;

    return Card(
      backgroundColor: ArenaColors.carbon,
      borderColor: accent.withValues(alpha: 0.4),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  row.username,
                  style: GoogleFonts.spaceGrotesk(
                    color: ArenaColors.bone,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: accent.withValues(alpha: 0.4)),
                ),
                child: Text(
                  _ageLabel(age),
                  style: GoogleFonts.spaceGrotesk(
                    color: accent,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            row.competitionName,
            style: GoogleFonts.spaceGrotesk(
              color: ArenaColors.silver,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 12),
          _kv(
            'Montant',
            '${adminMoney(payment.amountLocal)} ${payment.currency}',
            emphasize: true,
          ),
          _kv('Méthode', paymentMethodLabel(payment.payerMethod)),
          _kv('Numéro payeur', payment.payerPhone ?? '—'),
          _kv(
            'Reçu le',
            DateFormat('dd/MM HH:mm').format(payment.createdAt.toLocal()),
          ),
          _kv(
            'Référence',
            'ARENA-${_shortId(payment.id)}',
          ),
          if (payment.hasProof) ...[
            const SizedBox(height: 12),
            _DesktopProofPreview(proofPath: payment.proofPath!),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Button(
                  onPressed: () => _reject(context, ref),
                  child: const Text('Refuser'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: () => _validate(context, ref),
                  child: const Text('Valider'),
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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => ContentDialog(
        title: const Text('Valider le paiement ?'),
        content: Text(
          'Vérifiez sur votre compte ${paymentMethodLabel(row.payment.payerMethod)} '
          'avoir bien reçu ${adminMoney(row.payment.amountLocal)} '
          '${row.payment.currency} depuis le numéro '
          '${row.payment.payerPhone ?? "—"}.',
        ),
        actions: [
          Button(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Valider'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final totpOk = await showDesktopTotpGate(
      context,
      ref,
      reason: 'Valider un paiement P2P · '
          '${adminMoney(row.payment.amountLocal)} ${row.payment.currency}',
    );
    if (!totpOk || !context.mounted) return;
    try {
      final applied = await ref.read(adminPaymentsRepositoryProvider).validate(
            paymentId: row.payment.id,
            adminId: adminId,
          );
      if (!applied) {
        ref.invalidate(adminPendingPaymentsProvider);
        if (!context.mounted) return;
        await _showResult(
          context,
          "Ce paiement n'est plus en attente (déjà traité). "
          'Liste actualisée.',
          isError: true,
        );
        return;
      }
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
      ref.invalidate(adminPendingPaymentsProvider);
      if (!context.mounted) return;
      await _showResult(
        context,
        'Paiement validé · ${row.username} inscrit.',
        isError: false,
      );
    } catch (e) {
      if (!context.mounted) return;
      await _showResult(context, arenaErrorMessage(e), isError: true);
    }
  }

  Future<void> _reject(BuildContext context, WidgetRef ref) async {
    final adminId = ref.read(currentSessionProvider)?.user.id;
    if (adminId == null) return;
    final reason = await _askReason(context);
    if (reason == null || !context.mounted) return;
    final totpOk = await showDesktopTotpGate(
      context,
      ref,
      reason: 'Refuser un paiement P2P',
    );
    if (!totpOk || !context.mounted) return;
    try {
      final applied = await ref.read(adminPaymentsRepositoryProvider).reject(
            paymentId: row.payment.id,
            adminId: adminId,
            reason: reason,
          );
      if (!applied) {
        ref.invalidate(adminPendingPaymentsProvider);
        if (!context.mounted) return;
        await _showResult(
          context,
          "Ce paiement n'est plus en attente (déjà traité). "
          'Liste actualisée.',
          isError: true,
        );
        return;
      }
      await ref.read(adminAuditLogRepositoryProvider).record(
        adminId: adminId,
        action: 'payment_rejected',
        targetType: 'payment',
        targetId: row.payment.id,
        afterState: {'rejection_reason': reason},
      );
      ref.invalidate(adminPendingPaymentsProvider);
      if (!context.mounted) return;
      await _showResult(
        context,
        'Paiement refusé · ${row.username} notifié.',
        isError: false,
      );
    } catch (e) {
      if (!context.mounted) return;
      await _showResult(context, arenaErrorMessage(e), isError: true);
    }
  }

  Future<String?> _askReason(BuildContext context) async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => ContentDialog(
        title: const Text('Refuser le paiement ?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Justification (affichée au joueur) :',
              style: GoogleFonts.spaceGrotesk(
                color: ArenaColors.silver,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 8),
            TextBox(
              controller: controller,
              maxLines: 3,
              autofocus: true,
              placeholder: 'Ex. montant incorrect, transaction introuvable…',
            ),
          ],
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
            child: const Text('Refuser'),
          ),
        ],
      ),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => controller.dispose());
    return result;
  }

  Widget _kv(String key, String value, {bool emphasize = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
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
                color: emphasize ? ArenaColors.signalBlue : ArenaColors.bone,
                fontSize: 13,
                fontWeight: emphasize ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _ageLabel(Duration d) {
    if (d.inMinutes < 1) return "à l'instant";
    if (d.inHours < 1) return 'il y a ${d.inMinutes} min';
    if (d.inDays < 1) return 'il y a ${d.inHours}h';
    return 'il y a ${d.inDays}j';
  }
}

class _RefundList extends ConsumerWidget {
  const _RefundList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(adminRefundPendingProvider);
    return async.when(
      loading: () => const Center(child: ProgressRing()),
      error: (e, _) => Padding(
        padding: const EdgeInsets.all(24),
        child: InfoBar(
          title: const Text('Erreur de chargement'),
          content: Text('$e'),
          severity: InfoBarSeverity.error,
        ),
      ),
      data: (list) {
        if (list.isEmpty) {
          return Center(
            child: Text(
              'Aucun remboursement à effectuer.',
              style: GoogleFonts.spaceGrotesk(
                color: ArenaColors.silver,
                fontSize: 14,
              ),
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          itemCount: list.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (_, i) => _RefundCard(row: list[i]),
        );
      },
    );
  }
}

class _RefundCard extends ConsumerWidget {
  const _RefundCard({required this.row});

  final AdminPaymentRow row;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final payment = row.payment;
    return Card(
      backgroundColor: ArenaColors.carbon,
      borderColor: ArenaColors.statusWarn.withValues(alpha: 0.4),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            row.username,
            style: GoogleFonts.spaceGrotesk(
              color: ArenaColors.bone,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${row.competitionName} · compétition annulée',
            style: GoogleFonts.spaceGrotesk(
              color: ArenaColors.silver,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 12),
          _refundKv(
            'À rembourser',
            '${adminMoney(payment.amountLocal)} ${payment.currency}',
            emphasize: true,
          ),
          _refundKv('Méthode', paymentMethodLabel(payment.payerMethod)),
          _refundKv('Numéro payeur', payment.payerPhone ?? '—'),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () => _refund(context, ref),
            child: const Text('Marquer remboursé'),
          ),
        ],
      ),
    );
  }

  Future<void> _refund(BuildContext context, WidgetRef ref) async {
    final adminId = ref.read(currentSessionProvider)?.user.id;
    if (adminId == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => ContentDialog(
        title: const Text('Marquer remboursé ?'),
        content: Text(
          'Confirme avoir reversé ${adminMoney(row.payment.amountLocal)} '
          '${row.payment.currency} à ${row.username} sur le '
          '${paymentMethodLabel(row.payment.payerMethod)} '
          '${row.payment.payerPhone ?? "—"} (compétition annulée).',
        ),
        actions: [
          Button(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Marquer remboursé'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final totpOk = await showDesktopTotpGate(
      context,
      ref,
      reason: 'Marquer un remboursement · '
          '${adminMoney(row.payment.amountLocal)} ${row.payment.currency}',
    );
    if (!totpOk || !context.mounted) return;
    try {
      await ref
          .read(adminPaymentsRepositoryProvider)
          .markRefunded(row.payment.id);
      await ref.read(adminAuditLogRepositoryProvider).record(
        adminId: adminId,
        action: 'payment_refunded',
        targetType: 'payment',
        targetId: row.payment.id,
        afterState: {
          'amount_local': row.payment.amountLocal,
          'currency': row.payment.currency,
        },
      );
      ref.invalidate(adminRefundPendingProvider);
      if (!context.mounted) return;
      await _showResult(
        context,
        'Remboursement marqué · ${row.username} notifié.',
        isError: false,
      );
    } catch (e) {
      if (!context.mounted) return;
      await _showResult(context, arenaErrorMessage(e), isError: true);
    }
  }

  Widget _refundKv(String key, String value, {bool emphasize = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
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
                color: emphasize ? ArenaColors.statusWarn : ArenaColors.bone,
                fontSize: 13,
                fontWeight: emphasize ? FontWeight.w700 : FontWeight.w400,
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
      loading: () => const Center(child: ProgressRing()),
      error: (e, _) => Padding(
        padding: const EdgeInsets.all(24),
        child: InfoBar(
          title: const Text('Erreur de chargement'),
          content: Text('$e'),
          severity: InfoBarSeverity.error,
        ),
      ),
      data: (list) {
        if (list.isEmpty) {
          return Center(
            child: Text(
              "Pas encore d'historique.",
              style: GoogleFonts.spaceGrotesk(
                color: ArenaColors.silver,
                fontSize: 14,
              ),
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          itemCount: list.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
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
    final payment = row.payment;
    final (label, color) = switch (payment.status) {
      'succeeded' => ('VALIDÉ', ArenaColors.statusOk),
      'rejected' => ('REFUSÉ', ArenaColors.neonRed),
      _ => ('—', ArenaColors.silver),
    };
    return Card(
      backgroundColor: ArenaColors.carbon,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  row.username,
                  style: GoogleFonts.spaceGrotesk(
                    color: ArenaColors.bone,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: color.withValues(alpha: 0.4)),
                ),
                child: Text(
                  label,
                  style: GoogleFonts.spaceGrotesk(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${row.competitionName} · ${adminMoney(payment.amountLocal)} '
            '${payment.currency} · ${paymentMethodLabel(payment.payerMethod)}',
            style: GoogleFonts.spaceGrotesk(
              color: ArenaColors.silver,
              fontSize: 12,
            ),
          ),
          if (payment.rejectionReason != null) ...[
            const SizedBox(height: 4),
            Text(
              'Refus : ${payment.rejectionReason}',
              style: GoogleFonts.spaceGrotesk(color: color, fontSize: 12),
            ),
          ],
          const SizedBox(height: 4),
          Text(
            DateFormat('dd/MM/yyyy HH:mm').format(
              (payment.validatedAt ?? payment.createdAt).toLocal(),
            ),
            style: GoogleFonts.spaceGrotesk(
              color: ArenaColors.silverDim,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

// _methodLabel → paymentMethodLabel (features_shared/admin/payment_labels.dart)

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
    id.length <= 8 ? id.toUpperCase() : id.substring(0, 8).toUpperCase();

/// Vignette de la capture d'inscription (bucket privé `payment-proofs`, URL
/// signée à la demande). Tap → aperçu plein cadre dans un ContentDialog.
class _DesktopProofPreview extends ConsumerWidget {
  const _DesktopProofPreview({required this.proofPath});

  final String proofPath;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final urlFuture =
        ref.watch(adminPaymentsRepositoryProvider).signedProofUrl(proofPath);
    return FutureBuilder<String?>(
      future: urlFuture,
      builder: (context, snap) {
        final url = snap.data;
        if (url == null) {
          return const SizedBox(height: 40, child: Center(child: ProgressRing()));
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Capture d'inscription (cliquer pour agrandir)",
              style: GoogleFonts.spaceGrotesk(
                color: ArenaColors.silver,
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 4),
            GestureDetector(
              onTap: () => _showFull(context, url),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  url,
                  height: 120,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 120,
                    color: ArenaColors.void_,
                    alignment: Alignment.center,
                    child: const Icon(FluentIcons.photo_error, size: 24),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showFull(BuildContext context, String url) {
    showDialog<void>(
      context: context,
      builder: (ctx) => ContentDialog(
        constraints: const BoxConstraints(maxWidth: 720),
        title: const Text("Capture d'inscription"),
        content: Image.network(url, fit: BoxFit.contain),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }
}
