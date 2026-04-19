import 'package:mobile_app/app/flavor/app_flavor.dart';

class AppConfig {
  const AppConfig._();

  static String get appName => FlavorConfig.current.appName;
  static String get envLabel => FlavorConfig.current.envLabel;
  static bool get isDebug => FlavorConfig.current.isDev;

  // TODO: Add feature flags here as the product evolves
  // static bool get enableAnalytics => FlavorConfig.current.isProd;
}
