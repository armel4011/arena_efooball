import 'package:arena/core/services/anticheat/anticheat_config_service.dart';
import 'package:arena/core/services/anticheat/anticheat_provider.dart';
import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/features_shared/widgets/arena_app_bar.dart';
import 'package:arena/features_shared/widgets/arena_button.dart';
import 'package:arena/features_shared/widgets/arena_card.dart';
import 'package:arena/features_shared/widgets/arena_screen_background.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Écran super-admin : choisir le provider anti-triche ACTIF
/// (`app_config.anticheat_provider`).
///
/// Système DUAL en coexistence — le recorder natif (filet de sécurité) n'est
/// jamais supprimé. Le changement n'est PAS rétroactif : les matchs déjà
/// enregistrés gardent leur provider d'origine.
class SuperAdminAntiCheat extends ConsumerStatefulWidget {
  const SuperAdminAntiCheat({super.key});

  @override
  ConsumerState<SuperAdminAntiCheat> createState() =>
      _SuperAdminAntiCheatState();
}

class _SuperAdminAntiCheatState extends ConsumerState<SuperAdminAntiCheat> {
  AntiCheatProviderKind? _selected;
  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final kind = await ref.read(antiCheatConfigServiceProvider).fetch();
      _selected = kind;
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    final kind = _selected;
    if (kind == null) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref.read(antiCheatConfigServiceProvider).setActive(kind);
      // Rafraîchit les lecteurs du provider actif (cycle de vie du match).
      ref.invalidate(activeAntiCheatProviderProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Provider anti-triche enregistré.')),
        );
      }
    } catch (e) {
      if (mounted) setState(() => _error = 'Échec : $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const ArenaAppBar(title: 'ANTI-TRICHE'),
      body: ArenaScreenBackground(
        accent: ArenaColors.neonRed,
        child: SafeArea(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  padding: const EdgeInsets.all(ArenaSpacing.lg),
                  children: [
                    Text(
                      'Choisis le système qui enregistre le gameplay des '
                      'joueurs comme preuve. Les deux coexistent ; le recorder '
                      'natif reste le filet de sécurité. Le changement ne '
                      "s'applique qu'aux NOUVEAUX matchs.",
                      style: ArenaText.bodyMuted,
                    ),
                    const SizedBox(height: ArenaSpacing.lg),
                    _ProviderTile(
                      title: 'LiveKit Track Egress (recommandé)',
                      subtitle:
                          'Capture cloud publish-only + enregistrement serveur '
                          '(1 piste vidéo / joueur). Robuste, ne dépend pas du '
                          'téléphone après le démarrage.',
                      selected:
                          _selected == AntiCheatProviderKind.livekitTrackEgress,
                      onTap: () => setState(
                        () => _selected =
                            AntiCheatProviderKind.livekitTrackEgress,
                      ),
                    ),
                    const SizedBox(height: ArenaSpacing.md),
                    _ProviderTile(
                      title: 'Enregistrement natif (écran)',
                      subtitle:
                          'Recorder MediaProjection embarqué (overlay, pause, '
                          'forfait, export galerie). Filet de sécurité '
                          'historique, Android uniquement.',
                      selected:
                          _selected == AntiCheatProviderKind.nativeRecorder,
                      onTap: () => setState(
                        () => _selected = AntiCheatProviderKind.nativeRecorder,
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
                  ],
                ),
        ),
      ),
    );
  }
}

class _ProviderTile extends StatelessWidget {
  const _ProviderTile({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ArenaCard(
      onTap: onTap,
      borderColor: selected ? ArenaColors.iceCyan : null,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            selected
                ? Icons.radio_button_checked
                : Icons.radio_button_unchecked,
            color: selected ? ArenaColors.iceCyan : ArenaColors.silver,
          ),
          const SizedBox(width: ArenaSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: ArenaText.body.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: ArenaText.small.copyWith(color: ArenaColors.silver),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
