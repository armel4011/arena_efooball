import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/core/utils/arena_error_message.dart';
import 'package:arena/core/utils/supported_countries.dart';
import 'package:arena/data/repositories/admin/payment_collectors_repository.dart';
import 'package:arena/features_shared/widgets/arena_app_bar.dart';
import 'package:arena/features_shared/widgets/arena_button.dart';
import 'package:arena/features_shared/widgets/arena_screen_background.dart';
import 'package:arena/features_shared/widgets/arena_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

final _money = NumberFormat.decimalPattern('fr');

String _countryLabel(String code) {
  for (final c in kSupportedCountries) {
    if (c.code == code) return '${c.flag} ${c.name}';
  }
  return code;
}

/// Écran super-admin — gestion des COLLECTEURS de paiement (par pays) :
/// affecter un pays + un quota, activer/désactiver, et valider les versements
/// (qui remettent l'encours à zéro et rouvrent le collecteur).
class SuperAdminCollectorsPage extends ConsumerStatefulWidget {
  const SuperAdminCollectorsPage({super.key});

  @override
  ConsumerState<SuperAdminCollectorsPage> createState() =>
      _SuperAdminCollectorsPageState();
}

class _SuperAdminCollectorsPageState
    extends ConsumerState<SuperAdminCollectorsPage> {
  String? _newProfileId;
  String? _newCountry;
  final _quotaCtrl = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _quotaCtrl.dispose();
    super.dispose();
  }

  void _refresh() {
    ref
      ..invalidate(collectorsListProvider)
      ..invalidate(pendingRemittancesProvider)
      ..invalidate(collectorProfilesProvider);
  }

  @override
  Widget build(BuildContext context) {
    final collectors = ref.watch(collectorsListProvider);
    final remittances = ref.watch(pendingRemittancesProvider);
    final profiles = ref.watch(collectorProfilesProvider);

    return Scaffold(
      appBar: const ArenaAppBar(title: 'COLLECTEURS'),
      body: ArenaScreenBackground(
        accent: ArenaColors.neonRed,
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(ArenaSpacing.lg),
            children: [
              // ─── Versements à valider ─────────────────────────────────
              Text('VERSEMENTS À VALIDER', style: ArenaText.inputLabel),
              const SizedBox(height: ArenaSpacing.sm),
              remittances.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) =>
                    Text('Erreur : $e', style: ArenaText.bodyMuted),
                data: (list) => list.isEmpty
                    ? Text('Aucun versement en attente.',
                        style: ArenaText.bodyMuted)
                    : Column(
                        children: [
                          for (final r in list) ...[
                            _RemittanceCard(
                              remittance: r,
                              onValidate: () => _validateRemittance(r),
                              onReject: () => _rejectRemittance(r),
                            ),
                            const SizedBox(height: ArenaSpacing.sm),
                          ],
                        ],
                      ),
              ),
              const SizedBox(height: ArenaSpacing.lg),

              // ─── Collecteurs ──────────────────────────────────────────
              Text('COLLECTEURS', style: ArenaText.inputLabel),
              const SizedBox(height: ArenaSpacing.sm),
              collectors.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) =>
                    Text('Erreur : $e', style: ArenaText.bodyMuted),
                data: (list) => list.isEmpty
                    ? Text('Aucun collecteur configuré.',
                        style: ArenaText.bodyMuted)
                    : Column(
                        children: [
                          for (final c in list) ...[
                            _CollectorCard(
                              collector: c,
                              onEditQuota: () => _editQuota(c),
                              onToggleActive: () => _toggleActive(c),
                            ),
                            const SizedBox(height: ArenaSpacing.sm),
                          ],
                        ],
                      ),
              ),
              const SizedBox(height: ArenaSpacing.lg),

              // ─── Ajouter / configurer ─────────────────────────────────
              Text('+ AFFECTER UN COLLECTEUR', style: ArenaText.inputLabel),
              const SizedBox(height: ArenaSpacing.sm),
              profiles.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) =>
                    Text('Erreur : $e', style: ArenaText.bodyMuted),
                data: (list) => _addForm(list),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _addForm(List<CollectorProfile> profiles) {
    if (profiles.isEmpty) {
      return Text(
        "Aucun compte au rôle « collecteur ». Génère d'abord un code "
        "d'invitation COLLECTEUR (écran Invitations) et fais-le rédimer.",
        style: ArenaText.bodyMuted,
      );
    }
    // Pré-remplit le pays depuis le périmètre du collecteur choisi.
    final selected = profiles.where((p) => p.id == _newProfileId).firstOrNull;
    final suggestedCountry = _newCountry ??
        (selected != null && selected.allowedCountries.isNotEmpty
            ? selected.allowedCountries.first
            : null);

    return Container(
      padding: const EdgeInsets.all(ArenaSpacing.md),
      decoration: BoxDecoration(
        color: ArenaColors.carbon,
        borderRadius: BorderRadius.circular(ArenaRadius.md),
        border: Border.all(color: ArenaColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DropdownButtonFormField<String>(
            initialValue: _newProfileId,
            dropdownColor: ArenaColors.carbon,
            decoration: const InputDecoration(labelText: 'Collecteur'),
            items: [
              for (final p in profiles)
                DropdownMenuItem(value: p.id, child: Text(p.username)),
            ],
            onChanged: (v) => setState(() {
              _newProfileId = v;
              _newCountry = null;
            }),
          ),
          const SizedBox(height: ArenaSpacing.sm),
          DropdownButtonFormField<String>(
            initialValue: suggestedCountry,
            dropdownColor: ArenaColors.carbon,
            decoration: const InputDecoration(labelText: 'Pays'),
            items: [
              for (final c in kSupportedCountries)
                DropdownMenuItem(
                  value: c.code,
                  child: Text('${c.flag} ${c.name}'),
                ),
            ],
            onChanged: (v) => setState(() => _newCountry = v),
          ),
          const SizedBox(height: ArenaSpacing.sm),
          ArenaTextField(
            controller: _quotaCtrl,
            hint: 'Quota (ex. 100000)',
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: ArenaSpacing.md),
          ArenaButton(
            label: 'AFFECTER',
            fullWidth: true,
            isLoading: _submitting,
            onPressed: () => _submitAdd(suggestedCountry),
          ),
        ],
      ),
    );
  }

  Future<void> _submitAdd(String? country) async {
    final profileId = _newProfileId;
    final quota = double.tryParse(_quotaCtrl.text.trim().replaceAll(' ', ''));
    if (profileId == null || country == null || quota == null || quota <= 0) {
      _toast('Renseigne un collecteur, un pays et un quota valide.');
      return;
    }
    setState(() => _submitting = true);
    try {
      await ref.read(paymentCollectorsRepositoryProvider).upsertCollector(
            profileId: profileId,
            country: country,
            quota: quota,
          );
      _quotaCtrl.clear();
      setState(() {
        _newProfileId = null;
        _newCountry = null;
      });
      _refresh();
      _toast('Collecteur affecté.');
    } catch (e) {
      _toast(arenaErrorMessage(e));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _editQuota(PaymentCollector c) async {
    final ctrl = TextEditingController(text: c.quotaLocal.toStringAsFixed(0));
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ArenaColors.carbon,
        title:
            Text('Quota — ${c.username ?? c.profileId}', style: ArenaText.body),
        content: ArenaTextField(
          controller: ctrl,
          hint: 'Nouveau quota',
          keyboardType: TextInputType.number,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final quota = double.tryParse(ctrl.text.trim().replaceAll(' ', ''));
    if (quota == null || quota <= 0) {
      _toast('Quota invalide.');
      return;
    }
    try {
      await ref.read(paymentCollectorsRepositoryProvider).upsertCollector(
            profileId: c.profileId,
            country: c.countryCode,
            quota: quota,
          );
      _refresh();
      _toast('Quota mis à jour.');
    } catch (e) {
      _toast(arenaErrorMessage(e));
    }
  }

  Future<void> _toggleActive(PaymentCollector c) async {
    try {
      await ref.read(paymentCollectorsRepositoryProvider).setCollectorActive(
            collectorId: c.id,
            active: !c.isActive,
          );
      _refresh();
    } catch (e) {
      _toast(arenaErrorMessage(e));
    }
  }

  Future<void> _validateRemittance(CollectorRemittance r) async {
    final ok = await _confirm(
      'Valider le versement',
      'Confirmes-tu avoir bien REÇU ${_money.format(r.amountLocal)} de '
          '${r.username ?? 'ce collecteur'} ? Son encours sera remis à zéro et '
          'son compte réactivé.',
    );
    if (!ok) return;
    try {
      await ref
          .read(paymentCollectorsRepositoryProvider)
          .validateRemittance(r.id);
      _refresh();
      _toast('Versement validé.');
    } catch (e) {
      _toast(arenaErrorMessage(e));
    }
  }

  Future<void> _rejectRemittance(CollectorRemittance r) async {
    final ctrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ArenaColors.carbon,
        title: Text('Refuser le versement', style: ArenaText.body),
        content: ArenaTextField(controller: ctrl, hint: 'Motif'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Refuser'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(paymentCollectorsRepositoryProvider).rejectRemittance(
            remittanceId: r.id,
            reason: ctrl.text.trim(),
          );
      _refresh();
      _toast('Versement refusé.');
    } catch (e) {
      _toast(arenaErrorMessage(e));
    }
  }

  Future<bool> _confirm(String title, String body) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ArenaColors.carbon,
        title: Text(title, style: ArenaText.body),
        content: Text(body, style: ArenaText.bodyMuted),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );
    return ok ?? false;
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }
}

