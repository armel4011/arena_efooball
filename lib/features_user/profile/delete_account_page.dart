import 'package:arena/core/router/user_router.dart';
import 'package:arena/core/theme/arena_colors.dart';
import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/core/theme/arena_typography.dart';
import 'package:arena/data/repositories/profile_repository.dart';
import 'package:arena/features_shared/widgets/arena_button.dart';
import 'package:arena/features_shared/widgets/arena_card.dart';
import 'package:arena/features_shared/widgets/arena_text_field.dart';
import 'package:arena/features_user/auth/auth_providers.dart';
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
    final profile = ref.read(currentProfileProvider).value;
    if (profile == null) {
      setState(() => _checkingPayments = false);
      return;
    }
    try {
      final rows = await Supabase.instance.client
          .from('payments')
          .select('id')
          .eq('user_id', profile.id)
          .eq('status', 'pending')
          .limit(1);
      setState(() {
        _hasPendingPayments = rows.isNotEmpty;
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
    final profile = ref.read(currentProfileProvider).value;
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
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _step == 3
              ? null
              : () {
                  if (_step == 0) {
                    context.pop();
                  } else {
                    setState(() => _step--);
                  }
                },
        ),
        title: const Text('SUPPRIMER MON COMPTE'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(ArenaSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _StepIndicator(current: _step),
              const SizedBox(height: ArenaSpacing.lg),
              Expanded(child: _buildBody()),
            ],
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

  static const _losses = <(IconData, String)>[
    (Icons.history, 'Tout ton historique de matchs et de tournois'),
    (Icons.emoji_events_outlined, 'Tes badges et accomplissements'),
    (Icons.chat_bubble_outline, 'Tes conversations et chats de match'),
    (Icons.payments_outlined, 'Tes méthodes de paiement enregistrées'),
  ];

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        Row(
          children: [
            const Icon(Icons.warning_amber_rounded,
                color: ArenaColors.danger, size: 32),
            const SizedBox(width: ArenaSpacing.sm),
            Expanded(
              child: Text(
                'Cette action est irréversible',
                style: ArenaTypography.headlineMedium
                    .copyWith(color: ArenaColors.danger),
              ),
            ),
          ],
        ),
        const SizedBox(height: ArenaSpacing.md),
        Text(
          'En supprimant ton compte, tu vas perdre :',
          style: ArenaTypography.bodyLarge,
        ),
        const SizedBox(height: ArenaSpacing.md),
        ArenaCard(
          child: Column(
            children: [
              for (var i = 0; i < _losses.length; i++) ...[
                Row(
                  children: [
                    Icon(_losses[i].$1, color: ArenaColors.textMuted),
                    const SizedBox(width: ArenaSpacing.md),
                    Expanded(
                      child: Text(
                        _losses[i].$2,
                        style: ArenaTypography.bodyMedium,
                      ),
                    ),
                  ],
                ),
                if (i < _losses.length - 1)
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
          'Ton compte sera désactivé immédiatement, puis définitivement '
          'supprimé sous 30 jours. Pendant ce délai, tu peux contacter le '
          'support pour annuler la suppression.',
          style: ArenaTypography.bodySmall,
        ),
        const SizedBox(height: ArenaSpacing.xl),
        ArenaButton(
          label: 'JE COMPRENDS, CONTINUER',
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
    if (checking) {
      return const Center(child: CircularProgressIndicator());
    }
    if (hasPending) {
      return Column(
        children: [
          const Icon(Icons.payments, size: 48, color: ArenaColors.warning),
          const SizedBox(height: ArenaSpacing.md),
          Text(
            'Tu as des gains en attente',
            style: ArenaTypography.headlineMedium
                .copyWith(color: ArenaColors.warning),
          ),
          const SizedBox(height: ArenaSpacing.md),
          Text(
            'Récupère tes paiements en attente avant de supprimer ton '
            "compte. Une fois supprimé, ces fonds ne pourront plus t'être "
            'envoyés.',
            textAlign: TextAlign.center,
            style: ArenaTypography.bodyMedium,
          ),
          const Spacer(),
          ArenaButton(
            label: 'RETOUR',
            variant: ArenaButtonVariant.secondary,
            fullWidth: true,
            onPressed: () => context.pop(),
          ),
        ],
      );
    }
    return Column(
      children: [
        const Icon(Icons.check_circle_outline,
            size: 48, color: ArenaColors.success),
        const SizedBox(height: ArenaSpacing.md),
        Text(
          'Aucun gain en attente',
          style: ArenaTypography.headlineMedium,
        ),
        const SizedBox(height: ArenaSpacing.md),
        Text(
          'Tu peux poursuivre la suppression sans risque de perdre des '
          'paiements en cours.',
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
          label: 'CONTINUER',
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
  static const _confirmWord = 'SUPPRIMER';

  @override
  Widget build(BuildContext context) {
    final canSubmit = widget.passwordCtrl.text.length >= 8 &&
        widget.confirmCtrl.text.trim().toUpperCase() == _confirmWord &&
        !widget.submitting;

    return ListView(
      children: [
        Text(
          'Confirme la suppression',
          style: ArenaTypography.headlineMedium
              .copyWith(color: ArenaColors.danger),
        ),
        const SizedBox(height: ArenaSpacing.lg),
        ArenaTextField(
          label: 'Mot de passe',
          controller: widget.passwordCtrl,
          obscureText: true,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: ArenaSpacing.md),
        ArenaTextField(
          label: 'Tape "$_confirmWord" pour confirmer',
          controller: widget.confirmCtrl,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z]')),
          ],
          onChanged: (_) => setState(() {}),
          autofocus: false,
        ),
        const SizedBox(height: ArenaSpacing.md),
        ArenaTextField(
          label: 'Raison (optionnel)',
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
          label: 'SUPPRIMER DÉFINITIVEMENT',
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
    return Column(
      children: [
        const SizedBox(height: ArenaSpacing.xxl),
        const Icon(Icons.check_circle, size: 64, color: ArenaColors.success),
        const SizedBox(height: ArenaSpacing.lg),
        Text(
          'Compte désactivé',
          style: ArenaTypography.headlineMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: ArenaSpacing.md),
        Text(
          "Ton compte sera définitivement supprimé sous 30 jours. "
          'Contacte le support si tu changes d\'avis.',
          style: ArenaTypography.bodyMedium,
          textAlign: TextAlign.center,
        ),
        const Spacer(),
        ArenaButton(
          label: "RETOUR À L'ACCUEIL",
          fullWidth: true,
          onPressed: () => context.go(UserRoutes.splash),
        ),
      ],
    );
  }
}
