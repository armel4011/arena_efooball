import 'package:arena/core/router/user_router.dart';
import 'package:arena/core/services/onboarding_service.dart';
import 'package:arena/core/theme/arena_colors.dart';
import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/core/theme/arena_typography.dart';
import 'package:arena/data/repositories/profile_repository.dart';
import 'package:arena/features_shared/widgets/arena_card.dart';
import 'package:arena/features_shared/widgets/language_switcher.dart';
import 'package:arena/features_user/auth/auth_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Settings hub for the user app (PHASE 9.2).
///
/// 4 sections — Préférences, Compte, Confidentialité, Aide & Infos —
/// match the master prompt's spec. Several entries (download data,
/// social sign-in linking, support email) are flagged "à venir" because
/// they require Edge Functions / SSO providers reported to PHASE 12.5
/// or PHASE 2.3. The actions that ARE wired:
///   * change email / password (Supabase auth API),
///   * marketing consent toggle (profile UPDATE),
///   * replay onboarding (`OnboardingFlagController.reset()`),
///   * navigate to /profile/delete (PHASE 9.3 RGPD flow).
class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: const Text('PARAMÈTRES'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(ArenaSpacing.lg),
          children: const [
            _SectionHeader(label: 'PRÉFÉRENCES'),
            _PreferencesSection(),
            SizedBox(height: ArenaSpacing.lg),
            _SectionHeader(label: 'COMPTE'),
            _AccountSection(),
            SizedBox(height: ArenaSpacing.lg),
            _SectionHeader(label: 'CONFIDENTIALITÉ'),
            _PrivacySection(),
            SizedBox(height: ArenaSpacing.lg),
            _SectionHeader(label: 'AIDE & INFOS'),
            _HelpSection(),
            SizedBox(height: ArenaSpacing.xxl),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: ArenaSpacing.sm),
      child: Text(label, style: ArenaTypography.labelMedium),
    );
  }
}

class _PreferencesSection extends ConsumerWidget {
  const _PreferencesSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentProfileProvider).value;

    return ArenaCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          const ListTile(
            leading: Icon(Icons.language, color: ArenaColors.textMuted),
            title: Text('Langue'),
            subtitle: LanguageSwitcher(),
            dense: true,
          ),
          const _Divider(),
          ListTile(
            leading: const Icon(Icons.payments_outlined,
                color: ArenaColors.textMuted),
            title: const Text('Devise'),
            subtitle: Text(
              profile?.preferredCurrency ?? '—',
              style: ArenaTypography.bodyMedium.copyWith(
                color: ArenaColors.textMuted,
              ),
            ),
            trailing: const Icon(Icons.lock_outline,
                size: 16, color: ArenaColors.textFaint),
            // The currency is auto-derived from country in V1.0 — admins
            // will own the override flow in PHASE 11.
          ),
          const _Divider(),
          SwitchListTile(
            secondary: const Icon(Icons.campaign_outlined,
                color: ArenaColors.textMuted),
            title: const Text('Notifications marketing'),
            subtitle: Text(
              'Conseils, nouveaux tournois, promotions',
              style: ArenaTypography.bodySmall.copyWith(
                color: ArenaColors.textMuted,
              ),
            ),
            value: profile?.marketingConsent ?? false,
            onChanged: profile == null
                ? null
                : (v) async {
                    await ref
                        .read(profileRepositoryProvider)
                        .update(profile.id, {'marketing_consent': v});
                    ref.invalidate(currentProfileProvider);
                  },
          ),
        ],
      ),
    );
  }
}

