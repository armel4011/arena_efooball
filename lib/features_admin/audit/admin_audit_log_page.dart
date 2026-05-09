import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/features_shared/widgets/arena_app_bar.dart';
import 'package:arena/features_shared/widgets/arena_text_field.dart';
import 'package:flutter/material.dart';

/// PHASE 11 · A15 — admin audit log.
///
/// Search bar + 2 filter rows (action category + period) over a list of
/// log cards. Each card carries the action type, perpetrator, target
/// resource, an optional quoted justification and the admin IP/device
/// metadata. Source: `admin_audit_log` (PHASE 11.5).
///
/// Maps to screen A15 of `arena_v2.html`.
class AdminAuditLogPage extends StatefulWidget {
  const AdminAuditLogPage({super.key});

  @override
  State<AdminAuditLogPage> createState() => _AdminAuditLogPageState();
}

class _AdminAuditLogPageState extends State<AdminAuditLogPage> {
  final _searchCtrl = TextEditingController();
  String _category = 'Toutes';
  String _period = '7 jours';

  static const _categories = [
    'Toutes',
    'Payouts',
    'Disputes',
    'Bans',
    'Streams',
  ];
  static const _periods = ["Aujourd'hui", '7 jours', '30 jours', 'Tout'];

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ArenaAppBar(
        title: "Journal d'audit",
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: ArenaColors.silver),
            onPressed: () {},
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(ArenaSpacing.lg),
          children: [
            ArenaTextField(
              controller: _searchCtrl,
              hint: '🔍 Rechercher action, admin, ressource…',
            ),
            const SizedBox(height: ArenaSpacing.md),
            _ChipsRow(
              labels: _categories,
              current: _category,
              onTap: (l) => setState(() => _category = l),
            ),
            const SizedBox(height: ArenaSpacing.xs),
            _ChipsRow(
              labels: _periods,
              current: _period,
              onTap: (l) => setState(() => _period = l),
            ),
            const SizedBox(height: ArenaSpacing.md),
            _LogCard(
              accent: ArenaColors.statusOk,
              header: '💰 Payout validé',
              time: '14:23',
              detail: RichText(
                text: TextSpan(
                  style: ArenaText.bodyMuted,
                  children: [
                    TextSpan(
                      text: 'Modérateur1',
                      style: ArenaText.body
                          .copyWith(fontWeight: FontWeight.w600),
                    ),
                    const TextSpan(text: ' a validé le payout '),
                    TextSpan(
                      text: 'PO-2284',
                      style: ArenaText.mono
                          .copyWith(color: ArenaColors.signalBlue),
                    ),
                    const TextSpan(text: ' de 25 000 XAF pour '),
                    TextSpan(
                      text: 'KevinM_237',
                      style: ArenaText.body,
                    ),
                  ],
                ),
              ),
              footer: 'IP 41.205.•.• · device Android',
            ),
            const SizedBox(height: ArenaSpacing.sm),
            _LogCard(
              accent: ArenaColors.statusWarn,
              header: '⚖ Dispute tranchée',
              time: '14:15',
              detail: RichText(
                text: TextSpan(
                  style: ArenaText.bodyMuted,
                  children: [
                    TextSpan(
                      text: 'AdminPaul',
                      style: ArenaText.body
                          .copyWith(fontWeight: FontWeight.w600),
                    ),
                    const TextSpan(text: ' a validé score 3-1 pour '),
                    TextSpan(
                      text: 'M-4282',
                      style: ArenaText.mono
                          .copyWith(color: ArenaColors.signalBlue),
                    ),
                  ],
                ),
              ),
              quote:
                  '"Recording montre clairement 3 buts de AhmedB. PaulN '
                  "n'a marqué que 1 but.\"",
            ),
            const SizedBox(height: ArenaSpacing.sm),
            _LogCard(
              accent: ArenaColors.neonRed,
              header: '🚫 User banni',
              time: '12:42',
              detail: RichText(
                text: TextSpan(
                  style: ArenaText.bodyMuted,
                  children: [
                    TextSpan(
                      text: 'AdminPaul',
                      style: ArenaText.body
                          .copyWith(fontWeight: FontWeight.w600),
                    ),
                    const TextSpan(text: ' a banni '),
                    TextSpan(
                      text: 'XploitR_99',
                      style: ArenaText.body
                          .copyWith(fontWeight: FontWeight.w700),
                    ),
                    const TextSpan(text: ' (triche détectée)'),
                  ],
                ),
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
    required this.current,
    required this.onTap,
  });

  final List<String> labels;
  final String current;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final l in labels)
            Padding(
              padding: const EdgeInsets.only(right: ArenaSpacing.xs),
              child: InkWell(
                onTap: () => onTap(l),
                borderRadius: BorderRadius.circular(ArenaRadius.round),
                child: AnimatedContainer(
                  duration: ArenaDurations.short,
                  padding: const EdgeInsets.symmetric(
                    horizontal: ArenaSpacing.md,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: l == current
                        ? ArenaColors.signalBlue.withValues(alpha: 0.15)
                        : ArenaColors.carbon,
                    borderRadius:
                        BorderRadius.circular(ArenaRadius.round),
                    border: Border.all(
                      color: l == current
                          ? ArenaColors.signalBlue
                          : ArenaColors.border,
                    ),
                  ),
                  child: Text(
                    l,
                    style: ArenaText.body.copyWith(
                      color: l == current
                          ? ArenaColors.signalBlue
                          : ArenaColors.silver,
                      fontWeight: l == current
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
  const _LogCard({
    required this.accent,
    required this.header,
    required this.time,
    required this.detail,
    this.quote,
    this.footer,
  });

  final Color accent;
  final String header;
  final String time;
  final Widget detail;
  final String? quote;
  final String? footer;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(ArenaSpacing.md),
      decoration: BoxDecoration(
        color: ArenaColors.carbon,
        borderRadius: BorderRadius.circular(ArenaRadius.lg),
        border: Border(
          top: const BorderSide(color: ArenaColors.border),
          right: const BorderSide(color: ArenaColors.border),
          bottom: const BorderSide(color: ArenaColors.border),
          left: BorderSide(color: accent, width: 3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  header,
                  style: ArenaText.body.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              Text(time, style: ArenaText.monoSmall),
            ],
          ),
          const SizedBox(height: ArenaSpacing.xs),
          detail,
          if (quote != null) ...[
            const SizedBox(height: ArenaSpacing.sm),
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: ArenaColors.carbon2,
                borderRadius: BorderRadius.circular(ArenaRadius.sm),
              ),
              child: Text(
                quote!,
                style: ArenaText.body.copyWith(fontStyle: FontStyle.italic),
              ),
            ),
          ],
          if (footer != null) ...[
            const SizedBox(height: ArenaSpacing.sm),
            Text(footer!, style: ArenaText.small),
          ],
        ],
      ),
    );
  }
}
