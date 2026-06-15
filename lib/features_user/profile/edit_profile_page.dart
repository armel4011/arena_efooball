import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/core/utils/supported_countries.dart';
import 'package:arena/data/repositories/profile_repository.dart';
import 'package:arena/features_shared/avatar_palette.dart';
import 'package:arena/features_shared/widgets/arena_app_bar.dart';
import 'package:arena/features_shared/widgets/arena_button.dart';
import 'package:arena/features_shared/widgets/arena_card.dart';
import 'package:arena/features_shared/widgets/arena_screen_background.dart';
import 'package:arena/features_shared/widgets/arena_text_field.dart';
import 'package:arena/features_user/auth/auth_providers.dart';
import 'package:arena/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Lets the player tweak their public-ish profile bits (PHASE 9.1).
///
/// Editable: `username`, `avatar_color`, `country_code`, `whatsapp_number`.
/// Email + password changes live behind `SettingsPage` since they go
/// through Supabase auth rather than a `profiles` UPDATE. La liste pays
/// + indicatifs vient du module partagé `core/utils/supported_countries`.
class EditProfilePage extends ConsumerStatefulWidget {
  const EditProfilePage({super.key});

  @override
  ConsumerState<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends ConsumerState<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _usernameCtrl;
  late final TextEditingController _whatsappCtrl;
  late String _avatarColor;
  late String _countryCode;
  bool _saving = false;
  String? _error;

  /// Strip le préfixe `+XXX` du numéro stocké en DB pour qu'on l'édite
  /// comme un numéro local. L'utilisateur change de pays → le dial code
  /// change automatiquement, on n'écrase pas son input.
  String _stripDialCode(String? e164, String countryCode) {
    if (e164 == null || e164.isEmpty) return '';
    final dial = dialCodeFor(countryCode);
    if (e164.startsWith(dial)) return e164.substring(dial.length);
    if (e164.startsWith('+')) {
      final justDigits = e164.replaceAll(RegExp(r'\D'), '');
      // Best-effort : strip les 3-4 premiers chiffres si on ne match pas
      return justDigits.length > 4 ? justDigits.substring(3) : justDigits;
    }
    return e164;
  }

  @override
  void initState() {
    super.initState();
    final profile = ref.read(currentProfileProvider).valueOrNull;
    _usernameCtrl = TextEditingController(text: profile?.username ?? '');
    _avatarColor = profile?.avatarColor ?? AvatarPalette.colors.first;
    _countryCode = profile?.countryCode ?? 'CM';
    final inList = kSupportedCountries.any((c) => c.code == _countryCode);
    if (!inList) _countryCode = 'CM';
    _whatsappCtrl = TextEditingController(
      text: _stripDialCode(profile?.whatsappNumber, _countryCode),
    );
    _whatsappCtrl.addListener(_onWhatsappChanged);
  }

