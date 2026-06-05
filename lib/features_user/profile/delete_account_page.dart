import 'package:arena/core/router/user_router.dart';
import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/data/repositories/payment_repository.dart';
import 'package:arena/data/repositories/profile_repository.dart';
import 'package:arena/features_shared/widgets/arena_app_bar.dart';
import 'package:arena/features_shared/widgets/arena_button.dart';
import 'package:arena/features_shared/widgets/arena_card.dart';
import 'package:arena/features_shared/widgets/arena_screen_background.dart';
import 'package:arena/features_shared/widgets/arena_text_field.dart';
import 'package:arena/features_user/auth/auth_providers.dart';
import 'package:arena/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// 4-step RGPD-compliant account deletion flow (PHASE 9.3).
///
/// 1. Warning — what the user is about to lose.
/// 2. Pending earnings check — V1.0 has no payouts yet, so this almost
///    always shows "rien à débloquer", but the screen is wired so the
///    flow stays correct once `payments` is populated in PHASE 11bis.
/// 3. Confirmation — re-enter password + literally type `SUPPRIMER`.
/// 4. Done — soft-delete row + sign-out + go home.
///
/// Soft-delete writes `account_deletion_requested_at`, `deleted_at`,
/// `account_deletion_reason`, `is_active = false`. The Edge Function
/// `cleanup_deleted_accounts` (PHASE 12.5, cron 24h) anonymises rows
/// older than 30 days.
class DeleteAccountPage extends ConsumerStatefulWidget {
  const DeleteAccountPage({super.key});

  @override
  ConsumerState<DeleteAccountPage> createState() => _DeleteAccountPageState();
}

class _DeleteAccountPageState extends ConsumerState<DeleteAccountPage> {
  int _step = 0;
  bool _hasPendingPayments = false;
  bool _checkingPayments = true;
  String? _checkError;

  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _reasonCtrl = TextEditingController();
  bool _submitting = false;
  String? _submitError;

  @override
  void initState() {
    super.initState();
    Future.microtask(_checkPendingEarnings);
  }

  @override
  void dispose() {
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    _reasonCtrl.dispose();
    super.dispose();
  }

  Future<void> _checkPendingEarnings() async {
    final profile = ref.read(currentProfileProvider).valueOrNull;
    if (profile == null) {
      setState(() => _checkingPayments = false);
      return;
    }
    try {
      final hasPending = await ref
          .read(paymentRepositoryProvider)
          .hasPendingPayments(profile.id);
      setState(() {
        _hasPendingPayments = hasPending;
        _checkingPayments = false;
      });
    } catch (e) {
      // Table might not exist yet on remote (PHASE 11bis). Don't block
      // the deletion flow on that — assume no pending payments.
      setState(() {
        _checkError = e.toString();
        _hasPendingPayments = false;
        _checkingPayments = false;
      });
    }
  }

