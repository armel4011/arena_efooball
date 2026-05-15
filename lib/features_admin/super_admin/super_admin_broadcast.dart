import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/data/repositories/admin/admin_audit_log_repository.dart';
import 'package:arena/data/repositories/admin/admin_users_repository.dart';
import 'package:arena/data/repositories/profile_repository.dart';
import 'package:arena/features_admin/auth_admin/widgets/totp_gate.dart';
import 'package:arena/features_shared/auth_common/shared_auth_providers.dart';
import 'package:arena/features_shared/widgets/arena_app_bar.dart';
import 'package:arena/features_shared/widgets/arena_button.dart';
import 'package:arena/features_shared/widgets/arena_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// PHASE 12.5 — Écran super-admin pour envoyer une notification ciblée.
///
/// Réutilise `AdminUsersFilter` pour piocher les destinataires (mêmes
/// critères que la page Users : pays, statut, recherche, won, paid,
/// rewarded, disputed, guilty). Chaque INSERT dans `notifications` est
/// dispatché vers FCM par le trigger `trg_notifications_dispatch`.
///
/// Route : `/super/broadcast` (super-admin only — TOTP gate en plus).
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

  String? _statusFilter;
  String? _countryCode;
  String _searchQuery = '';
  bool _wonCompetition = false;
  bool _paidEntry = false;
  bool _receivedReward = false;
  bool _hadDispute = false;
  bool _guiltyInDispute = false;
  String _notifType = 'system';
  bool _sending = false;
  String? _lastResult;

  static const _statusFilters = <(String?, String)>[
    (null, 'Tous'),
    ('active', 'Actifs'),
    ('banned', 'Bannis'),
    ('kyc_pending', 'KYC pending'),
  ];
  static const _countryFilters = <(String?, String)>[
    (null, 'Tous pays'),
    ('CM', '🇨🇲'),
    ('SN', '🇸🇳'),
    ('CI', '🇨🇮'),
  ];
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

  AdminUsersFilter get _filter => AdminUsersFilter(
        countryCode: _countryCode,
        filter: _statusFilter,
        searchQuery: _searchQuery.isEmpty ? null : _searchQuery,
        wonCompetition: _wonCompetition,
        paidEntry: _paidEntry,
        receivedReward: _receivedReward,
        hadDispute: _hadDispute,
        guiltyInDispute: _guiltyInDispute,
      );

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
    final filter = _filter;
    final usersAsync = ref.watch(adminUsersProvider(filter));

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
              onChanged: (v) => setState(() => _searchQuery = v.trim()),
            ),
            const SizedBox(height: ArenaSpacing.sm),
            _ChipsRow(
              labels: [for (final (_, l) in _statusFilters) l],
              currentIndex:
                  _statusFilters.indexWhere((e) => e.$1 == _statusFilter),
              onTap: (i) => setState(
                () => _statusFilter = _statusFilters[i].$1,
              ),
            ),
            const SizedBox(height: ArenaSpacing.xs),
            _ChipsRow(
              labels: [for (final (_, l) in _countryFilters) l],
              currentIndex:
                  _countryFilters.indexWhere((e) => e.$1 == _countryCode),
              onTap: (i) => setState(
                () => _countryCode = _countryFilters[i].$1,
              ),
            ),
            const SizedBox(height: ArenaSpacing.sm),
            Wrap(
              spacing: ArenaSpacing.xs,
              runSpacing: ArenaSpacing.xs,
              children: [
                _toggle('🏆 A gagné', _wonCompetition,
                    () => setState(() => _wonCompetition = !_wonCompetition)),
                _toggle('💳 A payé', _paidEntry,
                    () => setState(() => _paidEntry = !_paidEntry)),
                _toggle('💰 A reçu un gain', _receivedReward,
                    () => setState(() => _receivedReward = !_receivedReward)),
                _toggle('⚖ Litige', _hadDispute,
                    () => setState(() => _hadDispute = !_hadDispute)),
                _toggle('🚨 Coupable', _guiltyInDispute,
                    () => setState(() => _guiltyInDispute = !_guiltyInDispute)),
              ],
            ),
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
                  ' cette page de l\'app.',
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
                    borderRadius: BorderRadius.circular(ArenaRadius.round),
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
