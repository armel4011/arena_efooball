import 'package:arena/core/theme/arena_fluent_theme.dart';
import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/core/utils/arena_error_message.dart';
import 'package:arena/data/repositories/whatsapp_group_repository.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

/// Écran super-admin desktop : groupe WhatsApp obligatoire pour tous les
/// joueurs (`whatsapp_group_config`). Équivalent Fluent de
/// SuperAdminWhatsAppGroup.
class DesktopWhatsAppGroupPage extends ConsumerStatefulWidget {
  const DesktopWhatsAppGroupPage({super.key});

  @override
  ConsumerState<DesktopWhatsAppGroupPage> createState() =>
      _DesktopWhatsAppGroupPageState();
}

class _DesktopWhatsAppGroupPageState
    extends ConsumerState<DesktopWhatsAppGroupPage> {
  final _inviteUrl = TextEditingController();
  final _groupName = TextEditingController();

  bool _loading = true;
  bool _saving = false;
  String? _error;
  String? _success;

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
      _success = null;
    });
    try {
      await ref.read(whatsAppGroupRepositoryProvider).saveConfig(
            inviteUrl: _inviteUrl.text,
            groupName: _groupName.text,
          );
      if (mounted) {
        setState(
          () => _success = disable
              ? 'Étape « groupe WhatsApp » désactivée.'
              : 'Groupe WhatsApp enregistré.',
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
    return ScaffoldPage(
      header: const PageHeader(title: Text('GROUPE WHATSAPP')),
      content: _loading
          ? const Center(child: ProgressRing())
          : Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: ArenaDesktop.pagePadding,
              ),
              child: ListView(
                children: [
                  Text(
                    'Tout joueur devra rejoindre ce groupe puis saisir son nom '
                    'pour continuer à utiliser l’app. La saisie tolère '
                    'majuscules, accents, espaces et emojis.',
                    style: GoogleFonts.spaceGrotesk(color: ArenaColors.silver),
                  ),
                  const SizedBox(height: 16),
                  _field(
                    "Lien d'invitation",
                    _inviteUrl,
                    'https://chat.whatsapp.com/…',
                  ),
                  _field('Nom exact du groupe', _groupName, 'Arena Communauté'),
                  Text(
                    'Le nom reste secret : il n’est jamais envoyé aux joueurs. '
                    'Si tu renommes le groupe, mets ce champ à jour (les '
                    'joueurs déjà validés le restent).',
                    style: GoogleFonts.spaceGrotesk(
                      color: ArenaColors.silver,
                      fontSize: 12,
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    InfoBar(
                      title: const Text('Erreur'),
                      content: Text(_error!),
                      severity: InfoBarSeverity.error,
                    ),
                  ],
                  if (_success != null) ...[
                    const SizedBox(height: 12),
                    InfoBar(
                      title: const Text('OK'),
                      content: Text(_success!),
                      severity: InfoBarSeverity.success,
                    ),
                  ],
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      FilledButton(
                        onPressed: _saving ? null : _save,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 6,
                            horizontal: 12,
                          ),
                          child:
                              Text(_saving ? 'Enregistrement…' : 'Enregistrer'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Button(
                        onPressed:
                            _saving ? null : () => _save(disable: true),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(
                            vertical: 6,
                            horizontal: 12,
                          ),
                          child: Text("Désactiver l'étape"),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  Widget _field(
    String label,
    TextEditingController ctrl,
    String placeholder,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.spaceGrotesk(
              color: ArenaColors.silver,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          TextBox(controller: ctrl, placeholder: placeholder),
        ],
      ),
    );
  }
}
