import 'package:arena/data/models/profile.dart';
import 'package:arena/features_shared/admin_sections.dart';
import 'package:fluent_ui/fluent_ui.dart';

/// VOLET 3 — bandeau « Périmètre : {pays} » (desktop, Fluent) affiché sur
/// les écrans finance quand l'admin courant a un scope pays restreint.
/// Clarifie pourquoi la liste est réduite (filtrage pays fait côté RLS).
class DesktopScopeBanner extends StatelessWidget {
  const DesktopScopeBanner({required this.profile, super.key});

  final Profile? profile;

  @override
  Widget build(BuildContext context) {
    final label = adminCountriesLabel(profile?.adminAllowedCountries);
    if (label.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
      child: InfoBar(
        title: const Text('Périmètre'),
        content: Text(label),
        severity: InfoBarSeverity.info,
        isLong: true,
      ),
    );
  }
}
