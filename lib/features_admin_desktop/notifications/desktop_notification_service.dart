import 'package:arena/core/router/admin_desktop_router.dart';
import 'package:arena/data/repositories/profile_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Catégories d'événements suivies par le centre de notifications desktop.
///
/// FCM n'existe pas sur Windows : ce service écoute Supabase Realtime et
/// alimente la cloche de l'app. Chaque catégorie mappe une table observée
/// en INSERT et possède sa propre route cible dans le shell admin.
enum DesktopNotificationCategory {
  /// Paiement P2P en attente de validation super-admin (`payments`).
  payment,

  /// Litige ouvert sur un match (`disputes`).
  dispute,

  /// Message envoyé par un utilisateur vers l'admin (`admin_chat_messages`).
  message,

  /// Demande de réintégration d'un compte banni (`reintegration_requests`).
  reintegration;

  /// Libellé court affiché dans la cloche / les filtres (français).
  String get label => switch (this) {
        DesktopNotificationCategory.payment => 'Paiement à valider',
        DesktopNotificationCategory.dispute => 'Litige ouvert',
        DesktopNotificationCategory.message => 'Nouveau message',
        DesktopNotificationCategory.reintegration => 'Réintégration',
      };

  /// Route du shell vers laquelle naviguer quand l'admin clique l'événement.
  String get targetRoute => switch (this) {
        DesktopNotificationCategory.payment =>
          AdminDesktopRoutes.superPaymentsValidation,
        DesktopNotificationCategory.dispute => AdminDesktopRoutes.matches,
        DesktopNotificationCategory.message => AdminDesktopRoutes.superUsers,
        DesktopNotificationCategory.reintegration =>
          AdminDesktopRoutes.superReintegration,
      };
}

/// Un événement Realtime observé (1 INSERT en base).
@immutable
class DesktopNotificationEvent {
  const DesktopNotificationEvent({
    required this.category,
    required this.title,
    required this.subtitle,
    required this.route,
    required this.at,
    this.payloadId,
  });

  final DesktopNotificationCategory category;
  final String title;
  final String subtitle;

  /// Route cible — par défaut celle de la catégorie, mais peut être
  /// affinée (ex. un message ouvre directement le fil de l'utilisateur).
  final String route;
  final DateTime at;

  /// Identifiant de la ligne source (utile pour le débogage / dédup).
  final String? payloadId;
}

/// État exposé par [desktopNotificationsProvider] : compteurs de non-lus
/// par catégorie + les derniers événements reçus (toutes catégories).
@immutable
class DesktopNotificationState {
  const DesktopNotificationState({
    this.unreadByCategory = const {},
    this.recentEvents = const [],
  });

  /// Compteur de non-lus par catégorie (absent = 0).
  final Map<DesktopNotificationCategory, int> unreadByCategory;

  /// Derniers événements reçus, du plus récent au plus ancien.
  final List<DesktopNotificationEvent> recentEvents;

  /// Total de non-lus toutes catégories confondues (badge de la cloche).
  int get totalUnread =>
      unreadByCategory.values.fold(0, (sum, value) => sum + value);

  int unreadFor(DesktopNotificationCategory category) =>
      unreadByCategory[category] ?? 0;

  DesktopNotificationState copyWith({
    Map<DesktopNotificationCategory, int>? unreadByCategory,
    List<DesktopNotificationEvent>? recentEvents,
  }) {
    return DesktopNotificationState(
      unreadByCategory: unreadByCategory ?? this.unreadByCategory,
      recentEvents: recentEvents ?? this.recentEvents,
    );
  }
}

/// Notifier Riverpod : s'abonne aux INSERT Realtime sur les 4 tables
/// admin et maintient [DesktopNotificationState].
///
/// Cycle de vie :
///  * abonnement créé dans [build] sur un canal unique `desktop_admin_notif`
///  * nettoyé via `ref.onDispose` (unsubscribe + removeChannel)
///  * l'admin de session est requis pour distinguer les messages
///    entrants (user → admin) des sortants (admin → user) ; sans session
///    le service reste inerte.
class DesktopNotificationsNotifier extends Notifier<DesktopNotificationState> {
  RealtimeChannel? _channel;
  String? _adminId;

  /// Nombre max d'événements conservés dans la liste (cloche).
  static const _maxEvents = 30;

  @override
  DesktopNotificationState build() {
    final client = ref.watch(supabaseClientProvider);
    _adminId = client.auth.currentSession?.user.id;

    _subscribe(client);
    ref.onDispose(_teardown);

    return const DesktopNotificationState();
  }

  void _subscribe(SupabaseClient client) {
    final channel = client.channel('desktop_admin_notif')
      ..onPostgresChanges(
        event: PostgresChangeEvent.insert,
        schema: 'public',
        table: 'payments',
        callback: _onPaymentInsert,
      )
      ..onPostgresChanges(
        event: PostgresChangeEvent.insert,
        schema: 'public',
        table: 'disputes',
        callback: _onDisputeInsert,
      )
      ..onPostgresChanges(
        event: PostgresChangeEvent.insert,
        schema: 'public',
        table: 'admin_chat_messages',
        callback: _onMessageInsert,
      )
      ..onPostgresChanges(
        event: PostgresChangeEvent.insert,
        schema: 'public',
        table: 'reintegration_requests',
        callback: _onReintegrationInsert,
      )
      ..subscribe();
    _channel = channel;
  }

