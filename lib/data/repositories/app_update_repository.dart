import 'package:arena/data/repositories/profile_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Config de release publiée par les super-admins (table
/// `app_release_config`). Sert à proposer une mise à jour in-app (l'app
/// est distribuée en APK direct, hors Play Store).
class AppReleaseConfig {
  const AppReleaseConfig({
    required this.latestVersion,
    required this.apkUrl,
    this.latestBuild = 0,
    this.changelog,
    this.mandatory = false,
    this.minSupportedVersion,
  });

  factory AppReleaseConfig.fromJson(Map<String, dynamic> json) =>
      AppReleaseConfig(
        latestVersion: json['latest_version'] as String,
        apkUrl: json['apk_url'] as String,
        latestBuild: (json['latest_build'] as int?) ?? 0,
        changelog: json['changelog'] as String?,
        mandatory: (json['mandatory'] as bool?) ?? false,
        minSupportedVersion: json['min_supported_version'] as String?,
      );

  final String latestVersion;
  final String apkUrl;
  final int latestBuild;
  final String? changelog;
  final bool mandatory;
  final String? minSupportedVersion;
}

/// Résultat de la vérification de MAJ (null = à jour / pas de config).
class UpdateStatus {
  const UpdateStatus({
    required this.config,
    required this.currentVersion,
    required this.mandatory,
  });

  final AppReleaseConfig config;
  final String currentVersion;

  /// `true` si la version installée est sous le `min_supported_version`
  /// déclaré ET que la config est marquée obligatoire (force-update).
  final bool mandatory;
}

class AppUpdateRepository {
  const AppUpdateRepository(this._client);

  final SupabaseClient _client;
  static const _table = 'app_release_config';

  /// Lit la config Android active (ou null).
  Future<AppReleaseConfig?> fetchActiveAndroidConfig() async {
    final row = await _client
        .from(_table)
        .select()
        .eq('platform', 'android')
        .eq('is_active', true)
        .maybeSingle();
    if (row == null) return null;
    return AppReleaseConfig.fromJson(row);
  }

  /// **Admin** : lit la row brute (avec `id`) de la config Android active.
  Future<Map<String, dynamic>?> fetchAndroidConfigRow() async {
    return _client
        .from(_table)
        .select()
        .eq('platform', 'android')
        .eq('is_active', true)
        .maybeSingle();
  }

  /// **Admin** : publie / met à jour la config Android (RLS : is_admin).
  Future<void> upsertAndroidConfig({
    required String latestVersion,
    required String apkUrl,
    String? id,
    int latestBuild = 0,
    String? changelog,
    bool mandatory = false,
    String? minSupportedVersion,
  }) async {
    final payload = <String, dynamic>{
      'platform': 'android',
      'latest_version': latestVersion.trim(),
      'latest_build': latestBuild,
      'apk_url': apkUrl.trim(),
      'changelog': changelog?.trim(),
      'mandatory': mandatory,
      'min_supported_version': minSupportedVersion?.trim(),
      'is_active': true,
      'updated_by': _client.auth.currentUser?.id,
    };
    if (id != null) {
      await _client.from(_table).update(payload).eq('id', id);
    } else {
      await _client.from(_table).insert(payload);
    }
  }
}

final appUpdateRepositoryProvider = Provider<AppUpdateRepository>((ref) {
  return AppUpdateRepository(ref.watch(supabaseClientProvider));
});

/// Compare deux noms de version sémantiques (« 1.2.3 »). Renvoie `true` si
/// [candidate] est STRICTEMENT plus récent que [current]. Tolère des
/// suffixes non numériques (ignorés) et des longueurs différentes.
bool isNewerVersion(String candidate, String current) {
  int cmp(String a, String b) {
    final pa = _versionParts(a);
    final pb = _versionParts(b);
    final n = pa.length > pb.length ? pa.length : pb.length;
    for (var i = 0; i < n; i++) {
      final x = i < pa.length ? pa[i] : 0;
      final y = i < pb.length ? pb[i] : 0;
      if (x != y) return x.compareTo(y);
    }
    return 0;
  }

  return cmp(candidate, current) > 0;
}

List<int> _versionParts(String v) {
  // Garde la partie avant un éventuel '+' (build) ou '-' (pré-release).
  final core = v.split(RegExp('[+-]')).first.trim();
  return core
      .split('.')
      .map((p) => int.tryParse(p.replaceAll(RegExp('[^0-9]'), '')) ?? 0)
      .toList();
}

/// Vérifie s'il existe une MAJ proposable pour la version installée.
/// Renvoie `null` si l'app est à jour, s'il n'y a pas de config, ou hors
/// Android. Best-effort : toute erreur réseau est avalée (→ null).
final updateStatusProvider = FutureProvider.autoDispose<UpdateStatus?>((ref) async {
  try {
    final cfg = await ref.watch(appUpdateRepositoryProvider).fetchActiveAndroidConfig();
    if (cfg == null) return null;
    final info = await PackageInfo.fromPlatform();
    if (!isNewerVersion(cfg.latestVersion, info.version)) return null;
    final mustForce = cfg.mandatory &&
        cfg.minSupportedVersion != null &&
        isNewerVersion(cfg.minSupportedVersion!, info.version);
    return UpdateStatus(
      config: cfg,
      currentVersion: info.version,
      mandatory: mustForce,
    );
  } catch (_) {
    return null;
  }
});
