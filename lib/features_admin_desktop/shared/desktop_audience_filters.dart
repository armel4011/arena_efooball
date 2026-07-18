import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/data/models/competition_enums.dart';
import 'package:arena/data/repositories/admin/admin_users_repository.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:google_fonts/google_fonts.dart';

/// Carte de filtres d'audience partagée (desktop) — réplique les 5 critères
/// de la RPC `admin_filter_users` : recherche, statut, pays, 3-strikes,
/// activité (gagné / payé / récompensé / litige) et multi-compétitions.
///
/// Mutualisée entre la page Diffusion (`DesktopBroadcastPage`) et la page
/// Utilisateurs (`DesktopUsersPage`) pour garantir la parité avec le mobile
/// (`ArenaFilterMenu`).
class DesktopAudienceFilters extends StatelessWidget {
  const DesktopAudienceFilters({
    required this.filter,
    required this.searchCtrl,
    required this.competitions,
    required this.onFilterChanged,
    super.key,
    this.searchPlaceholder = 'Username ou email (vide = tout le monde)',
  });

  final AdminUsersFilter filter;
  final TextEditingController searchCtrl;
  final List<FilterableCompetition> competitions;
  final ValueChanged<AdminUsersFilter> onFilterChanged;
  final String searchPlaceholder;

  static const _statusOptions = <(String?, String)>[
    (null, 'Tous'),
    ('active', 'Actifs'),
    ('banned', 'Bannis'),
    ('kyc_pending', 'KYC en attente'),
  ];

  static const _countryOptions = <(String?, String)>[
    (null, 'Tous'),
    ('CM', '🇨🇲 Cameroun'),
    ('SN', '🇸🇳 Sénégal'),
    ('CI', "🇨🇮 Côte d'Ivoire"),
    ('BF', '🇧🇫 Burkina Faso'),
  ];

  static const _guiltyOptions = <(int?, String)>[
    (null, 'Indifférent'),
    (1, '≥ 1 verdict'),
    (2, '≥ 2 verdicts'),
    (3, '≥ 3 (banni à vie)'),
  ];

  @override
  Widget build(BuildContext context) {
    return Card(
      backgroundColor: ArenaColors.carbon,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextBox(
            controller: searchCtrl,
            placeholder: searchPlaceholder,
            prefix: const Padding(
              padding: EdgeInsets.only(left: 8),
              child: Icon(FluentIcons.people, size: 14),
            ),
            onChanged: (v) {
              final q = v.trim();
              onFilterChanged(
                filter.copyWith(
                  searchQuery: q.isEmpty ? null : q,
                  resetSearch: q.isEmpty,
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 16,
            runSpacing: 12,
            children: [
              InfoLabel(
                label: 'Statut',
                child: ComboBox<String?>(
                  value: filter.filter,
                  placeholder: const Text('Tous'),
                  items: [
                    for (final (id, label) in _statusOptions)
                      ComboBoxItem(value: id, child: Text(label)),
                  ],
                  onChanged: (v) => onFilterChanged(
                    filter.copyWith(filter: v, resetFilter: v == null),
                  ),
                ),
              ),
              InfoLabel(
                label: 'Pays',
                child: ComboBox<String?>(
                  value: filter.countryCode,
                  placeholder: const Text('Tous'),
                  items: [
                    for (final (id, label) in _countryOptions)
                      ComboBoxItem(value: id, child: Text(label)),
                  ],
                  onChanged: (v) => onFilterChanged(
                    filter.copyWith(
                      countryCode: v,
                      resetCountryCode: v == null,
                    ),
                  ),
                ),
              ),
              InfoLabel(
                label: '3-strikes',
                child: ComboBox<int?>(
                  value: filter.guiltyMinCount,
                  placeholder: const Text('Indifférent'),
                  items: [
                    for (final (id, label) in _guiltyOptions)
                      ComboBoxItem(value: id, child: Text(label)),
                  ],
                  onChanged: (v) => onFilterChanged(
                    filter.copyWith(
                      guiltyMinCount: v,
                      resetGuiltyMin: v == null,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Activité',
            style: GoogleFonts.spaceGrotesk(
              color: ArenaColors.silver,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              Checkbox(
                checked: filter.wonCompetition,
                content: const Text('A gagné'),
                onChanged: (v) => onFilterChanged(
                  filter.copyWith(wonCompetition: v ?? false),
                ),
              ),
              Checkbox(
                checked: filter.paidEntry,
                content: const Text('A payé'),
                onChanged: (v) =>
                    onFilterChanged(filter.copyWith(paidEntry: v ?? false)),
              ),
              Checkbox(
                checked: filter.receivedReward,
                content: const Text('A reçu un gain'),
                onChanged: (v) => onFilterChanged(
                  filter.copyWith(receivedReward: v ?? false),
                ),
              ),
              Checkbox(
                checked: filter.hadDispute,
                content: const Text('A eu un litige'),
                onChanged: (v) =>
                    onFilterChanged(filter.copyWith(hadDispute: v ?? false)),
              ),
            ],
          ),
          if (competitions.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'Compétitions (multi-sélection)',
              style: GoogleFonts.spaceGrotesk(
                color: ArenaColors.silver,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final c in competitions)
                  ToggleButton(
                    checked: filter.competitionIds.contains(c.id),
                    onChanged: (checked) {
                      final ids = [...filter.competitionIds];
                      if (checked) {
                        ids.add(c.id);
                      } else {
                        ids.remove(c.id);
                      }
                      onFilterChanged(
                        filter.copyWith(
                          competitionIds: ids,
                          resetCompetitionIds: ids.isEmpty,
                        ),
                      );
                    },
                    child: Text(
                      '${c.name} · ${c.currentPlayers}/${c.maxPlayers}',
                    ),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          Text(
            "Jeux d'intérêt (sondage · multi-sélection)",
            style: GoogleFonts.spaceGrotesk(
              color: ArenaColors.silver,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final g in GameType.values)
                ToggleButton(
                  checked: filter.games.contains(g),
                  onChanged: (checked) {
                    final games = [...filter.games];
                    if (checked) {
                      games.add(g);
                    } else {
                      games.remove(g);
                    }
                    onFilterChanged(
                      filter.copyWith(
                        games: games,
                        resetGames: games.isEmpty,
                      ),
                    );
                  },
                  child: Text(g.label),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
