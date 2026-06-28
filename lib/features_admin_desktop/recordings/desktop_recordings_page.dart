import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/core/utils/arena_error_message.dart';
import 'package:arena/data/repositories/admin/admin_recordings_repository.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

/// Écran desktop admin « Enregistrements » : consultation des captures
/// anti-triche (natif + LiveKit) hors litige, avec filtre compétition/joueur.
/// Rétention 1 jour ⇒ petit jeu de données ; filtre client-side.
class DesktopRecordingsPage extends ConsumerStatefulWidget {
  const DesktopRecordingsPage({super.key});

  @override
  ConsumerState<DesktopRecordingsPage> createState() =>
      _DesktopRecordingsPageState();
}

class _DesktopRecordingsPageState extends ConsumerState<DesktopRecordingsPage> {
  String _query = '';
  bool _opening = false;

  Future<void> _open(AdminRecording rec) async {
    final path = rec.objectPath;
    if (path == null) {
      _info('Enregistrement indisponible (purgé).', InfoBarSeverity.warning);
      return;
    }
    setState(() => _opening = true);
    try {
      final url =
          await ref.read(adminRecordingsRepositoryProvider).signedUrl(path);
      final uri = Uri.tryParse(url);
      if (uri == null ||
          !await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        _info("Impossible d'ouvrir la vidéo.", InfoBarSeverity.error);
      }
    } catch (e) {
      _info(arenaErrorMessage(e), InfoBarSeverity.error);
    } finally {
      if (mounted) setState(() => _opening = false);
    }
  }

  void _info(String msg, InfoBarSeverity sev) {
    if (!mounted) return;
    displayInfoBar(
      context,
      builder: (_, close) => InfoBar(
        title: Text(msg),
        severity: sev,
        onClose: close,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final recordings = ref.watch(adminRecordingsProvider);

    return ScaffoldPage(
      header: PageHeader(
        title: const Text('Enregistrements anti-triche'),
        commandBar: CommandBar(
          mainAxisAlignment: MainAxisAlignment.end,
          primaryItems: [
            CommandBarButton(
              icon: const Icon(FluentIcons.refresh),
              label: const Text('Rafraîchir'),
              onPressed: () => ref.invalidate(adminRecordingsProvider),
            ),
          ],
        ),
      ),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
            child: TextBox(
              placeholder: 'Filtrer par compétition ou joueur…',
              prefix: const Padding(
                padding: EdgeInsets.only(left: 8),
                child: Icon(FluentIcons.search),
              ),
              onChanged: (v) =>
                  setState(() => _query = v.trim().toLowerCase()),
            ),
          ),
          if (_opening) const ProgressBar(),
          Expanded(
            child: recordings.when(
              loading: () => const Center(child: ProgressRing()),
              error: (e, _) => Padding(
                padding: const EdgeInsets.all(24),
                child: InfoBar(
                  title: const Text('Erreur'),
                  content: Text(arenaErrorMessage(e)),
                  severity: InfoBarSeverity.error,
                ),
              ),
              data: (all) {
                final list = _query.isEmpty
                    ? all
                    : all
                        .where((r) => r.searchHaystack.contains(_query))
                        .toList(growable: false);
                if (list.isEmpty) {
                  return Center(
                    child: Text(
                      all.isEmpty
                          ? 'Aucun enregistrement récent.'
                          : 'Aucun résultat pour « $_query ».',
                    ),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) =>
                      _RecordingCard(rec: list[i], onOpen: () => _open(list[i])),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _RecordingCard extends StatelessWidget {
  const _RecordingCard({required this.rec, required this.onOpen});

  final AdminRecording rec;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final started = rec.startedAt;
    final when = started == null
        ? '—'
        : DateFormat('d MMM HH:mm', 'fr').format(started);
    final players = [
      if (rec.playerUsername != null) rec.playerUsername!,
      if (rec.opponentUsername != null) rec.opponentUsername!,
    ].join(' vs ');

    return Card(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          const Icon(FluentIcons.play, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        rec.competitionName ?? 'Compétition ?',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _tag(rec.isLiveKit ? 'LiveKit' : 'Natif', ArenaColors.signalBlue),
                    if (rec.hasOpenDispute) ...[
                      const SizedBox(width: 6),
                      _tag('LITIGE', ArenaColors.warning),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(players.isEmpty ? 'Joueur ?' : players),
                Text(when, style: const TextStyle(fontSize: 12)),
              ],
            ),
          ),
          FilledButton(
            onPressed: onOpen,
            child: const Text('Ouvrir'),
          ),
        ],
      ),
    );
  }

  Widget _tag(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label, style: TextStyle(color: color, fontSize: 11)),
    );
  }
}
