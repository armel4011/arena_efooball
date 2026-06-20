import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/core/utils/arena_error_message.dart';
import 'package:arena/data/models/profile.dart';
import 'package:arena/data/models/reintegration_request.dart';
import 'package:arena/data/repositories/admin/admin_audit_log_repository.dart';
import 'package:arena/data/repositories/profile_repository.dart';
import 'package:arena/data/repositories/reintegration_requests_repository.dart';
import 'package:arena/features_admin/auth_admin/widgets/totp_gate.dart';
import 'package:arena/features_shared/auth_common/shared_auth_providers.dart';
import 'package:arena/features_shared/widgets/arena_app_bar.dart';
import 'package:arena/features_shared/widgets/arena_badge.dart';
import 'package:arena/features_shared/widgets/arena_button.dart';
import 'package:arena/features_shared/widgets/arena_screen_background.dart';
import 'package:arena/features_shared/widgets/arena_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Phase 12.6 — Super-admin "Arena Requête" : traitement des demandes
/// de réintégration déposées par les utilisateurs bannis à vie.
///
/// SLA indicatif : 48h. Une requête ouverte depuis > 48h affiche un
/// badge ⏰ rouge pour pression visuelle — pas d'auto-décision.
class SuperAdminReintegrationRequests extends ConsumerWidget {
  const SuperAdminReintegrationRequests({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requests = ref.watch(pendingReintegrationRequestsProvider);

    return Scaffold(
      appBar: const ArenaAppBar(title: 'Arena Requête'),
      body: ArenaScreenBackground(
        accent: ArenaColors.neonRed,
        child: SafeArea(
          child: requests.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Padding(
              padding: const EdgeInsets.all(ArenaSpacing.lg),
              child: Text('Erreur : $e', style: ArenaText.bodyMuted),
            ),
            data: (list) {
              if (list.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(ArenaSpacing.xl),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.check_circle_outline,
                          color: ArenaColors.statusOk,
                          size: 48,
                        ),
                        const SizedBox(height: ArenaSpacing.sm),
                        Text(
                          'Aucune requête en attente',
                          style: ArenaText.h3,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Toutes les demandes de réintégration ont été '
                          'traitées.',
                          style: ArenaText.bodyMuted,
                          textAlign: TextAlign.center,
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
                itemBuilder: (_, i) => _RequestCard(request: list[i]),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _RequestCard extends ConsumerWidget {
  const _RequestCard({required this.request});
  final ReintegrationRequest request;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(_requestUserProvider(request.userId));
    final overdue = request.isOverdue;
    final accent = overdue ? ArenaColors.statusWarn : ArenaColors.signalBlue;

    return Container(
      padding: const EdgeInsets.all(ArenaSpacing.md),
      decoration: BoxDecoration(
        color: ArenaColors.carbon,
        border: Border(
          top: const BorderSide(color: ArenaColors.border),
          right: const BorderSide(color: ArenaColors.border),
          bottom: const BorderSide(color: ArenaColors.border),
          left: BorderSide(color: accent, width: 3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: profileAsync.when(
                  loading: () => Text('Chargement…', style: ArenaText.body),
                  error: (_, __) =>
                      Text('Utilisateur introuvable', style: ArenaText.body),
                  data: (p) => Text(
                    p?.username ?? '— inconnu —',
                    style: ArenaText.body.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              if (overdue)
                const ArenaBadge(
                  label: '⏰ EN RETARD',
                  variant: ArenaBadgeVariant.warn,
                )
              else
                const ArenaBadge(
                  label: 'EN ATTENTE',
                  variant: ArenaBadgeVariant.info,
                ),
            ],
          ),
          const SizedBox(height: 4),
          profileAsync.maybeWhen(
            data: (p) => p == null
                ? const SizedBox.shrink()
                : Text(p.email ?? '—', style: ArenaText.bodyMuted),
            orElse: () => const SizedBox.shrink(),
          ),
          const SizedBox(height: ArenaSpacing.sm),
          Text('Message', style: ArenaText.inputLabel),
          const SizedBox(height: 2),
          Text(request.message, style: ArenaText.body),
          const SizedBox(height: ArenaSpacing.xs),
          Text(
            'Soumis le ${_formatDate(request.createdAt)}',
            style: ArenaText.small,
          ),
          const SizedBox(height: ArenaSpacing.sm),
          Row(
            children: [
              Expanded(
                child: ArenaButton(
                  label: '✅ APPROUVER',
                  variant: ArenaButtonVariant.primary,
                  fullWidth: true,
                  onPressed: () => _approve(context, ref),
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: ArenaButton(
                  label: '❌ REFUSER',
                  variant: ArenaButtonVariant.danger,
                  fullWidth: true,
                  onPressed: () => _reject(context, ref),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _approve(BuildContext context, WidgetRef ref) async {
    final adminId = ref.read(currentSessionProvider)?.user.id;
    if (adminId == null) return;
    final totpOk = await TotpGate.confirm(
      context,
      ref,
      reason: 'Approuver la réintégration',
    );
    if (!totpOk || !context.mounted) return;

    final reason = await _promptForReason(
      context,
      title: 'Approuver la requête',
      hint: 'Note interne (optionnelle)…',
      required: false,
    );
    if (reason == null || !context.mounted) return;

    try {
      await ref
          .read(reintegrationRequestsRepositoryProvider)
          .approve(requestId: request.id, adminId: adminId, reason: reason);
      await ref.read(adminAuditLogRepositoryProvider).record(
        adminId: adminId,
        action: 'reintegration_approved',
        targetType: 'reintegration_request',
        targetId: request.id,
        afterState: {
          'user_id': request.userId,
          if (reason.isNotEmpty) 'reason': reason,
        },
      );
      ref.invalidate(pendingReintegrationRequestsProvider);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Réintégration approuvée.')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Échec : ${arenaErrorMessage(e)}')),
      );
    }
  }

  Future<void> _reject(BuildContext context, WidgetRef ref) async {
    final adminId = ref.read(currentSessionProvider)?.user.id;
    if (adminId == null) return;
    final reason = await _promptForReason(
      context,
      title: 'Refuser la requête',
      hint: "Motif du refus (obligatoire, visible par l'utilisateur)…",
      required: true,
    );
    if (reason == null || !context.mounted) return;
    final totpOk = await TotpGate.confirm(
      context,
      ref,
      reason: 'Refuser la réintégration',
    );
    if (!totpOk || !context.mounted) return;

    try {
      await ref
          .read(reintegrationRequestsRepositoryProvider)
          .reject(requestId: request.id, adminId: adminId, reason: reason);
      await ref.read(adminAuditLogRepositoryProvider).record(
        adminId: adminId,
        action: 'reintegration_rejected',
        targetType: 'reintegration_request',
        targetId: request.id,
        afterState: {'user_id': request.userId, 'reason': reason},
      );
      ref.invalidate(pendingReintegrationRequestsProvider);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Requête refusée.')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Échec : ${arenaErrorMessage(e)}')),
      );
    }
  }

  static String _formatDate(DateTime? date) {
    if (date == null) return '—';
    final d = date.toLocal();
    return '${d.day.toString().padLeft(2, '0')}/'
        '${d.month.toString().padLeft(2, '0')}/'
        '${d.year} ${d.hour.toString().padLeft(2, '0')}:'
        '${d.minute.toString().padLeft(2, '0')}';
  }
}

Future<String?> _promptForReason(
  BuildContext context, {
  required String title,
  required String hint,
  required bool required,
}) {
  return showDialog<String>(
    context: context,
    builder: (ctx) => _ReasonDialog(
      title: title,
      hint: hint,
      required: required,
    ),
  );
}

/// Dialog de saisie d'un motif. StatefulWidget pour POSSÉDER le
/// `TextEditingController` et le disposer dans [State.dispose] — ne jamais le
/// disposer via `showDialog(...).whenComplete(ctrl.dispose)` (crash
/// `_dependents.isEmpty`, cf. conventions UI).
class _ReasonDialog extends StatefulWidget {
  const _ReasonDialog({
    required this.title,
    required this.hint,
    required this.required,
  });

  final String title;
  final String hint;
  final bool required;

  @override
  State<_ReasonDialog> createState() => _ReasonDialogState();
}

class _ReasonDialogState extends State<_ReasonDialog> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: ArenaColors.carbon,
      title: Text(widget.title, style: ArenaText.h3),
      content: ArenaTextField(
        controller: _ctrl,
        hint: widget.hint,
        minLines: 3,
        maxLines: 6,
        maxLength: 500,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: Text(
            'Annuler',
            style: ArenaText.body.copyWith(color: ArenaColors.silver),
          ),
        ),
        TextButton(
          onPressed: () {
            final v = _ctrl.text.trim();
            if (widget.required && v.isEmpty) return;
            Navigator.of(context).pop(v);
          },
          child: Text(
            'Confirmer',
            style: ArenaText.body.copyWith(color: ArenaColors.signalBlue),
          ),
        ),
      ],
    );
  }
}

/// Cache local du profil associé à une requête. AutoDispose pour éviter
/// de fuir les profils des requêtes traitées entre les sessions admin.
final _requestUserProvider =
    FutureProvider.autoDispose.family<Profile?, String>((ref, userId) {
  return ref.watch(profileRepositoryProvider).getById(userId);
});
