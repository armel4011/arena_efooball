import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/core/utils/arena_error_message.dart';
import 'package:arena/data/models/competition_enums.dart';
import 'package:arena/data/repositories/admin/admin_audit_log_repository.dart';
import 'package:arena/data/repositories/game_rules_repository.dart';
import 'package:arena/features_admin_desktop/shared/desktop_totp_gate.dart';
import 'package:arena/features_shared/auth_common/shared_auth_providers.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

/// Super-admin · Règles par jeu (desktop) — équivalent Fluent UI de l'écran
/// mobile SuperAdminGameRules. Une carte par jeu, texte multi-lignes, enregistrement
/// step-up TOTP + audit. Réutilise [gameRulesRepositoryProvider] et
/// [allGameRulesProvider] (mêmes providers que le mobile).
class DesktopGameRulesPage extends ConsumerWidget {
  const DesktopGameRulesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rulesAsync = ref.watch(allGameRulesProvider);

    return ScaffoldPage(
      header: const PageHeader(title: Text('RÈGLES PAR JEU')),
      content: rulesAsync.when(
        loading: () => const Center(child: ProgressRing()),
        error: (e, _) => Padding(
          padding: const EdgeInsets.all(24),
          child: InfoBar(
            title: const Text('Erreur de chargement'),
            content: Text('$e'),
            severity: InfoBarSeverity.error,
          ),
        ),
        data: (rules) {
          final byGame = {for (final r in rules) r.game: r.rulesText};
          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            children: [
              Text(
                "Ces règles s'affichent au joueur sur l'écran de verrouillage "
                "de la salle, avant le coup d'envoi.",
                style: GoogleFonts.spaceGrotesk(
                  color: ArenaColors.silver,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 16),
              for (final game in GameType.values) ...[
                _GameRulesCard(
                  key: ValueKey('${game.value}:${byGame[game] ?? ''}'),
                  game: game,
                  initialText: byGame[game] ?? '',
                ),
                const SizedBox(height: 12),
              ],
            ],
          );
        },
      ),
    );
  }
}

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
    final totpOk = await showDesktopTotpGate(
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
      if (!mounted) return;
      await _showResult(
        context,
        'Règles ${widget.game.label} enregistrées.',
        isError: false,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      await _showResult(context, arenaErrorMessage(e), isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      backgroundColor: ArenaColors.carbon,
      borderColor: ArenaColors.border,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.game.label,
            style: GoogleFonts.spaceGrotesk(
              color: ArenaColors.bone,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          TextBox(
            controller: _ctrl,
            minLines: 4,
            maxLines: 12,
            enabled: !_saving,
            placeholder:
                'Règles, format, barème de points, comportements interdits…',
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton(
              onPressed: _canSave ? _save : null,
              child: _saving
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: ProgressRing(strokeWidth: 2.5),
                    )
                  : const Text('Enregistrer'),
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> _showResult(
  BuildContext context,
  String message, {
  required bool isError,
}) async {
  await displayInfoBar(
    context,
    builder: (ctx, close) => InfoBar(
      title: Text(isError ? 'Échec' : 'Succès'),
      content: Text(message),
      severity: isError ? InfoBarSeverity.error : InfoBarSeverity.success,
      onClose: close,
    ),
  );
}
