import 'package:arena/core/router/user_router.dart';
import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/data/repositories/payment_repository.dart';
import 'package:arena/features_shared/widgets/arena_app_bar.dart';
import 'package:arena/features_shared/widgets/arena_button.dart';
import 'package:arena/features_shared/widgets/arena_screen_background.dart';
import 'package:arena/features_user/payments/payment_failed_page.dart';
import 'package:arena/features_user/payments/payment_method.dart';
import 'package:arena/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

/// PHASE 11bis · P3 — Attente de validation par le super-admin.
///
/// Une fois "J'AI PAYÉ" cliqué sur P2, le row `payments` est inséré en
/// `status='awaiting_admin'`. Cette page :
///   • stream le status du row en realtime
///   • bascule sur P4 si `status='succeeded'`
///   • bascule sur P5 si `status='rejected'` (refus admin)
///
/// Pas de timeout : la page reste en attente indéfiniment jusqu'à ce
/// que le super-admin valide ou refuse. L'utilisateur peut quitter
/// l'app et revenir plus tard via l'historique paiements.
///
/// Maps to screen P3 of `arena_v2.html` (mais sans WebView CinetPay).
class PaymentProcessingPage extends ConsumerStatefulWidget {
  const PaymentProcessingPage({
    required this.paymentId,
    required this.method,
    required this.amountXaf,
    required this.competitionName,
    required this.maskedPhone,
    super.key,
  });

  final String paymentId;
  final PaymentMethod method;
  final int amountXaf;
  final String competitionName;
  final String maskedPhone;

  @override
  ConsumerState<PaymentProcessingPage> createState() =>
      _PaymentProcessingPageState();
}

class _PaymentProcessingPageState extends ConsumerState<PaymentProcessingPage> {
  bool _navigatedAway = false;

