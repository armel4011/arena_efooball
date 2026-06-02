import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/core/utils/arena_error_message.dart';
import 'package:arena/data/models/profile.dart';
import 'package:arena/data/models/reintegration_request.dart';
import 'package:arena/data/repositories/admin/admin_audit_log_repository.dart';
import 'package:arena/data/repositories/profile_repository.dart';
import 'package:arena/data/repositories/reintegration_requests_repository.dart';
import 'package:arena/features_admin_desktop/shared/desktop_totp_gate.dart';
import 'package:arena/features_shared/auth_common/shared_auth_providers.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

/// Super-admin · Réintégration (desktop) — demandes des utilisateurs
/// bannis à vie (canal « Arena Requête »), avec traitement
/// approuver / refuser protégé par le step-up TOTP.
///
/// Réutilise [pendingReintegrationRequestsProvider],
/// [reintegrationRequestsRepositoryProvider],
/// [adminAuditLogRepositoryProvider] et [profileRepositoryProvider]
/// (mêmes providers que le mobile).
class DesktopReintegrationPage extends ConsumerWidget {
  const DesktopReintegrationPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requestsAsync = ref.watch(pendingReintegrationRequestsProvider);

    return ScaffoldPage(
      header: PageHeader(
        title: const Text('DEMANDES DE RÉINTÉGRATION'),
        commandBar: CommandBar(
          mainAxisAlignment: MainAxisAlignment.end,
          primaryItems: [
            CommandBarButton(
              icon: const Icon(FluentIcons.refresh),
              label: const Text('Actualiser'),
              onPressed: () =>
                  ref.invalidate(pendingReintegrationRequestsProvider),
            ),
          ],
        ),
      ),
      content: requestsAsync.when(
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
                    'Aucune requête en attente.',
                    style: GoogleFonts.spaceGrotesk(
                      color: ArenaColors.silver,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            itemCount: list.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, i) => _RequestCard(request: list[i]),
          );
        },
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
                child: profileAsync.when(
                  loading: () => Text(
                    'Chargement…',
                    style: GoogleFonts.spaceGrotesk(
                      color: ArenaColors.silver,
                      fontSize: 14,
                    ),
                  ),
                  error: (_, __) => Text(
                    'Utilisateur introuvable',
                    style: GoogleFonts.spaceGrotesk(
                      color: ArenaColors.silver,
                      fontSize: 14,
                    ),
                  ),
                  data: (p) => Text(
                    p?.username ?? '— inconnu —',
                    style: GoogleFonts.spaceGrotesk(
                      color: ArenaColors.bone,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
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
                  overdue ? 'EN RETARD' : 'EN ATTENTE',
                  style: GoogleFonts.spaceGrotesk(
                    color: accent,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          profileAsync.maybeWhen(
            data: (p) => p == null
                ? const SizedBox.shrink()
                : Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      p.email ?? '—',
                      style: GoogleFonts.spaceGrotesk(
                        color: ArenaColors.silver,
                        fontSize: 12,
                      ),
                    ),
                  ),
            orElse: () => const SizedBox.shrink(),
          ),
          const SizedBox(height: 12),
          Text(
            'MESSAGE',
            style: GoogleFonts.spaceGrotesk(
              color: ArenaColors.silver,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            request.message,
            style: GoogleFonts.spaceGrotesk(
              color: ArenaColors.bone,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Soumis le ${_formatDate(request.createdAt)}',
            style: GoogleFonts.spaceGrotesk(
              color: ArenaColors.silverDim,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: () => _approve(context, ref),
                  child: const Text('Approuver'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Button(
                  onPressed: () => _reject(context, ref),
                  child: const Text('Refuser'),
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
    final totpOk = await showDesktopTotpGate(
      context,
      ref,
      reason: 'Approuver la réintégration',
    );
    if (!totpOk || !context.mounted) return;
    final reason = await _askReason(
      context,
      title: 'Approuver la requête',
      hint: 'Note interne (optionnelle)…',
      required: false,
    );
    if (reason == null || !context.mounted) return;
    try {
      await ref.read(reintegrationRequestsRepositoryProvider).approve(
            requestId: request.id,
            adminId: adminId,
            reason: reason,
          );
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
      await _showResult(context, 'Réintégration approuvée.', isError: false);
    } catch (e) {
      if (!context.mounted) return;
      await _showResult(context, arenaErrorMessage(e), isError: true);
    }
  }

  Future<void> _reject(BuildContext context, WidgetRef ref) async {
    final adminId = ref.read(currentSessionProvider)?.user.id;
    if (adminId == null) return;
    final reason = await _askReason(
      context,
      title: 'Refuser la requête',
      hint: "Motif du refus (obligatoire, visible par l'utilisateur)…",
      required: true,
    );
    if (reason == null || !context.mounted) return;
    final totpOk = await showDesktopTotpGate(
      context,
      ref,
      reason: 'Refuser la réintégration',
    );
    if (!totpOk || !context.mounted) return;
    try {
      await ref.read(reintegrationRequestsRepositoryProvider).reject(
            requestId: request.id,
            adminId: adminId,
            reason: reason,
          );
      await ref.read(adminAuditLogRepositoryProvider).record(
        adminId: adminId,
        action: 'reintegration_rejected',
        targetType: 'reintegration_request',
        targetId: request.id,
        afterState: {'user_id': request.userId, 'reason': reason},
      );
      ref.invalidate(pendingReintegrationRequestsProvider);
      if (!context.mounted) return;
      await _showResult(context, 'Requête refusée.', isError: false);
    } catch (e) {
      if (!context.mounted) return;
      await _showResult(context, arenaErrorMessage(e), isError: true);
    }
  }

  Future<String?> _askReason(
    BuildContext context, {
    required String title,
    required String hint,
    required bool required,
  }) async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => ContentDialog(
        title: Text(title),
        content: TextBox(
          controller: controller,
          placeholder: hint,
          maxLines: 4,
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
              if (required && v.isEmpty) return;
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

  static String _formatDate(DateTime? date) {
    if (date == null) return '—';
    return DateFormat('dd/MM/yyyy HH:mm').format(date.toLocal());
  }
}

/// Cache local du profil associé à une requête. AutoDispose pour ne pas
/// fuir les profils des requêtes traitées entre les sessions admin.
final _requestUserProvider =
    FutureProvider.autoDispose.family<Profile?, String>((ref, userId) {
  return ref.watch(profileRepositoryProvider).getById(userId);
});

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