class _CollectorCard extends StatelessWidget {
  const _CollectorCard({
    required this.collector,
    required this.onEditQuota,
    required this.onToggleActive,
  });

  final PaymentCollector collector;
  final VoidCallback onEditQuota;
  final VoidCallback onToggleActive;

  @override
  Widget build(BuildContext context) {
    final c = collector;
    final statusColor = !c.isActive
        ? ArenaColors.silver
        : c.isBlocked
            ? ArenaColors.neonRed
            : ArenaColors.statusOk;
    final statusLabel = !c.isActive
        ? 'INACTIF'
        : c.isBlocked
            ? 'BLOQUÉ (quota atteint)'
            : 'ACTIF';

    return Container(
      padding: const EdgeInsets.all(ArenaSpacing.md),
      decoration: BoxDecoration(
        color: ArenaColors.carbon,
        borderRadius: BorderRadius.circular(ArenaRadius.md),
        border: Border.all(color: statusColor.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${c.username ?? c.profileId}  ·  ${_countryLabel(c.countryCode)}',
                  style: ArenaText.body.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              Text(statusLabel,
                  style: ArenaText.small.copyWith(
                      color: statusColor, fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: ArenaSpacing.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: c.usageRatio,
              minHeight: 8,
              backgroundColor: ArenaColors.void_,
              valueColor: AlwaysStoppedAnimation(statusColor),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Encours ${_money.format(c.outstandingLocal)} / quota '
            '${_money.format(c.quotaLocal)}  ·  reste '
            '${_money.format(c.remaining)}',
            style: ArenaText.small.copyWith(color: ArenaColors.silver),
          ),
          const SizedBox(height: ArenaSpacing.sm),
          Row(
            children: [
              Expanded(
                child: ArenaButton(
                  label: 'MODIFIER QUOTA',
                  variant: ArenaButtonVariant.secondary,
                  fullWidth: true,
                  onPressed: onEditQuota,
                ),
              ),
              const SizedBox(width: ArenaSpacing.xs),
              Expanded(
                child: ArenaButton(
                  label: c.isActive ? 'DÉSACTIVER' : 'ACTIVER',
                  variant: c.isActive
                      ? ArenaButtonVariant.danger
                      : ArenaButtonVariant.success,
                  fullWidth: true,
                  onPressed: onToggleActive,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RemittanceCard extends StatelessWidget {
  const _RemittanceCard({
    required this.remittance,
    required this.onValidate,
    required this.onReject,
  });

  final CollectorRemittance remittance;
  final VoidCallback onValidate;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    final r = remittance;
    return Container(
      padding: const EdgeInsets.all(ArenaSpacing.md),
      decoration: BoxDecoration(
        color: ArenaColors.carbon,
        borderRadius: BorderRadius.circular(ArenaRadius.md),
        border: Border.all(color: ArenaColors.tierGold.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${_money.format(r.amountLocal)}  ·  ${r.username ?? '—'}'
            '${r.countryCode != null ? '  ·  ${_countryLabel(r.countryCode!)}' : ''}',
            style: ArenaText.body.copyWith(fontWeight: FontWeight.w700),
          ),
          if (r.note != null && r.note!.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(r.note!,
                style: ArenaText.small.copyWith(color: ArenaColors.silver)),
          ],
          const SizedBox(height: ArenaSpacing.sm),
          Row(
            children: [
              Expanded(
                child: ArenaButton(
                  label: 'VALIDER',
                  variant: ArenaButtonVariant.success,
                  fullWidth: true,
                  onPressed: onValidate,
                ),
              ),
              const SizedBox(width: ArenaSpacing.xs),
              Expanded(
                child: ArenaButton(
                  label: 'REFUSER',
                  variant: ArenaButtonVariant.danger,
                  fullWidth: true,
                  onPressed: onReject,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
