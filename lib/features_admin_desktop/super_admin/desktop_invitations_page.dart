import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/core/utils/arena_error_message.dart';
import 'package:arena/core/utils/supported_countries.dart';
import 'package:arena/data/models/invitation_code.dart';
import 'package:arena/data/models/user_role.dart';
import 'package:arena/data/repositories/admin/admin_invitations_repository.dart';
import 'package:arena/features_shared/admin_sections.dart';
import 'package:arena/features_shared/auth_common/shared_auth_providers.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

/// Super-admin · Invitations (desktop) — liste des codes d'invitation
/// admin + formulaire de génération (rôle, email cible, expiration).
///
/// Réutilise [adminInvitationsProvider] et
/// [adminInvitationsRepositoryProvider] (mêmes providers que le mobile).
class DesktopInvitationsPage extends ConsumerStatefulWidget {
  const DesktopInvitationsPage({super.key});

  @override
  ConsumerState<DesktopInvitationsPage> createState() =>
      _DesktopInvitationsPageState();
}

enum _Expiration { sevenDays, thirtyDays, never }

extension on _Expiration {
  String get label => switch (this) {
        _Expiration.sevenDays => '7 jours',
        _Expiration.thirtyDays => '30 jours',
        _Expiration.never => 'Jamais',
      };

  DateTime? get deadline => switch (this) {
        _Expiration.sevenDays =>
          DateTime.now().toUtc().add(const Duration(days: 7)),
        _Expiration.thirtyDays =>
          DateTime.now().toUtc().add(const Duration(days: 30)),
        _Expiration.never => null,
      };
}

