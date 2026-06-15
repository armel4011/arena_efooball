import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/core/utils/supported_countries.dart';
import 'package:arena/data/models/profile.dart';
import 'package:arena/data/models/user_role.dart';
import 'package:arena/data/repositories/profile_repository.dart';
import 'package:arena/features_shared/auth_common/shared_auth_providers.dart';
import 'package:arena/features_shared/avatar_palette.dart';
import 'package:arena/features_shared/widgets/arena_app_bar.dart';
import 'package:arena/features_shared/widgets/arena_avatar.dart';
import 'package:arena/features_shared/widgets/arena_badge.dart';
import 'package:arena/features_shared/widgets/arena_button.dart';
import 'package:arena/features_shared/widgets/arena_screen_background.dart';
import 'package:arena/features_shared/widgets/arena_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// PHASE 11bis — Page profil pour l'app Admin / Super-admin.
///
/// Le router user bloque les comptes role=admin via `WrongAppForRoleFailure`,
/// donc un admin ne peut pas modifier son profil via l'app user. Cette
/// page est le pendant côté admin de `EditProfilePage`.
///
/// Champs éditables : `username`, `avatar_color`, `country_code`,
/// `whatsapp_number`. Le rôle et l'email sont read-only (l'email passe
/// par Supabase Auth ; le rôle ne se change pas côté self).
class AdminProfilePage extends ConsumerStatefulWidget {
  const AdminProfilePage({super.key});

  @override
  ConsumerState<AdminProfilePage> createState() => _AdminProfilePageState();
}

