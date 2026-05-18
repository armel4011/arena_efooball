import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/data/repositories/admin/admin_audit_log_repository.dart';
import 'package:arena/data/repositories/admin/admin_users_repository.dart';
import 'package:arena/data/repositories/profile_repository.dart';
import 'package:arena/features_admin/auth_admin/widgets/totp_gate.dart';
import 'package:arena/features_shared/auth_common/shared_auth_providers.dart';
import 'package:arena/features_shared/widgets/arena_app_bar.dart';
import 'package:arena/features_shared/widgets/arena_button.dart';
import 'package:arena/features_shared/widgets/arena_filter_menu.dart';
import 'package:arena/features_shared/widgets/arena_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// PHASE 12.5 — Écran super-admin pour envoyer une notification ciblée.
///
/// Lot C : la sélection de cible passe par `ArenaFilterMenu` qui réunit
/// tous les critères (status, pays, activité, 3-strikes, compétition).
/// Le filtre par compétition permet de broadcaster aux inscrits d'une
/// compétition précise (item 3 du prompt utilisateur).
class SuperAdminBroadcast extends ConsumerStatefulWidget {
  const SuperAdminBroadcast({super.key});

  @override
  ConsumerState<SuperAdminBroadcast> createState() =>
      _SuperAdminBroadcastState();
}

class _SuperAdminBroadcastState extends ConsumerState<SuperAdminBroadcast> {
  final _searchCtrl = TextEditingController();
  final _titleCtrl = TextEditingController();
  final _bodyCtrl = TextEditingController();
  final _routeCtrl = TextEditingController();

  AdminUsersFilter _filter = const AdminUsersFilter();
  String _notifType = 'system';
  bool _sending = false;
  String? _lastResult;

  static const _typeOptions = <String>[
    'system',
    'match_starting',
    'competition_starting',
    'payout_received',
    'dispute_opened',
  ];

  @override
  void initState() {
    super.initState();
    _titleCtrl.addListener(_onChanged);
    _bodyCtrl.addListener(_onChanged);
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _titleCtrl
      ..removeListener(_onChanged)
      ..dispose();
    _bodyCtrl
      ..removeListener(_onChanged)
      ..dispose();
    _routeCtrl.dispose();
    super.dispose();
  }

  bool get _canSend =>
      _titleCtrl.text.trim().isNotEmpty &&
      _bodyCtrl.text.trim().isNotEmpty &&
      !_sending;