  Future<void> _teardown() async {
    final channel = _channel;
    if (channel == null) return;
    _channel = null;
    try {
      final client = ref.read(supabaseClientProvider);
      await channel.unsubscribe();
      await client.removeChannel(channel);
    } catch (error, stack) {
      if (kDebugMode) {
        debugPrint('[desktop-notif] teardown error: $error\n$stack');
      }
    }
  }

  // ─── Callbacks Realtime ────────────────────────────────────────────

  void _onPaymentInsert(PostgresChangePayload payload) {
    final row = payload.newRecord;
    // Seuls les paiements en attente de validation intéressent l'admin.
    if (row['status'] != 'awaiting_admin') return;
    final amount = row['amount'];
    _push(
      DesktopNotificationEvent(
        category: DesktopNotificationCategory.payment,
        title: 'Paiement à valider',
        subtitle: amount == null
            ? 'Un paiement attend votre validation.'
            : 'Montant : $amount — en attente de validation.',
        route: DesktopNotificationCategory.payment.targetRoute,
        at: _parsedAt(row['created_at']),
        payloadId: row['id'] as String?,
      ),
    );
  }

  void _onDisputeInsert(PostgresChangePayload payload) {
    final row = payload.newRecord;
    if (row['status'] != 'open' && row['status'] != 'escalated') return;
    final reason = row['reason'] as String?;
    _push(
      DesktopNotificationEvent(
        category: DesktopNotificationCategory.dispute,
        title: 'Litige ouvert',
        subtitle: (reason != null && reason.isNotEmpty)
            ? reason
            : 'Un litige vient d’être ouvert sur un match.',
        route: DesktopNotificationCategory.dispute.targetRoute,
        at: _parsedAt(row['created_at']),
        payloadId: row['id'] as String?,
      ),
    );
  }

  void _onMessageInsert(PostgresChangePayload payload) {
    final row = payload.newRecord;
    // On ne notifie que les messages ENTRANTS (user → admin). Les rows où
    // `admin_id` correspond à l'admin de session sont des messages que
    // l'admin a lui-même envoyés → on les ignore.
    final adminId = _adminId;
    if (adminId != null && row['admin_id'] == adminId) return;

    final text = row['text'] as String?;
    final hasImage = row['image_url'] != null;
    final preview = (text != null && text.isNotEmpty)
        ? text
        : (hasImage ? '\u{1F4F7} Image' : 'Nouveau message');

    _push(
      DesktopNotificationEvent(
        category: DesktopNotificationCategory.message,
        title: 'Nouveau message',
        subtitle: preview,
        route: DesktopNotificationCategory.message.targetRoute,
        at: _parsedAt(row['sent_at']),
        payloadId: row['id'] as String?,
      ),
    );
  }

  void _onReintegrationInsert(PostgresChangePayload payload) {
    final row = payload.newRecord;
    if (row['status'] != 'pending') return;
    final message = row['message'] as String?;
    _push(
      DesktopNotificationEvent(
        category: DesktopNotificationCategory.reintegration,
        title: 'Demande de réintégration',
        subtitle: (message != null && message.isNotEmpty)
            ? message
            : 'Un compte banni demande sa réintégration.',
        route: DesktopNotificationCategory.reintegration.targetRoute,
        at: _parsedAt(row['created_at']),
        payloadId: row['id'] as String?,
      ),
    );
  }

  // ─── Mutations d'état ──────────────────────────────────────────────

  void _push(DesktopNotificationEvent event) {
    final counts =
        Map<DesktopNotificationCategory, int>.from(state.unreadByCategory)
          ..[event.category] = (state.unreadByCategory[event.category] ?? 0) + 1;

    final events = [event, ...state.recentEvents];
    if (events.length > _maxEvents) {
      events.removeRange(_maxEvents, events.length);
    }

    state = state.copyWith(unreadByCategory: counts, recentEvents: events);
  }

  /// Remet à zéro le compteur de non-lus d'une catégorie (l'admin a
  /// consulté la page correspondante).
  void markSeen(DesktopNotificationCategory category) {
    if ((state.unreadByCategory[category] ?? 0) == 0) return;
    final counts =
        Map<DesktopNotificationCategory, int>.from(state.unreadByCategory)
          ..[category] = 0;
    state = state.copyWith(unreadByCategory: counts);
  }

  /// Remet à zéro tous les compteurs (l'admin a ouvert puis vidé la
  /// cloche, ou cliqué « Tout marquer comme lu »).
  void markAllSeen() {
    if (state.totalUnread == 0) return;
    state = state.copyWith(
      unreadByCategory: const <DesktopNotificationCategory, int>{},
    );
  }

  static DateTime _parsedAt(Object? raw) {
    if (raw is String) {
      return DateTime.tryParse(raw)?.toLocal() ?? DateTime.now();
    }
    return DateTime.now();
  }
}

/// Provider du centre de notifications Realtime desktop.
final desktopNotificationsProvider =
    NotifierProvider<DesktopNotificationsNotifier, DesktopNotificationState>(
  DesktopNotificationsNotifier.new,
);