class _AdminProfilePageState extends ConsumerState<AdminProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _usernameCtrl;
  late final TextEditingController _whatsappCtrl;
  late String _avatarColor;
  late String _countryCode;
  bool _saving = false;
  String? _error;
  bool _initialized = false;

  String _stripDialCode(String? e164, String countryCode) {
    if (e164 == null || e164.isEmpty) return '';
    final dial = dialCodeFor(countryCode);
    if (e164.startsWith(dial)) return e164.substring(dial.length);
    if (e164.startsWith('+')) {
      final justDigits = e164.replaceAll(RegExp(r'\D'), '');
      return justDigits.length > 4 ? justDigits.substring(3) : justDigits;
    }
    return e164;
  }

  void _hydrate(Profile profile) {
    if (_initialized) return;
    _usernameCtrl = TextEditingController(text: profile.username);
    _avatarColor = profile.avatarColor;
    _countryCode = profile.countryCode;
    final inList = kSupportedCountries.any((c) => c.code == _countryCode);
    if (!inList) _countryCode = 'CM';
    _whatsappCtrl = TextEditingController(
      text: _stripDialCode(profile.whatsappNumber, _countryCode),
    );
    _whatsappCtrl.addListener(_onWhatsappChanged);
    _initialized = true;
  }

  void _onWhatsappChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    if (_initialized) {
      _whatsappCtrl
        ..removeListener(_onWhatsappChanged)
        ..dispose();
      _usernameCtrl.dispose();
    }
    super.dispose();
  }

  bool get _isWhatsappValid =>
      _whatsappCtrl.text.isEmpty || isLocalPhoneValid(_whatsappCtrl.text);

  Future<void> _save(Profile profile) async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (!_isWhatsappValid) {
      setState(() => _error = 'Numéro WhatsApp invalide.');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final patch = <String, dynamic>{
        'username': _usernameCtrl.text.trim(),
        'avatar_color': _avatarColor,
        'country_code': _countryCode,
      };
      final local = _whatsappCtrl.text.trim();
      patch['whatsapp_number'] = local.isEmpty
          ? null
          : buildE164Phone(countryCode: _countryCode, local: local);

      await ref.read(profileRepositoryProvider).update(profile.id, patch);
      ref.invalidate(currentProfileProvider);
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profil mis à jour.')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = 'Échec : $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(currentProfileProvider);

    return Scaffold(
      appBar: const ArenaAppBar(title: 'Mon profil'),
      body: ArenaScreenBackground(
        accent: ArenaColors.neonRed,
        child: SafeArea(
          child: profileAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Padding(
              padding: const EdgeInsets.all(ArenaSpacing.lg),
              child: Text('Erreur : $e', style: ArenaText.bodyMuted),
            ),
            data: (profile) {
              if (profile == null) {
                return Center(
                  child: Text(
                    'Profil introuvable.',
                    style: ArenaText.bodyMuted,
                  ),
                );
              }
              _hydrate(profile);
              return _ProfileForm(
                formKey: _formKey,
                profile: profile,
                usernameCtrl: _usernameCtrl,
                whatsappCtrl: _whatsappCtrl,
                avatarColor: _avatarColor,
                countryCode: _countryCode,
                isWhatsappValid: _isWhatsappValid,
                saving: _saving,
                error: _error,
                onAvatarChanged: (hex) => setState(() => _avatarColor = hex),
                onCountryChanged: (code) => setState(() => _countryCode = code),
                onSave: () => _save(profile),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _ProfileForm extends StatelessWidget {
  const _ProfileForm({
    required this.formKey,
    required this.profile,
    required this.usernameCtrl,
    required this.whatsappCtrl,
    required this.avatarColor,
    required this.countryCode,
    required this.isWhatsappValid,
    required this.saving,
    required this.error,
    required this.onAvatarChanged,
    required this.onCountryChanged,
    required this.onSave,
  });

  final GlobalKey<FormState> formKey;
  final Profile profile;
  final TextEditingController usernameCtrl;
  final TextEditingController whatsappCtrl;
  final String avatarColor;
  final String countryCode;
  final bool isWhatsappValid;
  final bool saving;
  final String? error;
  final ValueChanged<String> onAvatarChanged;
  final ValueChanged<String> onCountryChanged;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final dialCode = dialCodeFor(countryCode);
    final fullPhone = whatsappCtrl.text.isEmpty
        ? '—'
        : '$dialCode${whatsappCtrl.text.trim()}';

    return Form(
      key: formKey,
      child: ListView(
        padding: const EdgeInsets.all(ArenaSpacing.lg),
        children: [
          _Header(profile: profile, avatarColor: avatarColor),
          const SizedBox(height: ArenaSpacing.lg),

          // ─── Informations ───────────────────────────────────────
          Text('INFORMATIONS', style: ArenaText.inputLabel),
          const SizedBox(height: ArenaSpacing.sm),
          ArenaTextField(
            controller: usernameCtrl,
            label: 'Username',
            enabled: !saving,
            validator: (v) {
              final value = (v ?? '').trim();
              if (value.length < 3) return '3 caractères minimum';
              if (value.length > 20) return '20 caractères maximum';
              if (!RegExp(r'^[a-zA-Z0-9_\-.]+$').hasMatch(value)) {
                return 'Lettres, chiffres, _ - . uniquement';
              }
              return null;
            },
          ),
          const SizedBox(height: ArenaSpacing.md),

          Text('AVATAR', style: ArenaText.small),
          const SizedBox(height: ArenaSpacing.xs),
          _AvatarPalette(
            selected: avatarColor,
            onChanged: onAvatarChanged,
            enabled: !saving,
          ),
          const SizedBox(height: ArenaSpacing.md),

          Text('PAYS', style: ArenaText.small),
          const SizedBox(height: ArenaSpacing.xs),
          _CountryDropdown(
            value: countryCode,
            enabled: !saving,
            onChanged: onCountryChanged,
          ),
          const SizedBox(height: ArenaSpacing.md),

          Text('WHATSAPP', style: ArenaText.small),
          const SizedBox(height: ArenaSpacing.xs),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: ArenaSpacing.md,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: ArenaColors.carbon,
                  borderRadius: BorderRadius.circular(ArenaRadius.md),
                  border: Border.all(color: ArenaColors.borderHi),
                ),
                child: Text(dialCode, style: ArenaText.mono),
              ),
              const SizedBox(width: ArenaSpacing.sm),
              Expanded(
                child: ArenaTextField(
                  controller: whatsappCtrl,
                  hint: '6 12 34 56 78',
                  enabled: !saving,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            whatsappCtrl.text.isEmpty
                ? "Optionnel — laisse vide si tu n'utilises pas WhatsApp."
                : 'Sera enregistré : $fullPhone',
            style: ArenaText.small.copyWith(
              color: !isWhatsappValid && whatsappCtrl.text.isNotEmpty
                  ? ArenaColors.neonRed
                  : ArenaColors.silver,
            ),
          ),

          if (error != null) ...[
            const SizedBox(height: ArenaSpacing.sm),
            Text(
              error!,
              style: ArenaText.bodyMuted.copyWith(color: ArenaColors.neonRed),
            ),
          ],

          const SizedBox(height: ArenaSpacing.lg),
          ArenaButton(
            label: 'SAUVEGARDER',
            icon: Icons.check_circle_outline,
            fullWidth: true,
            isLoading: saving,
            onPressed: onSave,
          ),

          const SizedBox(height: ArenaSpacing.xl),

          // ─── Read-only block ────────────────────────────────────
          Text('COMPTE', style: ArenaText.inputLabel),
          const SizedBox(height: ArenaSpacing.sm),
          _ReadOnlyRow(label: 'Email', value: profile.email ?? '—'),
          _ReadOnlyRow(
            label: 'Rôle',
            value:
                profile.role == UserRole.superAdmin ? 'Super-admin' : 'Admin',
          ),
          _ReadOnlyRow(
            label: '2FA (TOTP)',
            value: profile.totpEnabled ? 'Activé' : 'Désactivé',
          ),
          const SizedBox(height: 6),
          Text(
            "L'email et le rôle se modifient via le dashboard Supabase. "
            'Le TOTP se reconfigure en passant `totp_enabled` à false côté DB '
            "puis en rouvrant l'app (router → /totp/setup).",
            style: ArenaText.small.copyWith(color: ArenaColors.silver),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.profile, required this.avatarColor});

  final Profile profile;
  final String avatarColor;

  @override
  Widget build(BuildContext context) {
    final initials = profile.username.isNotEmpty
        ? profile.username.substring(0, 1).toUpperCase()
        : '?';
    return Row(
      children: [
        ArenaAvatar(
          initials: initials,
          color: _previewColorFor(avatarColor),
          size: ArenaAvatarSize.xl,
        ),
        const SizedBox(width: ArenaSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                profile.username,
                style: ArenaText.h2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(profile.email ?? '—', style: ArenaText.bodyMuted),
              const SizedBox(height: 6),
              ArenaBadge(
                label: profile.role == UserRole.superAdmin
                    ? 'SUPER-ADMIN'
                    : 'ADMIN',
                variant: profile.role == UserRole.superAdmin
                    ? ArenaBadgeVariant.danger
                    : ArenaBadgeVariant.info,
              ),
            ],
          ),
        ),
      ],
    );
  }

  static ArenaAvatarColor _previewColorFor(String hex) {
    final cleaned = hex.replaceAll('#', '').trim().toUpperCase();
    return switch (cleaned) {
      'FF6B6B' || 'E03131' => ArenaAvatarColor.red,
      '69DB7C' || '94D82D' => ArenaAvatarColor.green,
      'FFA94D' || 'F4D03F' => ArenaAvatarColor.orange,
      '3BC9DB' || '15AABF' => ArenaAvatarColor.cyan,
      '9775FA' || '845EF7' => ArenaAvatarColor.purple,
      'F783AC' => ArenaAvatarColor.pink,
      'FFD700' => ArenaAvatarColor.yellow,
      _ => ArenaAvatarColor.blue,
    };
  }
}

class _AvatarPalette extends StatelessWidget {
  const _AvatarPalette({
    required this.selected,
    required this.onChanged,
    required this.enabled,
  });

  final String selected;
  final ValueChanged<String> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: ArenaSpacing.sm,
      runSpacing: ArenaSpacing.sm,
      children: [
        for (final hex in AvatarPalette.colors)
          GestureDetector(
            onTap: enabled ? () => onChanged(hex) : null,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AvatarPalette.colorFromHex(hex),
                shape: BoxShape.circle,
                border: Border.all(
                  color:
                      selected == hex ? ArenaColors.bone : ArenaColors.border,
                  width: selected == hex ? 2.5 : 1,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _CountryDropdown extends StatelessWidget {
  const _CountryDropdown({
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  final String value;
  final bool enabled;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: ArenaSpacing.md),
      decoration: BoxDecoration(
        color: ArenaColors.carbon,
        borderRadius: BorderRadius.circular(ArenaRadius.md),
        border: Border.all(color: ArenaColors.borderHi),
      ),
      child: DropdownButton<String>(
        value: value,
        isExpanded: true,
        underline: const SizedBox.shrink(),
        dropdownColor: ArenaColors.carbon,
        style: ArenaText.body,
        onChanged: enabled
            ? (code) {
                if (code != null) onChanged(code);
              }
            : null,
        items: [
          for (final c in kSupportedCountries)
            DropdownMenuItem(
              value: c.code,
              child: Text('${c.flag}  ${c.name}  (${c.dialCode})'),
            ),
        ],
      ),
    );
  }
}

class _ReadOnlyRow extends StatelessWidget {
  const _ReadOnlyRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Expanded(child: Text(label, style: ArenaText.bodyMuted)),
          Flexible(
            child: Text(
              value,
              style: ArenaText.body,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}
