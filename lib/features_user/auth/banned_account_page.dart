import 'package:arena/core/router/user_router.dart';
import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/data/models/reintegration_request.dart';
import 'package:arena/data/repositories/reintegration_requests_repository.dart';
import 'package:arena/features_shared/auth_common/shared_auth_providers.dart';
import 'package:arena/features_shared/widgets/arena_app_bar.dart';
import 'package:arena/features_shared/widgets/arena_button.dart';
import 'package:arena/features_shared/widgets/arena_text_field.dart';
import 'package:arena/features_user/auth/widgets/auth_error_banner.dart';
import 'package:arena/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Phase 12.6 — Écran de blocage affiché à un utilisateur banni à vie
/// (règle 3-strikes). Lui propose de déposer une requête de
/// réintégration auprès de l'équipe Arena Requête (SLA 48h).
///
/// États affichés :
/// - aucune requête → formulaire de soumission ;
/// - `pending`     → message "en cours d'analyse" + délai estimé ;
/// - `rejected`    → motif + bouton "Soumettre une nouvelle requête" ;
/// - `approved`    → ne devrait pas tomber ici (router redirige vers home
///                   dès que permanent_ban repasse à false).
class BannedAccountPage extends ConsumerStatefulWidget {
  const BannedAccountPage({super.key});

  @override
  ConsumerState<BannedAccountPage> createState() => _BannedAccountPageState();
}

class _BannedAccountPageState extends ConsumerState<BannedAccountPage> {
  final _messageCtrl = TextEditingController();
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _messageCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);
    final userId = ref.read(currentSessionProvider)?.user.id;
    if (userId == null) return;
    final text = _messageCtrl.text.trim();
    if (text.length < 10) {
      setState(
        () => _error = l10n.bannedMinLengthError,
      );
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await ref
          .read(reintegrationRequestsRepositoryProvider)
          .submit(userId: userId, message: text);
      _messageCtrl.clear();
      ref.invalidate(myReintegrationRequestProvider);
    } catch (e) {
      setState(
        () => _error = l10n.bannedSendError,
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _signOut() async {
    await ref.read(signOutProvider)();
    if (mounted) context.go(UserRoutes.splash);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final requestAsync = ref.watch(myReintegrationRequestProvider);

    return Scaffold(
      appBar: ArenaAppBar(
        title: l10n.bannedAppBarTitle,
        showBack: false,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(ArenaSpacing.lg),
          children: [
            const _BanHeader(),
            const SizedBox(height: ArenaSpacing.lg),
            requestAsync.when(
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(ArenaSpacing.lg),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (e, _) => Text(
                "Impossible de charger l'état de la requête : $e",
                style: ArenaText.bodyMuted,
              ),
              data: _buildRequestSection,
            ),
            const SizedBox(height: ArenaSpacing.xl),
            ArenaButton(
              label: l10n.bannedSignOut,
              variant: ArenaButtonVariant.secondary,
              fullWidth: true,
              onPressed: _submitting ? null : _signOut,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRequestSection(ReintegrationRequest? req) {
    if (req == null || req.isRejected) {
      return _buildFormSection(previousRejection: req);
    }
    if (req.isPending) {
      return _PendingCard(request: req);
    }
    // Approved — état transitoire avant que le router ne sorte de /banned.
    return _ApprovedCard(request: req);
  }

  Widget _buildFormSection({ReintegrationRequest? previousRejection}) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (previousRejection != null) ...[
          _RejectedCard(request: previousRejection),
          const SizedBox(height: ArenaSpacing.md),
        ],
        Text(l10n.bannedArenaRequestTitle, style: ArenaText.h3),
        const SizedBox(height: ArenaSpacing.xs),
        Text(
          l10n.bannedArenaRequestIntro,
          style: ArenaText.bodyMuted,
        ),
        const SizedBox(height: ArenaSpacing.sm),
        ArenaTextField(
          controller: _messageCtrl,
          hint: l10n.bannedMessageHint,
          minLines: 5,
          maxLines: 10,
          maxLength: 2000,
        ),
        if (_error != null) ...[
          const SizedBox(height: ArenaSpacing.xs),
          AuthErrorBanner(message: _error!),
        ],
        const SizedBox(height: ArenaSpacing.sm),
        ArenaButton(
          label: _submitting
              ? l10n.bannedSendingLabel
              : l10n.bannedSendRequestLabel,
          fullWidth: true,
          size: ArenaButtonSize.large,
          isLoading: _submitting,
          onPressed: _submitting ? null : _submit,
        ),
      ],
    );
  }
}

class _BanHeader extends StatelessWidget {
  const _BanHeader();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(ArenaSpacing.lg),
      decoration: BoxDecoration(
        color: ArenaColors.neonRed.withValues(alpha: 0.08),
        border: Border.all(color: ArenaColors.neonRed),
        borderRadius: BorderRadius.circular(ArenaRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.block,
                color: ArenaColors.neonRed,
                size: 28,
              ),
              const SizedBox(width: ArenaSpacing.sm),
              Expanded(
                child: Text(
                  l10n.bannedPermanentTitle,
                  style: ArenaText.h3.copyWith(color: ArenaColors.neonRed),
                ),
              ),
            ],
          ),
          const SizedBox(height: ArenaSpacing.sm),
          Text(
            l10n.bannedPermanentBody,
            style: ArenaText.body,
          ),
        ],
      ),
    );
  }
}

