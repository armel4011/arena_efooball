import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/core/utils/arena_error_message.dart';
import 'package:arena/data/models/arena_match.dart';
import 'package:arena/data/models/competition.dart';
import 'package:arena/data/models/competition_enums.dart';
import 'package:arena/data/models/match_status.dart';
import 'package:arena/data/repositories/admin/admin_audit_log_repository.dart';
import 'package:arena/data/repositories/admin/admin_bracket_repository.dart';
import 'package:arena/data/repositories/admin/admin_matches_repository.dart';
import 'package:arena/data/repositories/competition_repository.dart';
import 'package:arena/data/repositories/match_repository.dart';
import 'package:arena/data/repositories/profile_repository.dart';
import 'package:arena/features_shared/admin_result_gate.dart';
import 'package:arena/features_shared/auth_common/shared_auth_providers.dart';
import 'package:arena/features_shared/widgets/arena_app_bar.dart';
import 'package:arena/features_shared/widgets/arena_avatar.dart';
import 'package:arena/features_shared/widgets/arena_badge.dart';
import 'package:arena/features_shared/widgets/arena_bracket_tree.dart';
import 'package:arena/features_shared/widgets/arena_button.dart';
import 'package:arena/features_shared/widgets/arena_screen_background.dart';
import 'package:arena/features_shared/widgets/arena_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

part 'admin_bracket_management_page_generate.dart';
part 'admin_bracket_management_page_widgets.dart';
part 'admin_bracket_management_page_actions.dart';

/// PHASE 11 · A11 — admin bracket management.
///
/// If no matches yet → "Generate bracket" CTA (single-elim / round-robin
/// / groups+KO). Once matches exist → grouped-by-round list with admin
/// actions per match (verdict, cancel, toggle streaming). The
/// underlying generators are pure Dart ([lib/core/utils/bracket_generators/]);
/// the persist step lives in [AdminBracketRepository].
///
/// Maps to screen A11 of `arena_v2.html`.
class AdminBracketManagementPage extends ConsumerWidget {
  const AdminBracketManagementPage({
    required this.competitionId,
    super.key,
  });

  final String competitionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final compAsync = ref.watch(competitionByIdProvider(competitionId));
    final matchesAsync = ref.watch(competitionMatchesProvider(competitionId));

    return Scaffold(
      appBar: const ArenaAppBar(title: 'BRACKET'),
      body: ArenaScreenBackground(
        accent: ArenaColors.neonRed,
        child: SafeArea(
          child: compAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Padding(
              padding: const EdgeInsets.all(ArenaSpacing.lg),
              child: Text('Erreur : $e', style: ArenaText.bodyMuted),
            ),
            data: (comp) {
              if (comp == null) return const SizedBox.shrink();
              return matchesAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) =>
                    Text('Erreur : $e', style: ArenaText.bodyMuted),
                data: (matches) => matches.isEmpty
                    ? _EmptyState(competition: comp)
                    : _BracketView(competition: comp, matches: matches),
              );
            },
          ),
        ),
      ),
    );
  }
}
