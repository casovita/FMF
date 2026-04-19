enum AppFlavor { dev, staging, prod }

class FlavorConfig {
  const FlavorConfig({
    required this.flavor,
    required this.appName,
    required this.envLabel,
  });

  final AppFlavor flavor;
  final String appName;
  final String envLabel;

  bool get isDev => flavor == AppFlavor.dev;
  bool get isStaging => flavor == AppFlavor.staging;
  bool get isProd => flavor == AppFlavor.prod;

  static FlavorConfig? _instance;

  static FlavorConfig get current {
    assert(_instance != null, 'FlavorConfig not initialized. Call FlavorConfig.set() in main_*.dart');
    return _instance!;
  }

  static void set(FlavorConfig config) => _instance = config;
}
