import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/core/utils/arena_error_message.dart';
import 'package:arena/data/models/profile.dart';
import 'package:arena/data/repositories/profile_repository.dart';
import 'package:arena/features_admin/auth_admin/admin_auth_providers.dart';
import 'package:arena/features_shared/auth_common/shared_auth_providers.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Profil de l'admin connecté — édition (pseudo / pays), gestion de la
/// double authentification (réinitialisation) et déconnexion.
class DesktopProfilePage extends ConsumerStatefulWidget {
  const DesktopProfilePage({super.key});

  @override
  ConsumerState<DesktopProfilePage> createState() => _DesktopProfilePageState();
}

class _DesktopProfilePageState extends ConsumerState<DesktopProfilePage> {
  final _usernameCtrl = TextEditingController();
  String? _countryCode;
  bool _editing = false;
  bool _saving = false;
  String? _error;

  // Aligné sur les pays supportés ailleurs dans l'admin (filtres audience).
  static const _countryOptions = <(String, String)>[
    ('CM', '🇨🇲 Cameroun'),
    ('SN', '🇸🇳 Sénégal'),
    ('CI', "🇨🇮 Côte d'Ivoire"),
    ('BF', '🇧🇫 Burkina Faso'),
  ];

  @override
  void dispose() {
    _usernameCtrl.dispose();
    super.dispose();
  }

  void _startEditing(Profile profile) {
    setState(() {
      _editing = true;
      _error = null;
      _usernameCtrl.text = profile.username;
      _countryCode = profile.countryCode.isEmpty ? null : profile.countryCode;
    });
  }

  void _cancelEditing() {
    setState(() {
      _editing = false;
      _error = null;
    });
  }

  Future<void> _save(Profile profile) async {
    final username = _usernameCtrl.text.trim();
    if (username.length < 3) {
      setState(() => _error = 'Le pseudo doit faire au moins 3 caractères.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref.read(profileRepositoryProvider).update(profile.id, {
        'username': username,
        if (_countryCode != null) 'country_code': _countryCode,
      });
      ref.invalidate(currentProfileProvider);
      if (!mounted) return;
      setState(() {
        _saving = false;
        _editing = false;
      });
      await displayInfoBar(
        context,
        builder: (ctx, close) => InfoBar(
          title: const Text('Profil mis à jour'),
          severity: InfoBarSeverity.success,
          onClose: close,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = arenaErrorMessage(e);
      });
    }
  }

  /// Réinitialise la 2FA : demande un code courant, appelle `reset-totp`,
  /// puis invalide le profil → le router redirige vers `/totp/setup`.
  Future<void> _resetTotp() async {
    final codeCtrl = TextEditingController();
    var submitting = false;
    String? dialogError;

    final done = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => ContentDialog(
          title: const Text('Réinitialiser la double authentification'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Saisissez votre code actuel (6 chiffres) ou un code de '
                'secours pour confirmer. Vous devrez ensuite reconfigurer '
                'une nouvelle application d’authentification.',
              ),
              const SizedBox(height: 12),
              TextBox(
                controller: codeCtrl,
                placeholder: '123456 ou XXXX-XXXX',
                autofocus: true,
              ),
              if (dialogError != null) ...[
                const SizedBox(height: 8),
                Text(
                  dialogError!,
                  style: const TextStyle(color: ArenaColors.neonRed),
                ),
              ],
            ],
          ),
          actions: [
            Button(
              onPressed: submitting ? null : () => Navigator.of(ctx).pop(false),
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: submitting
                  ? null
                  : () async {
                      final code = codeCtrl.text.trim();
                      if (code.isEmpty) {
                        setDialogState(() => dialogError = 'Code requis.');
                        return;
                      }
                      setDialogState(() {
                        submitting = true;
                        dialogError = null;
                      });
                      try {
                        await ref
                            .read(adminAuthRepositoryProvider)
                            .resetTotp(code);
                        if (ctx.mounted) Navigator.of(ctx).pop(true);
                      } catch (e) {
                        setDialogState(() {
                          submitting = false;
                          dialogError = arenaErrorMessage(e);
                        });
                      }
                    },
              child: submitting
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: ProgressRing(strokeWidth: 2),
                    )
                  : const Text('Réinitialiser'),
            ),
          ],
        ),
      ),
    );
    codeCtrl.dispose();

    if (done == true && mounted) {
      // totp_enabled est repassé à false côté serveur : invalider le profil
      // déclenche la redirection router vers l'écran d'enrôlement.
      ref.invalidate(currentProfileProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
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
          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  backgroundColor: ArenaColors.carbon,
                  padding: const EdgeInsets.all(24),
                  child: _editing
                      ? _buildEditForm(profile)
                      : _buildReadOnly(profile),
                ),
                const SizedBox(height: 16),
                _buildSecurityCard(profile),
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
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildReadOnly(Profile profile) {
    return Column(
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
          label: 'Pays',
          value: _countryLabel(profile.countryCode),
        ),
        const SizedBox(height: 16),
        Button(
          onPressed: () => _startEditing(profile),
          child: const Padding(
            padding: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(FluentIcons.edit, size: 14),
                SizedBox(width: 8),
                Text('Modifier'),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEditForm(Profile profile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InfoLabel(
          label: 'Pseudo',
          child: TextBox(
            controller: _usernameCtrl,
            placeholder: 'Pseudo affiché',
          ),
        ),
        const SizedBox(height: 12),
        InfoLabel(
          label: 'Pays',
          child: ComboBox<String?>(
            value: _countryCode,
            placeholder: const Text('Sélectionner'),
            items: [
              for (final (id, label) in _countryOptions)
                ComboBoxItem(value: id, child: Text(label)),
            ],
            onChanged: (v) => setState(() => _countryCode = v),
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: 12),
          InfoBar(
            title: const Text('Échec'),
            content: Text(_error!),
            severity: InfoBarSeverity.error,
            onClose: () => setState(() => _error = null),
          ),
        ],
        const SizedBox(height: 16),
        Row(
          children: [
            FilledButton(
              onPressed: _saving ? null : () => _save(profile),
              child: _saving
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: ProgressRing(strokeWidth: 2),
                    )
                  : const Text('Enregistrer'),
            ),
            const SizedBox(width: 8),
            Button(
              onPressed: _saving ? null : _cancelEditing,
              child: const Text('Annuler'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSecurityCard(Profile profile) {
    return Card(
      backgroundColor: ArenaColors.carbon,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(FluentIcons.shield, size: 16),
              const SizedBox(width: 8),
              Text(
                'Sécurité',
                style: FluentTheme.of(context).typography.bodyStrong,
              ),
            ],
          ),
          const SizedBox(height: 12),
          _InfoRow(
            label: 'Double authentification',
            value: profile.totpEnabled ? 'Activée ✓' : 'Inactive',
          ),
          if (profile.totpEnabled) ...[
            const SizedBox(height: 12),
            Button(
              onPressed: _resetTotp,
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(FluentIcons.reset, size: 14),
                    SizedBox(width: 8),
                    Text('Réinitialiser la 2FA'),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _countryLabel(String code) {
    for (final (id, label) in _countryOptions) {
      if (id == code) return label;
    }
    return code.isEmpty ? '—' : code;
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
