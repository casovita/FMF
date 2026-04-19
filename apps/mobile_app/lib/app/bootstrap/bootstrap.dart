import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_app/app/app.dart';
import 'package:mobile_app/app/flavor/app_flavor.dart';

Future<void> bootstrap(FlavorConfig config) async {
  WidgetsFlutterBinding.ensureInitialized();
  FlavorConfig.set(config);

  // TODO: Initialize crash reporting here when added
  // TODO: Initialize feature flags here when added

  runApp(
    const ProviderScope(
      child: FmfApp(),
    ),
  );
}