  Future<void> _submit() async {
    final profile = ref.read(currentProfileProvider).valueOrNull;
    if (profile == null) return;
    setState(() {
      _submitting = true;
      _submitError = null;
    });
    try {
      // Re-authenticate to confirm password ownership before any write.
      await Supabase.instance.client.auth.signInWithPassword(
        email: profile.email,
        password: _passwordCtrl.text,
      );
      await ref.read(profileRepositoryProvider).requestAccountDeletion(
            id: profile.id,
            reason: _reasonCtrl.text.trim().isEmpty
                ? null
                : _reasonCtrl.text.trim(),
          );
      await ref.read(signOutProvider)();
      if (mounted) {
        setState(() => _step = 3);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _submitError = e.toString();
          _submitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final stepLabels = <String>[
      l10n.deleteAccountStepWarning,
      l10n.deleteAccountStepPendingEarnings,
      l10n.deleteAccountStepConfirmation,
      l10n.deleteAccountStepDone,
    ];
    final stepNum = (_step + 1).toString().padLeft(2, '0');
    return Scaffold(
      appBar: ArenaAppBar(
        title: l10n.deleteAccountAppBarTitle,
        showBack: _step != 3,
        onBack: _step == 3
            ? null
            : () {
                if (_step == 0) {
                  context.pop();
                } else {
                  setState(() => _step--);
                }
              },
      ),
      body: ArenaScreenBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(ArenaSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _StepIndicator(current: _step),
                const SizedBox(height: ArenaSpacing.sm),
                // Caption mono rouge "ÉTAPE 03/04 · CONFIRMATION"
                // (maquette #27 `m-text-caption color: var(--neon-red)`).
                Text(
                  'ÉTAPE $stepNum/04 · ${stepLabels[_step]}',
                  style: ArenaText.monoSmall.copyWith(
                    color: ArenaColors.neonRed,
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: ArenaSpacing.lg),
                Expanded(child: _buildBody()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    return switch (_step) {
      0 => _StepWarning(onContinue: () => setState(() => _step = 1)),
      1 => _StepPending(
          checking: _checkingPayments,
          hasPending: _hasPendingPayments,
          checkError: _checkError,
          onContinue: () => setState(() => _step = 2),
        ),
      2 => _StepConfirm(
          passwordCtrl: _passwordCtrl,
          confirmCtrl: _confirmCtrl,
          reasonCtrl: _reasonCtrl,
          submitting: _submitting,
          error: _submitError,
          onSubmit: _submit,
        ),
      _ => const _StepDone(),
    };
  }
}

class _StepIndicator extends StatelessWidget {
  const _StepIndicator({required this.current});
  final int current;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < 4; i++)
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: i == 3 ? 0 : ArenaSpacing.xs),
              child: Container(
                height: 4,
                decoration: BoxDecoration(
                  color: i <= current
                      ? ArenaColors.danger
                      : ArenaColors.surfaceLight,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _StepWarning extends StatelessWidget {
  const _StepWarning({required this.onContinue});
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final losses = <(IconData, String)>[
      (Icons.history, l10n.deleteAccountLossHistory),
      (Icons.emoji_events_outlined, l10n.deleteAccountLossBadges),
      (Icons.chat_bubble_outline, l10n.deleteAccountLossChats),
      (Icons.payments_outlined, l10n.deleteAccountLossPaymentMethods),
    ];
    return ListView(
      children: [
        Row(
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              color: ArenaColors.danger,
              size: 32,
            ),
            const SizedBox(width: ArenaSpacing.sm),
            Expanded(
              child: Text(
                l10n.deleteAccountIrreversibleTitle,
                style: ArenaTypography.headlineMedium
                    .copyWith(color: ArenaColors.danger),
              ),
            ),
          ],
        ),
        const SizedBox(height: ArenaSpacing.md),
        Text(
          l10n.deleteAccountLossIntro,
          style: ArenaTypography.bodyLarge,
        ),
        const SizedBox(height: ArenaSpacing.md),
        ArenaCard(
          child: Column(
            children: [
              for (var i = 0; i < losses.length; i++) ...[
                Row(
                  children: [
                    Icon(losses[i].$1, color: ArenaColors.textMuted),
                    const SizedBox(width: ArenaSpacing.md),
                    Expanded(
                      child: Text(
                        losses[i].$2,
                        style: ArenaTypography.bodyMedium,
                      ),
                    ),
                  ],
                ),
                if (i < losses.length - 1)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: ArenaSpacing.sm),
                    child: Divider(height: 1, color: ArenaColors.border),
                  ),
              ],
            ],
          ),
        ),
        const SizedBox(height: ArenaSpacing.md),
        Text(
          l10n.deleteAccountRetentionNotice,
          style: ArenaTypography.bodySmall,
        ),
        const SizedBox(height: ArenaSpacing.xl),
        ArenaButton(
          label: l10n.deleteAccountUnderstandContinue,
          variant: ArenaButtonVariant.danger,
          fullWidth: true,
          onPressed: onContinue,
        ),
      ],
    );
  }
}

class _StepPending extends StatelessWidget {
  const _StepPending({
    required this.checking,
    required this.hasPending,
    required this.checkError,
    required this.onContinue,
  });
  final bool checking;
  final bool hasPending;
  final String? checkError;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (checking) {
      return const Center(child: CircularProgressIndicator());
    }
    if (hasPending) {
      return Column(
        children: [
          const Icon(Icons.payments, size: 48, color: ArenaColors.warning),
          const SizedBox(height: ArenaSpacing.md),
          Text(
            l10n.deleteAccountHasPendingTitle,
            style: ArenaTypography.headlineMedium
                .copyWith(color: ArenaColors.warning),
          ),
          const SizedBox(height: ArenaSpacing.md),
          Text(
            l10n.deleteAccountHasPendingBody,
            textAlign: TextAlign.center,
            style: ArenaTypography.bodyMedium,
          ),
          const Spacer(),
          ArenaButton(
            label: l10n.deleteAccountBack,
            variant: ArenaButtonVariant.secondary,
            fullWidth: true,
            onPressed: () => context.pop(),
          ),
        ],
      );
    }
    return Column(
      children: [
        const Icon(
          Icons.check_circle_outline,
          size: 48,
          color: ArenaColors.success,
        ),
        const SizedBox(height: ArenaSpacing.md),
        Text(
          l10n.deleteAccountNoPendingTitle,
          style: ArenaTypography.headlineMedium,
        ),
        const SizedBox(height: ArenaSpacing.md),
        Text(
          l10n.deleteAccountNoPendingBody,
          textAlign: TextAlign.center,
          style: ArenaTypography.bodyMedium,
        ),
        if (checkError != null) ...[
          const SizedBox(height: ArenaSpacing.md),
          Text(
            'Note: vérification non concluante (table indisponible). '
            'Détail: $checkError',
            style: ArenaTypography.bodySmall.copyWith(
              color: ArenaColors.textFaint,
            ),
            textAlign: TextAlign.center,
          ),
        ],
        const Spacer(),
        ArenaButton(
          label: l10n.deleteAccountContinue,
          variant: ArenaButtonVariant.danger,
          fullWidth: true,
          onPressed: onContinue,
        ),
      ],
    );
  }
}

class _StepConfirm extends StatefulWidget {
  const _StepConfirm({
    required this.passwordCtrl,
    required this.confirmCtrl,
    required this.reasonCtrl,
    required this.submitting,
    required this.error,
    required this.onSubmit,
  });
  final TextEditingController passwordCtrl;
  final TextEditingController confirmCtrl;
  final TextEditingController reasonCtrl;
  final bool submitting;
  final String? error;
  final VoidCallback onSubmit;

