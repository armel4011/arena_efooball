import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/core/utils/arena_error_message.dart';
import 'package:arena/data/repositories/admin/admin_audit_log_repository.dart';
import 'package:arena/data/repositories/admin/admin_payments_repository.dart';
import 'package:arena/features_admin_desktop/shared/desktop_totp_gate.dart';
import 'package:arena/features_shared/admin/admin_formatters.dart';
import 'package:arena/features_shared/admin/payment_labels.dart';
import 'package:arena/features_shared/auth_common/shared_auth_providers.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

part 'desktop_payments_validation_widgets.dart';

/// Finance · Validation des paiements P2P (desktop) — file des paiements
/// `awaiting_admin` (Orange / MTN) à valider ou refuser par le
/// super-admin, plus un onglet historique. Actions protégées par le
/// step-up TOTP.
///
/// Réutilise [adminPendingPaymentsProvider], [adminPaymentsHistoryProvider],
/// [adminPaymentsRepositoryProvider] et [adminAuditLogRepositoryProvider]
/// (mêmes providers que le mobile).
class DesktopPaymentsValidationPage extends ConsumerStatefulWidget {
  const DesktopPaymentsValidationPage({super.key});

  @override
  ConsumerState<DesktopPaymentsValidationPage> createState() =>
      _DesktopPaymentsValidationPageState();
}

class _DesktopPaymentsValidationPageState
    extends ConsumerState<DesktopPaymentsValidationPage> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    return ScaffoldPage(
      header: PageHeader(
        title: const Text('VALIDATION DES PAIEMENTS'),
        commandBar: CommandBar(
          mainAxisAlignment: MainAxisAlignment.end,
          primaryItems: [
            CommandBarButton(
              icon: const Icon(FluentIcons.refresh),
              label: const Text('Actualiser'),
              onPressed: () => ref
                ..invalidate(adminPendingPaymentsProvider)
                ..invalidate(adminRefundPendingProvider)
                ..invalidate(adminPaymentsHistoryProvider),
            ),
          ],
        ),
      ),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                ToggleButton(
                  checked: _tab == 0,
                  onChanged: (_) => setState(() => _tab = 0),
                  child: const Text('En attente'),
                ),
                const SizedBox(width: 8),
                ToggleButton(
                  checked: _tab == 1,
                  onChanged: (_) => setState(() => _tab = 1),
                  child: const Text('Remboursements'),
                ),
                const SizedBox(width: 8),
                ToggleButton(
                  checked: _tab == 2,
                  onChanged: (_) => setState(() => _tab = 2),
                  child: const Text('Historique'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: switch (_tab) {
              0 => const _PendingList(),
              1 => const _RefundList(),
              _ => const _HistoryList(),
            },
          ),
        ],
      ),
    );
  }
}
