import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/data/models/admin_audit_log.dart';
import 'package:arena/data/repositories/admin/admin_audit_log_repository.dart';
import 'package:arena/features_shared/widgets/arena_app_bar.dart';
import 'package:arena/features_shared/widgets/arena_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

/// PHASE 11 · A15 — admin audit log.
///
/// Searches `admin_audit_log` via [adminAuditLogProvider]. Category +
/// period chips translate to repository filters. Each row renders the
/// action type, target reference, and timestamp.
///
/// Maps to screen A15 of `arena_v2.html`.
class AdminAuditLogPage extends ConsumerStatefulWidget {
  const AdminAuditLogPage({super.key});

  @override
  ConsumerState<AdminAuditLogPage> createState() => _AdminAuditLogPageState();
}

class _AdminAuditLogPageState extends ConsumerState<AdminAuditLogPage> {
  final _searchCtrl = TextEditingController();
  String? _category;
  int? _periodDays = 7;
  String _searchQuery = '';

  static const _categories = <(String?, String)>[
    (null, 'Toutes'),
    ('payout', 'Payouts'),
    ('dispute', 'Disputes'),
    ('ban', 'Bans'),
    ('stream', 'Streams'),
  ];

  static const _periods = <(int?, String)>[
    (1, "Aujourd'hui"),
    (7, '7 jours'),
    (30, '30 jours'),
    (null, 'Tout'),
  ];

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final entries = ref.watch(
      adminAuditLogProvider(AdminAuditLogFilter(
        category: _category,
        periodDays: _periodDays,
        searchQuery: _searchQuery.isEmpty ? null : _searchQuery,
      )),
    );

