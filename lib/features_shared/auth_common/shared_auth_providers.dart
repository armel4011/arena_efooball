import 'package:arena/core/flavors/flavor_config.dart';
import 'package:arena/core/services/persistent_cache.dart';
import 'package:arena/data/models/profile.dart';
import 'package:arena/data/repositories/auth_failure.dart';
import 'package:arena/data/repositories/auth_repository.dart';
import 'package:arena/data/repositories/profile_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

/// Providers d'authentification partagés entre l'app user et l'app admin.
///
/// Avant ce module, `features_user/auth/auth_providers.dart` exposait
/// `currentSessionProvider` / `currentProfileProvider` / `signOutProvider`
/// que l'app admin importait directement → violation de layering (admin
/// dépendant de features_user). Cette extraction supprime la dépendance
/// croisée : les deux apps consomment depuis `features_shared`.
///
/// Les controllers user-specific (SignIn, SignUp, GoogleSso, ForgotPassword,
/// ResetPassword, AcceptCgu) restent dans `features_user/auth/auth_providers.dart`.
/// Les controllers admin-specific (AdminSignIn, InvitationRedeem, TotpSetup,
/// TotpVerify) restent dans `features_admin/auth_admin/admin_auth_providers.dart`.

/// Stream of Supabase auth-state changes (signed-in, signed-out, refreshed).
///
/// Returns an empty stream if Supabase isn't initialized (creds missing
/// in `.env`, or running in a test that didn't override the client).
final authStateChangesProvider = StreamProvider<sb.AuthState>((ref) {
  try {
    return ref.watch(authRepositoryProvider).authStateChanges();
  } catch (e) {
    if (kDebugMode) {
      debugPrint('[auth] authStateChanges unavailable — empty stream: $e');
    }
    return const Stream.empty();
  }
});

/// Latest [sb.Session] — null when signed out OR when Supabase isn't
/// initialized. Re-evaluated whenever the auth stream emits.
final currentSessionProvider = Provider<sb.Session?>((ref) {
  ref.watch(authStateChangesProvider);
  try {
    return ref.watch(authRepositoryProvider).currentSession;
  } catch (e) {
    if (kDebugMode) {
      debugPrint('[auth] currentSession unavailable — null: $e');
    }
    return null;
  }
});

/// Current authenticated [Profile], with role-based gating for the
/// active flavor (admin profile in user app → [WrongAppForRoleFailure],
/// and vice-versa).
///
/// **Cold start cache** : le profil precedent est persiste via
/// PersistentCache → la home (avatar + username + tier) et la page
/// Profil (stats grid lue depuis profile.stats) s'affichent
/// instantanement au boot, meme offline. Le re-fetch reseau remplace
/// si necessaire.
final currentProfileProvider = StreamProvider<Profile?>((ref) async* {
  final session = ref.watch(currentSessionProvider);
  if (session == null) {
    yield null;
    return;
  }
  final cache = await ref.watch(persistentCacheProvider.future);
  final source = _fetchProfileOnce(ref, session.user.id);
  // Sécurité (M-3, audit 2026-06-14) : le profil contient de la PII (email,
  // WhatsApp, kycStatus) — on le cache CHIFFRÉ au repos, pas en clair dans
  // SharedPreferences (lisible sur device rooté). Cf. hydrateSingleSecure.
  yield* cache.hydrateSingleSecure<Profile>(
    namespace: 'profile.${session.user.id}',
    source: source,
    fromJson: Profile.fromJson,
    toJson: (p) => p.toJson(),
  );
});

/// Stream wrapper qui execute le fetch une seule fois puis ferme.
/// hydrateSingle veut un `Stream<Profile?>`, et on a un `Future`.
Stream<Profile?> _fetchProfileOnce(Ref ref, String userId) async* {
  final profile = await ref.watch(profileRepositoryProvider).getById(userId);
  if (profile == null) {
    yield null;
    return;
  }
  enforceRoleForFlavor(profile);
  yield profile;
}

/// Sign-out helper exposed as a callback so screens can wire it directly.
final signOutProvider = Provider<Future<void> Function()>((ref) {
  return () async {
    await ref.read(authRepositoryProvider).signOut();
    ref.invalidate(currentProfileProvider);
  };
});

/// Vérifie que le profil correspond au flavor de l'app courante
/// (admin profile dans l'app user et vice-versa → erreur). Levé en haut
/// de chaque controller de sign-in pour évacuer les comptes mal aiguillés
/// avant que la session ne se propage dans le router.
void enforceRoleForFlavor(Profile profile) {
  if (FlavorConfig.instance.isUser && profile.isAdmin) {
    throw const WrongAppForRoleFailure();
  }
  if (FlavorConfig.instance.isAdmin && !profile.isAdmin) {
    throw const WrongAppForRoleFailure();
  }
}
