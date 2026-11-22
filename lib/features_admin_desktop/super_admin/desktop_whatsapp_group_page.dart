import 'package:arena/core/theme/arena_fluent_theme.dart';
import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/core/utils/arena_error_message.dart';
import 'package:arena/data/repositories/whatsapp_group_repository.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

/// Écran super-admin desktop : jusqu'à 5 groupes WhatsApp obligatoires
/// (bascule automatique à 1020 validations). Équivalent Fluent de
/// SuperAdminWhatsAppGroup.
class DesktopWhatsAppGroupPage extends ConsumerStatefulWidget {
  const DesktopWhatsAppGroupPage({super.key});

  @override
  ConsumerState<DesktopWhatsAppGroupPage> createState() =>
      _DesktopWhatsAppGroupPageState();
}

class _DesktopWhatsAppGroupPageState
    extends ConsumerState<DesktopWhatsAppGroupPage> {
  final _urls = List.generate(
    WhatsAppGroupRepository.maxGroups,
    (_) => TextEditingController(),
  );
  final _names = List.generate(
    WhatsAppGroupRepository.maxGroups,
    (_) => TextEditingController(),
  );
  List<WhatsAppGroupSlot> _slots = const [];

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
    for (final c in [..._urls, ..._names]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final slots = await ref.read(whatsAppGroupRepositoryProvider).fetchGroups();
      for (var i = 0; i < slots.length; i++) {
        _urls[i].text = slots[i].inviteUrl;
        _names[i].text = slots[i].groupName;
      }
      _slots = slots;
    } catch (e) {
      _error = arenaErrorMessage(e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save({bool disable = false}) async {
    if (disable) {
      for (final c in [..._urls, ..._names]) {
        c.clear();
      }
    }
    setState(() {
      _saving = true;
      _error = null;
      _success = null;
    });
    try {
      await ref.read(whatsAppGroupRepositoryProvider).saveGroups([
        for (var i = 0; i < WhatsAppGroupRepository.maxGroups; i++)
          (inviteUrl: _urls[i].text, groupName: _names[i].text),
      ]);
      await _load();
      if (mounted) {
        setState(
          () => _success = disable
              ? 'Étape « groupe WhatsApp » désactivée.'
              : 'Groupes WhatsApp enregistrés.',
        );
      }
    } catch (e) {
      if (mounted) setState(() => _error = arenaErrorMessage(e));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  bool get _allFull {
    final configured = _slots.where((s) => s.isConfigured).toList();
    return configured.isNotEmpty && configured.every((s) => s.isFull);
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldPage(
      header: const PageHeader(title: Text('GROUPES WHATSAPP')),
      content: _loading
          ? const Center(child: ProgressRing())
          : Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: ArenaDesktop.pagePadding,
              ),
              child: ListView(
                children: [
                  Text(
                    'Tout joueur doit rejoindre l’un de ces groupes puis saisir '
                    'son nom. Les nouveaux reçoivent le lien du premier groupe '
                    'non plein (${WhatsAppGroupRepository.defaultCapacity} '
                    'validations), puis du suivant. Le remplissage compte les '
                    'joueurs ARENA ayant validé (WhatsApp ne communique pas son '
                    'nombre de membres).',
                    style: GoogleFonts.spaceGrotesk(color: ArenaColors.silver),
                  ),
                  if (_allFull) ...[
                    const SizedBox(height: 12),
                    const InfoBar(
                      title: Text('Tous les groupes sont pleins'),
                      content: Text(
                        'Les nouveaux joueurs ne sont plus bloqués. Ajoute un '
                        'groupe.',
                      ),
                      severity: InfoBarSeverity.warning,
                    ),
                  ],
                  const SizedBox(height: 16),
                  for (var i = 0; i < WhatsAppGroupRepository.maxGroups; i++)
                    _slotCard(
                      i < _slots.length
                          ? _slots[i]
                          : WhatsAppGroupSlot(position: i + 1),
                      _urls[i],
                      _names[i],
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

  Widget _slotCard(
    WhatsAppGroupSlot slot,
    TextEditingController urlCtrl,
    TextEditingController nameCtrl,
  ) {
    final number = slot.position.toString().padLeft(3, '0');
    final (String badge, Color color) = !slot.isConfigured
        ? ('VIDE', ArenaColors.silver)
        : slot.isCurrent
            ? ('EN COURS', ArenaColors.success)
            : slot.isFull
                ? ('PLEIN', ArenaColors.neonRed)
                : ('EN ATTENTE', ArenaColors.silver);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Groupe ${slot.position}',
                    style: GoogleFonts.spaceGrotesk(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Text(
                  badge,
                  style: TextStyle(color: color, fontWeight: FontWeight.w800),
                ),
              ],
            ),
            if (slot.isConfigured) ...[
              const SizedBox(height: 6),
              Text(
                '${slot.members} / ${slot.capacity} validés',
                style: const TextStyle(color: ArenaColors.silver, fontSize: 12),
              ),
              const SizedBox(height: 4),
              ProgressBar(
                value: (slot.members / slot.capacity * 100).clamp(0, 100).toDouble(),
              ),
            ],
            const SizedBox(height: 10),
            TextBox(
              controller: urlCtrl,
              placeholder: 'https://chat.whatsapp.com/…',
              enabled: !_saving,
            ),
            const SizedBox(height: 8),
            TextBox(
              controller: nameCtrl,
              placeholder: 'Arena_Game $number',
              enabled: !_saving,
            ),
          ],
        ),
      ),
    );
  }
}
