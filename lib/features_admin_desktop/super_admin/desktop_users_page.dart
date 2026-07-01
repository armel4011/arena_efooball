import 'dart:io';

import 'package:arena/core/router/admin_desktop_router.dart';
import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/core/utils/arena_error_message.dart';
import 'package:arena/core/utils/supported_countries.dart';
import 'package:arena/data/models/profile.dart';
import 'package:arena/data/repositories/admin/admin_audit_log_repository.dart';
import 'package:arena/data/repositories/admin/admin_users_repository.dart';
import 'package:arena/features_admin_desktop/shared/desktop_audience_filters.dart';
import 'package:arena/features_admin_desktop/shared/desktop_totp_gate.dart';
import 'package:arena/features_shared/auth_common/shared_auth_providers.dart';
import 'package:arena/features_shared/whatsapp_export.dart';
import 'package:file_picker/file_picker.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

/// Super-admin · Utilisateurs (desktop) — tableau des utilisateurs avec
/// recherche, filtres (statut, pays) et actions (bannir / débannir,
/// override KYC), protégées par le step-up TOTP.
///
/// Réutilise [adminUsersProvider], [AdminUsersFilter],
/// [adminUsersRepositoryProvider] et [adminAuditLogRepositoryProvider]
/// (mêmes providers que le mobile).
class DesktopUsersPage extends ConsumerStatefulWidget {
  const DesktopUsersPage({super.key});

  @override
  ConsumerState<DesktopUsersPage> createState() => _DesktopUsersPageState();
}

