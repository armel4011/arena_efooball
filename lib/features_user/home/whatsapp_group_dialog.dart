import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/data/repositories/whatsapp_group_repository.dart';
import 'package:arena/features_shared/widgets/arena_button.dart';
import 'package:arena/features_shared/widgets/arena_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

/// Étape OBLIGATOIRE « Rejoindre le groupe WhatsApp » (tous les utilisateurs).
///
/// Interroge le serveur ; si un groupe est configuré et que le joueur n'a pas
/// encore validé, affiche un dialogue NON dismissible : rejoindre le groupe
/// puis saisir son nom. La comparaison du nom est faite côté serveur (le nom
/// attendu n'est jamais envoyé au client).
///
/// En cas d'erreur réseau, on n'affiche rien (on retentera au prochain
/// démarrage) : un incident ne doit pas verrouiller l'app.
Future<void> maybePromptWhatsAppGroup(
  BuildContext context,
  WidgetRef ref,
) async {
  final WhatsAppGroupStatus? status;
  try {
    status = await ref.read(whatsAppGroupRepositoryProvider).fetchMyStatus();
  } catch (_) {
    return;
  }
  if (status == null || !status.mustJoin || !context.mounted) return;
  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _WhatsAppGroupDialog(inviteUrl: status!.inviteUrl!.trim()),
  );
}

class _WhatsAppGroupDialog extends ConsumerStatefulWidget {
  const _WhatsAppGroupDialog({required this.inviteUrl});

  final String inviteUrl;

  @override
  ConsumerState<_WhatsAppGroupDialog> createState() =>
      _WhatsAppGroupDialogState();
}

class _WhatsAppGroupDialogState extends ConsumerState<_WhatsAppGroupDialog> {
  final _nameCtrl = TextEditingController();
  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _nameCtrl.addListener(_onChanged);
  }

  @override
  void dispose() {
    _nameCtrl
      ..removeListener(_onChanged)
      ..dispose();
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _openGroup() async {
    final uri = Uri.tryParse(widget.inviteUrl);
    var opened = false;
    if (uri != null) {
      try {
        opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      } catch (_) {
        opened = false;
      }
    }
    if (!opened && mounted) {
      setState(() {
        _error = "Impossible d'ouvrir WhatsApp. Copie le lien et ouvre-le "
            'dans ton navigateur.';
      });
    }
  }

  Future<void> _copyLink() async {
    await Clipboard.setData(ClipboardData(text: widget.inviteUrl));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Lien du groupe copié.')),
    );
  }

  Future<void> _submit() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty || _submitting) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final ok = await ref.read(whatsAppGroupRepositoryProvider).confirm(name);
      if (!mounted) return;
      if (ok) {
        Navigator.of(context).pop();
        return;
      }
      setState(() {
        _submitting = false;
        _error = "Ce n'est pas le nom du groupe. Ouvre le groupe dans WhatsApp "
            'et recopie son nom exact.';
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _submitting = false;
          _error = 'Vérification impossible. Vérifie ta connexion et réessaie.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Étape obligatoire : on bloque le back système.
    return PopScope(
      canPop: false,
      child: Dialog(
        backgroundColor: ArenaColors.carbon,
        insetPadding: const EdgeInsets.symmetric(
          horizontal: ArenaSpacing.md,
          vertical: ArenaSpacing.xl,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ArenaRadius.lg),
        ),
        child: Padding(
          padding: const EdgeInsets.all(ArenaSpacing.xl),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.groups,
                      color: ArenaColors.success,
                      size: 28,
                    ),
                    const SizedBox(width: ArenaSpacing.sm),
                    Expanded(
                      child: Text(
                        'Rejoins la communauté ARENA',
                        style:
                            ArenaText.h3.copyWith(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: ArenaSpacing.sm),
                Text(
                  'Pour continuer, rejoins notre groupe WhatsApp officiel : '
                  'annonces des tournois, résultats et entraide entre joueurs.',
                  style: ArenaText.body.copyWith(color: ArenaColors.silver),
                ),
                const SizedBox(height: ArenaSpacing.lg),
                const _Step(
                  number: 1,
                  text: 'Rejoins le groupe WhatsApp.',
                ),
                const SizedBox(height: ArenaSpacing.sm),
                ArenaButton(
                  label: 'Rejoindre le groupe WhatsApp',
                  icon: Icons.open_in_new,
                  variant: ArenaButtonVariant.success,
                  fullWidth: true,
                  onPressed: _submitting ? null : _openGroup,
                ),
                Center(
                  child: TextButton(
                    onPressed: _submitting ? null : _copyLink,
                    child: const Text('Copier le lien'),
                  ),
                ),
                const SizedBox(height: ArenaSpacing.sm),
                const _Step(
                  number: 2,
                  text: 'Saisis le nom du groupe tel qu’il apparaît dans '
                      'WhatsApp.',
                ),
                const SizedBox(height: ArenaSpacing.sm),
                ArenaTextField(
                  controller: _nameCtrl,
                  hint: 'Nom du groupe',
                  prefixIcon: Icons.edit_outlined,
                  textInputAction: TextInputAction.done,
                  enabled: !_submitting,
                ),
                if (_error != null) ...[
                  const SizedBox(height: ArenaSpacing.sm),
                  Text(
                    _error!,
                    style: ArenaText.small.copyWith(color: ArenaColors.neonRed),
                  ),
                ],
                const SizedBox(height: ArenaSpacing.lg),
                ArenaButton(
                  label: 'Valider',
                  fullWidth: true,
                  isLoading: _submitting,
                  onPressed: _nameCtrl.text.trim().isEmpty ? null : _submit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({required this.number, required this.text});

  final int number;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 22,
          height: 22,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: ArenaColors.success,
            shape: BoxShape.circle,
          ),
          child: Text(
            '$number',
            style: ArenaText.small.copyWith(
              color: ArenaColors.void_,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: ArenaSpacing.sm),
        Expanded(
          child: Text(
            text,
            style: ArenaText.body.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}
