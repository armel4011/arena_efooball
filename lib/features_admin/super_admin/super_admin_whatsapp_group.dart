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

/// Écran super-admin : jusqu'à 5 groupes WhatsApp que TOUT joueur doit
/// rejoindre. Les nouveaux joueurs reçoivent le lien du premier groupe non
/// plein (1020 validations) ; bascule automatique sur le suivant.
class SuperAdminWhatsAppGroup extends ConsumerStatefulWidget {
  const SuperAdminWhatsAppGroup({super.key});

  @override
  ConsumerState<SuperAdminWhatsAppGroup> createState() =>
      _SuperAdminWhatsAppGroupState();
}

class _SuperAdminWhatsAppGroupState
    extends ConsumerState<SuperAdminWhatsAppGroup> {
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
      _error = null;
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
    });
    try {
      await ref.read(whatsAppGroupRepositoryProvider).saveGroups([
        for (var i = 0; i < WhatsAppGroupRepository.maxGroups; i++)
          (inviteUrl: _urls[i].text, groupName: _names[i].text),
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
    final configured = _slots.where((s) => s.isConfigured).toList();
    return configured.isNotEmpty && configured.every((s) => s.isFull);
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
                    for (var i = 0; i < WhatsAppGroupRepository.maxGroups; i++) ...[
                      _SlotCard(
                        slot: i < _slots.length
                            ? _slots[i]
                            : WhatsAppGroupSlot(position: i + 1),
                        urlCtrl: _urls[i],
                        nameCtrl: _names[i],
                        enabled: !_saving,
                      ),
                      const SizedBox(height: ArenaSpacing.md),
                    ],
                    if (_error != null) ...[
                      Text(
                        _error!,
                        style: ArenaText.small
                            .copyWith(color: ArenaColors.neonRed),
                      ),
                      const SizedBox(height: ArenaSpacing.md),
                    ],
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
}

class _SlotCard extends StatelessWidget {
  const _SlotCard({
    required this.slot,
    required this.urlCtrl,
    required this.nameCtrl,
    required this.enabled,
  });

  final WhatsAppGroupSlot slot;
  final TextEditingController urlCtrl;
  final TextEditingController nameCtrl;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final number = slot.position.toString().padLeft(3, '0');
    final (String badge, Color color) = !slot.isConfigured
        ? ('VIDE', ArenaColors.silver)
        : slot.isCurrent
            ? ('EN COURS', ArenaColors.success)
            : slot.isFull
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
                  'Groupe ${slot.position}',
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
            ],
          ),
          if (slot.isConfigured) ...[
            const SizedBox(height: ArenaSpacing.xs),
            Text(
              '${slot.members} / ${slot.capacity} validés',
              style: ArenaText.small.copyWith(color: ArenaColors.silver),
            ),
            const SizedBox(height: ArenaSpacing.xs),
            LinearProgressIndicator(
              value: (slot.members / slot.capacity).clamp(0, 1).toDouble(),
              color: color,
              backgroundColor: ArenaColors.border,
            ),
          ],
          const SizedBox(height: ArenaSpacing.md),
          ArenaTextField(
            controller: urlCtrl,
            hint: 'https://chat.whatsapp.com/…',
            keyboardType: TextInputType.url,
            enabled: enabled,
          ),
          const SizedBox(height: ArenaSpacing.sm),
          ArenaTextField(
            controller: nameCtrl,
            hint: 'Arena_Game $number',
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
