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

/// Écran super-admin : groupes WhatsApp que TOUT joueur doit rejoindre, en
/// nombre illimité (« Nouveau groupe »). Les nouveaux joueurs reçoivent le
/// lien du premier groupe non plein (1020 validations), puis du suivant.
class SuperAdminWhatsAppGroup extends ConsumerStatefulWidget {
  const SuperAdminWhatsAppGroup({super.key});

  @override
  ConsumerState<SuperAdminWhatsAppGroup> createState() =>
      _SuperAdminWhatsAppGroupState();
}

/// Groupe en cours d'édition. [stats] est null pour un groupe pas encore
/// enregistré.
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

class _SuperAdminWhatsAppGroupState
    extends ConsumerState<SuperAdminWhatsAppGroup> {
  final List<_GroupDraft> _drafts = [];

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
      _error = null;
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
        builder: (ctx) => AlertDialog(
          title: const Text('Supprimer ce groupe ?'),
          content: Text(
            '$members joueur(s) l’ont validé. Ils restent validés, mais ne '
            'compteront plus dans le remplissage. La suppression est '
            'appliquée à l’enregistrement.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Annuler'),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Supprimer'),
            ),
          ],
        ),
      );
      if (ok != true || !mounted) return;
    }
    setState(() {
      _drafts.removeAt(index);
    });
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
    });
    try {
      await ref.read(whatsAppGroupRepositoryProvider).saveGroups([
        for (final d in _drafts)
          (id: d.id, inviteUrl: d.url.text, groupName: d.name.text),
      ]);
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              disable
                  ? 'Étape « groupe WhatsApp » désactivée.'
                  : 'Groupes WhatsApp enregistrés.',
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

  bool get _allFull {
    final saved = _drafts.map((d) => d.stats).whereType<WhatsAppGroupSlot>();
    return saved.isNotEmpty && saved.every((s) => s.isFull);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const ArenaAppBar(title: 'GROUPES WHATSAPP'),
      body: ArenaScreenBackground(
        accent: ArenaColors.neonRed,
        child: SafeArea(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  padding: const EdgeInsets.all(ArenaSpacing.lg),
                  children: [
                    Text(
                      'Tout joueur doit rejoindre l’un de ces groupes puis '
                      'saisir son nom pour continuer. Les nouveaux reçoivent '
                      'le lien du premier groupe non plein '
                      '(${WhatsAppGroupRepository.defaultCapacity} '
                      'validations), puis du suivant. Le nom saisi est '
                      'accepté pour n’importe lequel des groupes (majuscules, '
                      'accents, espaces et emojis ignorés).',
                      style: ArenaText.bodyMuted,
                    ),
                    const SizedBox(height: ArenaSpacing.sm),
                    Text(
                      'Le remplissage compte les joueurs ARENA qui ont validé '
                      'chaque groupe (WhatsApp ne communique pas son nombre '
                      'de membres).',
                      style:
                          ArenaText.small.copyWith(color: ArenaColors.silver),
                    ),
                    if (_allFull) ...[
                      const SizedBox(height: ArenaSpacing.md),
                      const _Banner(
                        text: 'Tous les groupes sont pleins : les nouveaux '
                            'joueurs ne sont plus bloqués. Ajoute un groupe.',
                      ),
                    ],
                    const SizedBox(height: ArenaSpacing.lg),
                    if (_drafts.isEmpty)
                      Padding(
                        padding:
                            const EdgeInsets.only(bottom: ArenaSpacing.md),
                        child: Text(
                          'Aucun groupe : l’étape est inactive. Ajoute un '
                          'groupe pour l’activer.',
                          style: ArenaText.body
                              .copyWith(color: ArenaColors.silver),
                        ),
                      ),
                    for (var i = 0; i < _drafts.length; i++) ...[
                      _GroupCard(
                        number: i + 1,
                        draft: _drafts[i],
                        enabled: !_saving,
                        onRemove: () => _removeGroup(i),
                      ),
                      const SizedBox(height: ArenaSpacing.md),
                    ],
                    ArenaButton(
                      label: '+ NOUVEAU GROUPE',
                      variant: ArenaButtonVariant.secondary,
                      onPressed: _saving ? null : _addGroup,
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
                      onPressed: _saving || _drafts.isEmpty
                          ? null
                          : () => _save(disable: true),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _GroupCard extends StatelessWidget {
  const _GroupCard({
    required this.number,
    required this.draft,
    required this.enabled,
    required this.onRemove,
  });

  final int number;
  final _GroupDraft draft;
  final bool enabled;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final stats = draft.stats;
    final (String badge, Color color) = stats == null
        ? ('NOUVEAU', ArenaColors.signalBlue)
        : stats.isCurrent
            ? ('EN COURS', ArenaColors.success)
            : stats.isFull
                ? ('PLEIN', ArenaColors.neonRed)
                : ('EN ATTENTE', ArenaColors.silver);
    return ArenaCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Groupe $number',
                  style: ArenaText.body.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: ArenaSpacing.sm,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(ArenaRadius.sm),
                  border: Border.all(color: color),
                ),
                child: Text(
                  badge,
                  style: ArenaText.small.copyWith(
                    color: color,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Supprimer ce groupe',
                icon: const Icon(
                  Icons.delete_outline,
                  color: ArenaColors.neonRed,
                ),
                onPressed: enabled ? onRemove : null,
              ),
            ],
          ),
          if (stats != null) ...[
            Text(
              '${stats.members} / ${stats.capacity} validés',
              style: ArenaText.small.copyWith(color: ArenaColors.silver),
            ),
            const SizedBox(height: ArenaSpacing.xs),
            LinearProgressIndicator(
              value: (stats.members / stats.capacity).clamp(0, 1).toDouble(),
              color: color,
              backgroundColor: ArenaColors.border,
            ),
            const SizedBox(height: ArenaSpacing.sm),
          ],
          ArenaTextField(
            controller: draft.url,
            hint: 'https://chat.whatsapp.com/…',
            keyboardType: TextInputType.url,
            enabled: enabled,
          ),
          const SizedBox(height: ArenaSpacing.sm),
          ArenaTextField(
            controller: draft.name,
            hint: 'Nom exact du groupe',
            enabled: enabled,
          ),
        ],
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(ArenaSpacing.md),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(ArenaRadius.md),
        border: Border.all(color: ArenaColors.neonRed),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: ArenaColors.neonRed),
          const SizedBox(width: ArenaSpacing.sm),
          Expanded(child: Text(text, style: ArenaText.small)),
        ],
      ),
    );
  }
}
