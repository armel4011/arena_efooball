import 'package:arena/core/theme/arena_fluent_theme.dart';
import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/core/utils/arena_error_message.dart';
import 'package:arena/data/repositories/whatsapp_group_repository.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

/// Écran super-admin desktop : groupes WhatsApp obligatoires en nombre
/// illimité (« Nouveau groupe »), bascule automatique à 1020 validations.
/// Équivalent Fluent de SuperAdminWhatsAppGroup.
class DesktopWhatsAppGroupPage extends ConsumerStatefulWidget {
  const DesktopWhatsAppGroupPage({super.key});

  @override
  ConsumerState<DesktopWhatsAppGroupPage> createState() =>
      _DesktopWhatsAppGroupPageState();
}

class _GroupDraft {
  _GroupDraft({this.stats, String url = '', String name = ''})
      : url = TextEditingController(text: url),
        name = TextEditingController(text: name);

  final WhatsAppGroupSlot? stats;
  final TextEditingController url;
  final TextEditingController name;

  int? get id => stats?.id;

  void dispose() {
    url.dispose();
    name.dispose();
  }
}

class _DesktopWhatsAppGroupPageState
    extends ConsumerState<DesktopWhatsAppGroupPage> {
  final List<_GroupDraft> _drafts = [];

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
    for (final d in _drafts) {
      d.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final groups =
          await ref.read(whatsAppGroupRepositoryProvider).fetchGroups();
      for (final d in _drafts) {
        d.dispose();
      }
      _drafts
        ..clear()
        ..addAll([
          for (final g in groups)
            _GroupDraft(stats: g, url: g.inviteUrl, name: g.groupName),
        ]);
    } catch (e) {
      _error = arenaErrorMessage(e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _addGroup() {
    final suggestion = WhatsAppGroupRepository.suggestNextName(
      _drafts.map((d) => d.name.text).where((n) => n.trim().isNotEmpty),
    );
    setState(() => _drafts.add(_GroupDraft(name: suggestion)));
  }

  Future<void> _removeGroup(int index) async {
    final draft = _drafts[index];
    final members = draft.stats?.members ?? 0;
    if (members > 0) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => ContentDialog(
          title: const Text('Supprimer ce groupe ?'),
          content: Text(
            '$members joueur(s) l’ont validé. Ils restent validés, mais ne '
            'compteront plus dans le remplissage. La suppression est '
            'appliquée à l’enregistrement.',
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
      if (ok != true || !mounted) return;
    }
    setState(() => _drafts.removeAt(index));
    draft.dispose();
  }

  Future<void> _save({bool disable = false}) async {
    if (disable) {
      for (final d in _drafts) {
        d.dispose();
      }
      _drafts.clear();
    }
    setState(() {
      _saving = true;
      _error = null;
      _success = null;
    });
    try {
      await ref.read(whatsAppGroupRepositoryProvider).saveGroups([
        for (final d in _drafts)
          (id: d.id, inviteUrl: d.url.text, groupName: d.name.text),
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
    final saved = _drafts.map((d) => d.stats).whereType<WhatsAppGroupSlot>();
    return saved.isNotEmpty && saved.every((s) => s.isFull);
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
                  if (_drafts.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 12),
                      child: Text(
                        'Aucun groupe : l’étape est inactive. Ajoute un groupe '
                        'pour l’activer.',
                        style: TextStyle(color: ArenaColors.silver),
                      ),
                    ),
                  for (var i = 0; i < _drafts.length; i++)
                    _groupCard(i + 1, _drafts[i], () => _removeGroup(i)),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Button(
                      onPressed: _saving ? null : _addGroup,
                      child: const Padding(
                        padding: EdgeInsets.symmetric(
                          vertical: 6,
                          horizontal: 12,
                        ),
                        child: Text('+ Nouveau groupe'),
                      ),
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
                        onPressed: _saving || _drafts.isEmpty
                            ? null
                            : () => _save(disable: true),
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

  Widget _groupCard(int number, _GroupDraft draft, VoidCallback onRemove) {
    final stats = draft.stats;
    final (String badge, Color color) = stats == null
        ? ('NOUVEAU', ArenaColors.signalBlue)
        : stats.isCurrent
            ? ('EN COURS', ArenaColors.success)
            : stats.isFull
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
                    'Groupe $number',
                    style: GoogleFonts.spaceGrotesk(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Text(
                  badge,
                  style: TextStyle(color: color, fontWeight: FontWeight.w800),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(FluentIcons.delete),
                  onPressed: _saving ? null : onRemove,
                ),
              ],
            ),
            if (stats != null) ...[
              const SizedBox(height: 6),
              Text(
                '${stats.members} / ${stats.capacity} validés',
                style: const TextStyle(color: ArenaColors.silver, fontSize: 12),
              ),
              const SizedBox(height: 4),
              ProgressBar(
                value: (stats.members / stats.capacity * 100)
                    .clamp(0, 100)
                    .toDouble(),
              ),
            ],
            const SizedBox(height: 10),
            TextBox(
              controller: draft.url,
              placeholder: 'https://chat.whatsapp.com/…',
              enabled: !_saving,
            ),
            const SizedBox(height: 8),
            TextBox(
              controller: draft.name,
              placeholder: 'Nom exact du groupe',
              enabled: !_saving,
            ),
          ],
        ),
      ),
    );
  }
}
