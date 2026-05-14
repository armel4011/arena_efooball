import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/data/repositories/profile_repository.dart';
import 'package:arena/features_shared/widgets/arena_app_bar.dart';
import 'package:arena/features_shared/widgets/arena_button.dart';
import 'package:arena/features_shared/widgets/arena_card.dart';
import 'package:arena/features_shared/widgets/arena_text_field.dart';
import 'package:arena/features_user/auth/auth_providers.dart';
import 'package:arena/features_user/profile/avatar_palette.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Lets the player tweak their public-ish profile bits (PHASE 9.1).
///
/// Editable: `username`, `avatar_color`, `country_code`. Email + password
/// changes live behind `SettingsPage` since they go through Supabase auth
/// rather than a `profiles` UPDATE. The country list is the V1.0
/// francophone-Africa rollout (cf. ARENA_MASTER_PROMPT.md), extended on
/// subsequent rollouts.
class EditProfilePage extends ConsumerStatefulWidget {
  const EditProfilePage({super.key});

  @override
  ConsumerState<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends ConsumerState<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _usernameCtrl;
  late String _avatarColor;
  late String _countryCode;
  bool _saving = false;
  String? _error;

  static const _v1Countries = <String, String>{
    'CM': 'Cameroun',
    'CI': "Côte d'Ivoire",
    'SN': 'Sénégal',
    'BF': 'Burkina Faso',
    'ML': 'Mali',
    'GA': 'Gabon',
    'CG': 'Congo',
    'CD': 'RD Congo',
    'TG': 'Togo',
    'BJ': 'Bénin',
    'NE': 'Niger',
    'TD': 'Tchad',
    'MG': 'Madagascar',
  };

  @override
  void initState() {
    super.initState();
    final profile = ref.read(currentProfileProvider).valueOrNull;
    _usernameCtrl = TextEditingController(text: profile?.username ?? '');
    _avatarColor = profile?.avatarColor ?? AvatarPalette.colors.first;
    _countryCode = profile?.countryCode ?? 'CM';
  }

  @override
  void dispose() {
    _usernameCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final profile = ref.read(currentProfileProvider).valueOrNull;
    if (profile == null) return;

    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref.read(profileRepositoryProvider).update(profile.id, {
        'username': _usernameCtrl.text.trim(),
        'avatar_color': _avatarColor,
        'country_code': _countryCode,
      });
      ref.invalidate(currentProfileProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profil mis à jour.')),
      );
      context.pop();
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _saving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const ArenaAppBar(title: 'Modifier le profil'),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(ArenaSpacing.lg),
            children: [
              ArenaTextField(
                label: "Nom d'utilisateur",
                controller: _usernameCtrl,
                maxLength: 20,
                textInputAction: TextInputAction.next,
                validator: (v) {
                  final value = v?.trim() ?? '';
                  if (value.length < 3) return 'Minimum 3 caractères';
                  if (value.length > 20) return 'Maximum 20 caractères';
                  return null;
                },
              ),
              const SizedBox(height: ArenaSpacing.lg),
              Text('COULEUR AVATAR', style: ArenaTypography.labelMedium),
              const SizedBox(height: ArenaSpacing.sm),
              _ColorPicker(
                selected: _avatarColor,
                onChanged: (v) => setState(() => _avatarColor = v),
              ),
              const SizedBox(height: ArenaSpacing.lg),
              Text('PAYS', style: ArenaTypography.labelMedium),
              const SizedBox(height: ArenaSpacing.sm),
              ArenaCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: ArenaSpacing.md,
                  vertical: 4,
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _countryCode,
                    isExpanded: true,
                    dropdownColor: ArenaColors.surface,
                    style: ArenaTypography.bodyMedium,
                    items: [
                      for (final entry in _v1Countries.entries)
                        DropdownMenuItem(
                          value: entry.key,
                          child: Text('${entry.key} — ${entry.value}'),
                        ),
                    ],
                    onChanged: (v) {
                      if (v != null) setState(() => _countryCode = v);
                    },
                  ),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: ArenaSpacing.md),
                Text(
                  _error!,
                  style: ArenaTypography.bodySmall.copyWith(
                    color: ArenaColors.danger,
                  ),
                ),
              ],
              const SizedBox(height: ArenaSpacing.xl),
              ArenaButton(
                label: 'ENREGISTRER',
                isLoading: _saving,
                fullWidth: true,
                onPressed: _saving ? null : _save,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ColorPicker extends StatelessWidget {
  const _ColorPicker({required this.selected, required this.onChanged});

  final String selected;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: ArenaSpacing.sm,
      runSpacing: ArenaSpacing.sm,
      children: [
        for (final hex in AvatarPalette.colors)
          GestureDetector(
            onTap: () => onChanged(hex),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AvatarPalette.colorFromHex(hex),
                shape: BoxShape.circle,
                border: Border.all(
                  color:
                      hex == selected ? ArenaColors.text : ArenaColors.border,
                  width: hex == selected ? 3 : 1,
                ),
                boxShadow: hex == selected
                    ? [
                        BoxShadow(
                          color: AvatarPalette.colorFromHex(hex)
                              .withValues(alpha: 0.65),
                          blurRadius: 18,
                          spreadRadius: -2,
                        ),
                      ]
                    : null,
              ),
              child: hex == selected
                  ? const Icon(Icons.check, color: Colors.white, size: 22)
                  : null,
            ),
          ),
      ],
    );
  }
}