  void _handleStatus(BuildContext context, PaymentRecord rec) {
    if (_navigatedAway) return;
    if (rec.status == 'succeeded') {
      _navigatedAway = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        context.go(
          UserRoutes.paymentSuccess,
          extra: PaymentResultArgs(
            method: widget.method,
            amountXaf: widget.amountXaf,
            transactionId: 'ARENA-${rec.id.substring(0, 8).toUpperCase()}',
            dateLabel: DateFormat('dd/MM HH:mm').format(
              (rec.validatedAt ?? rec.createdAt).toLocal(),
            ),
            tournamentName: widget.competitionName,
            competitionId: rec.competitionId,
          ),
        );
      });
    } else if (rec.status == 'rejected') {
      _navigatedAway = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        context.go(
          UserRoutes.paymentFailed,
          extra: PaymentFailedArgs(
            reason: PaymentFailReason.rejected,
            adminReason: rec.rejectionReason,
            method: widget.method,
          ),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final accent = widget.method.brandColor;
    ref.watch(paymentByIdProvider(widget.paymentId)).whenData((rec) {
      if (rec != null) _handleStatus(context, rec);
    });
    return Scaffold(
      backgroundColor: ArenaColors.void_,
      appBar: ArenaAppBar(
        title: l10n.paymentProcessingAppBarTitle,
        onBack: () => _leaveScreen(context),
      ),
      body: ArenaScreenBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(ArenaSpacing.lg),
            children: [
              const SizedBox(height: ArenaSpacing.lg),
              Center(
                child: PaymentMethodLogo(method: widget.method, size: 70),
              ),
              const SizedBox(height: ArenaSpacing.md),
              Center(
                child: Text(
                  l10n.paymentProcessingWaitingTitle,
                  textAlign: TextAlign.center,
                  style: ArenaText.h1.copyWith(fontSize: 22),
                ),
              ),
              const SizedBox(height: ArenaSpacing.sm),
              Center(
                child: Text(
                  '${l10n.paymentProcessingWaitingSubtitle}'
                  '${widget.method.label}.',
                  textAlign: TextAlign.center,
                  style: ArenaText.bodyMuted,
                ),
              ),
              const SizedBox(height: ArenaSpacing.xl),
              Center(
                child: SizedBox(
                  width: 36,
                  height: 36,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation(accent),
                  ),
                ),
              ),
              const SizedBox(height: ArenaSpacing.lg),
              _PaymentRecap(
                method: widget.method,
                amountXaf: widget.amountXaf,
                competitionName: widget.competitionName,
                maskedPhone: widget.maskedPhone,
                paymentId: widget.paymentId,
              ),
              const SizedBox(height: ArenaSpacing.lg),
              Container(
                padding: const EdgeInsets.all(ArenaSpacing.md),
                decoration: BoxDecoration(
                  color: ArenaColors.carbon,
                  borderRadius: BorderRadius.circular(ArenaRadius.md),
                  border: Border.all(color: ArenaColors.border),
                ),
                child: Text(
                  l10n.paymentProcessingInfoNote,
                  style: ArenaText.small,
                ),
              ),
              const SizedBox(height: ArenaSpacing.lg),
              ArenaButton(
                label: l10n.paymentProcessingLeaveButton,
                variant: ArenaButtonVariant.secondary,
                fullWidth: true,
                onPressed: () => _leaveScreen(context),
              ),
              const SizedBox(height: ArenaSpacing.sm),
              ArenaButton(
                label: l10n.paymentProcessingCancelButton,
                variant: ArenaButtonVariant.ghost,
                fullWidth: true,
                onPressed: () => _confirmCancel(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Quitte la page sans annuler le paiement — la row payment reste
  /// en `awaiting_admin`, l'utilisateur peut revenir depuis l'historique
  /// ou la bannière home.
  void _leaveScreen(BuildContext context) {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    } else {
      context.go(UserRoutes.home);
    }
  }

  Future<void> _confirmCancel(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ArenaColors.carbon,
        title: Text(l10n.paymentProcessingCancelDialogTitle),
        content: Text(l10n.paymentProcessingCancelDialogBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.paymentProcessingCancelDialogStay),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: ArenaColors.neonRed),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.paymentProcessingCancelDialogConfirm),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    await ref.read(paymentRepositoryProvider).cancel(widget.paymentId);
    if (!context.mounted) return;
    context.go(UserRoutes.home);
  }
}

class _PaymentRecap extends StatelessWidget {
  const _PaymentRecap({
    required this.method,
    required this.amountXaf,
    required this.competitionName,
    required this.maskedPhone,
    required this.paymentId,
  });

  final PaymentMethod method;
  final int amountXaf;
  final String competitionName;
  final String maskedPhone;
  final String paymentId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(ArenaSpacing.lg),
      decoration: BoxDecoration(
        color: ArenaColors.carbon,
        borderRadius: BorderRadius.circular(ArenaRadius.lg),
        border: Border.all(color: ArenaColors.border),
      ),
      child: Column(
        children: [
          _Row(label: l10n.paymentProcessingRecapCompetition, value: competitionName),
          const SizedBox(height: 4),
          _Row(label: l10n.paymentProcessingRecapAmount, value: '${_formatXaf(amountXaf)} XAF'),
          const SizedBox(height: 4),
          _Row(label: l10n.paymentProcessingRecapMethod, value: method.label),
          const SizedBox(height: 4),
          _Row(label: l10n.paymentProcessingRecapPhone, value: maskedPhone),
          const SizedBox(height: 4),
          _Row(
            label: l10n.paymentProcessingRecapReference,
            value: 'ARENA-${paymentId.substring(0, 8).toUpperCase()}',
            mono: true,
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value, this.mono = false});
  final String label;
  final String value;
  final bool mono;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(child: Text(label, style: ArenaText.bodyMuted)),
        Text(
          value,
          style: mono ? ArenaText.mono : ArenaText.body,
        ),
      ],
    );
  }
}

String _formatXaf(int amount) {
  final s = amount.toString();
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write(' ');
    buf.write(s[i]);
  }
  return buf.toString();
}
