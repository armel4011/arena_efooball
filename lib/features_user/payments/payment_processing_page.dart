import 'package:arena/core/router/user_router.dart';
import 'package:arena/core/services/payment_proof_uploader.dart';
import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/core/utils/arena_error_message.dart';
import 'package:arena/data/repositories/payment_repository.dart';
import 'package:arena/features_shared/widgets/arena_app_bar.dart';
import 'package:arena/features_shared/widgets/arena_button.dart';
import 'package:arena/features_shared/widgets/arena_image_viewer.dart';
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
    required this.operator,
    required this.amountXaf,
    required this.competitionName,
    required this.maskedPhone,
    super.key,
  });

  final String paymentId;
  final PaymentOperator operator;
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
            operator: widget.operator,
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
            operator: widget.operator,
          ),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final accent = widget.operator.brandColor;
    ref.watch(paymentByIdProvider(widget.paymentId)).whenData((rec) {
      if (rec != null) _handleStatus(context, rec);
    });
    // On y arrive par `go` depuis la saisie du paiement (pile remplacée) et
    // cette route est hors shell : rien dessous, donc le Retour SYSTÈME sortait
    // de l'app en plein flux d'argent — le paiement est déjà en
    // `awaiting_admin`. Même bug que #345, une page plus loin : la pile avait
    // été corrigée, pas le geste Retour. On le renvoie vers la sortie douce
    // déjà câblée sur l'AppBar (retour à l'accueil, paiement conservé).
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _leaveScreen(context);
      },
      child: Scaffold(
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
                  child: PaymentOperatorLogo(
                    operator: widget.operator,
                    size: 70,
                  ),
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
                    '${widget.operator.label}'
                    '${l10n.paymentProcessingWaitingSubtitleSuffix}',
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
                  operator: widget.operator,
                  amountXaf: widget.amountXaf,
                  competitionName: widget.competitionName,
                  maskedPhone: widget.maskedPhone,
                  paymentId: widget.paymentId,
                ),
                const SizedBox(height: ArenaSpacing.lg),
                _PaymentProofSection(paymentId: widget.paymentId),
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
    required this.operator,
    required this.amountXaf,
    required this.competitionName,
    required this.maskedPhone,
    required this.paymentId,
  });

  final PaymentOperator operator;
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
          _Row(
            label: l10n.paymentProcessingRecapCompetition,
            value: competitionName,
          ),
          const SizedBox(height: 4),
          _Row(
            label: l10n.paymentProcessingRecapAmount,
            value: '${_formatXaf(amountXaf)} XAF',
          ),
          const SizedBox(height: 4),
          _Row(label: l10n.paymentProcessingRecapMethod, value: operator.label),
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

/// Bloc « capture d'inscription » : le joueur joint une capture d'écran de son
/// paiement P2P pour aider le super-admin à valider. Upload dans le bucket
/// privé `payment-proofs` puis enregistrement de la clé via `attach_payment_proof`.
class _PaymentProofSection extends ConsumerStatefulWidget {
  const _PaymentProofSection({required this.paymentId});

  final String paymentId;

  @override
  ConsumerState<_PaymentProofSection> createState() =>
      _PaymentProofSectionState();
}

class _PaymentProofSectionState extends ConsumerState<_PaymentProofSection> {
  bool _busy = false;
  String? _error;

  Future<void> _addProof(String userId) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final messenger = ScaffoldMessenger.of(context);
    try {
      final uploader = ref.read(paymentProofUploaderProvider);
      final picked = await uploader.pick();
      if (picked == null) {
        if (mounted) setState(() => _busy = false);
        return; // annulé
      }
      final path = await uploader.upload(
        paymentId: widget.paymentId,
        userId: userId,
        proof: picked,
      );
      await ref.read(paymentRepositoryProvider).attachProof(
            paymentId: widget.paymentId,
            proofPath: path,
          );
      messenger.showSnackBar(
        const SnackBar(content: Text("Capture envoyée à l'admin.")),
      );
    } catch (e) {
      if (mounted) setState(() => _error = arenaErrorMessage(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final rec = ref.watch(paymentByIdProvider(widget.paymentId)).valueOrNull;
    if (rec == null) return const SizedBox.shrink();
    final hasProof = rec.hasProof;
    return Container(
      padding: const EdgeInsets.all(ArenaSpacing.lg),
      decoration: BoxDecoration(
        color: ArenaColors.carbon,
        borderRadius: BorderRadius.circular(ArenaRadius.lg),
        border: Border.all(color: ArenaColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Capture de votre inscription',
            style: ArenaText.body.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            "Joignez une capture d'écran de votre paiement Mobile Money : "
            'elle aide le super-admin à valider votre inscription plus vite.',
            style: ArenaText.small.copyWith(color: ArenaColors.silver),
          ),
          const SizedBox(height: ArenaSpacing.md),
          if (hasProof) ...[
            _ProofThumbnail(proofPath: rec.proofPath!),
            const SizedBox(height: ArenaSpacing.sm),
          ],
          if (_error != null) ...[
            Text(
              _error!,
              style: ArenaText.small.copyWith(color: ArenaColors.neonRed),
            ),
            const SizedBox(height: ArenaSpacing.sm),
          ],
          ArenaButton(
            label: _busy
                ? 'ENVOI…'
                : hasProof
                    ? 'REMPLACER LA CAPTURE'
                    : 'AJOUTER MA CAPTURE',
            variant: ArenaButtonVariant.secondary,
            fullWidth: true,
            isLoading: _busy,
            onPressed: _busy ? null : () => _addProof(rec.userId),
          ),
        ],
      ),
    );
  }
}

/// URL signée d'une capture, mémorisée par chemin de stockage.
///
/// Indispensable ici : le parent écoute `paymentByIdProvider`, un stream
/// realtime qui réémet à chaque tick. Appeler `signedProofUrl()` directement
/// dans `build` fabriquait un Future NEUF à chaque reconstruction — le
/// FutureBuilder repassait en spinner, et comme chaque URL signée porte un
/// token différent, la clé de cache d'`Image.network` changeait aussi : la
/// capture était re-téléchargée en boucle sur un écran fait pour rester ouvert.
final _signedProofUrlProvider =
    FutureProvider.autoDispose.family<String?, String>((ref, proofPath) {
  return ref.watch(paymentRepositoryProvider).signedProofUrl(proofPath);
});

/// Vignette cliquable de la capture jointe (URL signée à la demande).
class _ProofThumbnail extends ConsumerWidget {
  const _ProofThumbnail({required this.proofPath});

  final String proofPath;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final url = ref.watch(_signedProofUrlProvider(proofPath)).valueOrNull;
    if (url == null) {
      return const SizedBox(
        height: 120,
        child: Center(child: CircularProgressIndicator()),
      );
    }
    return GestureDetector(
      onTap: () => ArenaImageViewer.show(
        context,
        imageUrl: url,
        caption: "Capture d'inscription",
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(ArenaRadius.md),
        child: Image.network(
          url,
          height: 140,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            height: 140,
            color: ArenaColors.void_,
            alignment: Alignment.center,
            child: const Icon(Icons.broken_image, color: ArenaColors.silver),
          ),
        ),
      ),
    );
  }
}