class _PendingCard extends StatelessWidget {
  const _PendingCard({required this.request});
  final ReintegrationRequest request;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final overdue = request.isOverdue;
    final accent = overdue ? ArenaColors.statusWarn : ArenaColors.signalBlue;
    return Container(
      padding: const EdgeInsets.all(ArenaSpacing.md),
      decoration: BoxDecoration(
        color: ArenaColors.carbon,
        border: Border.all(color: accent),
        borderRadius: BorderRadius.circular(ArenaRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                overdue ? Icons.access_time_filled : Icons.hourglass_top,
                color: accent,
              ),
              const SizedBox(width: ArenaSpacing.sm),
              Expanded(
                child: Text(
                  overdue
                      ? l10n.bannedOverdueTitle
                      : l10n.bannedPendingTitle,
                  style: ArenaText.h3.copyWith(color: accent),
                ),
              ),
            ],
          ),
          const SizedBox(height: ArenaSpacing.sm),
          Text(
            overdue ? l10n.bannedOverdueBody : l10n.bannedPendingBody,
            style: ArenaText.bodyMuted,
          ),
          const SizedBox(height: ArenaSpacing.sm),
          Text(l10n.bannedYourMessageLabel, style: ArenaText.inputLabel),
          const SizedBox(height: 4),
          Text(request.message, style: ArenaText.body),
        ],
      ),
    );
  }
}

class _RejectedCard extends StatelessWidget {
  const _RejectedCard({required this.request});
  final ReintegrationRequest request;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(ArenaSpacing.md),
      decoration: BoxDecoration(
        color: ArenaColors.carbon,
        border: Border.all(color: ArenaColors.neonRed),
        borderRadius: BorderRadius.circular(ArenaRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.bannedRejectedTitle,
            style: ArenaText.h3.copyWith(color: ArenaColors.neonRed),
          ),
          if (request.resolutionReason != null &&
              request.resolutionReason!.isNotEmpty) ...[
            const SizedBox(height: ArenaSpacing.xs),
            Text(l10n.bannedReasonLabel, style: ArenaText.inputLabel),
            const SizedBox(height: 2),
            Text(request.resolutionReason!, style: ArenaText.body),
          ],
          const SizedBox(height: ArenaSpacing.sm),
          Text(
            l10n.bannedRejectedBody,
            style: ArenaText.bodyMuted,
          ),
        ],
      ),
    );
  }
}

class _ApprovedCard extends StatelessWidget {
  const _ApprovedCard({required this.request});
  final ReintegrationRequest request;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(ArenaSpacing.md),
      decoration: BoxDecoration(
        color: ArenaColors.statusOk.withValues(alpha: 0.08),
        border: Border.all(color: ArenaColors.statusOk),
        borderRadius: BorderRadius.circular(ArenaRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.bannedApprovedTitle,
            style: ArenaText.h3.copyWith(color: ArenaColors.statusOk),
          ),
          const SizedBox(height: ArenaSpacing.xs),
          Text(
            l10n.bannedApprovedBody,
            style: ArenaText.body,
          ),
        ],
      ),
    );
  }
}
