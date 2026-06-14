part of 'super_admin_broadcast.dart';

/// Helpers de construction/lecture/application des filtres cible.
///
/// Extraits de l'état de l'écran via une extension (même bibliothèque
/// grâce au `part of`) pour alléger l'écran principal. Comportement
/// identique à `SuperAdminUsers`.
extension _BroadcastFilters on _SuperAdminBroadcastState {
  List<ArenaFilterSection> _buildSections(
    List<FilterableCompetition> comps,
  ) {
    return [
      const ArenaFilterSection(
        id: 'status',
        title: 'Statut',
        mode: ArenaFilterMode.radio,
        options: [
          ArenaFilterOption(id: 'active', label: 'Actifs'),
          ArenaFilterOption(id: 'banned', label: 'Bannis'),
          ArenaFilterOption(id: 'kyc_pending', label: 'KYC pending'),
        ],
      ),
      const ArenaFilterSection(
        id: 'country',
        title: 'Pays',
        mode: ArenaFilterMode.radio,
        options: [
          ArenaFilterOption(id: 'CM', label: '🇨🇲 Cameroun'),
          ArenaFilterOption(id: 'SN', label: '🇸🇳 Sénégal'),
          ArenaFilterOption(id: 'CI', label: "🇨🇮 Côte d'Ivoire"),
          ArenaFilterOption(id: 'BF', label: '🇧🇫 Burkina Faso'),
        ],
      ),
      const ArenaFilterSection(
        id: 'activity',
        title: 'Activité',
        options: [
          ArenaFilterOption(id: 'won', label: '🏆 A gagné'),
          ArenaFilterOption(id: 'paid', label: '💳 A payé'),
          ArenaFilterOption(id: 'rewarded', label: '💰 A reçu un gain'),
          ArenaFilterOption(id: 'disputed', label: '⚖ Litige'),
        ],
      ),
      const ArenaFilterSection(
        id: 'guilty',
        title: '3-strikes (verdicts coupables)',
        mode: ArenaFilterMode.radio,
        options: [
          ArenaFilterOption(id: '1', label: '🚨 ≥ 1'),
          ArenaFilterOption(id: '2', label: '🚨🚨 ≥ 2'),
          ArenaFilterOption(id: '3', label: '⛔ ≥ 3 (banni à vie)'),
        ],
      ),
      ArenaFilterSection(
        id: 'competition',
        title: 'Compétitions (multi-sélection)',
        options: [
          for (final c in comps)
            ArenaFilterOption(
              id: c.id,
              label: '${c.name} · ${c.currentPlayers}/${c.maxPlayers}',
            ),
        ],
      ),
    ];
  }

  Map<String, List<String>> _selectionFromFilter() {
    return {
      'status': [if (_filter.filter != null) _filter.filter!],
      'country': [if (_filter.countryCode != null) _filter.countryCode!],
      'activity': [
        if (_filter.wonCompetition) 'won',
        if (_filter.paidEntry) 'paid',
        if (_filter.receivedReward) 'rewarded',
        if (_filter.hadDispute) 'disputed',
      ],
      'guilty': [
        if (_filter.guiltyMinCount != null) '${_filter.guiltyMinCount}',
      ],
      'competition': _filter.competitionIds,
    };
  }

  /// Calcule le nouveau filtre à partir d'une sélection (méthode pure).
  /// L'application (`setState`) reste dans l'état principal.
  AdminUsersFilter _filterFromSelection(
    Map<String, List<String>> selection,
  ) {
    final status = selection['status']?.firstOrNull;
    final country = selection['country']?.firstOrNull;
    final activity = selection['activity'] ?? const <String>[];
    final guiltyStr = selection['guilty']?.firstOrNull;
    final competitions = selection['competition'] ?? const <String>[];

    return _filter.copyWith(
      filter: status,
      resetFilter: status == null,
      countryCode: country,
      resetCountryCode: country == null,
      wonCompetition: activity.contains('won'),
      paidEntry: activity.contains('paid'),
      receivedReward: activity.contains('rewarded'),
      hadDispute: activity.contains('disputed'),
      guiltyMinCount: guiltyStr == null ? null : int.parse(guiltyStr),
      resetGuiltyMin: guiltyStr == null,
      competitionIds: competitions,
      resetCompetitionIds: competitions.isEmpty,
    );
  }

  int _activeFilterCount() {
    var n = 0;
    if (_filter.filter != null) n++;
    if (_filter.countryCode != null) n++;
    if (_filter.wonCompetition) n++;
    if (_filter.paidEntry) n++;
    if (_filter.receivedReward) n++;
    if (_filter.hadDispute) n++;
    if (_filter.guiltyMinCount != null) n++;
    if (_filter.competitionIds.isNotEmpty) n++;
    return n;
  }
}
