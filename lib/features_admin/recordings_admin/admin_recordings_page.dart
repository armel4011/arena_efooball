import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/core/utils/arena_error_message.dart';
import 'package:arena/data/repositories/admin/admin_recordings_repository.dart';
import 'package:arena/features_shared/widgets/arena_app_bar.dart';
import 'package:arena/features_shared/widgets/arena_badge.dart';
import 'package:arena/features_shared/widgets/arena_screen_background.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

/// Écran admin « Enregistrements » : consultation directe des captures
/// anti-triche (recorder natif + LiveKit), indépendamment d'un litige.
///
/// La rétention est de 1 jour (sauf litige ouvert) — le jeu de données reste
/// donc petit ; on liste tout et on filtre côté client par compétition/joueur.
/// Un tap signe l'URL (1h) et ouvre la vidéo dans le lecteur externe.
class AdminRecordingsPage extends ConsumerStatefulWidget {
  const AdminRecordingsPage({super.key});

  @override
  ConsumerState<AdminRecordingsPage> createState() =>
      _AdminRecordingsPageState();
}

class _AdminRecordingsPageState extends ConsumerState<AdminRecordingsPage> {
  String _query = '';
  bool _opening = false;

  Future<void> _open(AdminRecording rec) async {
    final path = rec.objectPath;
    final messenger = ScaffoldMessenger.of(context);
    if (path == null) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Enregistrement indisponible (purgé).')),
      );
      return;
    }
    setState(() => _opening = true);
    try {
      final url =
          await ref.read(adminRecordingsRepositoryProvider).signedUrl(path);
      final uri = Uri.tryParse(url);
      var ok = false;
      if (uri != null) {
        ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
      if (!ok && mounted) {
        messenger.showSnackBar(
          const SnackBar(content: Text("Impossible d'ouvrir la vidéo.")),
        );
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text(arenaErrorMessage(e))),
        );
      }
    } finally {
      if (mounted) setState(() => _opening = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final recordings = ref.watch(adminRecordingsProvider);

    return Scaffold(
      appBar: const ArenaAppBar(title: 'ENREGISTREMENTS'),
      body: ArenaScreenBackground(
        accent: ArenaColors.neonRed,
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  ArenaSpacing.lg,
                  ArenaSpacing.lg,
                  ArenaSpacing.lg,
                  ArenaSpacing.sm,
                ),
                child: TextField(
                  style: ArenaText.body.copyWith(color: ArenaColors.bone),
                  onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
                  decoration: InputDecoration(
                    hintText: 'Filtrer par compétition, pays ou joueur…',
                    hintStyle:
                        ArenaText.body.copyWith(color: ArenaColors.silver),
                    prefixIcon:
                        const Icon(Icons.search, color: ArenaColors.silver),
                    filled: true,
                    fillColor: ArenaColors.carbon,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(ArenaRadius.md),
                      borderSide: const BorderSide(color: ArenaColors.borderHi),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(ArenaRadius.md),
                      borderSide: const BorderSide(color: ArenaColors.borderHi),
                    ),
                  ),
                ),
              ),
              if (_opening) const LinearProgressIndicator(minHeight: 2),
              Expanded(
                child: recordings.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(
                    child: Padding(
                      padding: const EdgeInsets.all(ArenaSpacing.lg),
                      child: Text(
                        arenaErrorMessage(e),
                        textAlign: TextAlign.center,
                        style: ArenaText.body
                            .copyWith(color: ArenaColors.silver),
                      ),
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
                          style: ArenaText.body
                              .copyWith(color: ArenaColors.silver),
                        ),
                      );
                    }
                    return RefreshIndicator(
                      onRefresh: () async =>
                          ref.invalidate(adminRecordingsProvider),
                      child: ListView.separated(
                        padding: const EdgeInsets.all(ArenaSpacing.lg),
                        itemCount: list.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: ArenaSpacing.sm),
                        itemBuilder: (context, i) => _RecordingTile(
                          rec: list[i],
                          onTap: () => _open(list[i]),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecordingTile extends StatelessWidget {
  const _RecordingTile({required this.rec, required this.onTap});

  final AdminRecording rec;
  final VoidCallback onTap;

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

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(ArenaRadius.md),
      child: Container(
        padding: const EdgeInsets.all(ArenaSpacing.md),
        decoration: BoxDecoration(
          color: ArenaColors.carbon,
          borderRadius: BorderRadius.circular(ArenaRadius.md),
          border: Border.all(color: ArenaColors.borderHi),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.play_circle_outline,
              color: ArenaColors.neonRed,
              size: 32,
            ),
            const SizedBox(width: ArenaSpacing.md),
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
                          style: ArenaText.body.copyWith(
                            color: ArenaColors.bone,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: ArenaSpacing.sm),
                      ArenaBadge(
                        label: rec.isLiveKit ? 'LiveKit' : 'Natif',
                        variant: ArenaBadgeVariant.neutral,
                      ),
                      if (rec.countryCode != null &&
                          rec.countryCode!.isNotEmpty) ...[
                        const SizedBox(width: ArenaSpacing.xs),
                        ArenaBadge(
                          label: rec.countryCode!,
                          variant: ArenaBadgeVariant.neutral,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: ArenaSpacing.xs),
                  Text(
                    players.isEmpty ? 'Joueur ?' : players,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: ArenaText.bodyMuted.copyWith(color: ArenaColors.silver),
                  ),
                  const SizedBox(height: ArenaSpacing.xs),
                  Row(
                    children: [
                      Text(
                        when,
                        style: ArenaText.small
                            .copyWith(color: ArenaColors.silver),
                      ),
                      if (rec.hasOpenDispute) ...[
                        const SizedBox(width: ArenaSpacing.sm),
                        const ArenaBadge(
                          label: 'LITIGE',
                          variant: ArenaBadgeVariant.warn,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: ArenaColors.silver),
          ],
        ),
      ),
    );
  }
}