  Future<void> _send(List<String> userIds) async {
    if (userIds.isEmpty) return;
    final adminId = ref.read(currentSessionProvider)?.user.id;
    if (adminId == null) return;

    final totpOk = await TotpGate.confirm(
      context,
      ref,
      reason: 'Envoyer une notif à ${userIds.length} utilisateur(s)',
    );
    if (!totpOk) return;
    if (!mounted) return;

    setState(() {
      _sending = true;
      _lastResult = null;
    });

    final client = ref.read(supabaseClientProvider);
    final route = _routeCtrl.text.trim();
    final rows = [
      for (final uid in userIds)
        {
          'user_id': uid,
          'type': _notifType,
          'title': _titleCtrl.text.trim(),
          'body': _bodyCtrl.text.trim(),
          'data': route.isEmpty ? <String, dynamic>{} : {'route': route},
        },
    ];

    try {
      await client.from('notifications').insert(rows);
      await ref.read(adminAuditLogRepositoryProvider).record(
        adminId: adminId,
        action: 'broadcast_notification',
        targetType: 'notification',
        targetId: null,
        beforeState: {},
        afterState: {
          'recipients_count': userIds.length,
          'type': _notifType,
          'title': _titleCtrl.text.trim(),
          'has_route': route.isNotEmpty,
          'competition_id': _filter.competitionId,
        },
      );
      if (!mounted) return;
      setState(() {
        _sending = false;
        _lastResult = '✓ Envoyé à ${userIds.length} utilisateur(s)';
        _titleCtrl.clear();
        _bodyCtrl.clear();
        _routeCtrl.clear();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _sending = false;
        _lastResult = '✗ Erreur : $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(adminUsersProvider(_filter));
    final compsAsync = ref.watch(filterableCompetitionsProvider);

    return Scaffold(
      appBar: const ArenaAppBar(title: 'Notification broadcast'),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(ArenaSpacing.lg),
          children: [
            // ─── Filtres cible ──────────────────────────────────────
            Text('🎯 CIBLE', style: ArenaText.h3),
            const SizedBox(height: ArenaSpacing.sm),
            ArenaTextField(
              controller: _searchCtrl,
              hint: '🔍 Username ou email (laisser vide pour tous)',
              onChanged: (v) => setState(() {
                final q = v.trim();
                _filter = _filter.copyWith(
                  searchQuery: q.isEmpty ? null : q,
                  resetSearch: q.isEmpty,
                );
              }),
            ),
            const SizedBox(height: ArenaSpacing.sm),
            Row(
              children: [
                compsAsync.when(
                  data: (comps) => ArenaFilterMenu(
                    activeCount: _activeFilterCount(),
                    sections: _buildSections(comps),
                    initialSelection: _selectionFromFilter(),
                    onApply: _applySelection,
                  ),
                  loading: () => const _LoadingFilterButton(),
                  error: (_, __) => ArenaFilterMenu(
                    activeCount: _activeFilterCount(),
                    sections: _buildSections(const []),
                    initialSelection: _selectionFromFilter(),
                    onApply: _applySelection,
                  ),
                ),
                const Spacer(),
                if (_activeFilterCount() > 0)
                  TextButton(
                    onPressed: () => setState(() {
                      _filter = AdminUsersFilter(
                        searchQuery: _filter.searchQuery,
                      );
                    }),
                    child: Text(
                      'Réinitialiser',
                      style: ArenaText.small.copyWith(
                        color: ArenaColors.signalBlue,
                      ),
                    ),
                  ),
              ],
            ),
            if (_filter.competitionId != null) ...[
              const SizedBox(height: ArenaSpacing.sm),
              _ActiveCompetitionBadge(
                competitionId: _filter.competitionId!,
                comps: compsAsync.asData?.value ?? const [],
                onClear: () => setState(() {
                  _filter = _filter.copyWith(resetCompetitionId: true);
                }),
              ),
            ],
            const SizedBox(height: ArenaSpacing.md),

            // ─── Compteur destinataires + bouton envoi ──────────────
            usersAsync.when(
              loading: () => _RecipientCard(
                child: Row(
                  children: [
                    const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: ArenaSpacing.sm),
                    Text(
                      'Calcul du nombre de destinataires…',
                      style: ArenaText.bodyMuted,
                    ),
                  ],
                ),
              ),
              error: (e, _) => _RecipientCard(
                child: Text(
                  'Erreur de filtre : $e',
                  style: ArenaText.bodyMuted
                      .copyWith(color: ArenaColors.neonRed),
                ),
              ),
              data: (list) => _RecipientCard(
                child: Row(
                  children: [
                    Icon(
                      list.isEmpty ? Icons.warning_amber : Icons.group,
                      color: list.isEmpty
                          ? ArenaColors.statusWarn
                          : ArenaColors.signalBlue,
                    ),
                    const SizedBox(width: ArenaSpacing.sm),
                    Expanded(
                      child: Text(
                        list.isEmpty
                            ? 'Aucun destinataire — ajuste les filtres.'
                            : '${list.length} destinataire(s) ciblé(s)',
                        style: ArenaText.body,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: ArenaSpacing.lg),

            // ─── Composition du message ─────────────────────────────
            Text('📝 MESSAGE', style: ArenaText.h3),
            const SizedBox(height: ArenaSpacing.sm),
            ArenaTextField(
              controller: _titleCtrl,
              hint: 'Titre (visible dans la notification)',
              maxLength: 60,
            ),
            const SizedBox(height: ArenaSpacing.sm),
            ArenaTextField(
              controller: _bodyCtrl,
              hint: 'Corps du message',
              minLines: 3,
              maxLines: 6,
            ),
            const SizedBox(height: ArenaSpacing.sm),
            ArenaTextField(
              controller: _routeCtrl,
              hint: 'Route deep-link (optionnel) — ex. /competitions',
              helper:
                  "Si défini, taper la notif redirige l'utilisateur sur"
                  " cette page de l'app.",
            ),
            const SizedBox(height: ArenaSpacing.sm),
            Text('Type', style: ArenaText.inputLabel),
            const SizedBox(height: ArenaSpacing.xs),
            Wrap(
              spacing: ArenaSpacing.xs,
              runSpacing: ArenaSpacing.xs,
              children: [
                for (final t in _typeOptions)
                  _toggle(t, _notifType == t, () {
                    setState(() => _notifType = t);
                  }),
              ],
            ),
            const SizedBox(height: ArenaSpacing.lg),

            // ─── Action ─────────────────────────────────────────────
            ArenaButton(
              label: _sending
                  ? 'ENVOI EN COURS…'
                  : '🚀 ENVOYER MAINTENANT',
              fullWidth: true,
              size: ArenaButtonSize.large,
              isLoading: _sending,
              onPressed: !_canSend
                  ? null
                  : () {
                      usersAsync.whenData((list) {
                        _send([for (final u in list) u.id]);
                      });
                    },
            ),
            if (_lastResult != null) ...[
              const SizedBox(height: ArenaSpacing.sm),
              Text(
                _lastResult!,
                style: ArenaText.body.copyWith(
                  color: _lastResult!.startsWith('✓')
                      ? ArenaColors.statusOk
                      : ArenaColors.neonRed,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ─── Filter helpers (même que SuperAdminUsers) ─────────────────────

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
        title: 'Compétition (inscrits)',
        mode: ArenaFilterMode.radio,
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
      'competition': [
        if (_filter.competitionId != null) _filter.competitionId!,
      ],
    };
  }

  void _applySelection(Map<String, List<String>> selection) {
    setState(() {
      final status = selection['status']?.firstOrNull;
      final country = selection['country']?.firstOrNull;
      final activity = selection['activity'] ?? const <String>[];
      final guiltyStr = selection['guilty']?.firstOrNull;
      final competition = selection['competition']?.firstOrNull;

      _filter = _filter.copyWith(
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
        competitionId: competition,
        resetCompetitionId: competition == null,
      );
    });
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
    if (_filter.competitionId != null) n++;
    return n;
  }

  Widget _toggle(String label, bool active, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(ArenaRadius.round),
      child: AnimatedContainer(
        duration: ArenaDurations.short,
        padding: const EdgeInsets.symmetric(
          horizontal: ArenaSpacing.md,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color: active
              ? ArenaColors.signalBlue.withValues(alpha: 0.15)
              : ArenaColors.carbon,
          borderRadius: BorderRadius.circular(ArenaRadius.round),
          border: Border.all(
            color: active ? ArenaColors.signalBlue : ArenaColors.border,
          ),
        ),
        child: Text(
          label,
          style: ArenaText.body.copyWith(
            color: active ? ArenaColors.signalBlue : ArenaColors.silver,
            fontWeight: active ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _LoadingFilterButton extends StatelessWidget {
  const _LoadingFilterButton();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: ArenaSpacing.md,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: ArenaColors.carbon,
        borderRadius: BorderRadius.circular(ArenaRadius.round),
        border: Border.all(color: ArenaColors.border),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: ArenaColors.silver,
            ),
          ),
          SizedBox(width: 6),
          Text('Chargement…'),
        ],
      ),
    );
  }
}

class _ActiveCompetitionBadge extends StatelessWidget {
  const _ActiveCompetitionBadge({
    required this.competitionId,
    required this.comps,
    required this.onClear,
  });

  final String competitionId;
  final List<FilterableCompetition> comps;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final match = comps.where((c) => c.id == competitionId).firstOrNull;
    final label = match == null
        ? 'Compétition ciblée'
        : '🏆 ${match.name} · ${match.currentPlayers}/${match.maxPlayers}';
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: ArenaSpacing.md,
        vertical: ArenaSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: ArenaColors.signalBlue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(ArenaRadius.md),
        border: Border.all(color: ArenaColors.signalBlue),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: ArenaText.body.copyWith(
                color: ArenaColors.signalBlue,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          InkWell(
            onTap: onClear,
            child: const Icon(
              Icons.close_rounded,
              size: 18,
              color: ArenaColors.signalBlue,
            ),
          ),
        ],
      ),
    );
  }
}

class _RecipientCard extends StatelessWidget {
  const _RecipientCard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(ArenaSpacing.md),
      decoration: BoxDecoration(
        color: ArenaColors.carbon,
        border: Border.all(color: ArenaColors.border),
        borderRadius: BorderRadius.circular(ArenaRadius.md),
      ),
      child: child,
    );
  }
}
