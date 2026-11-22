import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/core/utils/arena_error_message.dart';
import 'package:arena/data/repositories/whatsapp_group_repository.dart';
import 'package:arena/features_shared/widgets/arena_app_bar.dart';
import 'package:arena/features_shared/widgets/arena_button.dart';
import 'package:arena/features_shared/widgets/arena_card.dart';
import 'package:arena/features_shared/widgets/arena_screen_background.dart';
import 'package:arena/features_shared/widgets/arena_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Écran super-admin : groupe WhatsApp que TOUT joueur doit rejoindre
/// (table `whatsapp_group_config`). Lien + nom renseignés = étape active ;
/// les deux vides = étape désactivée.
class SuperAdminWhatsAppGroup extends ConsumerStatefulWidget {
  const SuperAdminWhatsAppGroup({super.key});

  @override
  ConsumerState<SuperAdminWhatsAppGroup> createState() =>
      _SuperAdminWhatsAppGroupState();
}

class _SuperAdminWhatsAppGroupState
    extends ConsumerState<SuperAdminWhatsAppGroup> {
  final _inviteUrl = TextEditingController();
  final _groupName = TextEditingController();

  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _inviteUrl.dispose();
    _groupName.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final cfg = await ref.read(whatsAppGroupRepositoryProvider).fetchConfig();
      _inviteUrl.text = cfg.inviteUrl ?? '';
      _groupName.text = cfg.groupName ?? '';
    } catch (e) {
      _error = arenaErrorMessage(e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save({bool disable = false}) async {
    if (disable) {
      _inviteUrl.clear();
      _groupName.clear();
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref.read(whatsAppGroupRepositoryProvider).saveConfig(
            inviteUrl: _inviteUrl.text,
            groupName: _groupName.text,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              disable
                  ? 'Étape « groupe WhatsApp » désactivée.'
                  : 'Groupe WhatsApp enregistré.',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) setState(() => _error = arenaErrorMessage(e));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const ArenaAppBar(title: 'GROUPE WHATSAPP'),
      body: ArenaScreenBackground(
        accent: ArenaColors.neonRed,
        child: SafeArea(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  padding: const EdgeInsets.all(ArenaSpacing.lg),
                  children: [
                    Text(
                      'Tout joueur devra rejoindre ce groupe puis saisir son '
                      'nom pour continuer à utiliser l’app. La saisie tolère '
                      'majuscules, accents, espaces et emojis.',
                      style: ArenaText.bodyMuted,
                    ),
                    const SizedBox(height: ArenaSpacing.lg),
                    ArenaCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _label("Lien d'invitation"),
                          ArenaTextField(
                            controller: _inviteUrl,
                            hint: 'https://chat.whatsapp.com/…',
                            keyboardType: TextInputType.url,
                          ),
                          const SizedBox(height: ArenaSpacing.md),
                          _label('Nom exact du groupe'),
                          ArenaTextField(
                            controller: _groupName,
                            hint: 'Arena Communauté',
                          ),
                          const SizedBox(height: ArenaSpacing.sm),
                          Text(
                            'Le nom reste secret : il n’est jamais envoyé aux '
                            'joueurs. Si tu renommes le groupe, mets ce champ '
                            'à jour (les joueurs déjà validés le restent).',
                            style: ArenaText.small
                                .copyWith(color: ArenaColors.silver),
                          ),
                        ],
                      ),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: ArenaSpacing.md),
                      Text(
                        _error!,
                        style: ArenaText.small
                            .copyWith(color: ArenaColors.neonRed),
                      ),
                    ],
                    const SizedBox(height: ArenaSpacing.lg),
                    ArenaButton(
                      label: _saving ? 'ENREGISTREMENT…' : 'ENREGISTRER',
                      onPressed: _saving ? null : _save,
                      isLoading: _saving,
                    ),
                    const SizedBox(height: ArenaSpacing.sm),
                    ArenaButton(
                      label: 'DÉSACTIVER L’ÉTAPE',
                      variant: ArenaButtonVariant.ghost,
                      onPressed: _saving ? null : () => _save(disable: true),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(
          text,
          style: ArenaText.small.copyWith(
            color: ArenaColors.silver,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
}
