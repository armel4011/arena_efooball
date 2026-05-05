enum Flavor { user, admin }

class FlavorConfig {
  FlavorConfig._({
    required this.flavor,
    required this.appName,
    required this.bundleId,
  });

  static FlavorConfig? _instance;

  static FlavorConfig get instance {
    final instance = _instance;
    if (instance == null) {
      throw StateError(
        'FlavorConfig not initialized. Call FlavorConfig.init() in main.',
      );
    }
    return instance;
  }

  final Flavor flavor;
  final String appName;
  final String bundleId;

  bool get isUser => flavor == Flavor.user;
  bool get isAdmin => flavor == Flavor.admin;

  static void init({
    required Flavor flavor,
    required String appName,
    required String bundleId,
  }) {
    _instance = FlavorConfig._(
      flavor: flavor,
      appName: appName,
      bundleId: bundleId,
    );
  }
}