class _DesktopInvitationsPageState
    extends ConsumerState<DesktopInvitationsPage> {
  UserRole _role = UserRole.admin;
  _Expiration _expiration = _Expiration.thirtyDays;
  final _emailController = TextEditingController();

  // VOLET 3 — périmètre facultatif (vide = aucune restriction).
  final Set<String> _countries = <String>{};
  final Set<String> _sections = <String>{};

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _generate() async {
    final adminId = ref.read(currentSessionProvider)?.user.id;
    if (adminId == null) return;
    final email = _emailController.text.trim();
    try {
      await ref.read(adminInvitationsRepositoryProvider).create(
            generatedBy: adminId,
            role: _role,
            targetEmail: email.isEmpty ? null : email,
            expiresAt: _expiration.deadline,
            allowedCountryCodes:
                _countries.isEmpty ? null : _countries.toList(),
            allowedSections: _sections.isEmpty ? null : _sections.toList(),
          );
      ref.invalidate(adminInvitationsProvider);
      _emailController.clear();
      setState(() {
        _countries.clear();
        _sections.clear();
      });
      if (!mounted) return;
      await _showResult(context, 'Code généré.', isError: false);
    } catch (e) {
      if (!mounted) return;
      await _showResult(context, arenaErrorMessage(e), isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final codesAsync = ref.watch(adminInvitationsProvider);

    return ScaffoldPage(
      header: PageHeader(
        title: const Text('INVITATIONS'),
        commandBar: CommandBar(
          mainAxisAlignment: MainAxisAlignment.end,
          primaryItems: [
            CommandBarButton(
              icon: const Icon(FluentIcons.refresh),
              label: const Text('Actualiser'),
              onPressed: () => ref.invalidate(adminInvitationsProvider),
            ),
          ],
        ),
      ),
      content: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        children: [
          Text('GÉNÉRER UN CODE', style: _sectionStyle),
          const SizedBox(height: 12),
          _GenerateCard(
            role: _role,
            expiration: _expiration,
            emailController: _emailController,
            selectedCountries: _countries,
            selectedSections: _sections,
            onRoleChanged: (r) => setState(() => _role = r),
            onExpirationChanged: (e) => setState(() => _expiration = e),
            onToggleCountry: (code) => setState(() {
              _countries.contains(code)
                  ? _countries.remove(code)
                  : _countries.add(code);
            }),
            onToggleSection: (key) => setState(() {
              _sections.contains(key)
                  ? _sections.remove(key)
                  : _sections.add(key);
            }),
            onSubmit: _generate,
          ),
          const SizedBox(height: 32),
          Text('CODES', style: _sectionStyle),
          const SizedBox(height: 12),
          codesAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: ProgressRing()),
            ),
            error: (e, _) => InfoBar(
              title: const Text('Erreur de chargement'),
              content: Text('$e'),
              severity: InfoBarSeverity.error,
            ),
            data: (list) {
              if (list.isEmpty) {
                return const Card(
                  backgroundColor: ArenaColors.carbon,
                  padding: EdgeInsets.all(24),
                  child: Center(child: Text('Aucun code généré.')),
                );
              }
              return Column(
                children: [
                  for (final code in list) ...[
                    _CodeCard(code: code),
                    const SizedBox(height: 8),
                  ],
                ],
              );
            },
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _GenerateCard extends StatelessWidget {
  const _GenerateCard({
    required this.role,
    required this.expiration,
    required this.emailController,
    required this.selectedCountries,
    required this.selectedSections,
    required this.onRoleChanged,
    required this.onExpirationChanged,
    required this.onToggleCountry,
    required this.onToggleSection,
    required this.onSubmit,
  });

  final UserRole role;
  final _Expiration expiration;
  final TextEditingController emailController;
  final Set<String> selectedCountries;
  final Set<String> selectedSections;
  final ValueChanged<UserRole> onRoleChanged;
  final ValueChanged<_Expiration> onExpirationChanged;
  final ValueChanged<String> onToggleCountry;
  final ValueChanged<String> onToggleSection;
  final Future<void> Function() onSubmit;

  @override
  Widget build(BuildContext context) {
    return Card(
      backgroundColor: ArenaColors.carbon,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InfoLabel(
            label: 'Rôle cible',
            child: ComboBox<UserRole>(
              value: role,
              items: const [
                ComboBoxItem(value: UserRole.admin, child: Text('Admin')),
                ComboBoxItem(
                  value: UserRole.superAdmin,
                  child: Text('Super-admin'),
                ),
              ],
              onChanged: (v) => v == null ? null : onRoleChanged(v),
            ),
          ),
          const SizedBox(height: 16),
          InfoLabel(
            label: 'Email cible (optionnel)',
            child: TextBox(
              controller: emailController,
              placeholder: 'laisser vide pour un code libre',
            ),
          ),
          const SizedBox(height: 16),
          InfoLabel(
            label: 'Expiration',
            child: ComboBox<_Expiration>(
              value: expiration,
              items: [
                for (final e in _Expiration.values)
                  ComboBoxItem(value: e, child: Text(e.label)),
              ],
              onChanged: (v) => v == null ? null : onExpirationChanged(v),
            ),
          ),
          const SizedBox(height: 20),
          Text('RESTRICTIONS (optionnel)', style: _sectionStyle),
          const SizedBox(height: 4),
          Text(
            'Limite ce futur admin à certains pays et/ou sections. '
            'Laisse vide pour un accès complet.',
            style: GoogleFonts.spaceGrotesk(
              color: ArenaColors.silver,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 12),
          InfoLabel(
            label: selectedCountries.isEmpty
                ? 'Pays autorisés · Tous les pays'
                : 'Pays autorisés',
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final c in kSupportedCountries)
                  _ScopeChip(
                    label: '${c.flag} ${c.code}',
                    selected: selectedCountries.contains(c.code),
                    onTap: () => onToggleCountry(c.code),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          InfoLabel(
            label: selectedSections.isEmpty
                ? 'Sections autorisées · Toutes les sections'
                : 'Sections autorisées',
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final s in kAdminSections)
                  _ScopeChip(
                    label: s.labelFr,
                    selected: selectedSections.contains(s.key),
                    onTap: () => onToggleSection(s.key),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: () async => onSubmit(),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(FluentIcons.add, size: 14),
                  SizedBox(width: 8),
                  Text('Générer'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Puce sélectionnable (pays / section) du périmètre d'invitation (desktop).
class _ScopeChip extends StatelessWidget {
  const _ScopeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = selected ? ArenaColors.signalBlue : ArenaColors.border;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? ArenaColors.signalBlue.withValues(alpha: 0.18)
              : ArenaColors.surface,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: accent),
        ),
        child: Text(
          label,
          style: GoogleFonts.spaceGrotesk(
            color: selected ? ArenaColors.bone : ArenaColors.silver,
            fontSize: 12,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _CodeCard extends ConsumerWidget {
  const _CodeCard({required this.code});

  final InvitationCode code;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isUsed = code.isUsed;
    final isActive = code.isActive;
    final accent = isActive
        ? ArenaColors.statusOk
        : isUsed
            ? ArenaColors.silverDim
            : ArenaColors.neonRed;
    final statusLabel = isActive
        ? 'VALIDE'
        : isUsed
            ? 'UTILISÉ'
            : 'EXPIRÉ';
    final expirationLabel = code.expiresAt == null
        ? 'Expire jamais'
        : 'Expire le ${DateFormat('dd/MM/yyyy').format(code.expiresAt!)}';

    return Card(
      backgroundColor: ArenaColors.carbon,
      borderColor: accent.withValues(alpha: 0.4),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
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
                  statusLabel,
                  style: GoogleFonts.spaceGrotesk(
                    color: accent,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                expirationLabel,
                style: GoogleFonts.spaceGrotesk(
                  color: ArenaColors.silver,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'ARENA-${code.code}',
            style: GoogleFonts.spaceGrotesk(
              color: ArenaColors.bone,
              fontSize: 14,
              fontWeight: FontWeight.w700,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 8),
          _kv(
            'Rôle',
            code.role == UserRole.superAdmin ? 'Super-admin' : 'Admin',
            valueColor: code.role == UserRole.superAdmin
                ? ArenaColors.tierGold
                : ArenaColors.bone,
          ),
          if (code.targetEmail != null) _kv('Cible', code.targetEmail!),
          _kv('Usages', '${code.usesCount}/${code.maxUses}'),
          const SizedBox(height: 12),
          Row(
            children: [
              if (isActive) ...[
                Button(
                  onPressed: () async {
                    await Clipboard.setData(
                      ClipboardData(text: 'ARENA-${code.code}'),
                    );
                    if (!context.mounted) return;
                    await _showResult(context, 'Code copié.', isError: false);
                  },
                  child: const Text('Copier'),
                ),
                const SizedBox(width: 8),
                Button(
                  onPressed: () => _revoke(context, ref),
                  child: const Text('Révoquer'),
                ),
              ] else
                Button(
                  onPressed: () => _confirmDelete(context, ref),
                  child: const Text('Supprimer'),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _revoke(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(adminInvitationsRepositoryProvider).revoke(code.id);
      ref.invalidate(adminInvitationsProvider);
      if (!context.mounted) return;
      await _showResult(context, 'Code révoqué.', isError: false);
    } catch (e) {
      if (!context.mounted) return;
      await _showResult(context, arenaErrorMessage(e), isError: true);
    }
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => ContentDialog(
        title: const Text('Supprimer ce code ?'),
        content: Text(
          'Le code ARENA-${code.code} sera définitivement effacé. '
          'Cette action est irréversible.',
        ),
        actions: [
          Button(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(adminInvitationsRepositoryProvider).delete(code.id);
      ref.invalidate(adminInvitationsProvider);
      if (!context.mounted) return;
      await _showResult(context, 'Code supprimé.', isError: false);
    } catch (e) {
      if (!context.mounted) return;
      await _showResult(context, arenaErrorMessage(e), isError: true);
    }
  }

  Widget _kv(String key, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(
            child: Text(
              key,
              style: GoogleFonts.spaceGrotesk(
                color: ArenaColors.silver,
                fontSize: 13,
              ),
            ),
          ),
          Text(
            value,
            style: GoogleFonts.spaceGrotesk(
              color: valueColor ?? ArenaColors.bone,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

final TextStyle _sectionStyle = GoogleFonts.bebasNeue(
  color: ArenaColors.silver,
  fontSize: 16,
  letterSpacing: 1.5,
);

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
