/// Football mobile games supported by ARENA's anti-cheat layer.
///
/// V1.0 covers eFootball (Konami) and FIFA / EA SPORTS FC Mobile (EA).
/// EA renamed "FIFA Mobile" to "EA SPORTS FC Mobile" in Sept. 2023 but
/// kept the same Android package id and iOS bundle id, so we model them
/// as a single entry.
///
/// Adding a new title later only requires extending this enum and
/// updating the `<queries>` block in `AndroidManifest.xml`.
enum TargetGame {
  efootball(
    packageAndroid: 'jp.konami.pesam',
    bundleIos: 'jp.konami.efootball',
    displayName: 'eFootball',
    publisher: 'Konami',
  ),
  eaFcMobile(
    packageAndroid: 'com.ea.gp.fifamobile',
    bundleIos: 'com.ea.fifamobile',
    displayName: 'EA SPORTS FC Mobile',
    publisher: 'Electronic Arts',
  );

  const TargetGame({
    required this.packageAndroid,
    required this.bundleIos,
    required this.displayName,
    required this.publisher,
  });

  /// Android application id used to query `installed_apps` and `app_usage`.
  final String packageAndroid;

  /// iOS bundle id. Currently informational — iOS sandboxing prevents
  /// us from detecting third-party apps, so the anti-cheat flow stays
  /// Android-only.
  final String bundleIos;

  /// Human-readable name shown in the UI.
  final String displayName;

  /// Publisher label, used in the dispute review screens to disambiguate
  /// in case two titles end up with similar display names.
  final String publisher;

  /// Resolves a [TargetGame] from an Android package name. Returns null
  /// if the package is not one of ours — most foreground events come
  /// from launchers, browsers, ARENA itself, etc.
  static TargetGame? fromAndroidPackage(String package) {
    for (final game in TargetGame.values) {
      if (game.packageAndroid == package) return game;
    }
    return null;
  }
}