  void _onWhatsappChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _whatsappCtrl
      ..removeListener(_onWhatsappChanged)
      ..dispose();
    _usernameCtrl.dispose();
    super.dispose();
  }

  bool get _isWhatsappValid =>
      _whatsappCtrl.text.isEmpty || isLocalPhoneValid(_whatsappCtrl.text);

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (!_isWhatsappValid) {
      setState(() => _error = l10n.editProfileWhatsappInvalidError);
      return;
    }
    final profile = ref.read(currentProfileProvider).valueOrNull;
    if (profile == null) return;

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
      // Seuls les utilisateurs qui veulent vraiment fixer leur WhatsApp
      // écrivent la colonne — on ne l'écrase pas avec une chaîne vide.
      if (_whatsappCtrl.text.trim().isNotEmpty) {
        patch['whatsapp_number'] = buildE164Phone(
          countryCode: _countryCode,
          local: _whatsappCtrl.text,
        );
      }
      await ref.read(profileRepositoryProvider).update(profile.id, patch);
      ref.invalidate(currentProfileProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.editProfileUpdatedSnack)),
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
    final l10n = AppLocalizations.of(context);
    final profile = ref.watch(currentProfileProvider).valueOrNull;
    final initial = (profile?.username.isNotEmpty ?? false)
        ? profile!.username[0].toUpperCase()
        : '?';
    final avatarColor = AvatarPalette.colorFromHex(_avatarColor);

    return Scaffold(
      appBar: ArenaAppBar(
        title: l10n.editProfileAppBarTitle,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.check,
              color: ArenaColors.statusOk,
              size: 22,
            ),
            tooltip: l10n.editProfileSaveTooltip,
            onPressed: _saving ? null : _save,
          ),
        ],
      ),
      body: ArenaScreenBackground(
        child: SafeArea(
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(ArenaSpacing.lg),
              children: [
                // Avatar preview centré — reflète en live le _avatarColor
                // sélectionné dans le _ColorPicker. La maquette montre un
                // lien "Change avatar ›" en signalBlue ; on remappe ce lien
                // sur la section couleur en dessous (scroll au lieu de
                // bottom-sheet pour rester simple en V1).
                Center(
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: avatarColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: avatarColor.withValues(alpha: 0.55),
                          blurRadius: 28,
                          spreadRadius: -2,
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      initial,
                      style: ArenaText.h1.copyWith(
                        color: ArenaColors.bone,
                        fontSize: 34,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Center(
                  child: Text(
                    l10n.editProfileColorEditableHint,
                    style: ArenaText.small.copyWith(
                      color: ArenaColors.signalBlue,
                    ),
                  ),
                ),
                const SizedBox(height: ArenaSpacing.lg),
                _Caption(l10n.editProfileUsernameCaption),
                const SizedBox(height: ArenaSpacing.xs),
                ArenaTextField(
                  controller: _usernameCtrl,
                  maxLength: 20,
                  textInputAction: TextInputAction.next,
                  validator: (v) {
                    final value = v?.trim() ?? '';
                    if (value.length < 3) {
                      return l10n.editProfileUsernameMinError;
                    }
                    if (value.length > 20) {
                      return l10n.editProfileUsernameMaxError;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: ArenaSpacing.lg),
                _Caption(l10n.editProfileCountryCaption),
                const SizedBox(height: ArenaSpacing.xs),
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
                        for (final c in kSupportedCountries)
                          DropdownMenuItem(
                            value: c.code,
                            child: Text('${c.flag}  ${c.name}'),
                          ),
                      ],
                      onChanged: (v) {
                        if (v != null) setState(() => _countryCode = v);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: ArenaSpacing.lg),
                _Caption(l10n.editProfileAvatarColorCaption),
                const SizedBox(height: ArenaSpacing.xs),
                _ColorPicker(
                  selected: _avatarColor,
                  onChanged: (v) => setState(() => _avatarColor = v),
                ),
                const SizedBox(height: ArenaSpacing.lg),
                _Caption(l10n.editProfileWhatsappCaption(dialCodeFor(_countryCode))),
                const SizedBox(height: ArenaSpacing.xs),
                ArenaTextField(
                  hint: l10n.editProfileWhatsappHint,
                  helper: l10n.editProfileWhatsappHelper(dialCodeFor(_countryCode)),
                  controller: _whatsappCtrl,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.done,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[\d\s]')),
                  ],
                  errorText:
                      _isWhatsappValid ? null : l10n.editProfileWhatsappInvalidErrorText,
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
                  label: l10n.editProfileSaveButton,
                  isLoading: _saving,
                  fullWidth: true,
                  onPressed: _saving ? null : _save,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Caption mono small au-dessus de chaque champ — reproduit
/// `m-text-caption` de la maquette #25 (USERNAME / COUNTRY / AVATAR
/// COLOR / BIO).
class _Caption extends StatelessWidget {
  const _Caption(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: ArenaText.monoSmall.copyWith(
        color: ArenaColors.silver,
        letterSpacing: 1.5,
        fontWeight: FontWeight.w700,
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
