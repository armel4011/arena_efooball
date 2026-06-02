import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/features_shared/auth_common/shared_auth_providers.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Profil de l'admin connecté — infos du compte + déconnexion.
class DesktopProfilePage extends ConsumerWidget {
  const DesktopProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(currentProfileProvider);

    return ScaffoldPage(
      header: const PageHeader(title: Text('MON PROFIL')),
      content: profileAsync.when(
        loading: () => const Center(child: ProgressRing()),
        error: (e, _) => Center(child: Text('Erreur : $e')),
        data: (profile) {
          if (profile == null) {
            return const Center(child: Text('Profil introuvable.'));
          }
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  backgroundColor: ArenaColors.carbon,
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _InfoRow(label: 'Pseudo', value: profile.username),
                      _InfoRow(label: 'Email', value: profile.email ?? '—'),
                      _InfoRow(
                        label: 'Rôle',
                        value: profile.isSuperAdmin
                            ? 'Super administrateur'
                            : 'Administrateur',
                      ),
                      _InfoRow(
                        label: 'Double authentification',
                        value: profile.totpEnabled ? 'Activée ✓' : 'Inactive',
                      ),
                      _InfoRow(label: 'Pays', value: profile.countryCode),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Button(
                  onPressed: () async {
                    await ref.read(signOutProvider)();
                  },
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(FluentIcons.sign_out, size: 14),
                        SizedBox(width: 8),
                        Text('Se déconnecter'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final typography = FluentTheme.of(context).typography;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 220,
            child: Text(
              label,
              style: typography.body?.copyWith(color: ArenaColors.silver),
            ),
          ),
          Expanded(
            child: Text(value, style: typography.bodyStrong),
          ),
        ],
      ),
    );
  }
}
