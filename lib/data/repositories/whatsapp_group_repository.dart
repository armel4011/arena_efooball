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

/// Un emplacement de groupe WhatsApp (1..[WhatsAppGroupRepository.maxGroups])
/// vu par le super-admin, avec son remplissage.
///
/// ⚠️ `members` = joueurs ARENA ayant VALIDÉ ce groupe (WhatsApp n'expose
/// aucune API de comptage des membres) : c'est une estimation du remplissage.
class WhatsAppGroupSlot {
  const WhatsAppGroupSlot({
    required this.position,
    this.inviteUrl = '',
    this.groupName = '',
    this.capacity = WhatsAppGroupRepository.defaultCapacity,
    this.members = 0,
    this.isCurrent = false,
  });

  factory WhatsAppGroupSlot.fromRow(Map<String, dynamic> row) {
    return WhatsAppGroupSlot(
      position: (row['position'] as num).toInt(),
      inviteUrl: (row['invite_url'] as String?) ?? '',
      groupName: (row['group_name'] as String?) ?? '',
      capacity: (row['capacity'] as num?)?.toInt() ??
          WhatsAppGroupRepository.defaultCapacity,
      members: (row['members'] as num?)?.toInt() ?? 0,
      isCurrent: row['is_current'] == true,
    );
  }

  final int position;
  final String inviteUrl;
  final String groupName;
  final int capacity;
  final int members;

  /// Groupe dont le lien est actuellement proposé aux nouveaux joueurs.
  final bool isCurrent;

  bool get isConfigured => inviteUrl.isNotEmpty && groupName.isNotEmpty;
  bool get isFull => members >= capacity;
}

class WhatsAppGroupRepository {
  const WhatsAppGroupRepository(this._client);

  final SupabaseClient _client;

  /// Nombre maximal de groupes configurables.
  static const maxGroups = 5;

  /// Capacité par groupe (plafond WhatsApp 1024, marge pour les validations
  /// simultanées) — valeur par défaut côté serveur.
  static const defaultCapacity = 1020;

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

  /// Les [maxGroups] emplacements (super-admin), complétés par des
  /// emplacements vides pour ceux non configurés.
  Future<List<WhatsAppGroupSlot>> fetchGroups() async {
    final res = await _client.rpc<dynamic>('admin_list_whatsapp_groups');
    final byPosition = <int, WhatsAppGroupSlot>{};
    if (res is List) {
      for (final row in res.whereType<Map<dynamic, dynamic>>()) {
        final slot =
            WhatsAppGroupSlot.fromRow(Map<String, dynamic>.from(row));
        byPosition[slot.position] = slot;
      }
    }
    return [
      for (var p = 1; p <= maxGroups; p++)
        byPosition[p] ?? WhatsAppGroupSlot(position: p),
    ];
  }

  /// Enregistre les emplacements dans l'ordre (super-admin). Lien ET nom
  /// vides = emplacement libéré ; tous vides = étape désactivée.
  Future<void> saveGroups(
    List<({String inviteUrl, String groupName})> groups,
  ) async {
    await _client.rpc<dynamic>(
      'set_whatsapp_groups',
      params: {
        'p_groups': [
          for (final g in groups)
            {'invite_url': g.inviteUrl.trim(), 'group_name': g.groupName.trim()},
        ],
      },
    );
  }
}

final whatsAppGroupRepositoryProvider =
    Provider<WhatsAppGroupRepository>((ref) {
  return WhatsAppGroupRepository(ref.watch(supabaseClientProvider));
});
