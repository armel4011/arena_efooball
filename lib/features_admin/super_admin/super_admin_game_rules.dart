import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/data/models/competition_enums.dart';
import 'package:arena/data/repositories/admin/admin_audit_log_repository.dart';
import 'package:arena/data/repositories/game_rules_repository.dart';
import 'package:arena/features_admin/auth_admin/widgets/totp_gate.dart';
import 'package:arena/features_shared/auth_common/shared_auth_providers.dart';
import 'package:arena/features_shared/widgets/arena_app_bar.dart';
import 'package:arena/features_shared/widgets/arena_button.dart';
import 'package:arena/features_shared/widgets/arena_screen_background.dart';
import 'package:arena/features_shared/widgets/arena_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// SA · Règles par jeu — éditeur du texte des règles affiché sur l'écran de
/// verrouillage de la salle de match, une carte par jeu (eFootball, EA SPORTS
/// FC, Dames). Les règles ne changent pas d'un tournoi à l'autre, d'où un
/// stockage unique par jeu. Chaque enregistrement exige un step-up TOTP + un
/// audit log, comme les autres mutations super-admin.
class SuperAdminGameRules extends ConsumerWidget {
  const SuperAdminGameRules({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rulesAsync = ref.watch(allGameRulesProvider);

    return Scaffold(
      appBar: const ArenaAppBar(title: '📋 RÈGLES PAR JEU'),
      body: ArenaScreenBackground(
        accent: ArenaColors.neonRed,
        child: SafeArea(
          child: rulesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(ArenaSpacing.lg),
                child: Text(
                  'Erreur : $e',
                  style:
                      ArenaText.bodyMuted.copyWith(color: ArenaColors.neonRed),
                ),
              ),
            ),
            data: (rules) {
              final byGame = {for (final r in rules) r.game: r.rulesText};
              return ListView(
                padding: const EdgeInsets.all(ArenaSpacing.lg),
                children: [
                  Text(
                    "Ces règles s'affichent au joueur sur l'écran de "
                    "verrouillage de la salle, avant le coup d'envoi.",
                    style: ArenaText.bodyMuted,
                  ),
                  const SizedBox(height: ArenaSpacing.lg),
                  for (final game in GameType.values) ...[
                    _GameRulesCard(
                      // Clé sur le texte initial : si les données arrivent après
                      // le 1er build (ou changent après save), le champ est
                      // ré-initialisé proprement.
                      key: ValueKey('${game.value}:${byGame[game] ?? ''}'),
                      game: game,
                      initialText: byGame[game] ?? '',
                    ),
                    const SizedBox(height: ArenaSpacing.md),
                  ],
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Carte éditeur pour un jeu : champ multi-lignes + bouton d'enregistrement.
class _GameRulesCard extends ConsumerStatefulWidget {
  const _GameRulesCard({
    required this.game,
    required this.initialText,
    super.key,
  });

  final GameType game;
  final String initialText;

  @override
  ConsumerState<_GameRulesCard> createState() => _GameRulesCardState();
}

class _GameRulesCardState extends ConsumerState<_GameRulesCard> {
  late final TextEditingController _ctrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.initialText);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  String get _text => _ctrl.text.trim();

  bool get _dirty => _text != widget.initialText.trim();
  bool get _canSave => !_saving && _text.isNotEmpty && _dirty;

  Future<void> _save() async {
    if (!_canSave) return;
    final adminId = ref.read(currentSessionProvider)?.user.id;
    if (adminId == null) return;
    final messenger = ScaffoldMessenger.of(context);
    final totpOk = await TotpGate.confirm(
      context,
      ref,
      reason: 'Enregistrer les règles de ${widget.game.label}',
    );
    if (!totpOk || !mounted) return;

    setState(() => _saving = true);
    try {
      await ref.read(gameRulesRepositoryProvider).upsert(
            game: widget.game,
            rulesText: _text,
            updatedBy: adminId,
          );
      await ref.read(adminAuditLogRepositoryProvider).record(
        adminId: adminId,
        action: 'game_rules_updated',
        targetType: 'game_rules',
        targetId: widget.game.value,
        beforeState: {'rules_text': widget.initialText},
        afterState: {'rules_text': _text},
      );
      ref.invalidate(allGameRulesProvider);
      messenger.showSnackBar(
        SnackBar(
          content: Text('✓ Règles ${widget.game.label} enregistrées.'),
          backgroundColor: ArenaColors.statusOk,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      messenger.showSnackBar(
        SnackBar(
          content: Text('✗ Erreur : $e'),
          backgroundColor: ArenaColors.neonRed,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(ArenaSpacing.md),
      decoration: BoxDecoration(
        color: ArenaColors.carbon,
        borderRadius: BorderRadius.circular(ArenaRadius.md),
        border: Border.all(color: ArenaColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '🎮 ${widget.game.label}',
            style: ArenaText.body.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: ArenaSpacing.sm),
          ArenaTextField(
            controller: _ctrl,
            hint: 'Règles, format, barème de points, comportements interdits…',
            minLines: 4,
            maxLines: 12,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: ArenaSpacing.sm),
          ArenaButton(
            label: _saving ? 'ENREGISTREMENT…' : '💾 ENREGISTRER',
            fullWidth: true,
            isLoading: _saving,
            onPressed: _canSave ? _save : null,
          ),
        ],
      ),
    );
  }
}