  @override
  State<_StepConfirm> createState() => _StepConfirmState();
}

class _StepConfirmState extends State<_StepConfirm> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final confirmWord = l10n.deleteAccountConfirmWord;
    final canSubmit = widget.passwordCtrl.text.length >= 8 &&
        widget.confirmCtrl.text.trim().toUpperCase() == confirmWord &&
        !widget.submitting;

    return ListView(
      children: [
        Text(
          l10n.deleteAccountConfirmTitle,
          style: ArenaTypography.headlineMedium
              .copyWith(color: ArenaColors.danger),
        ),
        const SizedBox(height: ArenaSpacing.lg),
        ArenaTextField(
          label: l10n.deleteAccountPasswordLabel,
          controller: widget.passwordCtrl,
          obscureText: true,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: ArenaSpacing.md),
        ArenaTextField(
          label: 'Tape "$confirmWord" pour confirmer',
          controller: widget.confirmCtrl,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp('[A-Za-z]')),
          ],
          onChanged: (_) => setState(() {}),
          autofocus: false,
        ),
        const SizedBox(height: ArenaSpacing.md),
        ArenaTextField(
          label: l10n.deleteAccountReasonLabel,
          controller: widget.reasonCtrl,
          maxLines: 3,
          minLines: 2,
        ),
        if (widget.error != null) ...[
          const SizedBox(height: ArenaSpacing.md),
          Text(
            widget.error!,
            style:
                ArenaTypography.bodySmall.copyWith(color: ArenaColors.danger),
          ),
        ],
        const SizedBox(height: ArenaSpacing.xl),
        ArenaButton(
          label: l10n.deleteAccountDeletePermanently,
          variant: ArenaButtonVariant.danger,
          isLoading: widget.submitting,
          fullWidth: true,
          onPressed: canSubmit ? widget.onSubmit : null,
        ),
      ],
    );
  }
}

class _StepDone extends StatelessWidget {
  const _StepDone();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      children: [
        const SizedBox(height: ArenaSpacing.xxl),
        const Icon(Icons.check_circle, size: 64, color: ArenaColors.success),
        const SizedBox(height: ArenaSpacing.lg),
        Text(
          l10n.deleteAccountDoneTitle,
          style: ArenaTypography.headlineMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: ArenaSpacing.md),
        Text(
          l10n.deleteAccountDoneBody,
          style: ArenaTypography.bodyMedium,
          textAlign: TextAlign.center,
        ),
        const Spacer(),
        ArenaButton(
          label: l10n.deleteAccountBackToHome,
          fullWidth: true,
          onPressed: () => context.go(UserRoutes.splash),
        ),
      ],
    );
  }
}