    return Scaffold(
      appBar: const ArenaAppBar(title: "Journal d'audit"),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(ArenaSpacing.lg),
          children: [
            ArenaTextField(
              controller: _searchCtrl,
              hint: '🔍 Rechercher action, admin, ressource…',
              onChanged: (v) => setState(() => _searchQuery = v.trim()),
            ),
            const SizedBox(height: ArenaSpacing.md),
            _ChipsRow(
              labels: [for (final (_, l) in _categories) l],
              currentIndex: _categories.indexWhere((e) => e.$1 == _category),
              onTap: (i) => setState(() => _category = _categories[i].$1),
            ),
            const SizedBox(height: ArenaSpacing.xs),
            _ChipsRow(
              labels: [for (final (_, l) in _periods) l],
              currentIndex: _periods.indexWhere((e) => e.$1 == _periodDays),
              onTap: (i) => setState(() => _periodDays = _periods[i].$1),
            ),
            const SizedBox(height: ArenaSpacing.md),
            entries.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(ArenaSpacing.lg),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => Padding(
                padding: const EdgeInsets.all(ArenaSpacing.md),
                child: Text(
                  'Erreur de chargement : $e',
                  style: ArenaText.bodyMuted,
                ),
              ),
              data: (rows) => rows.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(ArenaSpacing.lg),
                      child: Text(
                        'Aucune entrée pour ce filtre.',
                        style: ArenaText.bodyMuted,
                        textAlign: TextAlign.center,
                      ),
                    )
                  : Column(
                      children: [
                        for (final r in rows) ...[
                          _LogCard(entry: r),
                          const SizedBox(height: ArenaSpacing.sm),
                        ],
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChipsRow extends StatelessWidget {
  const _ChipsRow({
    required this.labels,
    required this.currentIndex,
    required this.onTap,
  });

  final List<String> labels;
  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++)
            Padding(
              padding: const EdgeInsets.only(right: ArenaSpacing.xs),
              child: InkWell(
                onTap: () => onTap(i),
                borderRadius: BorderRadius.circular(ArenaRadius.round),
                child: AnimatedContainer(
                  duration: ArenaDurations.short,
                  padding: const EdgeInsets.symmetric(
                    horizontal: ArenaSpacing.md,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: i == currentIndex
                        ? ArenaColors.signalBlue.withValues(alpha: 0.15)
                        : ArenaColors.carbon,
                    borderRadius:
                        BorderRadius.circular(ArenaRadius.round),
                    border: Border.all(
                      color: i == currentIndex
                          ? ArenaColors.signalBlue
                          : ArenaColors.border,
                    ),
                  ),
                  child: Text(
                    labels[i],
                    style: ArenaText.body.copyWith(
                      color: i == currentIndex
                          ? ArenaColors.signalBlue
                          : ArenaColors.silver,
                      fontWeight: i == currentIndex
                          ? FontWeight.w600
                          : FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _LogCard extends StatelessWidget {
  const _LogCard({required this.entry});
  final AdminAuditLog entry;

  @override
  Widget build(BuildContext context) {
    final visual = _visualFor(entry.action);
    final justification =
        entry.afterState['justification'] ?? entry.beforeState['justification'];
    final quote = (justification is String && justification.isNotEmpty)
        ? '"$justification"'
        : null;

    return Container(
      padding: const EdgeInsets.all(ArenaSpacing.md),
      decoration: BoxDecoration(
        color: ArenaColors.carbon,
        border: Border(
          top: const BorderSide(color: ArenaColors.border),
          right: const BorderSide(color: ArenaColors.border),
          bottom: const BorderSide(color: ArenaColors.border),
          left: BorderSide(color: visual.color, width: 3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  visual.headerWith(entry.action),
                  style: ArenaText.body.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              Text(
                _formatTime(entry.createdAt),
                style: ArenaText.monoSmall,
              ),
            ],
          ),
          const SizedBox(height: ArenaSpacing.xs),
          RichText(
            text: TextSpan(
              style: ArenaText.bodyMuted,
              children: [
                TextSpan(
                  text: _shortId(entry.adminId),
                  style: ArenaText.body.copyWith(fontWeight: FontWeight.w600),
                ),
                TextSpan(text: ' · ${visual.actionVerb} '),
                if (entry.targetType != null && entry.targetId != null)
                  TextSpan(
                    text: '${entry.targetType}#${_shortId(entry.targetId!)}',
                    style: ArenaText.mono
                        .copyWith(color: ArenaColors.signalBlue),
                  ),
              ],
            ),
          ),
          if (quote != null) ...[
            const SizedBox(height: ArenaSpacing.sm),
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: ArenaColors.carbon2,
                borderRadius: BorderRadius.circular(ArenaRadius.sm),
              ),
              child: Text(
                quote,
                style: ArenaText.body.copyWith(fontStyle: FontStyle.italic),
              ),
            ),
          ],
          if (entry.ipAddress != null) ...[
            const SizedBox(height: ArenaSpacing.sm),
            Text(
              'IP ${entry.ipAddress}'
              '${entry.userAgent != null ? ' · ${entry.userAgent}' : ''}',
              style: ArenaText.small,
            ),
          ],
        ],
      ),
    );
  }

  static String _shortId(String id) =>
      id.length < 8 ? id : id.substring(0, 8);

  static String _formatTime(DateTime? at) {
    if (at == null) return '';
    final now = DateTime.now();
    if (now.year == at.year &&
        now.month == at.month &&
        now.day == at.day) {
      return DateFormat('HH:mm').format(at);
    }
    return DateFormat('dd/MM HH:mm').format(at);
  }
}

class _ActionVisual {
  const _ActionVisual({
    required this.emoji,
    required this.label,
    required this.color,
    required this.actionVerb,
  });

  final String emoji;
  final String label;
  final Color color;
  final String actionVerb;

  String headerWith(String action) {
    if (label.isNotEmpty) return '$emoji $label';
    return '$emoji ${action.replaceAll('_', ' ')}';
  }
}

_ActionVisual _visualFor(String action) {
  switch (action) {
    case 'payout_validated':
      return const _ActionVisual(
        emoji: '💰',
        label: 'Payout validé',
        color: ArenaColors.statusOk,
        actionVerb: 'a validé',
      );
    case 'payout_refused':
      return const _ActionVisual(
        emoji: '🚫',
        label: 'Payout refusé',
        color: ArenaColors.neonRed,
        actionVerb: 'a refusé',
      );
    case 'dispute_resolved':
      return const _ActionVisual(
        emoji: '⚖',
        label: 'Dispute tranchée',
        color: ArenaColors.statusWarn,
        actionVerb: 'a tranché',
      );
    case 'dispute_cancelled':
      return const _ActionVisual(
        emoji: '⚖',
        label: 'Dispute annulée',
        color: ArenaColors.statusWarn,
        actionVerb: 'a annulé',
      );
    case 'user_banned':
      return const _ActionVisual(
        emoji: '🚫',
        label: 'User banni',
        color: ArenaColors.neonRed,
        actionVerb: 'a banni',
      );
    case 'user_unbanned':
      return const _ActionVisual(
        emoji: '✅',
        label: 'User réactivé',
        color: ArenaColors.statusOk,
        actionVerb: 'a réactivé',
      );
    case 'stream_enabled':
    case 'stream_disabled':
    case 'stream_cut':
      return const _ActionVisual(
        emoji: '📺',
        label: 'Stream',
        color: ArenaColors.signalBlue,
        actionVerb: 'a modifié',
      );
    case 'match_verdict':
      return const _ActionVisual(
        emoji: '⚽',
        label: 'Verdict match',
        color: ArenaColors.signalBlue,
        actionVerb: 'a validé',
      );
    case 'bracket_generated':
      return const _ActionVisual(
        emoji: '🏆',
        label: 'Bracket généré',
        color: ArenaColors.signalBlue,
        actionVerb: 'a généré',
      );
    case 'competition_created':
      return const _ActionVisual(
        emoji: '➕',
        label: 'Compétition créée',
        color: ArenaColors.signalBlue,
        actionVerb: 'a créé',
      );
    case 'competition_cancelled':
      return const _ActionVisual(
        emoji: '🚫',
        label: 'Compétition annulée',
        color: ArenaColors.neonRed,
        actionVerb: 'a annulé',
      );
    default:
      return _ActionVisual(
        emoji: '•',
        label: '',
        color: ArenaColors.silver,
        actionVerb: 'a effectué',
      );
  }
}
