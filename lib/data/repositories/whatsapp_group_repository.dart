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

/// Un groupe WhatsApp vu par le super-admin, avec son remplissage.
///
/// [id] est stable : le compteur de validations suit le groupe même si
/// d'autres groupes sont ajoutés, supprimés ou réordonnés.
///
/// ⚠️ `members` = joueurs ARENA ayant VALIDÉ ce groupe (WhatsApp n'expose
/// aucune API de comptage des membres) : c'est une estimation du remplissage.
class WhatsAppGroupSlot {
  const WhatsAppGroupSlot({
    required this.id,
    this.inviteUrl = '',
    this.groupName = '',
    this.capacity = WhatsAppGroupRepository.defaultCapacity,
    this.members = 0,
    this.isCurrent = false,
  });

  factory WhatsAppGroupSlot.fromRow(Map<String, dynamic> row) {
    return WhatsAppGroupSlot(
      id: (row['id'] as num).toInt(),
      inviteUrl: (row['invite_url'] as String?) ?? '',
      groupName: (row['group_name'] as String?) ?? '',
      capacity: (row['capacity'] as num?)?.toInt() ??
          WhatsAppGroupRepository.defaultCapacity,
      members: (row['members'] as num?)?.toInt() ?? 0,
      isCurrent: row['is_current'] == true,
    );
  }

  final int id;
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

  /// Tous les groupes, dans l'ordre (super-admin).
  Future<List<WhatsAppGroupSlot>> fetchGroups() async {
    final res = await _client.rpc<dynamic>('admin_list_whatsapp_groups');
    if (res is! List) return const [];
    return [
      for (final row in res.whereType<Map<dynamic, dynamic>>())
        WhatsAppGroupSlot.fromRow(Map<String, dynamic>.from(row)),
    ];
  }

  /// Enregistre la liste complète, dans l'ordre (super-admin) :
  /// - `id` connu → groupe mis à jour (son compteur est conservé) ;
  /// - `id` null → nouveau groupe ;
  /// - groupe existant absent de la liste → supprimé ;
  /// - lien ET nom vides → ignoré. Liste vide = étape désactivée.
  Future<void> saveGroups(
    List<({int? id, String inviteUrl, String groupName})> groups,
  ) async {
    await _client.rpc<dynamic>(
      'set_whatsapp_groups',
      params: {
        'p_groups': [
          for (final g in groups)
            {
              'id': g.id,
              'invite_url': g.inviteUrl.trim(),
              'group_name': g.groupName.trim(),
            },
        ],
      },
    );
  }

  /// Nom suggéré pour un nouveau groupe : « Arena_Game NNN », NNN = numéro
  /// suivant le plus grand déjà utilisé (ou le rang si aucun ne suit ce
  /// modèle).
  static String suggestNextName(Iterable<String> existingNames) {
    final pattern = RegExp(r'(\d+)\s*$');
    var maxNumber = 0;
    var count = 0;
    for (final name in existingNames) {
      count++;
      final m = pattern.firstMatch(name.trim());
      final n = m == null ? null : int.tryParse(m.group(1)!);
      if (n != null && n > maxNumber) maxNumber = n;
    }
    final next = (maxNumber > 0 ? maxNumber : count) + 1;
    return 'Arena_Game ${next.toString().padLeft(3, '0')}';
  }
}

final whatsAppGroupRepositoryProvider =
    Provider<WhatsAppGroupRepository>((ref) {
  return WhatsAppGroupRepository(ref.watch(supabaseClientProvider));
});