class _DesktopUsersPageState extends ConsumerState<DesktopUsersPage> {
  final _searchController = TextEditingController();
  AdminUsersFilter _filter = const AdminUsersFilter();
  bool _exporting = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Exporte en CSV les numéros WhatsApp des utilisateurs correspondant aux
  /// filtres actuellement appliqués (pays, statut, activité, compétition…).
  /// Limite élevée pour récupérer TOUT le sous-ensemble filtré.
  Future<void> _exportWhatsapp() async {
    setState(() => _exporting = true);
    try {
      final users = await ref.read(adminUsersRepositoryProvider).list(
            filter: _filter,
            limit: 100000,
          );
      final bytes = buildWhatsappCsvBytes(users);
      final savedPath = await FilePicker.platform.saveFile(
        dialogTitle: 'Exporter les numéros WhatsApp',
        fileName: 'arena-whatsapp.csv',
        bytes: bytes,
        type: FileType.custom,
        allowedExtensions: const ['csv'],
      );
      // ⚠️ Sur desktop (Windows/macOS/Linux), FilePicker.saveFile IGNORE le
      // paramètre `bytes` : il ne fait qu'ouvrir la boîte de dialogue et
      // renvoyer le chemin choisi, sans jamais écrire le fichier. On écrit
      // donc nous-mêmes les octets. (Sur mobile, à l'inverse, `bytes` est
      // écrit par le plugin via SAF — mais cette page est desktop-only.)
      // Écrit avant le check `mounted` pour ne pas perdre le fichier si le
      // widget se démonte pendant l'ouverture du dialogue.
      if (savedPath != null) {
        await File(savedPath).writeAsBytes(bytes, flush: true);
      }
      if (!mounted) return;
      await displayInfoBar(
        context,
        builder: (ctx, close) => InfoBar(
          title: Text(
            savedPath == null
                ? 'Export annulé.'
                : '${users.length} numéros exportés',
          ),
          severity: savedPath == null
              ? InfoBarSeverity.warning
              : InfoBarSeverity.success,
          onClose: close,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      await displayInfoBar(
        context,
        builder: (ctx, close) => InfoBar(
          title: const Text('Export WhatsApp échoué'),
          content: Text('$e'),
          severity: InfoBarSeverity.error,
          onClose: close,
        ),
      );
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(adminUsersProvider(_filter));
    final compsAsync = ref.watch(filterableCompetitionsProvider);

    return ScaffoldPage(
      header: PageHeader(
        title: const Text('UTILISATEURS'),
        commandBar: CommandBar(
          mainAxisAlignment: MainAxisAlignment.end,
          primaryItems: [
            CommandBarButton(
              icon: const Icon(FluentIcons.refresh),
              label: const Text('Actualiser'),
              onPressed: () => ref.invalidate(adminUsersProvider),
            ),
            CommandBarButton(
              icon: const Icon(FluentIcons.download),
              label: const Text('Exporter WhatsApp'),
              onPressed: _exporting ? null : _exportWhatsapp,
            ),
          ],
        ),
      ),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: DesktopAudienceFilters(
              filter: _filter,
              searchCtrl: _searchController,
              competitions: compsAsync.valueOrNull ?? const [],
              searchPlaceholder: 'Rechercher username, email…',
              onFilterChanged: (f) => setState(() => _filter = f),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: usersAsync.when(
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
                      'Aucun utilisateur pour ces filtres.',
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
                  itemBuilder: (_, i) => _UserCard(profile: list[i]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Ligne « numéro WhatsApp » d'une carte utilisateur (desktop) : affiche le
/// numéro complet E.164 (indicatif pays + numéro local) et le copie dans le
/// presse-papier au clic. Placeholder discret si le compte n'a pas de numéro.
class _WhatsappLine extends StatelessWidget {
  const _WhatsappLine({required this.profile});

  final Profile profile;

  @override
  Widget build(BuildContext context) {
    final raw = profile.whatsappNumber?.trim() ?? '';
    if (raw.isEmpty) {
      return Text(
        'WhatsApp : —',
        style: GoogleFonts.spaceGrotesk(
          color: ArenaColors.silver,
          fontSize: 12,
        ),
      );
    }
    final e164 = buildE164Phone(countryCode: profile.countryCode, local: raw);
    return Tooltip(
      message: 'Cliquer pour copier',
      child: GestureDetector(
        onTap: () async {
          await Clipboard.setData(ClipboardData(text: e164));
          if (!context.mounted) return;
          await displayInfoBar(
            context,
            builder: (ctx, close) => InfoBar(
              title: Text('Numéro copié : $e164'),
              severity: InfoBarSeverity.success,
              onClose: close,
            ),
          );
        },
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                FluentIcons.phone,
                size: 12,
                color: ArenaColors.statusOk,
              ),
              const SizedBox(width: 4),
              Text(
                e164,
                style: GoogleFonts.spaceGrotesk(
                  color: ArenaColors.statusOk,
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(
                FluentIcons.copy,
                size: 10,
                color: ArenaColors.silver,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UserCard extends ConsumerWidget {
  const _UserCard({required this.profile});

  final Profile profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final banned = !profile.isActive;
    final permaBanned = profile.permanentBan;
    final kycPending = profile.kycStatus == 'pending';
    final accent = banned
        ? ArenaColors.neonRed
        : kycPending
            ? ArenaColors.statusWarn
            : ArenaColors.border;

    final (badgeLabel, badgeColor) = permaBanned
        ? ('BANNI À VIE', ArenaColors.neonRed)
        : banned
            ? ('BANNI', ArenaColors.neonRed)
            : kycPending
                ? ('KYC', ArenaColors.statusWarn)
                : profile.isAdmin
                    ? ('ADMIN', ArenaColors.signalBlue)
                    : ('ACTIF', ArenaColors.statusOk);

    return Card(
      backgroundColor: ArenaColors.carbon,
      borderColor: accent,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.username,
                      style: GoogleFonts.spaceGrotesk(
                        color: ArenaColors.bone,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      profile.email ?? '—',
                      style: GoogleFonts.spaceGrotesk(
                        color: ArenaColors.silver,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 2),
                    _WhatsappLine(profile: profile),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: badgeColor.withValues(alpha: 0.4)),
                ),
                child: Text(
                  badgeLabel,
                  style: GoogleFonts.spaceGrotesk(
                    color: badgeColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              // Chat individuel admin→user (même flux que le bouton
              // chat_bubble du mobile) : ouvre /super/messages/<userId>.
              Button(
                onPressed: () => context.go(
                  AdminDesktopRoutes.superChatThreadPath(profile.id),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(FluentIcons.chat, size: 12),
                    SizedBox(width: 6),
                    Text('Message'),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (banned)
                FilledButton(
                  onPressed: () => _toggleBan(context, ref),
                  child: const Text('Débannir'),
                )
              else
                Button(
                  onPressed: () => _toggleBan(context, ref),
                  child: const Text('Bannir'),
                ),
              if (kycPending) ...[
                const SizedBox(width: 8),
                Button(
                  onPressed: () => _overrideKyc(context, ref, 'verified'),
                  child: const Text('Valider KYC'),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _toggleBan(BuildContext context, WidgetRef ref) async {
    final adminId = ref.read(currentSessionProvider)?.user.id;
    if (adminId == null) return;
    final shouldBan = profile.isActive;
    final totpOk = await showDesktopTotpGate(
      context,
      ref,
      reason: shouldBan
          ? 'Bannir ${profile.username}'
          : 'Débannir ${profile.username}',
    );
    if (!totpOk || !context.mounted) return;
    final repo = ref.read(adminUsersRepositoryProvider);
    final audit = ref.read(adminAuditLogRepositoryProvider);
    try {
      if (shouldBan) {
        await repo.ban(profile.id);
        await audit.record(
          adminId: adminId,
          action: 'user_banned',
          targetType: 'profile',
          targetId: profile.id,
          beforeState: {'is_active': true},
          afterState: {'is_active': false},
        );
      } else {
        await repo.unban(profile.id);
        await audit.record(
          adminId: adminId,
          action: 'user_unbanned',
          targetType: 'profile',
          targetId: profile.id,
          beforeState: {'is_active': false},
          afterState: {'is_active': true},
        );
      }
      ref.invalidate(adminUsersProvider);
      if (!context.mounted) return;
      await _showResult(
        context,
        shouldBan
            ? '${profile.username} banni.'
            : '${profile.username} débanni.',
        isError: false,
      );
    } catch (e) {
      if (!context.mounted) return;
      await _showResult(context, arenaErrorMessage(e), isError: true);
    }
  }

  Future<void> _overrideKyc(
    BuildContext context,
    WidgetRef ref,
    String status,
  ) async {
    final adminId = ref.read(currentSessionProvider)?.user.id;
    if (adminId == null) return;
    final totpOk = await showDesktopTotpGate(
      context,
      ref,
      reason: 'Override KYC → $status pour ${profile.username}',
    );
    if (!totpOk || !context.mounted) return;
    try {
      await ref
          .read(adminUsersRepositoryProvider)
          .overrideKyc(userId: profile.id, status: status);
      await ref.read(adminAuditLogRepositoryProvider).record(
        adminId: adminId,
        action: 'user_kyc_overridden',
        targetType: 'profile',
        targetId: profile.id,
        afterState: {'kyc_status': status},
      );
      ref.invalidate(adminUsersProvider);
      if (!context.mounted) return;
      await _showResult(
        context,
        'KYC → $status pour ${profile.username}.',
        isError: false,
      );
    } catch (e) {
      if (!context.mounted) return;
      await _showResult(context, arenaErrorMessage(e), isError: true);
    }
  }
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
