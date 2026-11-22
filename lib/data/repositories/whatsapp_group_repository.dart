import 'package:arena/data/repositories/profile_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Statut de l'étape obligatoire « groupe WhatsApp » pour le joueur courant.
///
/// Le nom attendu du groupe n'est JAMAIS renvoyé au client (sinon on pourrait
/// le lire sans rejoindre) : seule la validation serveur le compare.
class WhatsAppGroupStatus {
  const WhatsAppGroupStatus({
    required this.required,
    required this.joined,
    this.inviteUrl,
  });

  factory WhatsAppGroupStatus.fromRow(Map<String, dynamic> row) {
    return WhatsAppGroupStatus(
      required: row['required'] == true,
      joined: row['joined'] == true,
      inviteUrl: row['invite_url'] as String?,
    );
  }

  /// Un groupe est configuré par le super-admin (étape active).
  final bool required;

  /// Le joueur a déjà validé l'étape.
  final bool joined;

  /// Lien d'invitation WhatsApp (https://chat.whatsapp.com/…).
  final String? inviteUrl;

  /// Le joueur doit encore rejoindre le groupe avant de continuer.
  bool get mustJoin =>
      required && !joined && (inviteUrl?.trim().isNotEmpty ?? false);
}

/// Réglage du groupe (lecture super-admin uniquement, RLS).
class WhatsAppGroupConfig {
  const WhatsAppGroupConfig({this.inviteUrl, this.groupName});

  final String? inviteUrl;
  final String? groupName;
}

class WhatsAppGroupRepository {
  const WhatsAppGroupRepository(this._client);

  final SupabaseClient _client;

  /// Statut du joueur courant. `null` si la réponse est vide (profil absent).
  Future<WhatsAppGroupStatus?> fetchMyStatus() async {
    final res = await _client.rpc<dynamic>('my_whatsapp_group_status');
    if (res is List && res.isNotEmpty && res.first is Map) {
      return WhatsAppGroupStatus.fromRow(
        Map<String, dynamic>.from(res.first as Map),
      );
    }
    return null;
  }

  /// Vérifie [groupName] côté serveur et valide l'étape si le nom correspond
  /// (casse, accents, espaces, emojis et ponctuation ignorés). `true` = validé.
  Future<bool> confirm(String groupName) async {
    final res = await _client.rpc<dynamic>(
      'confirm_whatsapp_group',
      params: {'p_group_name': groupName},
    );
    return res == true;
  }

  /// Réglage courant (super-admin : la RLS filtre les autres rôles à 0 ligne).
  Future<WhatsAppGroupConfig> fetchConfig() async {
    final row = await _client
        .from('whatsapp_group_config')
        .select('invite_url, group_name')
        .eq('id', 1)
        .maybeSingle();
    return WhatsAppGroupConfig(
      inviteUrl: row?['invite_url'] as String?,
      groupName: row?['group_name'] as String?,
    );
  }

  /// Enregistre le groupe (super-admin). Deux champs vides = étape désactivée.
  Future<void> saveConfig({
    required String inviteUrl,
    required String groupName,
  }) async {
    await _client.rpc<dynamic>(
      'set_whatsapp_group_config',
      params: {'p_invite_url': inviteUrl, 'p_group_name': groupName},
    );
  }
}

final whatsAppGroupRepositoryProvider =
    Provider<WhatsAppGroupRepository>((ref) {
  return WhatsAppGroupRepository(ref.watch(supabaseClientProvider));
});
