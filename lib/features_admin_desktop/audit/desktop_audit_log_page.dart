import 'package:arena/core/theme/arena_fluent_theme.dart';
import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/data/models/admin_audit_log.dart';
import 'package:arena/data/repositories/admin/admin_audit_log_repository.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

/// Journal d'audit admin — version desktop (Fluent UI).
///
/// Réutilise [adminAuditLogProvider] : la recherche, le filtre par
/// catégorie et par période se traduisent en [AdminAuditLogFilter]. Les
/// entrées s'affichent dans un tableau (action, admin, cible, horodatage).
class DesktopAuditLogPage extends ConsumerStatefulWidget {
  const DesktopAuditLogPage({super.key});

  @override
  ConsumerState<DesktopAuditLogPage> createState() =>
      _DesktopAuditLogPageState();
}

class _DesktopAuditLogPageState extends ConsumerState<DesktopAuditLogPage> {
  final _searchCtrl = TextEditingController();
  String? _category;
  int? _periodDays = 7;
  String _searchQuery = '';

  static const _categories = <(String?, String)>[
    (null, 'Toutes'),
    ('payout', 'Paiements'),
    ('dispute', 'Litiges'),
    ('ban', 'Bannissements'),
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
    final filter = AdminAuditLogFilter(
      category: _category,
      periodDays: _periodDays,
      searchQuery: _searchQuery.isEmpty ? null : _searchQuery,
    );
    final entriesAsync = ref.watch(adminAuditLogProvider(filter));

    return ScaffoldPage(
      header: PageHeader(
        title: const Text("JOURNAL D'AUDIT"),
        commandBar: CommandBar(
          mainAxisAlignment: MainAxisAlignment.end,
          primaryItems: [
            CommandBarButton(
              icon: const Icon(FluentIcons.refresh),
              label: const Text('Actualiser'),
              onPressed: () => ref.invalidate(adminAuditLogProvider),
            ),
          ],
        ),
      ),
      content: ListView(
        padding: const EdgeInsets.symmetric(
          horizontal: ArenaDesktop.pagePadding,
        ),
        children: [
          // ─── Filtres ────────────────────────────────────────────────
          TextBox(
            controller: _searchCtrl,
            placeholder: 'Rechercher une action, un admin, une ressource…',
            prefix: const Padding(
              padding: EdgeInsets.only(left: 8),
              child: Icon(FluentIcons.filter, size: 14),
            ),
            onChanged: (value) =>
                setState(() => _searchQuery = value.trim()),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _FilterChips(
                labels: [for (final (_, l) in _categories) l],
                currentIndex:
                    _categories.indexWhere((e) => e.$1 == _category),
                onTap: (i) => setState(() => _category = _categories[i].$1),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _FilterChips(
            labels: [for (final (_, l) in _periods) l],
            currentIndex: _periods.indexWhere((e) => e.$1 == _periodDays),
            onTap: (i) => setState(() => _periodDays = _periods[i].$1),
          ),
          const SizedBox(height: 20),

          // ─── Table ──────────────────────────────────────────────────
          entriesAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(48),
              child: Center(child: ProgressRing()),
            ),
            error: (e, _) => InfoBar(
              title: const Text('Impossible de charger le journal'),
              content: Text('$e'),
              severity: InfoBarSeverity.error,
            ),
            data: (rows) {
              if (rows.isEmpty) {
                return const Card(
                  backgroundColor: ArenaColors.carbon,
                  padding: EdgeInsets.all(40),
                  child: Center(
                    child: Text('Aucune entrée pour ces filtres.'),
                  ),
                );
              }
              return Card(
                backgroundColor: ArenaColors.carbon,
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    const _AuditHeaderRow(),
                    for (final entry in rows) _AuditDataRow(entry: entry),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _FilterChips extends StatelessWidget {
  const _FilterChips({
    required this.labels,
    required this.currentIndex,
    required this.onTap,
  });

  final List<String> labels;
  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (var i = 0; i < labels.length; i++)
          _Chip(
            label: labels[i],
            selected: i == currentIndex,
            onPressed: () => onTap(i),
          ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.onPressed,
  });

  final String label;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return ToggleButton(
      checked: selected,
      onChanged: (_) => onPressed(),
      child: Text(label),
    );
  }
}

class _AuditHeaderRow extends StatelessWidget {
  const _AuditHeaderRow();

  @override
  Widget build(BuildContext context) {
    TextStyle style() => GoogleFonts.spaceGrotesk(
          color: ArenaColors.silver,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        );
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: ArenaColors.carbon2,
        border: Border(bottom: BorderSide(color: ArenaColors.border)),
      ),
      child: Row(
        children: [
          Expanded(flex: 4, child: Text('ACTION', style: style())),
          Expanded(flex: 3, child: Text('ADMIN', style: style())),
          Expanded(flex: 4, child: Text('CIBLE', style: style())),
          Expanded(
            flex: 2,
            child: Text(
              'HORODATAGE',
              style: style(),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}

class _AuditDataRow extends StatelessWidget {
  const _AuditDataRow({required this.entry});

  final AdminAuditLog entry;

  @override
  Widget build(BuildContext context) {
    final visual = _visualFor(entry.action);
    final cible = (entry.targetType != null && entry.targetId != null)
        ? '${entry.targetType}#${_shortId(entry.targetId!)}'
        : '—';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: const Border(bottom: BorderSide(color: ArenaColors.border)),
        // Liseré coloré à gauche selon la gravité de l'action.
        gradient: LinearGradient(
          colors: [
            visual.color.withValues(alpha: 0.08),
            ArenaColors.carbon.withValues(alpha: 0),
          ],
          stops: const [0, 0.04],
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: Row(
              children: [
                Icon(visual.icon, size: 14, color: visual.color),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    visual.labelWith(entry.action),
                    style: GoogleFonts.spaceGrotesk(
                      color: ArenaColors.bone,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              _shortId(entry.adminId),
              style: GoogleFonts.jetBrainsMono(
                color: ArenaColors.silver,
                fontSize: 12,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 4,
            child: Text(
              cible,
              style: GoogleFonts.jetBrainsMono(
                color: cible == '—'
                    ? ArenaColors.silverDim
                    : ArenaColors.signalBlue,
                fontSize: 12,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              _formatTime(entry.createdAt),
              textAlign: TextAlign.right,
              style: GoogleFonts.spaceGrotesk(
                color: ArenaColors.silver,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _shortId(String id) =>
      id.length < 8 ? id : id.substring(0, 8);

  static String _formatTime(DateTime? at) {
    if (at == null) return '—';
    final local = at.toLocal();
    final now = DateTime.now();
    if (now.year == local.year &&
        now.month == local.month &&
        now.day == local.day) {
      return DateFormat('HH:mm').format(local);
    }
    return DateFormat('dd/MM HH:mm').format(local);
  }
}

class _ActionVisual {
  const _ActionVisual({
    required this.label,
    required this.icon,
    required this.color,
  });

  final String label;
  final IconData icon;
  final Color color;

  String labelWith(String action) =>
      label.isNotEmpty ? label : action.replaceAll('_', ' ');
}

_ActionVisual _visualFor(String action) {
  switch (action) {
    case 'payout_validated':
      return const _ActionVisual(
        label: 'Paiement validé',
        icon: FluentIcons.completed_solid,
        color: ArenaColors.statusOk,
      );
    case 'payout_refused':
      return const _ActionVisual(
        label: 'Paiement refusé',
        icon: FluentIcons.error_badge,
        color: ArenaColors.neonRed,
      );
    case 'dispute_resolved':
      return const _ActionVisual(
        label: 'Litige tranché',
        icon: FluentIcons.warning,
        color: ArenaColors.statusWarn,
      );
    case 'dispute_cancelled':
      return const _ActionVisual(
        label: 'Litige annulé',
        icon: FluentIcons.warning,
        color: ArenaColors.statusWarn,
      );
    case 'user_banned':
      return const _ActionVisual(
        label: 'Utilisateur banni',
        icon: FluentIcons.blocked2,
        color: ArenaColors.neonRed,
      );
    case 'user_unbanned':
      return const _ActionVisual(
        label: 'Utilisateur réactivé',
        icon: FluentIcons.completed_solid,
        color: ArenaColors.statusOk,
      );
    case 'stream_enabled':
    case 'stream_disabled':
    case 'stream_cut':
      return const _ActionVisual(
        label: 'Stream',
        icon: FluentIcons.video,
        color: ArenaColors.signalBlue,
      );
    case 'match_verdict':
      return const _ActionVisual(
        label: 'Verdict match',
        icon: FluentIcons.game,
        color: ArenaColors.signalBlue,
      );
    case 'bracket_generated':
      return const _ActionVisual(
        label: 'Bracket généré',
        icon: FluentIcons.trophy2,
        color: ArenaColors.signalBlue,
      );
    case 'competition_created':
      return const _ActionVisual(
        label: 'Compétition créée',
        icon: FluentIcons.add,
        color: ArenaColors.signalBlue,
      );
    case 'competition_cancelled':
      return const _ActionVisual(
        label: 'Compétition annulée',
        icon: FluentIcons.error_badge,
        color: ArenaColors.neonRed,
      );
    case 'broadcast_notification':
    case 'broadcast_chat_message':
      return const _ActionVisual(
        label: 'Diffusion',
        icon: FluentIcons.megaphone,
        color: ArenaColors.signalBlue,
      );
    default:
      return const _ActionVisual(
        label: '',
        icon: FluentIcons.history,
        color: ArenaColors.silver,
      );
  }
}