class _AccountSection extends ConsumerWidget {
  const _AccountSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentProfileProvider).value;

    return ArenaCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          ListTile(
            leading:
                const Icon(Icons.alternate_email, color: ArenaColors.textMuted),
            title: const Text("Changer l'email"),
            subtitle: Text(
              profile?.email ?? '',
              style: ArenaTypography.bodySmall.copyWith(
                color: ArenaColors.textMuted,
              ),
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _changeEmail(context, ref),
          ),
          const _Divider(),
          ListTile(
            leading: const Icon(Icons.lock_reset, color: ArenaColors.textMuted),
            title: const Text('Changer le mot de passe'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _changePassword(context, ref),
          ),
          const _Divider(),
          ListTile(
            leading: const Icon(Icons.link, color: ArenaColors.textMuted),
            title: const Text('Méthodes de connexion'),
            subtitle: Text(
              'Google / Apple — bientôt disponible',
              style: ArenaTypography.bodySmall.copyWith(
                color: ArenaColors.textMuted,
              ),
            ),
            trailing: const Icon(Icons.lock_outline,
                size: 16, color: ArenaColors.textFaint),
          ),
        ],
      ),
    );
  }

  Future<void> _changeEmail(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    final newEmail = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ArenaColors.surface,
        title: const Text("Nouvel email"),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.emailAddress,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'nom@example.com'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );
    if (newEmail == null || newEmail.isEmpty) return;
    try {
      await Supabase.instance.client.auth
          .updateUser(UserAttributes(email: newEmail));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text("Vérifie ta boîte mail pour confirmer le changement."),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Erreur: $e')));
      }
    }
  }

  Future<void> _changePassword(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    final newPwd = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ArenaColors.surface,
        title: const Text("Nouveau mot de passe"),
        content: TextField(
          controller: controller,
          obscureText: true,
          autofocus: true,
          decoration: const InputDecoration(hintText: '8 caractères minimum'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );
    if (newPwd == null || newPwd.length < 8) return;
    try {
      await Supabase.instance.client.auth
          .updateUser(UserAttributes(password: newPwd));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Mot de passe mis à jour.')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Erreur: $e')));
      }
    }
  }
}

class _PrivacySection extends StatelessWidget {
  const _PrivacySection();

  @override
  Widget build(BuildContext context) {
    return ArenaCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.download_outlined,
                color: ArenaColors.textMuted),
            title: const Text('Télécharger mes données'),
            subtitle: Text(
              'Lien temporaire envoyé par email — bientôt disponible',
              style: ArenaTypography.bodySmall.copyWith(
                color: ArenaColors.textMuted,
              ),
            ),
            trailing: const Icon(Icons.lock_outline,
                size: 16, color: ArenaColors.textFaint),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    "Cette fonctionnalité sera disponible avec le lancement V1.0 "
                    '(Edge Function `export_user_data` — PHASE 12.5).',
                  ),
                ),
              );
            },
          ),
          const _Divider(),
          ListTile(
            leading:
                const Icon(Icons.delete_outline, color: ArenaColors.danger),
            title: const Text(
              'Supprimer mon compte',
              style: TextStyle(color: ArenaColors.danger),
            ),
            trailing:
                const Icon(Icons.chevron_right, color: ArenaColors.danger),
            onTap: () => context.push(UserRoutes.profileDelete),
          ),
        ],
      ),
    );
  }
}

class _HelpSection extends ConsumerWidget {
  const _HelpSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ArenaCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.replay, color: ArenaColors.textMuted),
            title: const Text("Revoir l'introduction"),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              await ref.read(onboardingCompletedProvider.notifier).reset();
              if (context.mounted) context.go(UserRoutes.onboarding);
            },
          ),
          const _Divider(),
          ListTile(
            leading:
                const Icon(Icons.help_outline, color: ArenaColors.textMuted),
            title: const Text('Support'),
            subtitle: Text(
              'support@arena.gg',
              style: ArenaTypography.bodySmall.copyWith(
                color: ArenaColors.textMuted,
              ),
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('support@arena.gg')),
              );
            },
          ),
          const _Divider(),
          ListTile(
            leading:
                const Icon(Icons.info_outline, color: ArenaColors.textMuted),
            title: const Text('À propos'),
            subtitle: Text(
              'ARENA V1.0 — Plateforme de tournois e-sport mobile',
              style: ArenaTypography.bodySmall.copyWith(
                color: ArenaColors.textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return const Divider(
      height: 1,
      thickness: 1,
      color: ArenaColors.border,
      indent: ArenaSpacing.md,
      endIndent: ArenaSpacing.md,
    );
  }
}
